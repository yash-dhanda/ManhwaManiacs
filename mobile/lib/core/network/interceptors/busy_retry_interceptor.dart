import 'dart:async';

import 'package:dio/dio.dart';
import 'package:manhwamaniacs/core/network/retry_after.dart';

/// Quietly retries a `GET` or `HEAD` that got `503` with code `db_busy`: up to [maxRetries]
/// times, each after `Retry-After` (else [fallback]). After the last failure [onExhausted] runs
/// once and the error goes on to the error mapping.
class BusyRetryInterceptor extends Interceptor {
  BusyRetryInterceptor(this._dio, {this.onExhausted, this.maxRetries = 3, this.fallback = const Duration(milliseconds: 2000)});

  final Dio _dio;
  final void Function()? onExhausted;
  final int maxRetries;
  final Duration fallback;
  static const _key = 'mm.busy.attempt';

  static bool _isBusy(Response<dynamic>? r) {
    if (r?.statusCode != 503) return false;
    final d = r!.data;
    return d is Map && d['code'] == 'db_busy';
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final o = err.requestOptions;
    final method = o.method.toUpperCase();
    if ((method != 'GET' && method != 'HEAD') || !_isBusy(err.response)) return handler.next(err);
    final attempt = (o.extra[_key] as int?) ?? 0;
    if (attempt >= maxRetries) {
      onExhausted?.call();
      return handler.next(err);
    }
    final wait = parseRetryAfter(err.response!.headers.value('retry-after')) ?? fallback;
    await Future<void>.delayed(wait);
    o.extra[_key] = attempt + 1;
    try {
      handler.resolve(await _dio.fetch<dynamic>(o));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
