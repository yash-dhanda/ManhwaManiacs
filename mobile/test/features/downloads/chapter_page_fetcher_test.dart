import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/network/interceptors/busy_retry_interceptor.dart';
import 'package:manhwamaniacs/features/downloads/services/chapter_page_fetcher.dart';

class _Capture implements HttpClientAdapter {
  RequestOptions? seen;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    seen = options;
    return ResponseBody.fromBytes([1, 2, 3], 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('a page fetch opts out of the interceptor\'s retries: the queue waits and retries pages itself', () async {
    final adapter = _Capture();
    final dio = Dio()..httpClientAdapter = adapter;
    final bytes = await DioChapterPageFetcher(dio).fetchPageBytes('https://x.test/p1');
    expect(bytes, [1, 2, 3]);
    expect(adapter.seen!.extra[kNoAutoRetryExtraKey], true);
  });
}
