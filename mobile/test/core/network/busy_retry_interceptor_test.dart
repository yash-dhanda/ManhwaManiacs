import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/network/interceptors/busy_retry_interceptor.dart';
import 'package:manhwamaniacs/core/network/interceptors/error_interceptor.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.status, this.code, {this.retryAfter});
  final int status;
  final String code;
  final String? retryAfter;
  final calls = <DateTime>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    calls.add(DateTime.now());
    return ResponseBody.fromString(jsonEncode({'code': code, 'message': 'busy'}), status, headers: {
      Headers.contentTypeHeader: ['application/json'],
      if (retryAfter != null) 'retry-after': [retryAfter!],
    },);
  }

  @override
  void close({bool force = false}) {}
}

({Dio dio, _Adapter adapter, int Function() exhausted}) _make(_Adapter a) {
  var n = 0;
  final dio = Dio(BaseOptions(baseUrl: 'https://x.test'))..httpClientAdapter = a;
  dio.interceptors.addAll([BusyRetryInterceptor(dio, onExhausted: () => n++, backoff: const [Duration(milliseconds: 20)], jitter: Duration.zero), ErrorInterceptor()]);
  return (dio: dio, adapter: a, exhausted: () => n);
}

Future<AppError?> _get(Dio d, {String method = 'GET'}) async {
  try {
    await d.request<dynamic>('/x', options: Options(method: method));
  } on DioException catch (e) {
    return e.error as AppError?;
  }
  return null;
}

/// Answers each call from [script] in order (the last entry repeats): a status, or an exception to throw.
class _Scripted implements HttpClientAdapter {
  _Scripted(this.script);
  final List<Object> script;
  int calls = 0;
  void Function()? onCall;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final step = script[calls < script.length ? calls : script.length - 1];
    calls++;
    onCall?.call();
    if (step is DioException) throw DioException(requestOptions: options, type: step.type, error: step.error, message: step.message);
    if (step is Exception) throw step;
    if (step is _Status) {
      return ResponseBody.fromString(jsonEncode({'code': step.code, 'message': 'm'}), step.status, headers: {
        Headers.contentTypeHeader: ['application/json'],
        if (step.retryAfter != null) 'retry-after': [step.retryAfter!],
      },);
    }
    return ResponseBody.fromString(jsonEncode({'ok': true}), 200, headers: {
      Headers.contentTypeHeader: ['application/json'],
    },);
  }

  @override
  void close({bool force = false}) {}
}

class _Status {
  const _Status(this.status, {this.code = 'x', this.retryAfter});
  final int status;
  final String code;
  final String? retryAfter;
}

const _ok = 'ok';

({Dio dio, _Scripted adapter}) _scripted(List<Object> script) {
  final a = _Scripted(script);
  final dio = Dio(BaseOptions(baseUrl: 'https://x.test'))..httpClientAdapter = a;
  dio.interceptors.addAll([BusyRetryInterceptor(dio, backoff: const [Duration(milliseconds: 5)], jitter: Duration.zero), ErrorInterceptor()]);
  return (dio: dio, adapter: a);
}

DioException _dioErr(DioExceptionType t, [Object? error]) => DioException(requestOptions: RequestOptions(), type: t, error: error);

void main() {
  for (final status in [502, 503, 504]) {
    test('a GET $status recovers on the second attempt', () async {
      final m = _scripted([_Status(status, code: status == 503 ? 'other' : 'x'), _ok]);
      final r = await m.dio.get<dynamic>('/x');
      expect(r.statusCode, 200);
      expect(m.adapter.calls, 2);
    });
  }

  test('a 429 with a short Retry-After recovers', () async {
    final m = _scripted([const _Status(429, code: 'rate_limited', retryAfter: '0'), _ok]);
    expect((await m.dio.get<dynamic>('/x')).statusCode, 200);
    expect(m.adapter.calls, 2);
  });

  for (final e in <String, Object>{
    'connectionError': _dioErr(DioExceptionType.connectionError),
    'connection closed HttpException': _dioErr(DioExceptionType.unknown, const HttpException('Connection closed before full header was received')),
    'connection reset SocketException': _dioErr(DioExceptionType.unknown, const SocketException('Connection reset by peer')),
    'connectionTimeout': _dioErr(DioExceptionType.connectionTimeout),
    'receiveTimeout': _dioErr(DioExceptionType.receiveTimeout),
  }.entries) {
    test('${e.key} recovers on the second attempt', () async {
      final m = _scripted([e.value, _ok]);
      expect((await m.dio.get<dynamic>('/x')).statusCode, 200);
      expect(m.adapter.calls, 2);
    });
  }

  test('a timeout is retried once only', () async {
    final m = _scripted([_dioErr(DioExceptionType.receiveTimeout)]);
    await _get(m.dio);
    expect(m.adapter.calls, 2);
  });

  test('a POST without the opt-in is not retried, with it is', () async {
    final a = _scripted([const _Status(502), _ok]);
    await _get(a.dio, method: 'POST');
    expect(a.adapter.calls, 1);
    final b = _scripted([const _Status(502), _ok]);
    final r = await b.dio.post<dynamic>('/x', options: Options(extra: {'mm.idempotent': true}));
    expect(r.statusCode, 200);
    expect(b.adapter.calls, 2);
  });

  test('a PUT / PATCH / DELETE is not retried even with 502', () async {
    for (final m in ['PUT', 'PATCH', 'DELETE']) {
      final s = _scripted([const _Status(502), _ok]);
      await _get(s.dio, method: m);
      expect(s.adapter.calls, 1, reason: m);
    }
  });

  test('a 429 without Retry-After, or with a long one, is not retried', () async {
    final a = _scripted([const _Status(429, code: 'rate_limited'), _ok]);
    await _get(a.dio);
    expect(a.adapter.calls, 1);
    final b = _scripted([const _Status(429, code: 'rate_limited', retryAfter: '11'), _ok]);
    await _get(b.dio);
    expect(b.adapter.calls, 1);
  });

  test('401, 404, 409, 422 and 423 are not retried', () async {
    for (final s in [401, 404, 409, 422, 423]) {
      final m = _scripted([_Status(s, code: s == 423 ? 'chapter_locked' : 'x'), _ok]);
      await _get(m.dio);
      expect(m.adapter.calls, 1, reason: '$s');
    }
  });

  test('at most two retries', () async {
    final m = _scripted([const _Status(502)]);
    final e = await _get(m.dio) as ApiError;
    expect(m.adapter.calls, 3);
    expect(e.statusCode, 502);
  });

  test('a cancelled request is not retried and a pending wait ends', () async {
    final token = CancelToken();
    final a = _Scripted([const _Status(502), _ok]);
    final dio = Dio(BaseOptions(baseUrl: 'https://x.test'))..httpClientAdapter = a;
    dio.interceptors.addAll([BusyRetryInterceptor(dio, backoff: const [Duration(seconds: 30)], jitter: Duration.zero), ErrorInterceptor()]);
    Timer(const Duration(milliseconds: 50), token.cancel);
    final sw = Stopwatch()..start();
    try {
      await dio.get<dynamic>('/x', cancelToken: token);
      fail('should have been cancelled');
    } on DioException catch (e) {
      expect(e.type, DioExceptionType.cancel);
    }
    expect(a.calls, 1);
    expect(sw.elapsed, lessThan(const Duration(seconds: 5)));
  });

  test('three retries honour the delay, then the counter goes up once', () async {
    final m = _make(_Adapter(503, 'db_busy', retryAfter: '0'));
    final e = await _get(m.dio);
    expect(m.adapter.calls.length, 3);
    expect(m.exhausted(), 1);
    expect((e! as ApiError).code, 'db_busy');
  });

  test('the fallback delay applies without Retry-After', () async {
    final m = _make(_Adapter(503, 'db_busy'));
    await _get(m.dio);
    final c = m.adapter.calls;
    for (var i = 1; i < c.length; i++) {
      expect(c[i].difference(c[i - 1]).inMilliseconds, greaterThanOrEqualTo(15));
    }
  });

  test('a POST 503 is not retried', () async {
    final m = _make(_Adapter(503, 'db_busy', retryAfter: '0'));
    await _get(m.dio, method: 'POST');
    expect(m.adapter.calls.length, 1);
    expect(m.exhausted(), 0);
  });

  test('a 503 with another code is retried too, without the busy counter', () async {
    final m = _make(_Adapter(503, 'other', retryAfter: '0'));
    await _get(m.dio);
    expect(m.adapter.calls.length, 3);
    expect(m.exhausted(), 0);
  });

  test('ErrorInterceptor fills retryAfter', () async {
    final m = _make(_Adapter(429, 'rate', retryAfter: '7'));
    final e = await _get(m.dio) as ApiError;
    expect(e.retryAfter, const Duration(seconds: 7));
  });
}
