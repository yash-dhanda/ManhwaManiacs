// ignore_for_file: directives_ordering

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/downloads/providers/active_download_queue_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/bookmark_outbox_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_lifecycle_gate.dart';
import 'package:manhwamaniacs/features/downloads/providers/retention_maintenance_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/downloads/services/retention_maintenance.dart';
import 'package:manhwamaniacs/features/downloads/utils/pending_removals.dart';
import 'package:manhwamaniacs/features/settings/models/app_changelog.dart';
import 'package:manhwamaniacs/features/settings/providers/app_changelog_provider.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/updates/providers/unread_count_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/app_frame.dart';
import 'package:manhwamaniacs/skins/cinematic/cinematic_skin.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/test_overrides.dart';

class _Unread extends UnreadCountNotifier {
  @override
  int build() => 0;
}

class FakeBookmarkOutbox extends Fake implements BookmarkOutboxController {
  int flushes = 0;
  @override
  Future<bool> flush() async {
    flushes++;
    return true;
  }

  @override
  Future<bool> sync() async => true;
}

class RecordingRetention extends Fake implements RetentionMaintenance {
  int sweeps = 0;
  @override
  Future<int> sweepExpired({required Duration? interval, Set<Object>? excludeOpen, dynamic now}) async {
    sweeps++;
    return 0;
  }
}

class _LoggingQueue extends DownloadQueueController {
  static final log = <String>[];

  @override
  DownloadQueueState build() => const DownloadQueueState();

  @override
  void setForeground(bool foreground) {
    log.add('fg:$foreground');
    super.setForeground(foreground);
  }

  @override
  void resumePendingOnLaunch() {
    log.add('resume');
    super.resumePendingOnLaunch();
  }
}

class Rig {
  Rig(this.container, this.retention, this.bookmarks, this.router);
  final ProviderContainer container;
  final RecordingRetention retention;
  final FakeBookmarkOutbox bookmarks;
  final GoRouter router;
}

Future<Rig> pumpShell(
  WidgetTester t, {
  Map<String, Object> prefs = const {},
  String start = '/',
  List<Override> extra = const [],
}) async {
  // The gate listens to connectivity; there is no plugin behind it in a host test.
  const connectivity = MethodChannel('dev.fluttercommunity.plus/connectivity_status');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(connectivity, (call) async => null);
  addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(connectivity, null));
  SharedPreferences.setMockInitialValues(testPrefsDefaults(prefs));
  final p = await SharedPreferences.getInstance();
  final retention = RecordingRetention();
  final bookmarks = FakeBookmarkOutbox();
  _LoggingQueue.log.clear();
  final c = ProviderContainer(
    overrides: [
      sharedPrefsProvider.overrideWithValue(p),
      skinIdProvider.overrideWithValue(SkinId.cinematic),
      authenticatedAuthOverride(),
      activeProfileOverride(),
      profileSessionReadyOverride(),
      unreadNotificationCountProvider.overrideWith(_Unread.new),
      setupCompletedProvider.overrideWithValue(true),
      ...noDownloadsStoreOverrides(),
      retentionMaintenanceProvider.overrideWithValue(retention),
      bookmarkOutboxControllerProvider.overrideWithValue(bookmarks),
      downloadQueueControllerProvider.overrideWith(_LoggingQueue.new),
      activeDownloadCountProvider.overrideWithValue(0),
      packageInfoProvider.overrideWith((ref) async => PackageInfo(appName: 'MM', packageName: 'x', version: '3.5.0', buildNumber: '57')),
      appChangelogProvider.overrideWith(
        (ref) async => const [ChangelogRelease(version: '3.5.0', build: 57, date: '2026-09-28', highlights: ['One thing changed.'])],
      ),
      ...extra,
    ],
  );
  addTearDown(c.dispose);
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final router = c.read(skinRouterProvider);
  if (start != '/') router.go(start);
  await t.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp.router(
        theme: CinematicSkin.baseTheme,
        routerConfig: router,
        // What SkinApp does: the lifecycle gate wraps every skin.
        builder: (context, child) => DownloadsLifecycleGate(child: CineAppFrame(splash: false, child: child!)),
      ),
    ),
  );
  await t.pump();
  await t.pump(const Duration(milliseconds: 600));
  return Rig(c, retention, bookmarks, router);
}

void main() {
  group('lifecycle under the Cinematic skin (mobile G10)', () {
    testWidgets('backgrounding pauses the queue with the backgrounded reason; returning sweeps, resumes and flushes', (t) async {
      final r = await pumpShell(t);
      final launchSweeps = r.retention.sweeps;
      expect(launchSweeps, greaterThanOrEqualTo(1), reason: 'the launch pass runs the retention sweep');
      expect(_LoggingQueue.log, contains('resume'));

      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await t.pump();
      expect(r.container.read(downloadQueueControllerProvider).pauseReason, DownloadQueuePauseReason.backgrounded);
      expect(_LoggingQueue.log, contains('fg:false'));

      _LoggingQueue.log.clear();
      final flushes = r.bookmarks.flushes;
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(_LoggingQueue.log, containsAll(['fg:true', 'resume']));
      expect(r.retention.sweeps, launchSweeps + 1, reason: 'resuming runs the retention sweep');
      expect(r.bookmarks.flushes, greaterThan(flushes), reason: 'the outboxes flush on resume');
    });

    testWidgets('pending chapter removals are flushed when the app pauses', (t) async {
      final r = await pumpShell(t);
      var ran = 0;
      r.container.read(pendingRemovalsProvider).schedule('k', () async => ran++);
      expect(ran, 0);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await t.pump();
      expect(ran, 1);
      expect(r.container.read(pendingRemovalsProvider).isPending('k'), isFalse);
    });
  });

  group("What's new opens by itself once per new build", () {
    testWidgets('a lower stored build opens the sheet on a shell route', (t) async {
      final r = await pumpShell(t, prefs: {'settings_last_seen_changelog_build': 55});
      await t.pump(const Duration(seconds: 1));
      expect(find.text('Release notes'), findsOneWidget);
      // Closing it stores the running build.
      await t.tap(find.byKey(const Key('cine-sheet-done')));
      await t.pump(const Duration(seconds: 1));
      expect(r.container.read(preferencesProvider).lastSeenChangelogBuild, 57);
    });

    testWidgets('a first run stores the build and does not open', (t) async {
      final r = await pumpShell(t);
      await t.pump(const Duration(seconds: 1));
      expect(find.text('Release notes'), findsNothing);
      expect(r.container.read(preferencesProvider).lastSeenChangelogBuild, 57);
    });

    testWidgets('never over a reader', (t) async {
      final r = await pumpShell(t, prefs: {'settings_last_seen_changelog_build': 55}, start: '/reader/asura/solo/c1');
      await t.pump(const Duration(seconds: 1));
      expect(find.text('Release notes'), findsNothing);
      expect(r.container.read(preferencesProvider).lastSeenChangelogBuild, 55);
    });
  });
}
