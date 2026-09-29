import 'dart:convert';
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
  dio.interceptors.addAll([BusyRetryInterceptor(dio, onExhausted: () => n++, fallback: const Duration(milliseconds: 20)), ErrorInterceptor()]);
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

void main() {
  test('three retries honour the delay, then the counter goes up once', () async {
    final m = _make(_Adapter(503, 'db_busy', retryAfter: '0'));
    final e = await _get(m.dio);
    expect(m.adapter.calls.length, 4);
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

  test('a 503 with another code is not retried', () async {
    final m = _make(_Adapter(503, 'other', retryAfter: '0'));
    await _get(m.dio);
    expect(m.adapter.calls.length, 1);
  });

  test('ErrorInterceptor fills retryAfter', () async {
    final m = _make(_Adapter(429, 'rate', retryAfter: '7'));
    final e = await _get(m.dio) as ApiError;
    expect(e.retryAfter, const Duration(seconds: 7));
  });
}
