// ignore_for_file: directives_ordering, require_trailing_commas, prefer_const_constructors, avoid_redundant_argument_values, unnecessary_lambdas
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart' show isTest;
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/reader/models/chapter_manifest_window.dart';
import 'package:manhwamaniacs/features/auth/models/bootstrap_status.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloaded_series_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart' show downloadQueueControllerProvider;
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/glass_skin.dart';
import 'package:manhwamaniacs/skins/skin_haptics.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/test_overrides.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import '../../cinematic/auth/auth_test_support.dart' show FakeAuth, profile;
import '../../cinematic/feature/feature_test_support.dart' show FakeReader, Recorder, RecordingHaptics, RecordingQueue;
import '../../cinematic/library/library_test_support.dart' show ShelfLibrary, kShelfNow, shelfSeries;
import '../../cinematic/qa/qa_fixtures.dart';
import '../shell/shell_rig.dart';

/// A reader repository whose multi-chapter manifest window answers offline (`FakeReader` leaves it unimplemented), so "Read all"
/// reaches its real error state instead of throwing in the feed factory.
class GlassQaReader extends FakeReader {
  GlassQaReader(super.rec);
  @override
  Future<Result<ChapterManifestWindow>> manifestWindow({required String sourceId, required String seriesKey, required List<String> chapterKeys}) async =>
      const Err(NetworkError(message: 'offline in test'));
}

/// The proof sizes of `mobile/45` (logical px). `phone-max` is defined here only (the large phone of `web/45`).
const Map<String, Size> kGlassQaSizes = {
  'phone': Size(390, 844),
  'phone-max': Size(440, 956),
  'tablet': Size(834, 1194),
  'tablet-wide': Size(1024, 1366),
  'desktop': Size(1366, 1024),
};

/// One `ScreenId` and how to mount it in the Glass router. Locations are the generated `Routes` builders.
class GlassQaScreen {
  const GlassQaScreen(this.id, this.location, {this.novels = false, this.extra = const [], this.more, this.signedOut = false});
  final ScreenId id;
  final String location;
  final bool novels;
  final bool signedOut;
  final List<Override> extra;
  final Future<List<Override>> Function()? more;
}

final List<Override> _signedOut = [
  authControllerProvider.overrideWith(() => FakeAuth()),
  bootstrapStatusProvider.overrideWith((ref) async => const BootstrapStatus(needsBootstrap: false, registrationEnabled: true)),
];

class _Profiles extends ProfilesNotifier {
  _Profiles(this.items);
  final List<Profile> items;
  @override
  Future<List<Profile>> build() async => items;
}

/// A profile list for the picker, form and manage screens (the shell fakes list none); [step] null needs onboarding.
Future<List<Override>> qaProfileList({String? step = 'done'}) async => [
      profilesProvider.overrideWith(() => _Profiles([profile(1, 'Tester', step: step), profile(2, 'Guest')])),
    ];

Future<List<Override>> qaProfileListForm() => qaProfileList();
Future<List<Override>> qaOnboardingProfile() => qaProfileList(step: '1');

final List<GlassQaScreen> kGlassQaScreens = [
  GlassQaScreen(ScreenId.setup, Routes.setup(), signedOut: true, extra: [..._signedOut, setupCompletedProvider.overrideWithValue(false)]),
  GlassQaScreen(ScreenId.login, Routes.login(), signedOut: true, extra: _signedOut),
  GlassQaScreen(ScreenId.register, Routes.register(), signedOut: true, extra: _signedOut),
  GlassQaScreen(ScreenId.profiles, Routes.profiles(), more: qaProfileListForm),
  GlassQaScreen(ScreenId.profileNew, Routes.profileNew(), more: qaProfileListForm),
  GlassQaScreen(ScreenId.profileEdit, Routes.profileEdit(2), more: qaProfileListForm),
  GlassQaScreen(ScreenId.profilesManage, Routes.profilesManage(), more: qaProfileListForm),
  GlassQaScreen(ScreenId.onboarding, Routes.onboarding(), more: qaOnboardingProfile),
  GlassQaScreen(ScreenId.tonight, Routes.tonight()),
  GlassQaScreen(ScreenId.library, Routes.library()),
  GlassQaScreen(ScreenId.updates, Routes.updates()),
  GlassQaScreen(ScreenId.collections, Routes.collections()),
  GlassQaScreen(ScreenId.collection, Routes.collection(1), more: qaCollectionOverrides),
  GlassQaScreen(ScreenId.history, Routes.history()),
  GlassQaScreen(ScreenId.bookmarks, Routes.bookmarks()),
  GlassQaScreen(ScreenId.picks, Routes.picks()),
  GlassQaScreen(ScreenId.numbers, Routes.numbers(), more: qaAnnualOverrides),
  GlassQaScreen(ScreenId.annual, Routes.annual(2026), more: qaAnnualOverrides),
  GlassQaScreen(ScreenId.featureByFollow, Routes.featureByFollow(7), more: qaFeatureOverrides),
  GlassQaScreen(ScreenId.feature, Routes.feature('demo', 'k'), more: qaFeatureOverrides),
  GlassQaScreen(ScreenId.recap, Routes.recap('shelf', 'series-1', const {'to': 'ch-2'})),
  GlassQaScreen(ScreenId.circle, Routes.circle()),
  GlassQaScreen(ScreenId.circleMember, Routes.circleMember(2), more: qaCircleMemberOverrides),
  GlassQaScreen(ScreenId.discover, Routes.discover()),
  GlassQaScreen(ScreenId.sources, Routes.sources()),
  GlassQaScreen(ScreenId.source, Routes.source('shelf')),
  GlassQaScreen(ScreenId.reader, Routes.reader('shelf', 'series-1', 'ch-1')),
  GlassQaScreen(ScreenId.readAll, Routes.readAll('shelf', 'series-1')),
  GlassQaScreen(ScreenId.novel, Routes.novel('shelf', 'novel-1', 'ch-1'), novels: true),
  GlassQaScreen(ScreenId.downloads, Routes.downloads()),
  GlassQaScreen(ScreenId.dialogue, Routes.dialogue()),
  GlassQaScreen(ScreenId.indexHub, Routes.indexHub()),
  GlassQaScreen(ScreenId.settings, Routes.settings()),
  GlassQaScreen(ScreenId.status, Routes.status()),
  GlassQaScreen(ScreenId.readerLanding, Routes.readerLanding()),
];

/// The sheet routes of B1: each has a deep-link full page (the screen above) and a sheet over its base.
const kGlassQaSheetIds = {ScreenId.feature, ScreenId.featureByFollow, ScreenId.recap, ScreenId.circleMember, ScreenId.profileNew, ScreenId.profileEdit};

/// Load-time guard: a `ScreenId` without an entry stops the test run.
final bool _complete = () {
  final have = {for (final s in kGlassQaScreens) s.id};
  for (final id in ScreenId.values) {
    if (!have.contains(id)) throw StateError('glass_qa_screens.dart has no entry for ScreenId.${id.id}');
  }
  return true;
}();

/// The library, reader, sources and downloads fakes shared by every Glass QA mount.
List<Override> glassQaDataOverrides({Recorder? rec, ShelfLibrary? lib, bool gateOpen = false, ContentMode mode = ContentMode.manga, bool novels = false}) {
  final r = rec ?? Recorder();
  return [
    ...contentModeOverrides(mode: mode, novelsEnabled: novels),
    libraryRepositoryProvider.overrideWithValue(lib ?? ShelfLibrary(all: [for (var i = 1; i <= 12; i++) shelfSeries(i)])),
    readerRepositoryProvider.overrideWithValue(GlassQaReader(r)),
    skinHapticsProvider.overrideWithValue(RecordingHaptics(r)),
    downloadQueueControllerProvider.overrideWith(() => RecordingQueue(r)),
    matureGateOpenProvider.overrideWithValue(gateOpen),
    downloadedSeriesProvider.overrideWith((ref) async => const []),
    clockProvider.overrideWithValue(() => kShelfNow),
    sourcesListProvider.overrideWith((ref) async => const [
          SourceSummary(id: 'shelf', name: 'Shelf Scans', description: '', browsable: true, supportsImport: false),
        ]),
  ];
}

/// What a QA pump returns: the shell rig and the call recorder behind the fakes.
class GlassQaRig {
  GlassQaRig(this.shell, this.rec);
  final ShellRig shell;
  final Recorder rec;
  String get at => shell.at;
}

/// Mounts [s] in the real Glass router (the shell, the frame and `GlassSkin.wrap`) over fake repositories, nothing on the network.
/// [platform] also sets `debugDefaultTargetPlatformOverride` (reset by teardown) for the audit's tap-target rule.
Future<GlassQaRig> pumpGlassQa(
  WidgetTester t,
  GlassQaScreen s, {
  Size size = const Size(390, 844),
  double dpr = 1,
  TargetPlatform platform = TargetPlatform.iOS,
  double textScale = 1,
  bool reduced = false,
  bool boldText = false,
  bool highContrast = false,
  Map<String, Object> prefs = const {},
  List<Override> extra = const [],
  bool settle = true,
}) async {
  assert(_complete);
  _mockPlugins(t);
  final rec = Recorder();
  SharedPreferences.setMockInitialValues(testPrefsDefaults(prefs));
  final p = await SharedPreferences.getInstance();
  final overrides = [
    sharedPrefsProvider.overrideWithValue(p),
    skinIdProvider.overrideWithValue(SkinId.glass),
    ...shellTestOverrides(),
    ...glassQaDataOverrides(rec: rec, novels: s.novels),
    ...s.extra,
    ...(await s.more?.call() ?? const <Override>[]),
    ...extra,
    // Last: the Cinematic fixtures' `featureOverrides` swap in an empty prefs instance, which would drop the caller's prefs.
    sharedPrefsProvider.overrideWithValue(p),
  ];
  final c = ProviderContainer(overrides: overrides);
  addTearDown(c.dispose);
  t.view.physicalSize = size * dpr;
  t.view.devicePixelRatio = dpr;
  addTearDown(t.view.reset);
  debugDefaultTargetPlatformOverride = platform; // reset by [glassQaWidgets] (a teardown runs after the invariant check)
  final router = c.read(skinRouterProvider);
  if (s.location != '/') router.go(s.location);
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: Consumer(
      builder: (context, ref, _) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: GlassSkin.baseTheme.copyWith(platform: platform),
        routerConfig: ref.watch(skinRouterProvider),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reduced,
            boldText: boldText,
            highContrast: highContrast,
          ),
          child: const GlassSkin().wrap(context, child ?? const SizedBox.shrink()),
        ),
      ),
    ),
  ));
  if (settle) {
    for (var i = 0; i < 16; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  } else {
    await t.pump();
  }
  return GlassQaRig(ShellRig(router, c), rec);
}

/// `testWidgets` that clears the platform override [pumpGlassQa] sets before the framework's invariant check.
@isTest
void glassQaWidgets(String description, Future<void> Function(WidgetTester t) body, {Timeout? timeout}) {
  testWidgets(description, (t) async {
    try {
      await body(t);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }, timeout: timeout);
}

/// Unmounts and lets every pending timer fire so the test ends with none pending.
Future<void> disposeGlassQa(WidgetTester t, GlassQaRig rig) async {
  await t.pumpWidget(const SizedBox());
  rig.shell.container.dispose();
  await t.pump(const Duration(seconds: 120));
}

void _mockPlugins(WidgetTester t) {
  final m = t.binding.defaultBinaryMessenger;
  final dir = Directory.systemTemp.createTempSync('mm-gqa-');
  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  m.setMockMethodCallHandler(pathProvider, (_) async => dir.path);
  const haptics = MethodChannel('gaimon');
  m.setMockMethodCallHandler(haptics, (_) async => null);
  const wakelock = BasicMessageChannel<Object?>('dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle', StandardMessageCodec());
  m.setMockMessageHandler(wakelock.name, (_) async => const StandardMessageCodec().encodeMessage(<Object?>[null]));
  addTearDown(() {
    m.setMockMethodCallHandler(pathProvider, null);
    m.setMockMethodCallHandler(haptics, null);
    m.setMockMessageHandler(wakelock.name, null);
  });
}
