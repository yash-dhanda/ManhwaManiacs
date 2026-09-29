import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/app/app_restart.dart';
import 'package:manhwamaniacs/app/skin_boot.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/pending_screen.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screenshots/support/shot_harness.dart';

Future<(SharedPreferences, int Function())> _pump(
  WidgetTester tester,
  SkinId skin, {
  Size size = const Size(390, 844),
  double textScale = 1,
  GlobalKey? boundary,
}) async {
  SharedPreferences.setMockInitialValues({kSkinDebugKey: skin.name});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  var builds = 0;
  await tester.pumpWidget(AppRestart(builder: () {
    builds++;
    return ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        skinIdProvider.overrideWithValue(skin),
      ],
      child: MaterialApp(
        builder: (c, child) => MediaQuery(
          data: MediaQuery.of(c)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: RepaintBoundary(key: boundary, child: child),
        ),
        home: const PendingScreen(
            screenId: 'settings', location: '/settings/diagnostics',),
      ),
    );
  },),);
  return (prefs, () => builds);
}

void main() {
  setUpAll(loadAppFonts);
  final proof = Platform.environment['MM_PROOF_DIR'];

  for (final skin in [SkinId.cinematic, SkinId.glass]) {
    testWidgets('${skin.name}: text renders, static, and shots',
        (tester) async {
      final key = GlobalKey();
      await _pump(tester, skin, boundary: key);
      expect(find.text('${skin.name.toUpperCase()} · NOT BUILT YET'),
          findsOneWidget,);
      expect(find.text('settings'), findsOneWidget);
      expect(find.text('/settings/diagnostics'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
      if (proof != null) {
        await writeShot(
            tester, find.byKey(key), '$proof/${skin.name}-pending-390x844.png',);
        tester.view.physicalSize = const Size(834, 1194);
        await tester.pump();
        await writeShot(tester, find.byKey(key),
            '$proof/${skin.name}-pending-834x1194.png',);
      }
    });
  }

  for (final (platform, min) in [
    (TargetPlatform.iOS, 44.0),
    (TargetPlatform.android, 48.0),
  ]) {
    testWidgets('button is at least $min tall on $platform, labelled',
        (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      await _pump(tester, SkinId.cinematic);
      expect(tester.getSize(find.byType(OutlinedButton)).height,
          greaterThanOrEqualTo(min),);
      expect(find.bySemanticsLabel('Leave the preview'), findsWidgets);
      debugDefaultTargetPlatformOverride = null;
    });
  }

  testWidgets('tapping Leave the preview clears the override and restarts',
      (tester) async {
    final (prefs, builds) = await _pump(tester, SkinId.cinematic);
    await tester.tap(find.byType(OutlinedButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(prefs.containsKey(kSkinDebugKey), isFalse);
    expect(builds(), 2);
  });

  testWidgets('text scale 2.0 does not overflow', (tester) async {
    await _pump(tester, SkinId.glass, textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
