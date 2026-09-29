import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/skin.dart';
import 'package:manhwamaniacs/skins/skin_haptics.dart';

/// Records every haptic event instead of vibrating.
class TestHaptics extends SkinHaptics {
  TestHaptics(this.log) : super(skin: SkinId.cinematic, map: const {}, enabled: true);
  final List<HapticEvent> log;

  @override
  Future<void> fire(HapticEvent event, {double velocity = 0, int depth = 1}) async => log.add(event);
}

/// Pumps [home] inside a Cinematic-themed app at 390 x 844.
Future<void> pumpCine(
  WidgetTester t,
  Widget home, {
  bool reduced = false,
  TargetPlatform platform = TargetPlatform.iOS,
  Size size = const Size(390, 844),
  double scale = 1,
  List<HapticEvent>? haptics,
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(ProviderScope(
    overrides: [if (haptics != null) skinHapticsProvider.overrideWithValue(TestHaptics(haptics))],
    child: MaterialApp(
      theme: ThemeData(platform: platform, extensions: const [cinematicTokens]),
      builder: (c, a) => MediaQuery(data: MediaQuery.of(c).copyWith(disableAnimations: reduced, textScaler: TextScaler.linear(scale)), child: a!),
      home: Scaffold(body: home),
    ),
  ),);
}
