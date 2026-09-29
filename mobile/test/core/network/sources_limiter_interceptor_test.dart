// ignore_for_file: unawaited_futures
import 'dart:io' show HttpDate;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/network/interceptors/sources_limiter_interceptor.dart';
import 'package:manhwamaniacs/core/network/request_limiter.dart';

import 'request_limiter_test.dart' show ManualClock;

/// Answers every request with [status] and an optional Retry-After.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.status, this.retryAfter);
  final int status;
  final String? retryAfter;
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<List<int>>? body, Future<void>? cancel) async =>
      ResponseBody.fromString('{}', status, headers: {
        Headers.contentTypeHeader: ['application/json'],
        if (retryAfter != null) 'retry-after': [retryAfter!],
      },);
}

void main() {
  late ManualClock clock;
  late RequestLimiter lim;
  setUp(() {
    clock = ManualClock();
    lim = RequestLimiter(now: () => clock.now, createTimer: clock.create);
  });

  Dio dio(int status, [String? retryAfter]) => Dio(BaseOptions(baseUrl: 'http://x'))
    ..httpClientAdapter = _Adapter(status, retryAfter)
    ..interceptors.add(SourcesLimiterInterceptor(lim));

  test('a /sources request records a start and a /library request does not', () async {
    final d = dio(200);
    await d.get<dynamic>('/library/list');
    expect(lim.free(), 50);
    await d.get<dynamic>('/sources/x/search');
    expect(lim.free(), 49);
  });

  test('a 429 with Retry-After: 7 pauses P2 for 7 s', () async {
    final d = dio(429, '7');
    await expectLater(d.get<dynamic>('/sources/x'), throwsA(isA<DioException>()));
    var started = false;
    lim.acquire(RequestPriority.p2).then((_) => started = true);
    await clock.advance(const Duration(seconds: 6));
    expect(started, isFalse);
    await clock.advance(const Duration(seconds: 1));
    expect(started, isTrue);
  });

  test('an HTTP-date Retry-After parses', () async {
    final at = DateTime.now().add(const Duration(seconds: 11)); // the interceptor reads the real clock
    final d = dio(429, HttpDate.format(at));
    await expectLater(d.get<dynamic>('/sources/x'), throwsA(isA<DioException>()));
    var started = false;
    lim.acquire(RequestPriority.p2).then((_) => started = true);
    await clock.advance(const Duration(seconds: 8));
    expect(started, isFalse);
    await clock.advance(const Duration(seconds: 4));
    expect(started, isTrue);
  });
}
