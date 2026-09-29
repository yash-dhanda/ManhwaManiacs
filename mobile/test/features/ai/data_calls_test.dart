// ignore_for_file: require_trailing_commas, avoid_dynamic_calls, prefer_const_declarations, unnecessary_null_checks
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/ai/repositories/ai_repository.dart';
import 'package:manhwamaniacs/features/library/repositories/library_repository_impl.dart';
import 'package:manhwamaniacs/features/sources/repositories/sources_repository_impl.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);
  final (int, Object?) Function(RequestOptions) respond;
  final calls = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? b, Future<void>? c) async {
    calls.add(o);
    final (code, body) = respond(o);
    return ResponseBody.fromString(jsonEncode(body), code, headers: {
      Headers.contentTypeHeader: ['application/json']
    });
  }

  @override
  void close({bool force = false}) {}
}

Dio _dio(_Adapter a) =>
    Dio(BaseOptions(baseUrl: 'http://x', validateStatus: (s) => s! < 400))..httpClientAdapter = a;

Map<String, dynamic> get _followed => {
      'id': 7,
      'source_id': 's',
      'series_key': 'k',
      'title': 'T',
      'cover_url': '',
      'is_favorite': false,
      'reading_status': 'reading',
      'notify': true,
      'sort_order': 0,
      'content_rating': 'safe',
      'rating': 'safe',
      'chapter_count': 1,
    };

void main() {
  test('enrichment maps fields and null', () async {
    final a = _Adapter((_) => (
          200,
          {
            'anilist_id': 5,
            'format': 'MANHWA',
            'score': 8.4,
            'official': [
              {'site': 'Tapas', 'url': 'https://t'}
            ]
          }
        ));
    final r = await SourcesRepositoryImpl(_dio(a), 'http://x').seriesEnrichment('s', 'k');
    final e = (r as Ok).value!;
    expect((e.anilistId, e.format, e.score, e.official.single.site), (5, 'MANHWA', 8.4, 'Tapas'));
    expect(a.calls.single.queryParameters, {'source': 's', 'series': 'k'});
    final n = await SourcesRepositoryImpl(_dio(_Adapter((_) => (200, null))), 'http://x')
        .seriesEnrichment('s', 'k');
    expect((n as Ok).value, isNull);
  });

  test('suggested tags: ok, and any failure means absent', () async {
    final ok = AiRepository(_dio(_Adapter((_) => (
          200,
          {
            'tags': ['a', ' b '],
            'available': true
          }
        ))));
    expect((await ok.suggestedTags('s', 'k')).tags, ['a', 'b']);
    final bad = AiRepository(_dio(_Adapter((_) => (404, {}))));
    expect(await bad.suggestedTags('s', 'k'), kNoSuggestedTags);
  });

  test('patchSeries sends null only for clear; repoint body and mapping', () async {
    final a = _Adapter((o) => o.path.endsWith('repoint')
        ? (200, {'followed': _followed, 'mapped_chapter_key': 'c9', 'mapped_chapter_number': 142})
        : (200, _followed));
    final repo = LibraryRepositoryImpl(_dio(a));
    await repo.patchSeries(7, clearMatureOverride: true);
    expect(a.calls.last.data, {'mature_override': null});
    await repo.patchSeries(7, matureOverride: false);
    expect(a.calls.last.data, {'mature_override': false});
    await repo.patchSeries(7, notify: true);
    expect((a.calls.last.data as Map).containsKey('mature_override'), false);
    final r = (await repo.repoint(7, sourceId: 'n', seriesKey: 'nk', keepOld: true) as Ok).value;
    expect(a.calls.last.data, {'source_id': 'n', 'series_key': 'nk', 'keep_old': true});
    expect((r.mappedChapterKey, r.mappedChapterNumber), ('c9', 142.0));
  });
}
