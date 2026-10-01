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

Future<void> _tap(WidgetTester t, Offset at) async {
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 350)));
  await t.tapAt(at);
  await settle(t, ms: 500);
}

void main() {
  testWidgets("Open menu with 'Double tap': a single tap does nothing, a double tap opens", (t) async {
    await pumpGlassNovel(t, prefs: {'mm.reader-settings.device': '{"menuOpen":"doubleTap"}', 'mm.glass.lightFollowsDevice': false});
    await settle(t);
    await _tap(t, const Offset(195, 500));
    expect(_live(t), isFalse);
    await t.tapAt(const Offset(195, 500));
    await t.pump(const Duration(milliseconds: 60));
    await t.tapAt(const Offset(195, 500));
    await settle(t, ms: 500);
    expect(_live(t), isTrue);
    await disposeGlassNovel(t);
  });

  testWidgets("Open menu with 'Top or bottom edge': the centre does nothing, the bottom band opens", (t) async {
    await pumpGlassNovel(t, prefs: {'mm.reader-settings.device': '{"menuOpen":"edge"}', 'mm.glass.lightFollowsDevice': false});
    await settle(t);
    await _tap(t, const Offset(195, 500));
    expect(_live(t), isFalse);
    await _tap(t, const Offset(195, 780));
    expect(_live(t), isTrue);
    await disposeGlassNovel(t);
  });

  testWidgets('the chapter end shows the menu', (t) async {
    await pumpGlassNovel(t);
    await settle(t);
    final pos = t.state<ScrollableState>(find.byType(Scrollable).first).position;
    pos.jumpTo(pos.maxScrollExtent);
    await settle(t, ms: 300);
    expect(_live(t), isTrue);
    // Let the progress save land before teardown.
    await settle(t, ms: 4000);
    await disposeGlassNovel(t);
  });

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
