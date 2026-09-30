// ignore_for_file: directives_ordering, require_trailing_commas, prefer_const_constructors, avoid_redundant_argument_values, unnecessary_lambdas, unnecessary_await_in_return
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

import 'package:manhwamaniacs/features/auth/models/bootstrap_status.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';

import '../auth/auth_test_support.dart' show FakeAuth;
import 'qa_fixtures.dart';
import 'package:manhwamaniacs/skins/cinematic/app_frame.dart';
import 'package:manhwamaniacs/skins/cinematic/flight_layer.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import '../library/library_test_support.dart';

/// The four proof sizes of the `mobile/03` harness (`kSkinShotSizes` + wide + landscape), logical px.
const Map<String, Size> kQaSizes = {
  'phone': Size(390, 844),
  'tablet': Size(834, 1194),
  'tablet-wide': Size(1024, 1366),
  'landscape': Size(844, 390),
};

/// A series key that needs every encoding rule of §8.0.3: a slash, a space and a percent sign.
const kQaHardKey = 'odd/key with 100%';

/// One `ScreenId` and how to mount it.
class QaScreen {
  const QaScreen(this.id, this.location, {this.novels = false, this.extra = const [], this.more});
  final ScreenId id;

  /// Built from the generated `Routes` builders.
  final String location;
  final bool novels;
  final List<Override> extra;

  /// Ready-state data (async fixtures).
  final Future<List<Override>> Function()? more;
}

/// Fixture follow 1 is `shelfSeries(1)`: source `shelf`, key `series-1`. Nothing here is a real
/// series, source or art (the install page is public and the app carries mature sources).
// The signed-out screens: the gates would redirect a signed-in session away from them.
final List<Override> _signedOut = [
  authControllerProvider.overrideWith(() => FakeAuth()),
  bootstrapStatusProvider.overrideWith((ref) async => const BootstrapStatus(needsBootstrap: false, registrationEnabled: true)),
];

final List<QaScreen> kQaScreens = [
  QaScreen(ScreenId.setup, Routes.setup(), extra: [..._signedOut, setupCompletedProvider.overrideWithValue(false)]),
  QaScreen(ScreenId.login, Routes.login(), extra: _signedOut),
  QaScreen(ScreenId.register, Routes.register(), extra: _signedOut),
  QaScreen(ScreenId.profiles, Routes.profiles(), more: qaProfilesOverrides),
  QaScreen(ScreenId.profileNew, Routes.profileNew(), more: qaProfilesOverrides),
  QaScreen(ScreenId.profileEdit, Routes.profileEdit(2), more: qaProfilesOverrides),
  QaScreen(ScreenId.profilesManage, Routes.profilesManage(), more: qaProfilesOverrides),
  QaScreen(ScreenId.onboarding, Routes.onboarding()),
  QaScreen(ScreenId.tonight, Routes.tonight()),
  QaScreen(ScreenId.library, Routes.library()),
  QaScreen(ScreenId.updates, Routes.updates()),
  QaScreen(ScreenId.collections, Routes.collections()),
  QaScreen(ScreenId.collection, Routes.collection(1), more: qaCollectionOverrides),
  QaScreen(ScreenId.history, Routes.history()),
  QaScreen(ScreenId.bookmarks, Routes.bookmarks()),
  QaScreen(ScreenId.picks, Routes.picks()),
  QaScreen(ScreenId.numbers, Routes.numbers(), more: qaAnnualOverrides),
  QaScreen(ScreenId.annual, Routes.annual(2026), more: qaAnnualOverrides),
  QaScreen(ScreenId.featureByFollow, Routes.featureByFollow(7), more: qaFeatureOverrides),
  QaScreen(ScreenId.feature, Routes.feature('demo', 'k'), more: qaFeatureOverrides),
  QaScreen(ScreenId.recap, Routes.recap('shelf', 'series-1', const {'to': 'ch-2'})),
  QaScreen(ScreenId.circle, Routes.circle()),
  QaScreen(ScreenId.circleMember, Routes.circleMember(2), more: qaCircleMemberOverrides),
  QaScreen(ScreenId.discover, Routes.discover()),
  QaScreen(ScreenId.sources, Routes.sources()),
  QaScreen(ScreenId.source, Routes.source('shelf')),
  QaScreen(ScreenId.reader, Routes.reader('shelf', 'series-1', 'ch-1')),
  QaScreen(ScreenId.readAll, Routes.readAll('shelf', 'series-1')),
  QaScreen(ScreenId.novel, Routes.novel('shelf', 'novel-1', 'ch-1'), novels: true),
  QaScreen(ScreenId.downloads, Routes.downloads()),
  QaScreen(ScreenId.dialogue, Routes.dialogue()),
  QaScreen(ScreenId.indexHub, Routes.indexHub()),
  QaScreen(ScreenId.settings, Routes.settings()),
  QaScreen(ScreenId.status, Routes.status()),
  QaScreen(ScreenId.readerLanding, Routes.readerLanding()),
];

/// Load-time guard: a `ScreenId` without an entry stops the test run.
final bool _complete = () {
  final have = {for (final s in kQaScreens) s.id};
  for (final id in ScreenId.values) {
    if (!have.contains(id)) throw StateError('qa_screens.dart has no entry for ScreenId.${id.id}');
  }
  return true;
}();

/// Mounts [s] in the real Cinematic router (the app frame, the shell and its providers), with the
/// Library, reader, sources and downloads data layers faked and nothing on the network.
/// [platform] also sets `debugDefaultTargetPlatformOverride` for the audit's tap-target rule.
Future<LibRig> pumpQaScreen(
  WidgetTester t,
  QaScreen s, {
  Size size = const Size(390, 844),
  TargetPlatform platform = TargetPlatform.iOS,
  double textScale = 1,
  bool reduced = false,
  Map<String, Object> prefs = const {},
  List<Override> extra = const [],
  bool settle = true,
  Key? boundaryKey,
  List<Override> before = const [],
  ShelfLibrary? lib,
}) async {
  assert(_complete);
  _mockPlugins(t);
  return await pumpShelf(
    t,
    start: s.location,
    size: size,
    platform: platform,
    textScale: textScale,
    reduced: reduced,
    novelsEnabled: s.novels,
    prefs: prefs,
    extra: [...before, ...s.extra, ...(await s.more?.call() ?? const <Override>[]), ...extra],
    settle: settle,
    frame: _realFrame,
    boundaryKey: boundaryKey,
    lib: lib,
  );
}

/// What `CinematicSkin.wrap` builds around the app (Increase Contrast, the app's reduced-motion
/// switch, Hyperlegible text, the frame and the flight layer), minus the splash.
Widget _realFrame(Widget child) => CineContrastScope(
      child: CineMotionScope(
        child: CineTextSettings(
          child: CineAppFrame(splash: false, child: FlightLayer(child: child)),
        ),
      ),
    );

/// Unmounts and lets every pending screen timer (retry back-offs, toasts) fire, so the test ends
/// with none pending.
Future<void> disposeQa(WidgetTester t, LibRig rig) async {
  await t.pumpWidget(const SizedBox());
  rig.container.dispose();
  await t.pump(const Duration(seconds: 120));
}

void _mockPlugins(WidgetTester t) {
  final m = t.binding.defaultBinaryMessenger;
  final dir = Directory.systemTemp.createTempSync('mm-qa-');
  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  m.setMockMethodCallHandler(pathProvider, (_) async => dir.path);
  const wakelock = BasicMessageChannel<Object?>('dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle', StandardMessageCodec());
  m.setMockMessageHandler(wakelock.name, (_) async => const StandardMessageCodec().encodeMessage(<Object?>[null]));
  addTearDown(() {
    m.setMockMethodCallHandler(pathProvider, null);
    m.setMockMessageHandler(wakelock.name, null);
  });
}
