// ignore_for_file: directives_ordering

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/network/network_connectivity.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/downloads/providers/download_switches_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_storage_providers.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/downloads/services/device_storage_info.dart';
import 'package:manhwamaniacs/features/downloads/store/downloads_store.dart';
import 'package:manhwamaniacs/features/downloads/utils/auto_download.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/updates/models/update_notification.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_overrides.dart';

class _Store extends Mock implements DownloadsStore {}

class _Queue extends DownloadQueueController {
  static final queued = <List<ChapterQueueRequest>>[];
  @override
  DownloadQueueState build() => const DownloadQueueState();
  @override
  Future<void> enqueueChapters(Iterable<ChapterQueueRequest> chapters, {bool automatic = false}) async => queued.add(chapters.toList());
  static Set<String> auto = {};
  @override
  Set<String> autoQueuedKeys() => auto;
}

class _Updates extends UpdatesNotifier {
  @override
  Future<UpdatesState> build() async => UpdatesState(
        notifications: [
          for (var i = 1; i <= 6; i++)
            UpdateNotification(
              id: i,
              followedSeriesId: 1,
              sourceId: 'src',
              seriesKey: 's1',
              chapterKey: 'c$i',
              chapterTitle: 'Chapter $i',
              chapterNumber: i.toDouble(),
              isRead: false,
            ),
        ],
        unreadCount: 6,
        followed: const [
          FollowedSeries(
            id: 1,
            sourceId: 'src',
            seriesKey: 's1',
            title: 'Series One',
            coverUrl: '',
            isFavorite: false,
            readingStatus: 'reading',
            notify: true,
            sortOrder: 0,
            contentRating: 'safe',
            rating: 'safe',
            chapterCount: 6,
          ),
        ],
      );
}

class _Wifi implements NetworkConnectivity {
  @override
  Future<bool> isOnWifi() async => true;
  @override
  Future<bool> isOnline() async => true;
}

class _Space implements DeviceStorageInfo {
  @override
  Future<int?> totalSpaceBytes() async => null;
  @override
  Future<int?> freeSpaceBytes() async => 100 * 1024 * 1024 * 1024;
}

Future<ProviderContainer> make({required bool switchOn}) async {
  SharedPreferences.setMockInitialValues(testPrefsDefaults(switchOn ? {'mm.downloads.auto-new.u1p1': true} : {}));
  final prefs = await SharedPreferences.getInstance();
  final store = _Store();
  when(() => store.listChapters(includeNarration: any(named: 'includeNarration'), hideMature: any(named: 'hideMature'))).thenAnswer((_) async => <SavedChapter>[]);
  _Queue.queued.clear();
  _Queue.auto = {};
  final c = ProviderContainer(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      authenticatedAuthOverride(),
      activeProfileOverride(),
      ...contentModeOverrides(),
      downloadsStoreProvider.overrideWithValue(store),
      updatesProvider.overrideWith(_Updates.new),
      downloadQueueControllerProvider.overrideWith(_Queue.new),
      networkConnectivityProvider.overrideWithValue(_Wifi()),
      deviceStorageInfoProvider.overrideWithValue(_Space()),
      totalDeviceDownloadBytesProvider.overrideWith((ref) async => 0),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('runs only while the switch is on, and queues the unread chapters of followed series', () async {
    final off = await make(switchOn: false);
    expect(await off.read(autoDownloadRunnerProvider).run(), 0);
    expect(_Queue.queued, isEmpty);

    final on = await make(switchOn: true);
    expect(on.read(autoNewProvider), isTrue);
    expect(await on.read(autoDownloadRunnerProvider).run(), 6);
    expect(_Queue.queued.single.map((r) => r.id.chapterKey), ['c1', 'c2', 'c3', 'c4', 'c5', 'c6']);
    expect(_Queue.queued.single.first.seriesTitle, 'Series One');
  });

  test('a chapter auto-queued before (then removed or cancelled) is not queued again', () async {
    final on = await make(switchOn: true);
    _Queue.auto = {'src s1 c1', 'src s1 c2'};
    expect(await on.read(autoDownloadRunnerProvider).run(), 4);
    expect(_Queue.queued.single.map((r) => r.id.chapterKey), ['c3', 'c4', 'c5', 'c6']);
  });

  testWidgets('the trigger reports the count on open and again on resume', (tester) async {
    final on = await make(switchOn: true);
    final counts = <int>[];
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: on,
        child: MaterialApp(home: AutoDownloadTrigger(onQueued: counts.add, child: const SizedBox())),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(counts, [6]);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
    expect(counts.length, 2);
    expect(queuedNewChaptersLine(counts.first), 'Queued 6 new chapters.');
  });
}
