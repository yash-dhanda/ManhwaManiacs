// ignore_for_file: directives_ordering
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/app/app_restart.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/models/storage_cap.dart';
import 'package:manhwamaniacs/features/downloads/models/retention_policy.dart';
import 'package:manhwamaniacs/features/downloads/providers/bookmark_outbox_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_lifecycle_gate.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/retention_maintenance_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/storage_settings_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/downloads/services/chapter_page_fetcher.dart';
import 'package:manhwamaniacs/features/downloads/services/device_storage_info.dart';
import 'package:manhwamaniacs/features/downloads/services/retention_maintenance.dart';
import 'package:manhwamaniacs/features/downloads/store/downloads_db.dart';
import 'package:manhwamaniacs/features/library/providers/dashboard_providers.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/reader/models/chapter_manifest.dart';
import 'package:manhwamaniacs/features/reader/repositories/reader_repository.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/downloads/downloads_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/downloads_test_support.dart';
import '../../../support/test_overrides.dart';
import 'downloads_rig.dart' show rigTheme;
import 'lifecycle_test.dart' show FakeBookmarkOutbox;

const _id = (sourceId: 'asura', seriesKey: 'solo', chapterKey: '12');

class _Reader implements ReaderRepository {
  @override
  Future<Result<ChapterManifest>> manifest({required String sourceId, required String seriesKey, required String chapterKey}) async => Ok(
        ChapterManifest(
          sourceId: sourceId,
          seriesKey: seriesKey,
          chapterKey: chapterKey,
          chapterNumber: 12,
          pageCount: 20,
          prev: null,
          next: null,
          pages: [for (var i = 1; i <= 20; i++) ManifestPage(number: i, url: '/$seriesKey/$i')],
        ),
      );

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError('${i.memberName}');
}

/// Holds every page fetch open, so a launched queue stays "downloading".
class _HeldFetcher implements ChapterPageFetcher {
  final fetched = <String>[];
  final _never = Completer<List<int>>();
  @override
  Future<List<int>> fetchPageBytes(String url) {
    fetched.add(url);
    return _never.future;
  }
}

class _Space implements DeviceStorageInfo {
  @override
  Future<int?> totalSpaceBytes() async => null;
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

class _NoUpdates extends UpdatesNotifier {
  @override
  Future<UpdatesState> build() async => const UpdatesState(notifications: [], unreadCount: 0, followed: []);
}

class _Sweeper extends Fake implements RetentionMaintenance {
  @override
  Future<int> sweepExpired({required Duration? interval, Set<Object>? excludeOpen, dynamic now}) async => 0;
}

Future<void> pumpReal(WidgetTester t, {int rounds = 8}) async {
  for (var i = 0; i < rounds; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  initSqfliteFfiForTests();

  testWidgets('a chapter left downloading is re-queued and resumes after AppRestart, and the Activity block shows it', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1200);
    addTearDown(tester.view.reset);
    final oldProbe = CineImage.cacheProbe, oldBuilder = CineImage.providerBuilder;
    CineImage.cacheProbe = (_) async => false;
    CineImage.providerBuilder = (url, headers) => MemoryImage(Uint8List(0));
    addTearDown(() {
      CineImage.cacheProbe = oldProbe;
      CineImage.providerBuilder = oldBuilder;
    });
    // The gate listens to connectivity; there is no plugin behind it in a host test.
    const connectivity = MethodChannel('dev.fluttercommunity.plus/connectivity_status');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(connectivity, (call) async => null);
    addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(connectivity, null));
    SharedPreferences.setMockInitialValues(testPrefsDefaults());
    final prefs = await SharedPreferences.getInstance();
    final harness = (await tester.runAsync(TestDownloadsHarness.create))!;
    final fetcher = _HeldFetcher();
    final containers = <ProviderContainer>[];

    // The row a kill left mid-download: the store is on disk, everything else starts fresh.
    await tester.runAsync(() async {
      final store = harness.storeFor('u1p1');
      await store.ensureQueued(id: _id, chapterNumber: 12, seriesTitle: 'Solo Leveling');
      final db = await harness.openDatabase();
      await db.update(DownloadsSchema.savedChapters, {DownloadsSchema.colState: DownloadChapterState.downloading.wire});
    });

    Widget app() {
      final c = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          apiBaseUrlOverride('http://example.test'),
          authenticatedAuthOverride(),
          activeProfileOverride(),
          ...contentModeOverrides(),
          activeDownloadsScopeIdProvider.overrideWithValue('u1p1'),
          downloadsStoreProvider.overrideWith((ref) => harness.storeFor('u1p1')),
          retentionMaintenanceProvider.overrideWithValue(_Sweeper()),
          bookmarkOutboxControllerProvider.overrideWithValue(FakeBookmarkOutbox()),
          readerRepositoryProvider.overrideWithValue(_Reader()),
          chapterPageFetcherProvider.overrideWithValue(fetcher),
          deviceStorageInfoProvider.overrideWithValue(_Space()),
          storageCapProvider.overrideWith(_Cap.new),
          retentionIntervalProvider.overrideWith(_Retention.new),
          downloadConcurrencyOverride(),
          matureGateOpenProvider.overrideWithValue(true),
          continueReadingProvider.overrideWith((ref) async => const []),
          updatesProvider.overrideWith(_NoUpdates.new),
          deviceOnlineProvider.overrideWith((ref) => Stream.value(true)),
        ],
      );
      containers.add(c);
      return UncontrolledProviderScope(
        container: c,
        child: MaterialApp.router(
          theme: rigTheme(TargetPlatform.android),
          routerConfig: GoRouter(routes: [GoRoute(path: '/', builder: (context, state) => const DownloadsScreen())]),
          // What SkinApp does: the lifecycle gate wraps every skin.
          builder: (context, child) => DownloadsLifecycleGate(child: child!),
        ),
      );
    }

    await tester.pumpWidget(AppRestart(builder: app));
    // The store opens on first read: do it where real I/O can complete.
    await tester.runAsync(() async => containers.last.read(downloadsStoreProvider));
    await pumpReal(tester, rounds: 12);
    expect(containers, hasLength(1));
    expect(fetcher.fetched, isNotEmpty, reason: 'the launch picked the stranded chapter up');
    expect(find.text('DOWNLOADING'), findsOneWidget);
    expect(find.text('CH 12 · PAGE 0 OF 20'), findsOneWidget);
    final firstLaunch = fetcher.fetched.length;

    // A restart: a fresh container, an empty controller, the same store on disk.
    AppRestart.of(tester.element(find.byType(MaterialApp))).restart();
    await tester.pump();
    await tester.runAsync(() async => containers.last.read(downloadsStoreProvider));
    await pumpReal(tester, rounds: 12);
    expect(containers, hasLength(2));
    expect(fetcher.fetched.length, greaterThan(firstLaunch), reason: 'the new queue re-queued the chapter and resumed it');
    expect(containers.last.read(downloadQueueControllerProvider).currentChapter, _id);
    expect(find.text('DOWNLOADING'), findsOneWidget, reason: 'the Activity block shows it again');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    // The containers and database handles are left to the process: closing them under a queue
    // loop parked mid-fetch never returns in a host test. The temp tree is just dropped.
    await tester.runAsync(() async {
      try {
        await harness.tempDir.delete(recursive: true);
      } catch (_) {}
    });
  });
}
