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

void main() {
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
