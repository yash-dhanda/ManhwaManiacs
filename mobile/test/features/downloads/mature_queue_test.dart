// ignore_for_file: require_trailing_commas, directives_ordering
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/models/storage_cap.dart';
import 'package:manhwamaniacs/features/downloads/models/retention_policy.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/retention_maintenance_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/storage_settings_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/downloads/services/chapter_page_fetcher.dart';
import 'package:manhwamaniacs/features/downloads/services/device_storage_info.dart';
import 'package:manhwamaniacs/features/downloads/services/retention_maintenance.dart';
import 'package:manhwamaniacs/features/reader/models/chapter_manifest.dart';
import 'package:manhwamaniacs/features/reader/repositories/reader_repository.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

import '../../support/downloads_test_support.dart';
import 'mature_gate_support.dart' show testGate;

const _hot = (sourceId: 'src', seriesKey: 'hot', chapterKey: 'c1');
const _plain = (sourceId: 'src', seriesKey: 'plain', chapterKey: 'p1');

class _Reader implements ReaderRepository {
  @override
  Future<Result<ChapterManifest>> manifest({required String sourceId, required String seriesKey, required String chapterKey}) async => Ok(ChapterManifest(
        sourceId: sourceId,
        seriesKey: seriesKey,
        chapterKey: chapterKey,
        chapterNumber: 1,
        pageCount: 20,
        prev: null,
        next: null,
        pages: [for (var i = 1; i <= 20; i++) ManifestPage(number: i, url: '/$seriesKey/$i')],
      ));

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError('${i.memberName}');
}

class _Fetcher implements ChapterPageFetcher {
  _Fetcher(this.onFetch);
  final Future<List<int>> Function(String url) onFetch;
  final fetched = <String>[];
  @override
  Future<List<int>> fetchPageBytes(String url) {
    fetched.add(url);
    return onFetch(url);
  }
}

class _Space implements DeviceStorageInfo {
  @override
  Future<int?> freeSpaceBytes() async => 1 << 40;
}

class _Cap extends StorageCapNotifier {
  @override
  StorageCap build() => StorageCap.unlimited;
}

class _Retention extends RetentionIntervalNotifier {
  @override
  RetentionInterval build() => RetentionInterval.off;
}

void main() {
  initSqfliteFfiForTests();
  late TestDownloadsHarness harness;
  setUp(() async => harness = await TestDownloadsHarness.create());
  tearDown(() async => harness.dispose());

  ProviderContainer build(_Fetcher fetcher, {required bool gateOpen}) {
    final c = ProviderContainer(overrides: [
      downloadsStoreProvider.overrideWithValue(harness.storeFor('u1p1', matureResolver: (s, k) async => k == 'hot')),
      retentionMaintenanceProvider.overrideWithValue(RetentionMaintenance(database: harness.openDatabase(), blobStore: harness.openBlobStore())),
      readerRepositoryProvider.overrideWithValue(_Reader()),
      chapterPageFetcherProvider.overrideWithValue(fetcher),
      deviceStorageInfoProvider.overrideWithValue(_Space()),
      storageCapProvider.overrideWith(_Cap.new),
      retentionIntervalProvider.overrideWith(_Retention.new),
      downloadConcurrencyOverride(),
      testGate.overrideWith((ref) => gateOpen),
      matureGateOpenProvider.overrideWith((ref) => ref.watch(testGate)),
    ],);
    addTearDown(c.dispose);
    return c;
  }

  test('a hidden series stays queued with no reason while the gate is closed, and downloads once it opens', () async {
    final fetcher = _Fetcher((url) async => [1]);
    final c = build(fetcher, gateOpen: false);
    final store = c.read(downloadsStoreProvider)!;
    await store.ensureQueued(id: _hot);
    await store.ensureQueued(id: _plain);

    final q = c.read(downloadQueueControllerProvider.notifier)..resumePendingOnLaunch();
    await q.debugWaitUntilIdle();

    expect((await store.getChapter(_plain))!.state, DownloadChapterState.complete);
    expect((await store.getChapter(_hot))!.state, DownloadChapterState.queued);
    expect(fetcher.fetched.any((u) => u.contains('hot')), isFalse);
    expect(c.read(downloadQueueControllerProvider).pauseReason, DownloadQueuePauseReason.none);

    c.read(testGate.notifier).state = true; // the controller kicks the queue itself
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await q.debugWaitUntilIdle();
    expect((await store.getChapter(_hot))!.state, DownloadChapterState.complete);
  });

  test('closing the gate on a running chapter of a hidden series puts it back to queued, pages kept', () async {
    final hold = Completer<void>();
    final started = Completer<void>();
    final fetcher = _Fetcher((url) async {
      if (!started.isCompleted) started.complete();
      await hold.future;
      return [7];
    });
    final c = build(fetcher, gateOpen: true);
    final store = c.read(downloadsStoreProvider)!;
    await store.ensureQueued(id: _hot);
    final q = c.read(downloadQueueControllerProvider.notifier)..resumePendingOnLaunch();
    await started.future;

    c.read(testGate.notifier).state = false;
    hold.complete();
    await q.debugWaitUntilIdle();

    final row = (await store.getChapter(_hot))!;
    expect(row.state, DownloadChapterState.queued, reason: 'not failed, not cancelled: silently back in the queue');
    expect(await store.pendingChapters(hideMature: true), isEmpty);
    expect(await store.pendingChapters(), hasLength(1));
  });
}
