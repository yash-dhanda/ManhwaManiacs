import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/app/theme/app_theme.dart';
import 'package:manhwamaniacs/features/settings/screens/feedback_lab_screen.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../screenshots/support/shot_harness.dart';
import '../../skins/skin_haptics_test.dart' show RecordingDriver;

Future<void> pump(WidgetTester tester, RecordingDriver d,
    {Size size = const Size(390, 844), double ratio = 3, GlobalKey? key,}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = size * ratio;
  tester.view.devicePixelRatio = ratio;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    child: MaterialApp(
      theme: AppTheme.dark,
      home: RepaintBoundary(key: key, child: FeedbackLabScreen(driver: d)),
    ),
  ),);
  await tester.pump();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('rows render for both skins and play through the driver', (tester) async {
    final d = RecordingDriver();
    await pump(tester, d);
    expect(find.text('tap.primary'), findsWidgets);
    await tester.tap(find.byTooltip('Play tap.primary'));
    await tester.pump();
    expect(d.calls, isNotEmpty);
    d.calls.clear();
    await tester.tap(find.text('GLASS'));
    await tester.pump();
    await tester.scrollUntilVisible(find.text('nav.push'), 200);
    expect(find.text('nav.push'), findsOneWidget);
    await tester.tap(find.byTooltip('Play nav.push'));
    await tester.pump();
    expect(d.calls.single, startsWith('ahap:'));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('play buttons are 48 x 48', (tester) async {
    await pump(tester, RecordingDriver());
    final b = find.widgetWithIcon(IconButton, Icons.play_arrow).first;
    final size = tester.getSize(find.ancestor(of: b, matching: find.byType(SizedBox)).first);
    expect(size, const Size(48, 48));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('proof shots', (tester) async {
    final proof = Platform.environment['MM_PROOF_DIR'];
    if (proof == null) return;
    for (final (label, size, ratio) in [
      ('390x844', const Size(390, 844), 3.0),
      ('834x1194', const Size(834, 1194), 2.0),
    ]) {
      for (final skin in ['cinematic', 'glass']) {
        final key = GlobalKey();
        await pump(tester, RecordingDriver(), size: size, ratio: ratio, key: key);
        if (skin == 'glass') {
          await tester.tap(find.text('GLASS'));
          await tester.pump();
        }
        await writeShot(tester, find.byKey(key), '$proof/legacy-feedback-lab-$skin-$label.png',
            pixelRatio: ratio,);
        await tester.pumpWidget(const SizedBox());
      }
    }
  });
}
