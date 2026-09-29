import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/network/interceptors/error_interceptor.dart';

/// Simulates an unreachable server by throwing a connection error instead of
/// performing a real fetch, so the interceptor's mapping runs end-to-end.
class _FailingAdapter implements HttpClientAdapter {
  _FailingAdapter(this.type);

  final DioExceptionType type;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: type,
      error: 'boom',
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dio(DioExceptionType type) {
  return Dio(BaseOptions(baseUrl: 'https://app.manhwamaniacs.xyz'))
    ..httpClientAdapter = _FailingAdapter(type)
    ..interceptors.add(ErrorInterceptor());
}

class _Status429 implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? r, Future<void>? c) async =>
      ResponseBody.fromString('{"code":"rate_limited","message":"slow"}', 429, headers: {
        Headers.contentTypeHeader: ['application/json'],
        'retry-after': ['7'],
      },);

  @override
  void close({bool force = false}) {}
}

void main() {
  test('429 Retry-After header lands in ApiError.details', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://x.test'))
      ..httpClientAdapter = _Status429()
      ..interceptors.add(ErrorInterceptor());
    try {
      await dio.get<void>('/a');
      fail('should throw');
    } on DioException catch (e) {
      final err = e.error! as ApiError;
      expect((err.details! as Map)['retry_after'], 7);
    }
  });

  group('ErrorInterceptor', () {
    test('maps a connection error to a host-aware NetworkError', () async {
      NetworkError? mapped;
      try {
        await _dio(DioExceptionType.connectionError)
            .post<dynamic>('/auth/login');
      } on DioException catch (e) {
        mapped = e.error as NetworkError?;
      }

      expect(mapped, isNotNull);
      expect(mapped!.host, 'app.manhwamaniacs.xyz');
      expect(mapped.userMessage, contains('app.manhwamaniacs.xyz'));
    });

    test('maps a bad certificate to a host-aware NetworkError', () async {
      NetworkError? mapped;
      try {
        await _dio(DioExceptionType.badCertificate).get<dynamic>('/health');
      } on DioException catch (e) {
        mapped = e.error as NetworkError?;
      }

      expect(mapped, isNotNull);
      expect(mapped!.host, 'app.manhwamaniacs.xyz');
    });
  });

  group('NetworkError.userMessage', () {
    test('falls back to a generic message when the host is unknown', () {
      expect(
        const NetworkError(message: 'x').userMessage,
        'Network error — check your connection.',
      );
    });

    test('names the server when the host is known', () {
      expect(
        const NetworkError(message: 'x', host: 'example.test').userMessage,
        "Can't reach the server at example.test — check your connection.",
      );
    });
  });
}
