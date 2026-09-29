import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/app/app_restart.dart';
import 'package:manhwamaniacs/app/skin_boot.dart';
import 'package:manhwamaniacs/app/theme/app_theme.dart';
import 'package:manhwamaniacs/features/settings/screens/diagnostics_screen.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../screenshots/support/shot_harness.dart';

Future<(SharedPreferences, int Function())> _pump(
    WidgetTester tester, Map<String, Object> initial,
    {GlobalKey? boundary,}) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  var builds = 0;
  await tester.pumpWidget(AppRestart(builder: () {
    builds++;
    return ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: RepaintBoundary(key: boundary, child: const DiagnosticsScreen()),
      ),
    );
  },),);
  await tester.pump();
  return (prefs, () => builds);
}

void main() {
  setUpAll(loadAppFonts);
  testWidgets('renders both segments and the caption', (tester) async {
    await _pump(tester, {});
    await tester.scrollUntilVisible(find.text('Clear override'), 300,
        scrollable: find.byType(Scrollable).first,);
    expect(find.text('LEGACY'), findsOneWidget);
    expect(find.text('CINEMATIC'), findsOneWidget);
    expect(find.textContaining('A device override for this phone'),
        findsOneWidget,);
    expect(
        tester
            .widget<TextButton>(
                find.widgetWithText(TextButton, 'Clear override'),)
            .onPressed,
        isNull,);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('choosing CINEMATIC writes the override and restarts',
      (tester) async {
    final (prefs, builds) = await _pump(tester, {});
    await tester.scrollUntilVisible(find.text('CINEMATIC'), 300,
        scrollable: find.byType(Scrollable).first,);
    await tester.tap(find.text('CINEMATIC'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(prefs.getString(kSkinDebugKey), 'cinematic');
    expect(prefs.getString(kSkinReturnKey), '/settings/diagnostics');
    expect(builds(), 2);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Clear override removes the key and restarts', (tester) async {
    final (p2, b2) = await _pump(tester, {kSkinDebugKey: 'cinematic'});
    await tester.scrollUntilVisible(find.text('Clear override'), 300,
        scrollable: find.byType(Scrollable).first,);
    await tester.tap(find.text('Clear override'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(p2.containsKey(kSkinDebugKey), isFalse);
    expect(b2(), 2);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('proof shot', (tester) async {
    final proof = Platform.environment['MM_PROOF_DIR'];
    if (proof == null) return;
    final key = GlobalKey();
    await _pump(tester, {}, boundary: key);
    await tester.scrollUntilVisible(find.text('Clear override'), 300,
        scrollable: find.byType(Scrollable).first,);
    await writeShot(tester, find.byKey(key),
        '$proof/legacy-diagnostics-edition-390x844.png',);
    await tester.pumpWidget(const SizedBox());
  });
}
