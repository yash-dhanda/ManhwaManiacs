import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/top_bar.dart';

import 'novel_test_support.dart';

// The reading menu's 5 s idle (shared with the manga readers): up at 4.9 s, hidden at 5.1 s; a sheet
// from it holds it (closing the Type sheet still returns to the bare page); a screen reader or reduce motion keeps it up.

/// The chrome's own switch (a sheet over it keeps it from being hit-testable, not from being shown).
bool _shown(WidgetTester t) {
  final top = find.byType(NovelTopBar);
  if (top.evaluate().isEmpty) return false;
  return !t.widgetList<IgnorePointer>(find.ancestor(of: top, matching: find.byType(IgnorePointer))).any((i) => i.ignoring);
}

Future<void> _open(WidgetTester t) async {
  await settleNovel(t);
  await t.tapAt(const Offset(195, 422));
  await t.pump();
  expect(_shown(t), isTrue, reason: 'a tap opens');
}

Future<void> _tap(WidgetTester t, Offset at) async {
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 350)));
  await t.tapAt(at);
  await settleNovel(t, ms: 400);
}

void main() {
  testWidgets("Open menu with 'Double tap': a single tap does nothing, a double tap opens", (t) async {
    await pumpNovel(t, prefsValues: {'mm.reader-settings.device': '{"menuOpen":"doubleTap"}'});
    await settleNovel(t);
    await _tap(t, const Offset(195, 422));
    expect(_shown(t), isFalse);
    await t.tapAt(const Offset(195, 422));
    await t.pump(const Duration(milliseconds: 60));
    await t.tapAt(const Offset(195, 422));
    await t.pump();
    expect(_shown(t), isTrue);
    await disposeNovel(t);
  });

  testWidgets("Open menu with 'Top or bottom edge': the centre does nothing, the bottom band opens", (t) async {
    await pumpNovel(t, prefsValues: {'mm.reader-settings.device': '{"menuOpen":"edge"}'});
    await settleNovel(t);
    await _tap(t, const Offset(195, 422));
    expect(_shown(t), isFalse);
    await _tap(t, const Offset(195, 780));
    expect(_shown(t), isTrue);
    await disposeNovel(t);
  });

  for (final on in [true, false]) {
    testWidgets('the chapter end shows the menu when Show menu at chapter end is ${on ? 'on' : 'off'}', (t) async {
      await pumpNovel(t, prefsValues: {if (!on) 'mm.reader-settings.device': '{"menuAtChapterEnd":false}'});
      await settleNovel(t);
      expect(_shown(t), isFalse);
      final pos = t.state<ScrollableState>(find.byType(Scrollable).first).position;
      // Steps down, so the lazy list's extent settles without a correction that reads as a scroll back.
      for (var i = 0; i < 40 && pos.extentAfter > 0; i++) {
        pos.jumpTo(math.min(pos.pixels + 300, pos.maxScrollExtent));
        await t.pump();
      }
      await settleNovel(t, ms: 300);
      expect(_shown(t), on);
      // Let the progress save land before teardown.
      await settleNovel(t, ms: 4000);
      await disposeNovel(t);
    });
  }

  testWidgets('opened, it is up at 4.9 s and hidden at 5.1 s', (t) async {
    await pumpNovel(t);
    await _open(t);
    await settleNovel(t, ms: 4900);
    expect(_shown(t), isTrue);
    await settleNovel(t, ms: 200);
    expect(_shown(t), isFalse);
    await disposeNovel(t);
  });

  testWidgets('a sheet from it holds it', (t) async {
    final handle = t.ensureSemantics();
    await pumpNovel(t);
    await _open(t);
    await settleNovel(t, ms: 500);
    await t.tap(find.bySemanticsLabel('Text and page').first);
    await settleNovel(t, ms: 800);
    final sheet = find.text('TEXT AND PAGE');
    expect(sheet, findsWidgets);
    await settleNovel(t, ms: 8000);
    expect(_shown(t), isTrue, reason: 'held by the sheet');
    Navigator.of(t.element(sheet.first)).pop();
    await settleNovel(t, ms: 500);
    expect(_shown(t), isFalse, reason: 'the Type sheet hands back to the page (unchanged)');
    await disposeNovel(t);
    handle.dispose();
  });

  testWidgets('a screen reader keeps it up', (t) async {
    t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(accessibleNavigation: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpNovel(t);
    await _open(t);
    await settleNovel(t, ms: 12000);
    expect(_shown(t), isTrue);
    await disposeNovel(t);
  });

  testWidgets('reduce motion keeps it up', (t) async {
    await pumpNovel(t, reduced: true);
    await _open(t);
    await settleNovel(t, ms: 12000);
    expect(_shown(t), isTrue);
    await disposeNovel(t);
  });
}
