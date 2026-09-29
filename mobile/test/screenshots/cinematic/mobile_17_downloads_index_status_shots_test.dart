// ignore_for_file: directives_ordering
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/models/downloaded_series_group.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/downloads/models/series_storage_usage.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/downloads/utils/mature_filter.dart';
import 'package:manhwamaniacs/features/settings/models/app_changelog.dart';
import 'package:manhwamaniacs/features/settings/models/app_version.dart';
import 'package:manhwamaniacs/features/settings/providers/app_changelog_provider.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/sources/models/source_health.dart';
import 'package:manhwamaniacs/skins/cinematic/overlays/whats_new_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/admin/status_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/downloads/downloads_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/index/index_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/index/update_banner.dart';
import 'package:manhwamaniacs/core/platform/media_store.dart';
import 'package:manhwamaniacs/features/downloads/services/chapter_export.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloaded_series_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../skins/cinematic/admin/status_screen_test.dart' show StatusRig, src, run, statusOverrides;
import '../../skins/cinematic/downloads/downloads_more_test.dart' show FakeExporter, FakeMedia, exported;
import '../../skins/cinematic/downloads/downloads_rig.dart' show Rig, chapter, rigOverrides, rigTheme, series;
import '../../skins/cinematic/index/index_screen_test.dart' show IndexRig, indexOverrides;
import '../support/skin_shots.dart';

/// mobile/17 proof: Downloads, the Index, What's new and System status, on phone and tablet, with
/// a `-reduced` copy of each screen's default state.
///
///   MM_PROOF_DIR=../docs/redesign/proof/mobile-17 flutter test \
///     test/screenshots/cinematic/mobile_17_downloads_index_status_shots_test.dart
///
/// Without MM_PROOF_DIR the shots are rasterised and discarded, so the suite still proves every
/// state renders. Titles are invented; one series is 18+ and is filtered out to prove its absence.

const _phone = SkinShotSize('phone', Size(390, 844), 2.0, EdgeInsets.only(top: 47, bottom: 34));
const _tablet = SkinShotSize('tablet', Size(834, 1194), 1.5, EdgeInsets.only(top: 24, bottom: 20));
const _sizes = [_phone, _tablet];
const gb = 1024 * 1024 * 1024;
const mb = 1024 * 1024;

SavedChapter _c(int id, String key, String seriesKey, String title, {DownloadChapterState state = DownloadChapterState.complete, int bytes = 24 * mb, DownloadKind kind = DownloadKind.manga, bool pinned = false, String? error}) =>
    chapter(id, key, seriesKey: seriesKey, seriesTitle: title, state: state, bytes: bytes, kind: kind, pinned: pinned, error: error);

/// Three invented series; "Halcyon" is 18+ and never reaches the lists with the gate closed.
List<DownloadedSeriesGroup> _shelf({bool gateOpen = false}) {
  final all = [
    series(
      [
        for (var i = 1; i <= 8; i++) _c(i, '$i', 'lantern', 'The Lantern Courier', bytes: 150 * mb, pinned: true),
        _c(20, '3:audio', 'lantern', 'The Lantern Courier', kind: DownloadKind.audio, bytes: 40 * mb, pinned: true),
      ],
      seriesKey: 'lantern',
      title: 'The Lantern Courier',
    ),
    series(
      [for (var i = 1; i <= 5; i++) _c(30 + i, '$i', 'salt', 'Salt and Ember', bytes: 160 * mb), _c(40, '6', 'salt', 'Salt and Ember', state: DownloadChapterState.queued, bytes: 0)],
      seriesKey: 'salt',
      title: 'Salt and Ember',
    ),
    series([for (var i = 1; i <= 3; i++) _c(50 + i, '$i', 'halcyon', 'Winter at Halcyon Row')], seriesKey: 'halcyon', title: 'Winter at Halcyon Row'),
  ];
  return filterMature(all, gateOpen: gateOpen, isMature: (g) => g.seriesKey == 'halcyon');
}

const _running = (sourceId: 'asura', seriesKey: 'lantern', chapterKey: '9');

Rig _rig({
  DownloadQueueState queueState = const DownloadQueueState(),
  bool downloading = false,
  bool profile = true,
  bool online = true,
  List<DownloadedSeriesGroup>? groups,
  int bytes = 4 * gb,
  int free = 21 * gb,
  List<Override> extra = const [],
}) {
  final cur = _c(90, '9', 'lantern', 'The Lantern Courier', state: DownloadChapterState.downloading, bytes: 0);
  final queued = _c(91, '10', 'lantern', 'The Lantern Courier', state: DownloadChapterState.queued, bytes: 0);
  final failed = _c(92, '11', 'lantern', 'The Lantern Courier', state: DownloadChapterState.failed, bytes: 0, error: 'The source timed out');
  final shelf = groups ?? _shelf();
  return Rig(
    profile: profile,
    online: online,
    bytes: bytes,
    free: free,
    queueState: queueState,
    groups: shelf,
    queue: downloading || queueState.isPaused ? [cur, queued, failed] : const [],
    breakdown: [
      const SeriesStorageUsage(sourceId: 'asura', seriesKey: 'lantern', seriesTitle: 'The Lantern Courier', bytes: 1200 * mb, chapterCount: 9, pinnedChapterCount: 9),
      const SeriesStorageUsage(sourceId: 'asura', seriesKey: 'salt', seriesTitle: 'Salt and Ember', bytes: 800 * mb, chapterCount: 5, pinnedChapterCount: 0),
    ],
    extra: extra,
  );
}

Widget _app(Widget screen, {String path = '/', bool reduced = false, TargetPlatform platform = TargetPlatform.android}) => MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: rigTheme(platform),
      routerConfig: GoRouter(routes: [GoRoute(path: path, builder: (c, s) => screen), GoRoute(path: '/:rest(.*)', builder: (c, s) => const SizedBox())]),
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: reduced), child: child!),
    );

Future<void> _shot(
  WidgetTester tester,
  String name,
  SkinShotSize size,
  Widget screen, {
  required List<Override> overrides,
  bool reduced = false,
  Future<void> Function(WidgetTester)? after,
  TargetPlatform platform = TargetPlatform.android,
  int settleMs = 2500,
}) async {
  // Whatever still asks path_provider for a directory (the image cache) gets the system temp dir.
  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(pathProvider, (call) async => Directory.systemTemp.path);
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(pathProvider, null));
  await captureSkinWidget(
    tester,
    name: name,
    size: size,
    child: _app(screen, reduced: reduced, platform: platform),
    overrides: overrides,
    disableAnimations: reduced,
    settle: (t) async {
      await t.pump();
      for (var ms = 0; ms < settleMs; ms += 250) {
        await t.pump(const Duration(milliseconds: 250));
      }
      if (after != null) await after(t);
    },
  );
}

Future<void> _tap(WidgetTester t, Finder f, {int ms = 900}) async {
  await t.tap(f.first);
  for (var i = 0; i < ms; i += 150) {
    await t.pump(const Duration(milliseconds: 150));
  }
}

/// The shelf never answers: the "checking" state.
Override downloadedShelfHold() => downloadedSeriesProvider.overrideWith((ref) => Completer<List<DownloadedSeriesGroup>>().future);

/// The shelf fails: the "error" state.
Override downloadedShelfFail() => downloadedSeriesProvider.overrideWith((ref) async => throw StateError('no read'));

void main() {
  const dl = DownloadsScreen();
  // Covers never touch the network or the disk cache: a flat plate (the design's own placeholder).
  final grey = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');
  final oldProbe = CineImage.cacheProbe, oldBuilder = CineImage.providerBuilder;
  setUpAll(() {
    CineImage.cacheProbe = (_) async => false;
    CineImage.providerBuilder = (url, headers) => MemoryImage(grey);
  });
  tearDownAll(() {
    CineImage.cacheProbe = oldProbe;
    CineImage.providerBuilder = oldBuilder;
  });

  group('Downloads', () {
    for (final size in _sizes) {
      testWidgets('saved, idle (${size.name})', (t) async {
        final r = _rig();
        await _shot(t, 'downloads-saved', size, dl, overrides: rigOverrides(r));
      });
      testWidgets('saved, downloading with the queue shown (${size.name})', (t) async {
        final r = _rig(
          downloading: true,
          queueState: const DownloadQueueState(isDownloading: true, currentChapter: _running, pagesDone: 7, pageTotal: 40, activeChapterCount: 3),
        );
        await _shot(t, 'downloads-saved-downloading', size, const DownloadsScreen(view: 'queue'), overrides: rigOverrides(r));
      });
      for (final (name, reason) in [
        ('paused-user', DownloadQueuePauseReason.userPaused),
        ('paused-floor', DownloadQueuePauseReason.freeSpaceFloor),
        ('paused-cap', DownloadQueuePauseReason.cap),
        ('paused-background', DownloadQueuePauseReason.backgrounded),
      ]) {
        testWidgets('saved, $name (${size.name})', (t) async {
          final r = _rig(queueState: DownloadQueueState(pauseReason: reason), free: reason == DownloadQueuePauseReason.freeSpaceFloor ? gb : 21 * gb, bytes: reason == DownloadQueuePauseReason.cap ? 10 * gb : 4 * gb);
          await _shot(t, 'downloads-saved-$name', size, dl, overrides: rigOverrides(r));
        });
      }
      testWidgets('saved, a series expanded (${size.name})', (t) async {
        await _shot(t, 'downloads-saved-expanded', size, dl, overrides: rigOverrides(_rig()), after: (t) => _tap(t, find.bySemanticsLabel('Expand chapters')));
      });
      testWidgets('saved, a chapter pending removal (${size.name})', (t) async {
        await _shot(
          t,
          'downloads-saved-removing',
          size,
          dl,
          overrides: rigOverrides(_rig()),
          after: (t) async {
            await _tap(t, find.bySemanticsLabel('Expand chapters'));
            await _tap(t, find.bySemanticsLabel('Remove chapter 2 from this phone'), ms: 400);
          },
        );
      });
      testWidgets('storage (${size.name})', (t) async {
        await _shot(t, 'downloads-storage', size, const DownloadsScreen(tab: 'storage'), overrides: rigOverrides(_rig()));
      });
      testWidgets('save to files sheet (${size.name})', (t) async {
        final r = _rig(extra: [chapterExporterProvider.overrideWithValue(FakeExporter(exported())), mediaStoreChannelProvider.overrideWithValue(FakeMedia(ExportDestination.mediaStoreDownloads))]);
        await _shot(
          t,
          'downloads-save-to-files',
          size,
          dl,
          overrides: rigOverrides(r),
          after: (t) async {
            await _tap(t, find.bySemanticsLabel('More for The Lantern Courier'), ms: 600);
            await _tap(t, find.text('Save to Files…'));
          },
        );
      });
      for (final (name, dest, platform) in [
        ('android', ExportDestination.mediaStoreDownloads, TargetPlatform.android),
        ('ios', ExportDestination.iosFiles, TargetPlatform.iOS),
      ]) {
        testWidgets('save to files result, $name (${size.name})', (t) async {
          final r = _rig(extra: [chapterExporterProvider.overrideWithValue(FakeExporter(exported())), mediaStoreChannelProvider.overrideWithValue(FakeMedia(dest))]);
          await _shot(
            t,
            'downloads-save-result-$name',
            size,
            dl,
            platform: platform,
            overrides: rigOverrides(r),
            after: (t) async {
              await _tap(t, find.bySemanticsLabel('More for The Lantern Courier'), ms: 600);
              await _tap(t, find.text('Save to Files…'));
              await _tap(t, find.byKey(const Key('export-format-cbz')), ms: 1500);
            },
          );
        });
      }
      testWidgets('empty (${size.name})', (t) async {
        await _shot(t, 'downloads-empty', size, dl, overrides: rigOverrides(_rig(groups: const [], bytes: 0)), settleMs: 4000);
      });
      testWidgets('checking (${size.name})', (t) async {
        final r = _rig();
        await _shot(t, 'downloads-checking', size, dl, overrides: [...rigOverrides(r), downloadedShelfHold()], settleMs: 700);
      });
      testWidgets('offline (${size.name})', (t) async {
        await _shot(t, 'downloads-offline', size, dl, overrides: rigOverrides(_rig(online: false)));
      });
      testWidgets('no profile (${size.name})', (t) async {
        await _shot(t, 'downloads-no-profile', size, dl, overrides: rigOverrides(_rig(profile: false)), settleMs: 4000);
      });
      testWidgets('error (${size.name})', (t) async {
        final r = _rig();
        await _shot(t, 'downloads-error', size, dl, overrides: [...rigOverrides(r), downloadedShelfFail()], settleMs: 4000);
      });
    }
    testWidgets('reduced motion copies', (t) async {
      await _shot(t, 'downloads-saved-reduced', _phone, dl, overrides: rigOverrides(_rig()), reduced: true);
    });
    testWidgets('reduced motion storage', (t) async {
      await _shot(t, 'downloads-storage-reduced', _phone, const DownloadsScreen(tab: 'storage'), overrides: rigOverrides(_rig()), reduced: true);
    });
  });

  group('Index', () {
    const update = AppVersionInfo(
      localVersion: '3.5.0',
      localBuild: 57,
      remoteVersion: '3.5.1',
      remoteBuild: 58,
      downloadUrl: 'http://example.test/app/download',
      channel: AppUpdateChannel.apk,
    );
    for (final size in _sizes) {
      testWidgets('member (${size.name})', (t) async {
        await _shot(t, 'index-member', size, const IndexScreen(), overrides: indexOverrides(IndexRig(admin: false)));
      });
      testWidgets('admin (${size.name})', (t) async {
        await _shot(t, 'index-admin', size, const IndexScreen(), overrides: indexOverrides(IndexRig()));
      });
      testWidgets('android update banner (${size.name})', (t) async {
        await _shot(t, 'index-update-banner', size, const IndexScreen(), overrides: indexOverrides(IndexRig(update: update)));
      });
      testWidgets('install now dialog (${size.name})', (t) async {
        await _shot(
          t,
          'index-install-now',
          size,
          const IndexScreen(),
          overrides: [...indexOverrides(IndexRig(update: update)), updateLauncherProvider.overrideWithValue((_) async => true)],
          after: (t) => _tap(t, find.text('Download update'), ms: 1200),
        );
      });
      testWidgets('offline (${size.name})', (t) async {
        await _shot(t, 'index-offline', size, const IndexScreen(), overrides: indexOverrides(IndexRig(online: false)));
      });
    }
    testWidgets('reduced motion', (t) async {
      await _shot(t, 'index-member-reduced', _phone, const IndexScreen(), overrides: indexOverrides(IndexRig(admin: false)), reduced: true);
    });
  });

  group("What's new", () {
    const entries = [
      ChangelogRelease(version: '3.5.0', build: 57, date: '2026-09-28', highlights: ['Downloads became an offline edition of its own.', 'The Index prints itself with dot leaders.']),
      ChangelogRelease(version: '3.4.2', build: 55, date: '2026-09-24', highlights: ['Sources fail loudly, then disappear.']),
    ];
    Widget host() => Consumer(builder: (context, ref, _) => Scaffold(body: Center(child: TextButton(onPressed: () => unawaited(showWhatsNewSheet(context, ref)), child: const Text('open')))));
    List<Override> base(Override changelog) => [
          changelog,
          packageInfoProvider.overrideWith((ref) async => PackageInfo(appName: 'MM', packageName: 'x', version: '3.5.0', buildNumber: '57')),
        ];
    for (final size in _sizes) {
      testWidgets('entries (${size.name})', (t) async {
        await _shot(t, 'whats-new-entries', size, host(), overrides: base(appChangelogProvider.overrideWith((ref) async => entries)), after: (t) => _tap(t, find.text('open'), ms: 1200));
      });
      testWidgets('loading (${size.name})', (t) async {
        await _shot(t, 'whats-new-loading', size, host(), overrides: base(appChangelogProvider.overrideWith((ref) => Completer<List<ChangelogRelease>>().future)), after: (t) => _tap(t, find.text('open'), ms: 1200));
      });
      testWidgets('unavailable (${size.name})', (t) async {
        await _shot(t, 'whats-new-unavailable', size, host(), overrides: base(appChangelogProvider.overrideWith((ref) async => const <ChangelogRelease>[])), after: (t) => _tap(t, find.text('open'), ms: 3000));
      });
    }
    testWidgets('reduced motion', (t) async {
      await _shot(t, 'whats-new-reduced', _phone, host(), overrides: base(appChangelogProvider.overrideWith((ref) async => entries)), reduced: true, after: (t) => _tap(t, find.text('open'), ms: 600));
    });
  });

  group('System status', () {
    for (final size in _sizes) {
      testWidgets('healthy (${size.name})', (t) async {
        final r = StatusRig(sources: [src('demo-a', SourceHealthStatus.ok), src('demo-b', SourceHealthStatus.ok)], runs: [run(1, 'completed'), run(2, 'completed')]);
        await _shot(t, 'status-healthy', size, const StatusScreen(), overrides: statusOverrides(r), settleMs: 3000);
      });
      testWidgets('two problems (${size.name})', (t) async {
        final r = StatusRig(
          sources: [src('demo-a', SourceHealthStatus.dead, fails: 10, demoted: true, err: 'NXDOMAIN'), src('demo-b', SourceHealthStatus.failing, fails: 2, err: 'HTTP 522'), src('demo-c', SourceHealthStatus.ok)],
          runs: [run(1, 'failed', error: 'connector registry unavailable'), run(2, 'completed')],
        );
        await _shot(t, 'status-two-problems', size, const StatusScreen(), overrides: statusOverrides(r), settleMs: 3000);
      });
      testWidgets('a card in error (${size.name})', (t) async {
        await _shot(t, 'status-card-error', size, const StatusScreen(), overrides: statusOverrides(StatusRig(settingsError: true, runs: [run(1, 'completed')])), settleMs: 3000);
      });
      testWidgets('non-admin (${size.name})', (t) async {
        await _shot(t, 'status-non-admin', size, const StatusScreen(), overrides: statusOverrides(StatusRig(admin: false)), settleMs: 3500);
      });
    }
    testWidgets('reduced motion', (t) async {
      final r = StatusRig(sources: [src('demo-a', SourceHealthStatus.ok)], runs: [run(1, 'completed')]);
      await _shot(t, 'status-healthy-reduced', _phone, const StatusScreen(), overrides: statusOverrides(r), reduced: true, settleMs: 500);
    });
  });
}
