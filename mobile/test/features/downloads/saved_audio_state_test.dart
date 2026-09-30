/// A chapter's saved audio as one answer (cinematic 8.16.9): none, preparing, saving, saved,
/// failed, unplayable, and the `503 audio_preparing` wait that produces `preparing`.
library;

import 'dart:io';

import 'package:flutter/foundation.dart' show debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart' show TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_identity.dart';
import 'package:manhwamaniacs/features/downloads/models/storage_cap.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/retention_maintenance_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/storage_settings_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/downloads/services/device_storage_info.dart';
import 'package:manhwamaniacs/features/downloads/services/retention_maintenance.dart';
import 'package:manhwamaniacs/features/novels/models/novel_audio.dart';
import 'package:manhwamaniacs/features/novels/models/novel_chapter.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_audio_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/saved_audio_provider.dart';
import 'package:manhwamaniacs/features/novels/utils/narration_playback.dart';
import 'package:manhwamaniacs/features/reader/repositories/reader_repository.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/downloads_test_support.dart';
import '../novels/support/fake_novels_repository.dart';

const _chapter = (sourceId: 'src', seriesKey: 'book', chapterKey: 'c12');

final _timing = NovelAudio.fromJson({
  'available': true,
  'total_ms': 4200,
  'bytes': 2048,
  'highlight_safe': true,
  'segments': [
    {'i': 0, 'start_ms': 0, 'end_ms': 2000, 'p': 0, 's': 0, 'e': 9, 'speech': false},
  ],
});
final _opus = [...'OggS'.codeUnits, ...List<int>.generate(2044, (i) => i % 251)];

class _ReaderSpy extends Mock implements ReaderRepository {}

class _Cap extends StorageCapNotifier {
  @override
  StorageCap build() => StorageCap.unlimited;
}

class _Storage implements DeviceStorageInfo {
  @override
  Future<int?> totalSpaceBytes() async => null;
  @override
  Future<int?> freeSpaceBytes() async => 10 * 1024 * 1024 * 1024;
}

class _Repo extends FakeNovelsRepository {
  @override
  Future<Result<NovelChapter>> chapter({required String sourceId, required String seriesKey, required String chapterKey}) async => Ok(
        NovelChapter(
          sourceId: sourceId,
          seriesKey: seriesKey,
          chapterKey: chapterKey,
          chapterNumber: 12,
          title: 'The Tower',
          paragraphs: const ['The gate.'],
          previousChapterKey: null,
          nextChapterKey: null,
          wordCount: 2,
        ),
      );
}

void main() {
  initSqfliteFfiForTests();
  late TestDownloadsHarness harness;
  late _Repo repo;

  setUp(() async {
    harness = await TestDownloadsHarness.create();
    repo = _Repo()
      ..audioByChapter = {'c12': _timing}
      ..audioBytesByChapter = {'c12': _opus};
  });
  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    await harness.dispose();
  });

  ProviderContainer container({List<Override> extra = const []}) {
    final c = ProviderContainer(
      overrides: [
        matureGateOpenProvider.overrideWithValue(true),
        downloadsStoreProvider.overrideWithValue(harness.storeFor('u1p1')),
        retentionMaintenanceProvider.overrideWithValue(
          RetentionMaintenance(database: harness.openDatabase(), blobStore: harness.openBlobStore()),
        ),
        novelsRepositoryProvider.overrideWithValue(repo),
        readerRepositoryProvider.overrideWithValue(_ReaderSpy()),
        deviceStorageInfoProvider.overrideWithValue(_Storage()),
        storageCapProvider.overrideWith(_Cap.new),
        downloadConcurrencyOverride(),
        narrationPlaybackCacheProvider.overrideWith((ref) async => Directory('${harness.tempDir.path}/playback')),
        narrationPrepareDelayProvider.overrideWithValue((_) => Duration.zero),
        ...extra,
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<void> refresh(ProviderContainer c) async {
    const series = (sourceId: 'src', seriesKey: 'book');
    c
      ..invalidate(seriesNarrationStatusProvider(series))
      ..invalidate(unplayableNarrationSavesProvider(series));
    await c.read(seriesNarrationStatusProvider(series).future);
    await c.read(unplayableNarrationSavesProvider(series).future);
  }

  Future<void> save(ProviderContainer c) async {
    final queue = c.read(downloadQueueControllerProvider.notifier);
    await queue.enqueueChapters(narrationDownloadRequests(chapter: _chapter, title: 'The Tower'));
    await queue.debugWaitUntilIdle();
  }

  test('none before anything is saved, saved after, and the row goes back to none when removed', () async {
    final c = container();
    final sub = c.listen(savedAudioStateProvider(_chapter), (_, __) {});
    expect(c.read(savedAudioStateProvider(_chapter)), SavedAudioState.none);
    await save(c);
    await refresh(c);
    expect(c.read(savedAudioStateProvider(_chapter)), SavedAudioState.saved);
    await c.read(downloadQueueControllerProvider.notifier).cancelChapter(audioIdentity(_chapter));
    await refresh(c);
    expect(c.read(savedAudioStateProvider(_chapter)), SavedAudioState.none);
    sub.close();
  });

  test('a failed save reads failed', () async {
    repo.audioByChapter = {};
    final c = container();
    final sub = c.listen(savedAudioStateProvider(_chapter), (_, __) {});
    await save(c);
    await refresh(c);
    expect(c.read(savedAudioStateProvider(_chapter)), SavedAudioState.failed);
    sub.close();
  });

  test('a 503 audio_preparing waits and retries; the chapter reads preparing meanwhile, then saved', () async {
    repo.audioBytesFailures.addAll([
      const ApiError(statusCode: 503, code: 'audio_preparing', message: 'Preparing', retryAfter: Duration(seconds: 2)),
      const ApiError(statusCode: 503, code: 'audio_preparing', message: 'Preparing'),
    ]);
    final seen = <bool>[];
    final c = container(
      extra: [
        narrationPrepareDelayProvider.overrideWithValue((ra) {
          expect(ra == null || ra == const Duration(seconds: 2), isTrue);
          return Duration.zero;
        }),
      ],
    );
    c.listen(savedAudioStateProvider(_chapter), (_, __) {});
    c.listen<Set<String>>(narrationPreparingProvider, (_, next) {
      final on = next.contains(preparingId('src', 'book', 'c12'));
      if (seen.isEmpty || seen.last != on) seen.add(on);
    });
    await save(c);
    expect(repo.audioBytesRequests, ['c12', 'c12', 'c12']);
    expect(seen, [true, false]);
    await refresh(c);
    expect(c.read(savedAudioStateProvider(_chapter)), SavedAudioState.saved);
  });

  test('preparing shows for a save in flight', () {
    final c = container();
    c.read(narrationPreparingProvider.notifier).state = {preparingId('src', 'book', 'c12')};
    // With nothing queued the state is still none: preparing only qualifies a save.
    expect(c.read(savedAudioStateProvider(_chapter)), SavedAudioState.none);
  });

  test('an Ogg save on an iPhone reads unplayable', () async {
    // Saved as Ogg on Android, then the same store read as an iPhone.
    repo.audioBytesByChapter = {'c12': _opus};
    final c = container();
    await save(c);
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final c2 = container();
    final sub = c2.listen(savedAudioStateProvider(_chapter), (_, __) {});
    await c2.read(unplayableNarrationSavesProvider((sourceId: 'src', seriesKey: 'book')).future);
    await refresh(c2);
    expect(c2.read(savedAudioStateProvider(_chapter)), SavedAudioState.unplayable);
    sub.close();
  });
}
