import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/network/interceptors/error_interceptor.dart';
import 'package:manhwamaniacs/features/novels/repositories/novels_repository.dart';
import 'package:manhwamaniacs/features/novels/repositories/novels_repository_impl.dart';

import '../../../support/narration_harness.dart';

class _Adapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  int status = 200;
  Object body = <String, Object?>{};
  Uint8List? bytes;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    if (bytes != null) {
      return ResponseBody.fromBytes(bytes!, status, headers: {Headers.contentTypeHeader: ['audio/ogg']});
    }
    return ResponseBody.fromString(jsonEncode(body), status, headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _Adapter adapter;
  late NovelsRepositoryImpl repo;

  setUp(() {
    adapter = _Adapter();
    repo = NovelsRepositoryImpl(
      Dio(BaseOptions(baseUrl: 'https://x.test'))
        ..httpClientAdapter = adapter
        ..interceptors.add(ErrorInterceptor()),
    );
  });

  test('requestAudio sends priority and force', () async {
    adapter.body = {'queued': <Object>[], 'skipped': <Object>[]};
    await repo.requestAudio(sourceId: 's', seriesKey: 'b', chapterKeys: ['c1', 'c2'], priority: 9, force: true);
    final r = adapter.requests.single;
    expect(r.path, '/novels/audio/render');
    expect(r.data, {'source_id': 's', 'series_key': 'b', 'chapter_keys': ['c1', 'c2'], 'priority': 9, 'force': true});
  });

  test('requestAudio defaults are priority 0 and force false', () async {
    adapter.body = {'queued': <Object>[], 'skipped': <Object>[]};
    await repo.requestAudio(sourceId: 's', seriesKey: 'b', chapterKeys: ['c1']);
    final data = adapter.requests.single.data as Map<String, Object?>;
    expect(data['priority'], 0);
    expect(data['force'], false);
  });

  test('a 503 narration_unavailable is an ApiError carrying the code', () async {
    adapter
      ..status = 503
      ..body = {'detail': 'Narration of new chapters is not available right now.', 'code': 'narration_unavailable'};
    final r = await repo.requestAudio(sourceId: 's', seriesKey: 'b', chapterKeys: ['c1']);
    expect(r.isErr, isTrue);
    expect((r.error as ApiError).statusCode, 503);
  });

  test('seriesAudioDetail reads rendered_at and cast_changed_at; chaptersToRevoice compares them', () async {
    adapter.body = listenFixture('audio-series');
    final r = await repo.seriesAudioDetail(sourceId: 's', seriesKey: 'b');
    final d = r.value;
    expect(d.renderedAt.keys, ['c1', 'c2', 'c3']);
    expect(d.castChangedAt, DateTime.utc(2026, 9, 20));
    expect(d.canRender, isTrue);
    expect(d.narratable, hasLength(6));
    // c1 and c2 predate the cast change; c3 does not.
    expect(chaptersToRevoice(d), ['c1', 'c2']);
    expect(chaptersToRevoice((renderedAt: d.renderedAt, narratable: d.narratable, canRender: true, castChangedAt: null)), isEmpty);
  });

  test('activeAudioJobs hits jobs/active and parses the fixture', () async {
    adapter.body = listenFixture('jobs');
    final r = await repo.activeAudioJobs();
    expect(adapter.requests.single.path, '/novels/audio/jobs/active');
    expect(r.value.map((j) => j.status), ['queued', 'rendering', 'failed']);
    expect(r.value[1].progress, 0.4);
    expect(r.value[2].isFailed, isTrue);
    expect(r.value[0].isWaiting, isTrue);
    expect(r.value[2].errorDetail, isNotNull);
  });

  test('cancelAudioJob is a DELETE on the job id', () async {
    adapter.status = 204;
    adapter.body = <String, Object?>{};
    await repo.cancelAudioJob('j2');
    expect(adapter.requests.single.method, 'DELETE');
    expect(adapter.requests.single.path, '/novels/audio/jobs/j2');
  });

  test('setCastGender sends the gender and NO voice_id key; setCastVoice sends voice_id', () async {
    await repo.setCastGender(sourceId: 's', seriesKey: 'b', name: 'Iris', gender: 'female');
    expect(adapter.requests.last.path, '/novels/cast');
    expect(adapter.requests.last.data, {'source_id': 's', 'series_key': 'b', 'name': 'Iris', 'gender': 'female'});
    await repo.setCastVoice(sourceId: 's', seriesKey: 'b', name: 'Iris', voiceId: null);
    expect((adapter.requests.last.data as Map<String, Object?>).containsKey('voice_id'), isTrue);
  });

  test('mergeCastAlias posts alias and canonical', () async {
    await repo.mergeCastAlias(sourceId: 's', seriesKey: 'b', alias: 'Dokja', canonical: 'Kim Dokja');
    expect(adapter.requests.single.path, '/novels/cast/alias');
    expect(adapter.requests.single.data, {'source_id': 's', 'series_key': 'b', 'alias': 'Dokja', 'canonical': 'Kim Dokja'});
  });

  test('setNarratorVoice posts null to clear', () async {
    await repo.setNarratorVoice(sourceId: 's', seriesKey: 'b', voiceId: null);
    expect(adapter.requests.single.path, '/novels/narrator');
    expect((adapter.requests.single.data as Map<String, Object?>)['voice_id'], isNull);
  });

  test('voiceSample asks for ogg always and returns the bytes', () async {
    adapter.bytes = Uint8List.fromList([79, 103, 103, 83, 1]);
    final r = await repo.voiceSample('voice-03');
    expect(adapter.requests.single.path, '/novels/voices/sample');
    expect(adapter.requests.single.queryParameters, {'voice': 'voice-03'});
    expect(r.value, [79, 103, 103, 83, 1]);
  });

  test('voices parse the full record', () async {
    adapter.body = listenFixture('voices');
    final r = await repo.voices();
    expect(r.value, hasLength(31));
    expect(r.value.where((v) => v.gender == 'male'), hasLength(13));
    expect(r.value.where((v) => v.gender == 'female'), hasLength(18));
    expect(r.value.first.transcript, isNotEmpty);
    expect(r.value.first.expressiveness, greaterThan(0));
    expect(r.value.first.license, 'CC-BY 4.0');
  });

  test('attribution keeps locked and line_count when the server sends them', () async {
    adapter.body = listenFixture('attribution');
    final r = await repo.attribution(sourceId: 's', seriesKey: 'b', chapterKey: 'c');
    expect(r.value.cast.first.locked, isTrue);
    expect(r.value.cast.first.lineCount, 34);
    expect(r.value.cast[1].locked, isFalse);
    expect(r.value.narratorVoiceId, 'voice-20');
  });

  test('saveListenSessions posts one array', () async {
    await repo.saveListenSessions([
      {'source_id': 's', 'series_key': 'b', 'chapter_key': 'c', 'seconds': 40, 'voice_ids': ['v'], 'started_at': '2026-09-30T12:00:00.000Z'},
    ]);
    expect(adapter.requests.single.path, '/novels/listen-sessions');
    expect(adapter.requests.single.data, isA<List<Object?>>());
    expect(((adapter.requests.single.data as List).single as Map<String, Object?>)['seconds'], 40);
  });
}
