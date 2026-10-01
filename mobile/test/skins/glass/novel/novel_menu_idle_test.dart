import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/chrome_top.dart';

import 'novel_rig.dart';

// The reading menu's 5 s idle on the Glass novel reader (shared with the manga readers): up at 4.9 s,
// hidden at 5.1 s; a touch on it restarts the 5 s; a screen reader keeps it up.

bool _live(WidgetTester t) {
  final top = find.byType(NovelChromeTop);
  if (top.evaluate().isEmpty) return false;
  return !t.widgetList<IgnorePointer>(find.ancestor(of: top, matching: find.byType(IgnorePointer))).any((i) => i.ignoring);
}

Future<void> _open(WidgetTester t) async {
  await settle(t);
  await t.tapAt(const Offset(195, 500));
  // The tap is told from a double tap first; the clock starts the frame the chrome turns live.
  for (var i = 0; i < 100 && !_live(t); i++) {
    await t.pump(const Duration(milliseconds: 10));
  }
  expect(_live(t), isTrue, reason: 'a tap opens');
}

void main() {
  testWidgets('opened, it is up at 4.9 s and hidden at 5.1 s', (t) async {
    await pumpGlassNovel(t);
    await _open(t);
    await settle(t, ms: 4900);
    expect(_live(t), isTrue);
    await settle(t, ms: 200);
    expect(_live(t), isFalse);
    await disposeGlassNovel(t);
  });

  testWidgets('a touch on the menu restarts the 5 s', (t) async {
    await pumpGlassNovel(t);
    await _open(t);
    await settle(t, ms: 4000);
    final g = await t.startGesture(t.getCenter(find.byType(NovelChromeTop)));
    await settle(t, ms: 3000);
    expect(_live(t), isTrue, reason: 'held while the finger is down');
    await g.cancel();
    await t.pump();
    await settle(t, ms: 4900);
    expect(_live(t), isTrue);
    await settle(t, ms: 200);
    expect(_live(t), isFalse);
    await disposeGlassNovel(t);
  });

  testWidgets('a screen reader keeps it up', (t) async {
    await pumpGlassNovel(t, accessibleNavigation: true);
    await _open(t);
    await settle(t, ms: 12000);
    expect(_live(t), isTrue);
    await disposeGlassNovel(t);
  });
}
