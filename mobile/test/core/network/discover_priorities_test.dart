import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/network/request_limiter.dart';
import 'package:manhwamaniacs/core/utils/pagination.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/ocr/providers/dialogue_still_provider.dart';
import 'package:manhwamaniacs/features/reader/models/reader_page.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/providers/discover_providers.dart';
import 'package:manhwamaniacs/features/sources/repositories/sources_repository.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

class _Limiter extends RequestLimiter {
  final seen = <RequestPriority>[];

  @override
  Future<T> run<T>(RequestPriority priority, Future<T> Function() request) {
    seen.add(priority);
    return request();
  }
}

class _Repo implements SourcesRepository {
  @override
  Future<Result<PagedResult<SourceSeriesSummary>>> listSeries(
    String sourceId, {
    int page = 1,
    String? query,
    String? sort,
    String? genre,
    bool refresh = false,
  }) async =>
      const Ok(PagedResult(
          items: [], total: 0, page: 1, perPage: 20, hasNext: false,),);

  @override
  Future<Result<List<ReaderPage>>> getChapterPages(
          String sourceId, String chapterKey,) async =>
      const Ok([
        ReaderPage(
            id: 'p',
            number: 1,
            imageUrl: 'http://x/p.png',
            width: 700,
            height: 1000,),
      ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Bytes implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
          RequestOptions o, Stream<Uint8List>? s, Future<void>? f,) async =>
      ResponseBody.fromBytes([1, 2, 3], 200);

  @override
  void close({bool force = false}) {}
}

void main() {
  test('genre cover lookup runs at P3', () async {
    final limiter = _Limiter();
    final c = ProviderContainer(overrides: [
      requestLimiterProvider.overrideWithValue(limiter),
      sourcesRepositoryProvider.overrideWithValue(_Repo()),
    ],);
    addTearDown(c.dispose);
    await c.read(genreCoverProvider((sourceId: 's', genre: 'Romance')).future);
    expect(limiter.seen, [RequestPriority.p3]);
  });

  test('dialogue still: page list at P1, image at P3', () async {
    final limiter = _Limiter();
    final dio = Dio()..httpClientAdapter = _Bytes();
    final c = ProviderContainer(overrides: [
      requestLimiterProvider.overrideWithValue(limiter),
      sourcesRepositoryProvider.overrideWithValue(_Repo()),
      downloadsStoreProvider.overrideWithValue(null),
      dioProvider.overrideWithValue(dio),
    ],);
    addTearDown(c.dispose);
    final still = await c.read(dialogueStillProvider(
      (chapter: (sourceId: 's', seriesKey: 'k', chapterKey: 'c'), page: 1),
    ).future,);
    expect(still?.bytes, isNotNull);
    expect(still?.aspect, closeTo(0.7, 1e-9));
    expect(limiter.seen, [RequestPriority.p1, RequestPriority.p3]);
  });
}
