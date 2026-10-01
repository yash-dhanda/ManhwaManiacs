import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/app/skin_app.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_overrides.dart';
import 'shot_harness.dart';

/// One proof size. Every later mobile step captures through these constants.
class SkinShotSize {
  const SkinShotSize(this.name, this.logical, this.pixelRatio, this.padding);
  final String name;
  final Size logical;
  final double pixelRatio;
  final EdgeInsets padding;

  String get label => '${logical.width.round()}x${logical.height.round()}';
}

const kSkinShotSizes = [
  SkinShotSize('phone', Size(390, 844), 3.0, EdgeInsets.only(top: 47, bottom: 34)),
  SkinShotSize('tablet', Size(834, 1194), 2.0, EdgeInsets.only(top: 24, bottom: 20)),
];

// Not in the default loop; a step asks for them by name when its layout needs them.
const kSkinShotTabletWide = SkinShotSize('tablet-wide', Size(1024, 1366), 2.0, EdgeInsets.only(top: 24, bottom: 20)); // the >= 900 px rows of 8.0.9
/// The Glass desktop frame's proof size (glass 8.0.1 gives it the 280 px sidebar from 1180 px wide; no mobile/03 size reaches it).
const kSkinShotDesktop = SkinShotSize('desktop', Size(1366, 1024), 2.0, EdgeInsets.only(top: 24, bottom: 20));
const kSkinShotLandscape = SkinShotSize('landscape', Size(844, 390), 3.0, EdgeInsets.only(left: 47, right: 47, bottom: 21)); // landscape phone, 8.0.9

/// The RepaintBoundary every capture rasterises.
final kSkinShotKey = GlobalKey(debugLabel: 'skinShot');

/// e.g. `../docs/redesign/proof/mobile-04`. Unset: rasterise and discard.
String? get proofDir {
  final v = (Platform.environment['MM_PROOF_DIR'] ?? '').trim();
  return v.isEmpty ? null : v;
}

/// `MM_PROOF_SCREENS=tonight,library`; default Tonight only.
List<ScreenId> get proofScreens {
  final v = (Platform.environment['MM_PROOF_SCREENS'] ?? '').trim();
  if (v.isEmpty) return const [ScreenId.tonight];
  return [for (final id in v.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty)) ScreenId.values.firstWhere((s) => s.id == id)];
}

/// Fixture overrides per screen; each screen step adds its own entry.
final Map<ScreenId, List<Override> Function()> kSkinShotOverrides = {};

/// Fills `:param` segments with fixture values.
String skinShotPath(ScreenId screen) => screen.path.replaceAllMapped(
      RegExp(r':(\w+)'),
      (m) => switch (m.group(1)) {
        'year' => '2026',
        'sourceId' => 'shelf',
        'seriesKey' => 'the-lantern-courier',
        'chapterKey' => 'ch-1',
        _ => '1',
      },
    );

/// The app root listens to connectivity; a test host has no plugin, so answer the channels.
void _mockPlatformChannels(WidgetTester tester) {
  final messenger = tester.binding.defaultBinaryMessenger;
  const status = MethodChannel('dev.fluttercommunity.plus/connectivity_status');
  const check = MethodChannel('dev.fluttercommunity.plus/connectivity');
  messenger.setMockMethodCallHandler(status, (_) async => null);
  messenger.setMockMethodCallHandler(check, (_) async => <String>['wifi']);
  addTearDown(() {
    messenger.setMockMethodCallHandler(status, null);
    messenger.setMockMethodCallHandler(check, null);
  });
}

/// [captureSkinScreen]'s view setup for a step that drives the app itself (mobile/29's shell shots).
void setSkinShotView(WidgetTester tester, SkinShotSize size) => _setView(tester, size);

/// The root overrides [captureSkinScreen] pumps with: prefs, auth, profile, no downloads store.
Future<List<Override>> skinShotRootOverrides() => _rootOverrides();

/// The alignment sweep re-runs the per-screen proof suites on other phones and text sizes: `MM_SHOT_PHONE=375x667` (or 430x932)
/// swaps every 'phone' capture's frame and safe areas, `MM_SHOT_TEXT_SCALE=1.3` sets the device text scale for every capture.
SkinShotSize _swept(SkinShotSize size) {
  final v = (Platform.environment['MM_SHOT_PHONE'] ?? '').trim();
  if (size.name != 'phone' || v.isEmpty) return size;
  final p = v.split('x').map(double.parse).toList();
  final pad = p[1] < 700 ? const EdgeInsets.only(top: 20) : EdgeInsets.only(top: p[0] >= 428 ? 59 : 47, bottom: 34);
  return SkinShotSize('phone', Size(p[0], p[1]), size.pixelRatio, pad);
}

void _setView(WidgetTester tester, SkinShotSize requested) {
  final size = _swept(requested);
  final scale = double.tryParse(Platform.environment['MM_SHOT_TEXT_SCALE'] ?? '');
  if (scale != null) {
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }
  _mockPlatformChannels(tester);
  tester.view.physicalSize = size.logical * size.pixelRatio;
  tester.view.devicePixelRatio = size.pixelRatio;
  tester.view.padding = FakeViewPadding(
    left: size.padding.left * size.pixelRatio,
    top: size.padding.top * size.pixelRatio,
    right: size.padding.right * size.pixelRatio,
    bottom: size.padding.bottom * size.pixelRatio,
  );
  addTearDown(() {
    tester.view.reset();
  });
}

Future<List<Override>> _rootOverrides() async {
  SharedPreferences.setMockInitialValues(testPrefsDefaults());
  final prefs = await SharedPreferences.getInstance();
  return [
    sharedPrefsProvider.overrideWithValue(prefs),
    authenticatedAuthOverride(),
    activeProfileOverride(),
    profileSessionReadyOverride(),
    ...noDownloadsStoreOverrides(),
    ...contentModeOverrides(),
  ];
}

Future<void> _finish(WidgetTester tester, String fileName, SkinShotSize size, String? dir) async {
  final target = dir ?? proofDir;
  if (target == null) {
    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(kSkinShotKey));
    await tester.runAsync(() async {
      (await boundary.toImage(pixelRatio: size.pixelRatio)).dispose();
    });
  } else {
    await writeShot(tester, find.byKey(kSkinShotKey), '$target/$fileName', pixelRatio: size.pixelRatio);
  }
  await drainCacheTimers(tester);
}

/// Pumps [screen] under [skin] and writes `<proofDir>/<skin>-<screen>-<w>x<h>.png`.
Future<void> captureSkinScreen(
  WidgetTester tester, {
  required SkinId skin,
  required ScreenId screen,
  required SkinShotSize size,
  String? location,
  List<Override> overrides = const [],
}) async {
  _setView(tester, size);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...await _rootOverrides(),
        skinIdProvider.overrideWithValue(skin),
        returnRouteProvider.overrideWithValue(location ?? skinShotPath(screen)),
        ...(kSkinShotOverrides[screen]?.call() ?? const <Override>[]),
        ...overrides,
      ],
      child: RepaintBoundary(key: kSkinShotKey, child: const SkinApp()),
    ),
  );
  await settleShot(tester);
  await _finish(tester, '${skin.name}-${screen.id}-${size.label}.png', size, null);
}

/// For what is not a route: pumps [child] and writes `<proofDir>/<name>-<size.name>.png`.
Future<void> captureSkinWidget(
  WidgetTester tester, {
  required String name,
  required SkinShotSize size,
  required Widget child,
  List<Override> overrides = const [],
  bool disableAnimations = false,
  double textScale = 1.0,
  String? proofDirOverride, // only for the harness's own test
  Future<void> Function(WidgetTester tester)? afterSettle, // e.g. pumpUntilCoversLoad
  Future<void> Function(WidgetTester tester)? settle, // replaces settleShot (a state at an exact time)
}) async {
  _setView(tester, size);
  final data = MediaQueryData.fromView(tester.view).copyWith(
    disableAnimations: disableAnimations,
    textScaler: TextScaler.linear(textScale),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...await _rootOverrides(), ...overrides],
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(data: data, child: RepaintBoundary(key: kSkinShotKey, child: child)),
      ),
    ),
  );
  await (settle ?? settleShot)(tester);
  if (afterSettle != null) await afterSettle(tester);
  await _finish(tester, '$name-${size.name}.png', size, proofDirOverride);
}
