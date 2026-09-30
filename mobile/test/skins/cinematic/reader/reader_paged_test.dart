import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/paged_reader_view.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_view.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_prefs_migration.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/paged_rules.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/tap_zone_bands.dart';

import '../../../screenshots/support/shot_network.dart';
import 'reader_test_support.dart';

Map<String, Object> seedLayout(String layout, {String direction = 'ltr', Map<String, Object> more = const {}}) => {
      kReaderPrefsSeedKey: jsonEncode({
        'seriesDefaults': {'layout': layout, 'direction': direction},
        ...more,
      }),
    };

/// The page the reader reports (the counter is in the chrome, which a turn hides).
int pageOf(WidgetTester tester) {
  final paged = find.byType(PagedReaderView);
  if (paged.evaluate().isNotEmpty) return tester.widget<PagedReaderView>(paged).controller.value.page;
  return tester.widget<ReaderEngineView>(find.byType(ReaderEngineView)).controller.value.page;
}

Future<void> key(WidgetTester tester, LogicalKeyboardKey k, {int ms = 600, bool shift = false}) async {
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(k);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await settleReader(tester, ms: ms);
}

void main() {
  setUpAll(setUpShotCoverCache);

  testWidgets('single layout mounts the paged view; taps 30 / 40 / 30 turn and toggle the chrome', (tester) async {
    await pumpReader(tester, prefsValues: seedLayout('single'));
    await settleReader(tester, ms: 500);
    expect(find.byType(PagedReaderView), findsOneWidget);
    expect(find.byType(ReaderEngineView), findsNothing);
    expect(pageOf(tester), 1);
    await tapSingle(tester, const Offset(350, 422));
    expect(pageOf(tester), 2);
    await tapSingle(tester, const Offset(40, 422));
    expect(pageOf(tester), 1);
    final before = chromeVisible(tester);
    await tapSingle(tester);
    expect(chromeVisible(tester), isNot(before));
    await disposeReader(tester);
  });

  testWidgets('right to left mirrors the automatic zones: left is next', (tester) async {
    await pumpReader(tester, prefsValues: seedLayout('single', direction: 'rtl'));
    await settleReader(tester, ms: 500);
    await tapSingle(tester, const Offset(40, 422));
    expect(pageOf(tester), 2);
    await tapSingle(tester, const Offset(350, 422));
    expect(pageOf(tester), 1);
    await disposeReader(tester);
  });

  testWidgets('the zone bands show on first use, hold 1500 ms, fade over 1000 ms and are remembered', (tester) async {
    await pumpReader(tester, prefsValues: seedLayout('single'));
    await settleReader(tester, ms: 300);
    expect(find.byKey(const ValueKey('zone-band-0')), findsOneWidget);
    expect(find.text('BACK'), findsOneWidget);
    expect(find.text('MENU'), findsOneWidget);
    expect(find.text('NEXT'), findsOneWidget);
    double opacity() => tester.widget<Opacity>(find.descendant(of: find.byType(TapZoneBands), matching: find.byType(Opacity)).first).opacity;
    await tester.pump(const Duration(milliseconds: 1000));
    expect(opacity(), 1);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(opacity(), inExclusiveRange(0, 1), reason: 'fading after the 1500 ms hold');
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.byKey(const ValueKey('zone-band-0')), findsNothing);
    final prefs = ProviderScope.containerOf(tester.element(find.byType(MaterialApp))).read(sharedPrefsProvider);
    expect(prefs.getStringList(kZonesSeenKey), ['single:previous,menu,next']);
    await disposeReader(tester);

    // Seen already: they do not come back.
    await pumpReader(tester, prefsValues: {...seedLayout('single'), kZonesSeenKey: ['single:previous,menu,next']});
    await settleReader(tester, ms: 400);
    expect(find.byKey(const ValueKey('zone-band-0')), findsNothing);
    await disposeReader(tester);
  });

  testWidgets('the K01 toast shows once per device after a sideways migration', (tester) async {
    await pumpReader(tester, prefsValues: {...seedLayout('single'), 'settings_reading_direction': 'leftToRight'});
    await settleReader(tester, ms: 500);
    expect(find.text(kK01ToastText), findsOneWidget);
    final prefs = ProviderScope.containerOf(tester.element(find.byType(MaterialApp))).read(sharedPrefsProvider);
    expect(prefs.getBool(kK01ToastSeenKey), isTrue);
    await disposeReader(tester);
    await pumpReader(tester, prefsValues: {...seedLayout('single'), 'settings_reading_direction': 'leftToRight', kK01ToastSeenKey: true});
    await settleReader(tester, ms: 500);
    expect(find.text(kK01ToastText), findsNothing);
    await disposeReader(tester);
  });

  testWidgets('w v r switch layouts and keep the page; the strip path is the engine view', (tester) async {
    await pumpReader(tester);
    await settleReader(tester, ms: 500);
    expect(find.byType(ReaderEngineView), findsOneWidget);
    await key(tester, LogicalKeyboardKey.keyV);
    expect(find.byType(PagedReaderView), findsOneWidget);
    await key(tester, LogicalKeyboardKey.keyJ);
    await key(tester, LogicalKeyboardKey.keyJ);
    expect(pageOf(tester), 3);
    await key(tester, LogicalKeyboardKey.keyW, ms: 900);
    expect(find.byType(ReaderEngineView), findsOneWidget);
    expect(pageOf(tester), 3, reason: 'the page carried over');
    await key(tester, LogicalKeyboardKey.keyR, ms: 900);
    expect(find.byType(PagedReaderView), findsOneWidget);
    expect(pageOf(tester), 3);
    await disposeReader(tester);
  });

  testWidgets('paged keys: arrows by reading direction, space, home and end; p does nothing', (tester) async {
    await pumpReader(tester, prefsValues: seedLayout('double'));
    await settleReader(tester, ms: 500);
    await key(tester, LogicalKeyboardKey.arrowRight);
    expect(pageOf(tester), 2);
    await key(tester, LogicalKeyboardKey.arrowRight);
    expect(pageOf(tester), 4, reason: 'a spread is one turn');
    await key(tester, LogicalKeyboardKey.arrowLeft);
    expect(pageOf(tester), 2);
    await key(tester, LogicalKeyboardKey.space);
    expect(pageOf(tester), 4);
    await key(tester, LogicalKeyboardKey.space, shift: true);
    expect(pageOf(tester), 2);
    await key(tester, LogicalKeyboardKey.end);
    expect(pageOf(tester), 6);
    await key(tester, LogicalKeyboardKey.home);
    expect(pageOf(tester), 1);
    await key(tester, LogicalKeyboardKey.keyP);
    expect(find.byIcon(Icons.pause), findsNothing);
    await disposeReader(tester);
  });
}
