// ignore_for_file: require_trailing_commas, directives_ordering
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/tag.dart';
import 'package:manhwamaniacs/features/library/providers/tags_controller.dart';
import 'package:manhwamaniacs/features/library/repositories/progress_deleter.dart';
import 'package:manhwamaniacs/features/library/utils/mark_read.dart';
import 'package:manhwamaniacs/features/reader/models/reading_progress.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

import '../../skins/cinematic/feature/feature_test_support.dart';

class _Recording implements HttpClientAdapter {
  final List<({String method, String path, Object? data})> calls = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    calls.add((method: options.method, path: options.path, data: options.data));
    return ResponseBody.fromString('', 204);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('manualReadRows are completed manual rows at the last page', () {
    final rows = manualReadRows('demo', 'k', [
      (key: 'c1', number: 1.0, pageCount: 20),
      (key: 'c2', number: null, pageCount: 4),
    ]);
    expect(rows.length, 2);
    expect(rows.every((r) => r.manual && r.isCompleted), isTrue);
    expect(rows[0].lastPage, 20);
    expect(rows[1].chapterNumber, isNull);
    expect(rows[0].toJson()['manual'], isTrue);
  });

  test('a manual flag survives the outbox round trip and a stamp; ordinary rows omit it', () {
    final row = manualReadRows('demo', 'k', [(key: 'c1', number: 1.0, pageCount: 20)]).single;
    final back = ProgressPush.fromJson(row.toJson());
    expect(back.manual, isTrue);
    expect(row.stampedAt(DateTime.utc(2026, 9, 29)).manual, isTrue);
    const plain = ProgressPush(sourceId: 'demo', seriesKey: 'k', chapterKey: 'c1', lastPage: 1);
    expect(plain.toJson().containsKey('manual'), isFalse);
  });

  test('Mark unread chunks its DELETE keys 200 at a time', () async {
    final rec = _Recording();
    final dio = Dio(BaseOptions(baseUrl: 'http://example.test'))..httpClientAdapter = rec;
    final r = await ProgressDeleter(dio).deleteProgress(
      sourceId: 'demo',
      seriesKey: 'k',
      chapterKeys: [for (var i = 0; i < 450; i++) 'c$i'],
    );
    expect(r.isOk, isTrue);
    expect(rec.calls.map((c) => c.method).toSet(), {'DELETE'});
    expect(rec.calls.map((c) => c.path).toSet(), {'/reader/progress'});
    expect(rec.calls.map((c) => ((c.data! as Map<String, Object?>)['chapter_keys']! as List<Object?>).length).toList(), [200, 200, 50]);
    expect((rec.calls.first.data! as Map<String, Object?>)['source_id'], 'demo');
  });

  test('TagsController keeps the optimistic overlay in step with add and remove', () async {
    final rec = Recorder();
    final container = ProviderContainer(overrides: [
      libraryRepositoryProvider.overrideWithValue(FakeLibrary(rec)),
    ]);
    addTearDown(container.dispose);
    const key = (sourceId: 'demo', seriesKey: 'k');
    const a = Tag(id: 1, name: 'slow burn', category: 'custom');
    final ctl = container.read(tagsControllerProvider);
    expect(await ctl.tagSeries(key, a, current: const []), isNull);
    expect(container.read(seriesTagOverlayProvider)[key], [a]);
    expect(await ctl.untagSeries(key, a, current: [a]), isNull);
    expect(container.read(seriesTagOverlayProvider)[key], isEmpty);
    expect(rec.tagCalls, ['add:1', 'remove:1']);
    expect(await ctl.createAndTag(key, 'new one', current: const []), isNull);
    expect(rec.tagCalls.last, startsWith('add:'));
    expect(container.read(seriesTagOverlayProvider)[key]!.single.name, 'new one');
  });
}
