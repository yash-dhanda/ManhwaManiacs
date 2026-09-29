// ignore_for_file: require_trailing_commas
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/setup/utils/server_check.dart';

Dio _dio(Future<ResponseBody> Function() answer) {
  final d = Dio(BaseOptions(baseUrl: 'https://x'));
  d.httpClientAdapter = _Adapter(answer);
  return d;
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.answer);
  final Future<ResponseBody> Function() answer;
  @override
  Future<ResponseBody> fetch(
          RequestOptions o, Stream<List<int>>? s, Future<void>? c) =>
      answer();
  @override
  void close({bool force = false}) {}
}

ResponseBody _json(String body, [int code = 200]) =>
    ResponseBody.fromString(body, code, headers: {
      Headers.contentTypeHeader: ['application/json']
    });

Future<ServerCheck> run(String url, Future<ResponseBody> Function() a,
        {bool release = false, bool online = true}) =>
    checkServer(url,
        releaseBuild: release,
        isOnline: () async => online,
        dioFor: (_) => _dio(a));

void main() {
  test('ok normalises', () async {
    final r = await run(
        'https://h.example/ ', () async => _json('{"name":"ManhwaManiacs"}'));
    expect((r as ServerCheckOk).normalisedUrl, 'https://h.example');
  });
  test(
      'offline',
      () async => expect(
          await run('https://h', () async => _json('{}'), online: false),
          isA<ServerCheckOffline>()));
  test(
      'http in release',
      () async => expect(
          await run('http://h', () async => _json('{}'), release: true),
          isA<ServerCheckHttpInRelease>()));
  test('not ManhwaManiacs', () async {
    expect(await run('https://h', () async => _json('{"name":"x"}')),
        isA<ServerCheckNotManhwaManiacs>());
    expect(await run('https://h', () async => _json('{}', 404)),
        isA<ServerCheckNotManhwaManiacs>());
  });
  test(
      'tls',
      () async => expect(
          await run(
              'https://h',
              () async => throw DioException(
                  requestOptions: RequestOptions(),
                  error:
                      const HandshakeException('CERTIFICATE_VERIFY_FAILED'))),
          isA<ServerCheckTls>()));
  test(
      'timeout',
      () async => expect(
          await run(
              'https://h',
              () async => throw DioException(
                  requestOptions: RequestOptions(),
                  type: DioExceptionType.connectionTimeout)),
          isA<ServerCheckTimeout>()));
  test(
      'unreachable',
      () async => expect(
          await run(
              'https://h',
              () async => throw DioException(
                  requestOptions: RequestOptions(), message: 'nope')),
          isA<ServerCheckUnreachable>()));
}
