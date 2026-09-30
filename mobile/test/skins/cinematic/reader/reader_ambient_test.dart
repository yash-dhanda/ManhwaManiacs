import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/models/reader_page.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_prefs_provider.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_prefs_migration.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/auto_scroll_chip.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/guided_view.dart';

import '../../../screenshots/support/shot_network.dart';
import 'reader_test_support.dart';

/// Three panels on page 1, none on page 2 (`[]`), nothing known on the rest.
ReaderChapter _withPanels(String id) {
  final base = readerChapter(id);
  return ReaderChapter(
    id: base.id,
    seriesId: base.seriesId,
    title: base.title,
    pageCount: base.pageCount,
    sourceId: base.sourceId,
    seriesTitle: base.seriesTitle,
    previousChapterId: base.previousChapterId,
    nextChapterId: base.nextChapterId,
    pages: [
      for (final p in base.pages)
        ReaderPage(
          id: p.id,
          number: p.number,
          imageUrl: p.imageUrl,
          width: 800,
          height: 1200,
          tint: p.number == 1 ? '#C82828' : null,
          panels: switch (p.number) {
            1 => const [Rect.fromLTWH(0, 0, 1, 0.3), Rect.fromLTWH(0, 0.35, 1, 0.3), Rect.fromLTWH(0, 0.7, 1, 0.3)],
            2 => const <Rect>[],
            _ => null,
          },
        ),
    ],
  );
}

Map<String, Object> _seed({Map<String, Object> more = const {}, String layout = 'strip'}) => {
      kReaderPrefsMigratedKey: true,
      kReaderPrefsSeedKey: jsonEncode({
        'seriesDefaults': {'layout': layout},
        ...more,
      }),
    };

/// The profile record (`mm.reader-settings`) under the signed-in and the device key.
Map<String, Object> _settings(Map<String, Object> record) => {
      'mm.reader-settings.u1p1': jsonEncode(record),
      'mm.reader-settings.device': jsonEncode(record),
    };

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key, {int ms = 700}) async {
  await tester.sendKeyEvent(key);
  await settleReader(tester, ms: ms);
}

Finder _folio(String t) => find.text(t, findRichText: true);

void main() {
  setUpAll(setUpShotCoverCache);

  testWidgets('u enters guided view: PANEL n / m, j dollies, the last panel cuts to the next page, u leaves', (tester) async {
    await pumpReader(tester, chapters: {'c2': _withPanels('c2')}, prefsValues: _seed());
    await settleReader(tester, ms: 500);
    await _key(tester, LogicalKeyboardKey.keyU, ms: 900);
    expect(find.byType(CineGuidedView), findsOneWidget);
    final view = tester.widget<CineGuidedView>(find.byType(CineGuidedView));
    expect(view.engine.value.guidedActive, isTrue, reason: 'iOS canSwipe reads this');
    expect(_folio('PANEL 1 / 3 · PAGE 1'), findsOneWidget);
    await _key(tester, LogicalKeyboardKey.keyJ, ms: 700);
    expect(_folio('PANEL 2 / 3 · PAGE 1'), findsOneWidget);
    await _key(tester, LogicalKeyboardKey.keyJ);
    await _key(tester, LogicalKeyboardKey.keyJ);
    // Page 2 has `[]` panels: the page shows whole.
    expect(_folio('PAGE 2 · WHOLE PAGE'), findsOneWidget);
    await _key(tester, LogicalKeyboardKey.keyK);
    expect(_folio('PANEL 3 / 3 · PAGE 1'), findsOneWidget);
    await _key(tester, LogicalKeyboardKey.keyU, ms: 900);
    expect(find.byType(CineGuidedView), findsNothing);
    await disposeReader(tester);
  });

  testWidgets('guided view reads the page and its panels before analysis: FINDING PANELS then WHOLE PAGE', (tester) async {
    await pumpReader(tester, chapters: {'c2': _withPanels('c2')}, prefsValues: _seed(layout: 'guided'));
    await settleReader(tester, ms: 300);
    // Page 3 has no stored panels: analysing (or having failed to decode the test image).
    for (var i = 0; i < 4; i++) {
      await _key(tester, LogicalKeyboardKey.keyJ, ms: 200);
    }
    final t = find.textContaining('PAGE 3', findRichText: true);
    expect(t, findsOneWidget);
    await settleReader(tester, ms: 13000);
    expect(_folio('PAGE 3 · WHOLE PAGE'), findsOneWidget);
    await disposeReader(tester);
  });

  testWidgets('auto-advance holds the fixed time, a key pauses it and p resumes', (tester) async {
    await pumpReader(
      tester,
      chapters: {'c2': _withPanels('c2')},
      prefsValues: {..._seed(layout: 'guided'), ..._settings({'guidedAutoAdvance': {'on': true, 'mode': 'FIXED', 'fixedMs': 3500}})},
    );
    await settleReader(tester, ms: 500);
    expect(_folio('PANEL 1 / 3 · PAGE 1'), findsOneWidget);
    await settleReader(tester, ms: 2900);
    expect(_folio('PANEL 1 / 3 · PAGE 1'), findsOneWidget, reason: 'still holding at 3.4 s');
    await settleReader(tester, ms: 1000);
    expect(_folio('PANEL 2 / 3 · PAGE 1'), findsOneWidget);
    // A key press pauses it.
    await _key(tester, LogicalKeyboardKey.keyK, ms: 600);
    await settleReader(tester, ms: 5000);
    expect(_folio('PANEL 1 / 3 · PAGE 1'), findsOneWidget);
    // p resumes.
    await _key(tester, LogicalKeyboardKey.keyP, ms: 300);
    await settleReader(tester, ms: 4200);
    expect(_folio('PANEL 2 / 3 · PAGE 1'), findsOneWidget);
    await disposeReader(tester);
  });

  testWidgets('reduced motion: guided auto-advance never starts by itself', (tester) async {
    await pumpReader(
      tester,
      reduced: true,
      chapters: {'c2': _withPanels('c2')},
      prefsValues: {..._seed(layout: 'guided'), ..._settings({'guidedAutoAdvance': {'on': true, 'mode': 'FIXED', 'fixedMs': 2000}})},
    );
    await settleReader(tester, ms: 500);
    await settleReader(tester, ms: 6000);
    expect(_folio('PANEL 1 / 3 · PAGE 1'), findsOneWidget);
    await disposeReader(tester);
  });

  test('chip text: speed folio, PACED, PAUSED FOR LISTEN and the guided labels', () {
    expect(autoScrollChipText(speedX: 1.25, paced: false), '1.25×');
    expect(autoScrollChipText(speedX: 1, paced: true), '1.00× · PACED');
    expect(autoScrollChipText(speedX: 1, paced: false, pausedForListen: true), 'PAUSED FOR LISTEN');
    expect(autoScrollChipText(speedX: 1, paced: false, autoLabel: 'AUTO · 3.5 S'), 'AUTO · 3.5 S');
  });
}
