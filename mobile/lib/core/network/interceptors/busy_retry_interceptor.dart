import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:manhwamaniacs/core/network/retry_after.dart';

/// `options.extra` key that marks a non-GET request as safe to repeat (read-only). Only the bulk
/// `POST /reader/chapters/manifest` window sets it; no other POST/PUT/PATCH/DELETE may.
const String kIdempotentExtraKey = 'mm.idempotent';

/// Quietly repeats a request that failed in a way a second try usually fixes, so the reader never
/// sees a "Try again" for a hiccup. Sits before `ErrorInterceptor` so it reads the raw
/// [DioException].
///
/// Only `GET`/`HEAD`, or a request that sets [kIdempotentExtraKey]; anything else could double an
/// effect. Retried: 502, 503 (any code), 504, a 429 whose `Retry-After` is at most [maxRetryAfter]
/// (a longer one is the server asking for real quiet, which the limiters and the screens own),
/// `connectionError` and a closed / reset socket (a reused keep-alive socket the OS dropped while
/// the app slept), and a connect / receive timeout once. Never a 4xx other than 429: 401 belongs to
/// the auth interceptor, 423 `chapter_locked` has its own screen state.
///
/// At most [maxRetries] repeats per request, each after `Retry-After` (capped) else the next
/// [backoff] step plus up to [jitter]. A cancelled request is not repeated and a pending wait ends
/// at once. After the last `503 db_busy` failure [onExhausted] runs once and the error goes on to
/// the error mapping.
class BusyRetryInterceptor extends Interceptor {
  BusyRetryInterceptor(
    this._dio, {
    this.onExhausted,
    this.maxRetries = 2,
    this.backoff = const [Duration(milliseconds: 500), Duration(milliseconds: 1500)],
    this.jitter = const Duration(milliseconds: 250),
    this.maxRetryAfter = const Duration(seconds: 10),
    Timer Function(Duration, void Function())? createTimer,
    Random? random,
  })  : _createTimer = createTimer ?? Timer.new,
        _random = random ?? Random();

  final Dio _dio;
  final void Function()? onExhausted;
  final int maxRetries;
  final List<Duration> backoff;
  final Duration jitter;
  final Duration maxRetryAfter;
  final Timer Function(Duration, void Function()) _createTimer;
  final Random _random;
  // The attempt counter rides on the request, so the nested pass through this interceptor (the
  // retry is a fresh `fetch`) continues the count instead of starting over.
  static const _key = 'mm.busy.attempt';

  static bool _isBusy(Response<dynamic>? r) {
    if (r?.statusCode != 503) return false;
    final d = r!.data;
    return d is Map && d['code'] == 'db_busy';
  }

  bool _safeToRepeat(RequestOptions o) {
    final method = o.method.toUpperCase();
    return method == 'GET' || method == 'HEAD' || o.extra[kIdempotentExtraKey] == true;
  }

  bool _isClosedSocket(Object? e) {
    if (e is SocketException) return true;
    if (e is HttpException) return RegExp('closed|reset', caseSensitive: false).hasMatch(e.message);
    return false;
  }

  /// How many repeats this failure allows, or 0 when it is not one worth repeating.
  int _allowedRetries(DioException err) {
    switch (err.type) {
      case DioExceptionType.badResponse:
        final r = err.response;
        final status = r?.statusCode;
        if (status == 502 || status == 503 || status == 504) return maxRetries;
        if (status == 429) {
          final ra = parseRetryAfter(r!.headers.value('retry-after'));
          return ra != null && ra <= maxRetryAfter ? maxRetries : 0;
        }
        return 0;
      case DioExceptionType.connectionError:
        return maxRetries;
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return min(1, maxRetries);
      case DioExceptionType.unknown:
        return _isClosedSocket(err.error) ? maxRetries : 0;
      default:
        return 0;
    }
  }

  Duration _delayFor(DioException err, int attempt) {
    final ra = parseRetryAfter(err.response?.headers.value('retry-after'));
    if (ra != null) return ra > maxRetryAfter ? maxRetryAfter : ra;
    final base = backoff.isEmpty ? Duration.zero : backoff[min(attempt, backoff.length - 1)];
    return base + Duration(milliseconds: jitter.inMilliseconds == 0 ? 0 : _random.nextInt(jitter.inMilliseconds + 1));
  }

  /// Completes after [d], or as soon as [token] is cancelled; the timer never outlives either.
  Future<void> _wait(Duration d, CancelToken? token) {
    final done = Completer<void>();
    final timer = _createTimer(d, () {
      if (!done.isCompleted) done.complete();
    });
    token?.whenCancel.then((_) {
      timer.cancel();
      if (!done.isCompleted) done.complete();
    });
    return done.future;
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final o = err.requestOptions;
    if (!_safeToRepeat(o) || CancelToken.isCancel(err)) return handler.next(err);
    final attempt = (o.extra[_key] as int?) ?? 0;
    final allowed = _allowedRetries(err);
    if (attempt >= allowed) {
      if (allowed > 0 && _isBusy(err.response)) onExhausted?.call();
      return handler.next(err);
    }
    await _wait(_delayFor(err, attempt), o.cancelToken);
    final token = o.cancelToken;
    if (token != null && token.isCancelled) {
      return handler.next(DioException.requestCancelled(requestOptions: o, reason: token.cancelError?.error));
    }
    o.extra[_key] = attempt + 1;
    try {
      handler.resolve(await _dio.fetch<dynamic>(o));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
