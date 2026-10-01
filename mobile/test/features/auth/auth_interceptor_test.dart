import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/network/interceptors/auth_interceptor.dart';

/// Captures the outgoing request and returns a canned response without touching
/// the network, so the interceptor can be exercised end-to-end.
class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter({this.statusCode = 200});

  final int statusCode;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      '{}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Answers 401 only once released, so the token can change while the request is out.
class _GatedAdapter implements HttpClientAdapter {
  final _gate = Completer<void>();
  void release() => _gate.complete();

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    await _gate.future;
    return ResponseBody.fromString('{}', 401, headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
  }

  @override
  void close({bool force = false}) {}
}

Dio _dio(AuthInterceptor interceptor, HttpClientAdapter adapter) {
  return Dio(BaseOptions(baseUrl: 'https://example.test'))
    ..httpClientAdapter = adapter
    ..interceptors.add(interceptor);
}

void main() {
  group('AuthInterceptor', () {
    test('attaches the bearer token when present', () async {
      final store = AuthTokenStore()..token = 'abc123';
      final adapter = _CapturingAdapter();
      final dio = _dio(
        AuthInterceptor(tokenStore: store, onUnauthorized: () {}),
        adapter,
      );

      await dio.get<dynamic>('/downloads');

      expect(adapter.lastRequest!.headers['Authorization'], 'Bearer abc123');
    });

    test('omits the header when there is no token', () async {
      final adapter = _CapturingAdapter();
      final dio = _dio(
        AuthInterceptor(tokenStore: AuthTokenStore(), onUnauthorized: () {}),
        adapter,
      );

      await dio.get<dynamic>('/downloads');

      expect(
        adapter.lastRequest!.headers.containsKey('Authorization'),
        isFalse,
      );
    });

    test('invokes onUnauthorized on a 401 for a protected route', () async {
      var expired = 0;
      final dio = _dio(
        AuthInterceptor(
          tokenStore: AuthTokenStore()..token = 't',
          onUnauthorized: () => expired++,
        ),
        _CapturingAdapter(statusCode: 401),
      );

      await expectLater(
        dio.get<dynamic>('/downloads'),
        throwsA(isA<DioException>()),
      );
      expect(expired, 1);
    });

    test('a 401 for a request sent without the current token is not an expiry', () async {
      var expired = 0;
      final store = AuthTokenStore();
      final adapter = _GatedAdapter();
      final dio = _dio(AuthInterceptor(tokenStore: store, onUnauthorized: () => expired++), adapter);

      // Sent before the launch-time restore set the token; it answers after.
      final pending = dio.get<dynamic>('/profiles');
      await pumpEventQueue();
      store.token = 'restored';
      adapter.release();
      await expectLater(pending, throwsA(isA<DioException>()));
      // Sent under a token that has since been replaced.
      final adapter2 = _GatedAdapter();
      dio.httpClientAdapter = adapter2;
      final stale = dio.get<dynamic>('/profiles');
      await pumpEventQueue();
      store.token = 'newer';
      adapter2.release();
      await expectLater(stale, throwsA(isA<DioException>()));
      expect(expired, 0);
    });

    test('ignores a 401 from the public login endpoint', () async {
      var expired = 0;
      final dio = _dio(
        AuthInterceptor(
          tokenStore: AuthTokenStore(),
          onUnauthorized: () => expired++,
        ),
        _CapturingAdapter(statusCode: 401),
      );

      await expectLater(
        dio.post<dynamic>('/auth/login'),
        throwsA(isA<DioException>()),
      );
      expect(expired, 0);
    });

    test('ignores a 401 from the launch-time /auth/me probe', () async {
      var expired = 0;
      final dio = _dio(
        AuthInterceptor(
          tokenStore: AuthTokenStore()..token = 'stale',
          onUnauthorized: () => expired++,
        ),
        _CapturingAdapter(statusCode: 401),
      );

      await expectLater(
        dio.get<dynamic>('/auth/me'),
        throwsA(isA<DioException>()),
      );
      expect(expired, 0);
    });
  });
}
