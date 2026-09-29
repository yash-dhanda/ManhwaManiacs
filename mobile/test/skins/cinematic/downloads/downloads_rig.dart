// ignore_for_file: directives_ordering
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/models/downloaded_series_group.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/downloads/providers/active_download_queue_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloaded_series_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_storage_providers.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/downloads/store/downloads_store.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/downloads/models/series_storage_usage.dart';
import 'package:manhwamaniacs/features/library/providers/dashboard_providers.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/set_heading.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/typed_headline.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/downloads/downloads_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/skin_haptics.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/test_overrides.dart';

class MockStore extends Mock implements DownloadsStore {}

class FixedQueue extends DownloadQueueController {
  FixedQueue(this._state, {this.log});
  final DownloadQueueState _state;
  final List<String>? log;

  @override
  DownloadQueueState build() => _state;

  @override
  void pause() => log?.add('pause');

  @override
  void resume() => log?.add('resume');

  @override
  Future<void> cancelAll() async => log?.add('cancelAll');

  @override
  Future<void> cancelChapter(identity) async => log?.add('cancel:${identity.chapterKey}');

  @override
  Future<void> retryChapter(identity) async => log?.add('retry:${identity.chapterKey}');

  @override
  void retryAfterStorageChange() => log?.add('storageChange');
}

class HapticLog extends SkinHaptics {
  HapticLog(this.events) : super(skin: SkinId.cinematic, map: const {}, enabled: true);
  final List<String> events;

  @override
  Future<void> fire(HapticEvent event, {double velocity = 0, int depth = 1}) async => events.add(event.id);
}

SavedChapter chapter(
  int rowId,
  String key, {
  DownloadChapterState state = DownloadChapterState.complete,
  int bytes = 1024 * 1024,
  String? error,
  String seriesKey = 'solo',
  String seriesTitle = 'Solo Leveling',
  DownloadKind kind = DownloadKind.manga,
  bool pinned = false,
  int pages = 40,
}) =>
    SavedChapter(
      rowId: rowId,
      scopeId: 'u1p1',
      sourceId: 'asura',
      seriesKey: seriesKey,
      chapterKey: key,
      chapterNumber: double.tryParse(key.replaceAll(':audio', '')),
      title: null,
      seriesTitle: seriesTitle,
      pageCount: pages,
      bytes: bytes,
      state: state,
      pinned: pinned,
      readAt: null,
      createdAt: DateTime.utc(2026),
      retryCount: 0,
      error: error,
      kind: kind,
    );

DownloadedSeriesGroup series(List<SavedChapter> chapters, {String seriesKey = 'solo', String title = 'Solo Leveling'}) =>
    DownloadedSeriesGroup(sourceId: 'asura', seriesKey: seriesKey, seriesTitle: title, chapters: chapters);

class Rig {
  Rig({
    this.groups = const [],
    this.queue = const [],
    this.queueState = const DownloadQueueState(),
    this.bytes = 0,
    this.free = 20 * 1024 * 1024 * 1024,
    this.total = 100 * 1024 * 1024 * 1024,
    this.profile = true,
    this.online = true,
    this.breakdown = const [],
    this.extra = const [],
    this.store,
    this.gateOpen = true,
    this.cap,
  });

  List<DownloadedSeriesGroup> groups;
  final List<SavedChapter> queue;
  final DownloadQueueState queueState;
  final int bytes;
  final int? free;
  final int? total;
  final bool profile;
  final bool online;
  final List<SeriesStorageUsage> breakdown;
  final List<Override> extra;
  final DownloadsStore? store;
  final bool gateOpen;
  final Object? cap;
  final List<String> queueLog = [];
  final List<String> haptics = [];
  late final ProviderContainer container;
}

ThemeData rigTheme(TargetPlatform p) => ThemeData(brightness: Brightness.dark, platform: p, extensions: const [cinematicTokens]);

/// Every provider the Downloads screen reads, fixed to [r] (the shots reuse it).
List<Override> rigOverrides(Rig r) => [

  apiBaseUrlOverride('http://example.test'),
  if (r.profile) ...[authenticatedAuthOverride(), activeProfileOverride()],
  ...contentModeOverrides(),
  downloadedSeriesProvider.overrideWith((ref) async => r.groups),
  activeDownloadQueueProvider.overrideWith((ref) async => r.queue),
  totalDeviceDownloadBytesProvider.overrideWith((ref) async => r.bytes),
  deviceSpaceProvider.overrideWith((ref) async => (free: r.free, total: r.total)),
  seriesStorageBreakdownProvider.overrideWith((ref) async => r.breakdown),
  downloadQueueControllerProvider.overrideWith(() => FixedQueue(r.queueState, log: r.queueLog)),
  matureGateOpenProvider.overrideWithValue(r.gateOpen),
  deviceOnlineProvider.overrideWith((ref) => Stream.value(r.online)),
  updatesProvider.overrideWith(_NoUpdates.new),
  continueReadingProvider.overrideWith((ref) async => const []),
  skinHapticsProvider.overrideWithValue(HapticLog(r.haptics)),
  if (r.store != null) downloadsStoreProvider.overrideWithValue(r.store),
  ...r.extra,
];

Future<Rig> pumpDownloads(
  WidgetTester tester, {
  Rig? rig,
  String? tab,
  String? view,
  Size size = const Size(390, 844),
  bool reduced = false,
  TargetPlatform platform = TargetPlatform.android,
  double textScale = 1,
}) async {
  final r = rig ?? Rig();
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(testPrefsDefaults());
  final prefs = await SharedPreferences.getInstance();
  r.container = ProviderContainer(overrides: [sharedPrefsProvider.overrideWithValue(prefs), ...rigOverrides(r)]);
  addTearDown(r.container.dispose);
  final router = GoRouter(
    initialLocation: Routes.downloads({if (tab != null) 'tab': tab, if (view != null) 'view': view}),
    routes: [
      GoRoute(
        path: '/downloads',
        builder: (context, state) =>
            DownloadsScreen(tab: state.uri.queryParameters['tab'], view: state.uri.queryParameters['view']),
      ),
      GoRoute(path: '/:rest(.*)', builder: (context, state) => Scaffold(body: Text('at ${state.uri}'))),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: r.container,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        theme: rigTheme(platform),
        builder: (context, c) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduced, textScaler: TextScaler.linear(textScale)),
          child: c!,
        ),
      ),
    ),
  );
  await settle(tester);
  return r;
}

Future<void> settle(WidgetTester tester, {int ms = 1500}) async {
  for (var t = 0; t < ms; t += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

class _NoUpdates extends UpdatesNotifier {
  @override
  Future<UpdatesState> build() async => const UpdatesState(notifications: [], unreadCount: 0, followed: []);
}

/// A typed headline (`TypedHeadline`) by its full text: the letters land one by one, the widget
/// always carries the whole string.
Finder typed(String text) => find.byWidgetPredicate((w) => w is TypedHeadline && w.text == text);

/// A level-1 `SetHeading` by its text.
Finder heading(String text) => find.byWidgetPredicate((w) => w is SetHeading && w.text == text);
