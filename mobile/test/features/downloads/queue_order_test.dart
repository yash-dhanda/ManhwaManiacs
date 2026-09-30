import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/reader/models/chapter_manifest_window.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_identity.dart';
import 'package:manhwamaniacs/features/downloads/models/retention_policy.dart';
import 'package:manhwamaniacs/features/downloads/models/storage_cap.dart';
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
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/downloads_test_support.dart';

ChapterIdentity _c(String k) => (sourceId: 'asura', seriesKey: 'solo', chapterKey: k);

class _Reader implements ReaderRepository {
  final manifestOrder = <String>[];
  @override
  Future<Result<ChapterManifest>> manifest({required String sourceId, required String seriesKey, required String chapterKey}) async {
    manifestOrder.add(chapterKey);
    return Ok(ChapterManifest(
      sourceId: sourceId,
      seriesKey: seriesKey,
      chapterKey: chapterKey,
      chapterNumber: 1,
      pageCount: 1,
      prev: null,
      next: null,
      pages: [ManifestPage(number: 1, url: '/p/1')],
    ));
  }

  // The window is an optimisation: refusing it makes the loop fetch each manifest on its own, in queue order.
  @override
  Future<Result<ChapterManifestWindow>> manifestWindow({required String sourceId, required String seriesKey, required List<String> chapterKeys}) async =>
      const Err(NetworkError(message: 'no window'));

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Fetcher implements ChapterPageFetcher {
  @override
  Future<List<int>> fetchPageBytes(String url) async => [1];
}

class _Device implements DeviceStorageInfo {
  @override
  Future<int?> totalSpaceBytes() async => null;
  @override
  Future<int?> freeSpaceBytes() async => 10 * 1024 * 1024 * 1024;
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

  Future<({ProviderContainer c, _Reader reader, SharedPreferences prefs})> open({String scope = 'u1p1', Map<String, Object> prefsInit = const {}}) async {
    SharedPreferences.setMockInitialValues(prefsInit);
    final prefs = await SharedPreferences.getInstance();
    final reader = _Reader();
    final c = ProviderContainer(overrides: [
      downloadsStoreProvider.overrideWithValue(harness.storeFor('u1p1')),
      activeDownloadsScopeIdProvider.overrideWithValue(scope),
      sharedPrefsProvider.overrideWithValue(prefs),
      retentionMaintenanceProvider.overrideWithValue(RetentionMaintenance(database: harness.openDatabase(), blobStore: harness.openBlobStore())),
      readerRepositoryProvider.overrideWithValue(reader),
      chapterPageFetcherProvider.overrideWithValue(_Fetcher()),
      deviceStorageInfoProvider.overrideWithValue(_Device()),
      storageCapProvider.overrideWith(_Cap.new),
      retentionIntervalProvider.overrideWith(_Retention.new),
      matureGateOpenProvider.overrideWithValue(true),
      downloadConcurrencyOverride(),
    ]);
    addTearDown(c.dispose);
    return (c: c, reader: reader, prefs: prefs);
  }

  Future<void> queue3(ProviderContainer c) async {
    final store = harness.storeFor('u1p1');
    for (final k in ['a', 'b', 'c']) {
      await store.ensureQueued(id: _c(k));
    }
  }

  test('moving a chapter to the top starts it next; the rest keep their order', () async {
    final o = await open();
    final ctl = o.c.read(downloadQueueControllerProvider.notifier)..pause();
    await queue3(o.c);
    await ctl.moveInQueue(_c('c'), 0);
    final ordered = ctl.applyQueueOrder(await harness.storeFor('u1p1').unfinishedChapters());
    expect([for (final r in ordered) r.chapterKey], ['c', 'a', 'b']);
    ctl.resume();
    await ctl.debugWaitUntilIdle();
    expect(o.reader.manifestOrder, ['c', 'a', 'b']);
  });

  test('a finished chapter leaves the stored order, and another scope never sees it', () async {
    final o = await open();
    final ctl = o.c.read(downloadQueueControllerProvider.notifier)..pause();
    await queue3(o.c);
    await ctl.moveInQueue(_c('b'), 0);
    expect(o.prefs.getStringList('mm.downloads.queue-order.u1p1'), hasLength(3));
    ctl.resume();
    await ctl.debugWaitUntilIdle();
    expect(o.prefs.getStringList('mm.downloads.queue-order.u1p1'), isNull, reason: 'every chapter finished, every key pruned');
    final other = await open(scope: 'u1p2', prefsInit: {'mm.downloads.queue-order.u1p1': ['asura|solo|c']});
    final rows = await harness.storeFor('u1p1').unfinishedChapters();
    expect([for (final r in other.c.read(downloadQueueControllerProvider.notifier).applyQueueOrder(rows)) r.chapterKey], [for (final r in rows) r.chapterKey]);
  });

  test('cancelling a chapter drops its key', () async {
    final o = await open();
    final ctl = o.c.read(downloadQueueControllerProvider.notifier)..pause();
    await queue3(o.c);
    await ctl.moveInQueue(_c('c'), 0);
    await ctl.cancelChapter(_c('c'));
    expect(o.prefs.getStringList('mm.downloads.queue-order.u1p1'), ['asura|solo|a', 'asura|solo|b']);
  });
}
