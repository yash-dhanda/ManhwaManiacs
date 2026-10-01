// ignore_for_file: require_trailing_commas, directives_ordering
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/app/app_restart.dart';
import 'package:manhwamaniacs/app/skin_app.dart';
import 'package:manhwamaniacs/app/skin_boot.dart';
import 'package:manhwamaniacs/core/platform/app_icon_switcher.dart';
import 'package:manhwamaniacs/core/platform/mm_platform.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloaded_series_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart' show downloadQueueControllerProvider;
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/library/providers/intelligence_providers.dart' show askRepositoryProvider;
import 'package:manhwamaniacs/features/library/repositories/ask_repository.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/profiles/repositories/profiles_repository.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_chapter_provider.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_wakelock.dart';
import 'package:manhwamaniacs/features/sources/providers/source_reader_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/glass/glass/liquid.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../skins/cinematic/feature/feature_test_support.dart' show Recorder, RecordingQueue;
import '../skins/cinematic/library/library_test_support.dart' show ShelfLibrary, savedGroup, shelfSeries;
import '../skins/cinematic/qa/qa_fixtures.dart' show qaFeatureOverrides;
import '../skins/cinematic/reader/reader_test_support.dart' show readerChapter;
import '../skins/glass/qa/glass_qa_screens.dart' show glassQaDataOverrides;
import '../skins/glass/shell/shell_rig.dart' show shellTestOverrides;
import '../support/test_overrides.dart';

/// The cross-skin release rig: the real `main.dart` boot (`AppRestart` re-running `SkinBoot.read` into a fresh
/// `ProviderScope` and `SkinApp`), over fakes that live outside the scope the way the device stores and the server do, so a
/// restart keeps them: prefs, the `/profiles` API, the library, the icon plugin and the download queue's launch counter.

/// A `/profiles` row with a skin.
Profile releaseProfile(int id, String name, {String? skin, bool mature = false, String onboardingStep = 'done'}) => Profile(
      id: id,
      name: name,
      avatarKey: 'violet',
      mood: Mood.neutral,
      sortOrder: id,
      matureContentEnabled: mature,
      createdAt: DateTime.utc(2026),
      skin: skin,
      onboardingStep: onboardingStep,
    );

/// The server's `/profiles`: `PATCH {skin}` is recorded and stored, as the backend does.
class FakeProfilesApi implements ProfilesRepository {
  FakeProfilesApi(List<Profile> items) : items = [...items];
  List<Profile> items;
  final List<(int, String)> skinPatches = [];

  @override
  Future<Result<List<Profile>>> list() async => Ok([...items]);

  @override
  Future<Result<Profile>> update(int id, {String? name, String? avatarKey, Mood? mood, int? sortOrder, bool? matureContentEnabled, String? skin, bool? notifyEnabled}) async {
    final i = items.indexWhere((p) => p.id == id);
    final o = items[i];
    if (skin != null) skinPatches.add((id, skin));
    items[i] = releaseProfile(id, name ?? o.name, skin: skin ?? o.skin, mature: matureContentEnabled ?? o.matureContentEnabled, onboardingStep: o.onboardingStep ?? 'done');
    return Ok(items[i]);
  }

  @override
  Future<Result<Profile>> create({required String name, required String avatarKey, required Mood mood, int? sortOrder, bool? matureContentEnabled, String? skin}) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> remove(int id) => throw UnimplementedError();
}

/// The two plugin calls of `AppIconSwitcher`.
class SpyIconPlugin implements AppIconPlugin {
  final List<String> calls = [];
  @override
  Future<void> setIos(String? name) async => calls.add('ios:$name');
  @override
  Future<void> setAndroid(String name) async => calls.add('android:$name');
}

/// Counts `resumePendingOnLaunch` across restarts (each boot builds a new controller).
class _SpyQueue extends RecordingQueue {
  _SpyQueue(super.rec, this.onResume);
  final VoidCallback onResume;
  @override
  void resumePendingOnLaunch() => onResume();
}

/// `GET /discover/genre/{genre}/ai`: one page, then the end.
class FakeAsk extends AskRepository {
  FakeAsk(this.items) : super(Dio());
  final List<WorldItem> items;
  @override
  Future<Result<WorldGenrePage>> genrePage(String genre, {String? cursor, CancelToken? cancel}) async => Ok(WorldGenrePage(items: items));
}

class _Wakelock implements ReaderWakelock {
  @override
  Future<void> enable() async {}
  @override
  Future<void> disable() async {}
}

class _Platform extends MmPlatform {
  _Platform() : super(channel: const MethodChannel('mm/platform-release'));
  @override
  Future<void> setExclusionRects(List<List<double>> rects) async {}
  @override
  Future<EdgeInsets?> stableInsets() async => null;
}

class ReleaseRig {
  ReleaseRig(this.t, this.prefs, this.api, this.icon, this.rec, this.lib);
  final WidgetTester t;
  final SharedPreferences prefs;
  final FakeProfilesApi api;
  final SpyIconPlugin icon;
  final Recorder rec;
  final ShelfLibrary lib;

  /// One entry per boot: the skin and return route `SkinBoot.read` gave it.
  final List<SkinId> skins = [];
  final List<String?> routes = [];
  int resumes = 0;
  int get boots => skins.length;

  ProviderContainer get container => ProviderScope.containerOf(t.element(find.byType(SkinApp)), listen: false);

  /// The top route's location (a pushed reader is an imperative match).
  String get at {
    final cfg = container.read(skinRouterProvider).routerDelegate.currentConfiguration;
    if (cfg.isEmpty) return '';
    final last = cfg.last;
    return last is ImperativeRouteMatch ? last.matches.uri.toString() : cfg.uri.toString();
  }

  GoRouter get router => container.read(skinRouterProvider);
}

/// `testWidgets` that resets the platform override before the framework's invariant check.
void releaseWidgets(String description, Future<void> Function(WidgetTester t) body, {TargetPlatform platform = TargetPlatform.iOS}) {
  testWidgets('${platform.name}: $description', (t) async {
    debugDefaultTargetPlatformOverride = platform;
    try {
      await body(t);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

/// Boots the app the way `main.dart` does with the device mirror at [skin] and [route] as the return route. Profiles 1 (Riya)
/// and 2 (Aarav) exist on the fake server with [profileSkins] (default: both [skin]); profile [active] is remembered.
Future<ReleaseRig> pumpRelease(
  WidgetTester t, {
  required SkinId skin,
  String? skinName,
  String route = '/',
  Map<int, String?>? profileSkins,
  int active = 1,
  bool gateOpen = false,
  bool iconFollow = false,
  List<WorldItem> genreItems = const [],
  Map<String, Object> prefs = const {},
  Size size = const Size(390, 844),
  String onboardingStep = 'done',
}) async {
  _mockPlugins(t);
  // Glass prepare() initialises the liquid-glass shaders; a test host only needs it to resolve.
  resetLiquidGlassReadyForTest();
  liquidGlassInitializer = () async {};
  final platform = defaultTargetPlatform;
  // The Cinematic series fixtures reset the mock prefs, so they are built first.
  final feature = await qaFeatureOverrides();
  final skins = profileSkins ?? {1: skin.name, 2: skin.name};
  final api = FakeProfilesApi([releaseProfile(1, 'Riya', skin: skins[1], onboardingStep: onboardingStep), releaseProfile(2, 'Aarav', skin: skins[2])]);
  final activeRow = api.items.firstWhere((p) => p.id == active);
  SharedPreferences.setMockInitialValues(testPrefsDefaults({
    kSkinActiveKey: skinName ?? skin.name,
    if (route != '/') kSkinReturnKey: route,
    'mm.active_profile': jsonEncode(activeRow.toSnapshot().toJson()),
    if (iconFollow) kIconFollowKey: true,
    ...prefs,
  }));
  final p = await SharedPreferences.getInstance();
  final icon = SpyIconPlugin();
  final rec = Recorder();
  final lib = ShelfLibrary(all: [for (var i = 1; i <= 12; i++) shelfSeries(i)]);
  final rig = ReleaseRig(t, p, api, icon, rec, lib);
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  ({String? prev, String? next}) n(String k) => k == 'ch-1' ? (prev: null, next: 'ch-2') : (prev: 'ch-1', next: null);

  await t.pumpWidget(AppRestart(builder: () {
    final boot = SkinBoot.read(p);
    rig.skins.add(boot.skin);
    rig.routes.add(boot.returnRoute);
    return ProviderScope(
      overrides: [
        ...shellTestOverrides(),
        ...feature,
        ...glassQaDataOverrides(rec: rec, lib: lib, gateOpen: gateOpen),
        readerWakelockProvider.overrideWithValue(_Wakelock()),
        mmPlatformProvider.overrideWithValue(_Platform()),
        resolvedReaderChapterProvider.overrideWith((ref, key) async {
          final x = n(key.chapterKey);
          return (chapter: readerChapter(key.chapterKey, prev: x.prev, next: x.next), chapterNumber: 1.0, prev: x.prev, next: x.next, isOffline: false);
        }),
        sourceReaderChapterProvider.overrideWith((ref, key) async {
          final x = n(key.chapterId);
          return readerChapter(key.chapterId, prev: x.prev, next: x.next);
        }),
        sourceChapterNeighboursProvider.overrideWith((ref, key) async => (previousChapterId: n(key.chapterId).prev, nextChapterId: n(key.chapterId).next)),
        chapterNeighboursProvider.overrideWith((ref, key) async => (chapterNumber: 1.0, prev: n(key.chapterKey).prev, next: n(key.chapterKey).next)),
        askRepositoryProvider.overrideWithValue(FakeAsk(genreItems)),
        // One chapter saved on the device (the downloads store outlives a restart).
        downloadedSeriesProvider.overrideWith((ref) async => [savedGroup(1)]),
        downloadQueueControllerProvider.overrideWith(() => _SpyQueue(rec, () => rig.resumes++)),
        // The real boot state: the remembered profile, the session gate, the profile list from the fake server, the outbox.
        profilesRepositoryProvider.overrideWithValue(api),
        profilesProvider.overrideWith(ProfilesNotifier.new),
        activeProfileProvider.overrideWith(ActiveProfileNotifier.new),
        profileSessionReadyProvider.overrideWith(ProfileSessionReadyNotifier.new),
        appIconSwitcherProvider.overrideWithValue(AppIconSwitcher(prefs: p, plugin: icon, platform: platform)),
        skinIdProvider.overrideWithValue(boot.skin),
        returnRouteProvider.overrideWithValue(boot.returnRoute),
        skinRestartCarriesSessionProvider.overrideWithValue(boot.carrySession),
        sharedPrefsProvider.overrideWithValue(p),
      ],
      child: const SkinApp(),
    );
  }));
  await settle(t, ms: 3000);
  return rig;
}

/// Frames in 50 ms steps, letting real async (prefs writes, the outbox) run between them.
Future<void> settle(WidgetTester t, {int ms = 1000}) async {
  for (var e = 0; e < ms; e += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

/// Pumps until [done] or [maxMs]; returns the frames' total.
Future<int> pumpUntil(WidgetTester t, bool Function() done, {int maxMs = 5000}) async {
  var e = 0;
  while (!done() && e < maxMs) {
    await t.pump(const Duration(milliseconds: 50));
    await t.runAsync(() async {});
    e += 50;
  }
  return e;
}

/// Unmounts and lets every pending timer (toasts, retries, the 10 s undo) fire.
Future<void> disposeRelease(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 30));
}

/// Every paragraph on screen carries the skin's face and no underline, never Flutter's debug fallback (yellow double
/// underline on red 48 px) that text gets outside a DefaultTextStyle.
void expectSkinText(Finder scope) {
  final hosted = find.descendant(of: scope, matching: find.byType(RichText)).evaluate().toList();
  expect(hosted, isNotEmpty);
  for (final e in hosted) {
    final p = e.renderObject! as RenderParagraph;
    final s = p.text.style;
    final what = p.text.toPlainText();
    if (what.trim().isEmpty) continue;
    expect(s?.fontFamily, isNotNull, reason: '"$what" has no skin face');
    expect(s?.decorationColor, isNot(const Color(0xFFFFFF00)), reason: '"$what" is the debug fallback');
    p.text.visitChildren((span) {
      final d = span.style?.decoration;
      expect(d == null || d == TextDecoration.none, isTrue, reason: '"$what" is underlined');
      return true;
    });
  }
}

void _mockPlugins(WidgetTester t) {
  final m = t.binding.defaultBinaryMessenger;
  final dir = Directory.systemTemp.createTempSync('mm-release-');
  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  const haptics = MethodChannel('gaimon');
  const secure = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  const status = MethodChannel('dev.fluttercommunity.plus/connectivity_status');
  const check = MethodChannel('dev.fluttercommunity.plus/connectivity');
  const wakelock = BasicMessageChannel<Object?>('dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle', StandardMessageCodec());
  m.setMockMethodCallHandler(pathProvider, (_) async => dir.path);
  m.setMockMethodCallHandler(haptics, (_) async => null);
  m.setMockMethodCallHandler(secure, (_) async => null);
  m.setMockMethodCallHandler(status, (_) async => null);
  m.setMockMethodCallHandler(check, (_) async => <String>['wifi']);
  m.setMockMessageHandler(wakelock.name, (_) async => const StandardMessageCodec().encodeMessage(<Object?>[null]));
  // The connectivity handlers stay: the plugin's broadcast stream is a process singleton, and its `cancel` can arrive after a
  // teardown, which would report a MissingPluginException into the next test.
  addTearDown(() {
    for (final c in [pathProvider, haptics, secure]) {
      m.setMockMethodCallHandler(c, null);
    }
    m.setMockMessageHandler(wakelock.name, null);
  });
}
