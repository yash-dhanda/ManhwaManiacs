import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_profile_settings.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/edge_hud.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/image_layers.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_chrome.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/running_head.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/zoom_chip.dart';

import '../../../screenshots/support/shot_network.dart';
import 'reader_test_support.dart';

ProviderContainer _c(WidgetTester tester) => ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

bool _chip(WidgetTester tester) => tester.widget<ReaderZoomChip>(find.byType(ReaderZoomChip)).visible;

void main() {
  setUpAll(setUpShotCoverCache);

  testWidgets('a double tap zooms to 200% and the chip shows for 1200 ms', (tester) async {
    await pumpReader(tester);
    await settleReader(tester, ms: 600);
    expect(_chip(tester), isFalse);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 350)));
    await tester.tapAt(const Offset(195, 422));
    await tester.pump(const Duration(milliseconds: 20));
    await tester.tapAt(const Offset(195, 422));
    await settleReader(tester, ms: 500);
    expect(find.text('200%'), findsOneWidget);
    expect(_chip(tester), isTrue);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(_chip(tester), isTrue, reason: 'still held about 1000 ms after the zoom landed');
    await tester.pump(const Duration(milliseconds: 300));
    expect(_chip(tester), isFalse, reason: 'gone after 1200 ms');
    await disposeReader(tester);
  });

  testWidgets('a left-edge vertical drag sets the brightness and the HUD reads NIGHT −40', (tester) async {
    await pumpReader(tester);
    await settleReader(tester, ms: 600);
    final g = await tester.startGesture(const Offset(12, 300));
    var seen = false;
    for (var dy = 0; dy < 260 && !seen; dy += 2) {
      await g.moveBy(const Offset(0, 2));
      await tester.pump(const Duration(milliseconds: 16));
      seen = find.text('NIGHT −40').evaluate().isNotEmpty;
    }
    expect(seen, isTrue, reason: 'the HUD reads NIGHT −40 on the way down');
    expect(tester.widget<EdgeHud>(find.byType(EdgeHud).first).visible, isTrue);
    await g.up();
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.widget<EdgeHud>(find.byType(EdgeHud).first).visible, isFalse, reason: 'fades 600 ms after release');
    await disposeReader(tester);
  });

  testWidgets('warmth and colour wrap only the pages; the dimmer sits under the chrome', (tester) async {
    await pumpReader(tester);
    await settleReader(tester, ms: 500);
    await _c(tester).read(readerSettingsProvider.notifier).put({'warmth': 50, 'brightness': -40, 'colour': 'grey'});
    await settleReader(tester, ms: 400);
    final filters = find.byType(ColorFiltered);
    expect(filters, findsWidgets);
    final multiply = filters.evaluate().map((e) => e.widget as ColorFiltered).where((w) => w.colorFilter == ColorFilter.mode(_warmthOf(tester), BlendMode.multiply));
    expect(multiply, isNotEmpty, reason: 'the warmth layer: color.warmth at 0.5 * 0.36 multiplied');
    expect(find.descendant(of: filters, matching: find.byType(ReaderRunningHead)), findsNothing);
    expect(find.descendant(of: filters, matching: find.byType(ReaderChromeMotion)), findsNothing);
    expect(find.descendant(of: filters, matching: find.byType(ReaderDimmer)), findsNothing);
    final dimmer = tester.widget<ReaderDimmer>(find.byType(ReaderDimmer));
    expect(dimmer.brightness, -40);
    final box = tester.widget<ColoredBox>(find.descendant(of: find.byType(ReaderDimmer), matching: find.byType(ColoredBox)));
    expect(box.color.a, closeTo(0.4, 0.01));
    // Drawn before the chrome, so under it.
    final dimmerOrder = tester.allWidgets.toList();
    expect(dimmerOrder.indexWhere((w) => w is ReaderDimmer), lessThan(dimmerOrder.indexWhere((w) => w is ReaderRunningHead)));
    await disposeReader(tester);
  });

  for (final (px, commits) in [(71.0, false), (72.0, true)]) {
    testWidgets('a ${px.toInt()} px horizontal drag ${commits ? 'commits' : 'does not commit'} a chapter change at zoom 1.0', (tester) async {
      final rig = await pumpReader(tester);
      await settleReader(tester, ms: 600);
      expect(find.text('CH 2'), findsWidgets);
      final g = await tester.startGesture(const Offset(250, 422));
      await g.moveBy(Offset(-px, 0));
      await tester.pump(const Duration(milliseconds: 16));
      await g.up();
      await settleReader(tester, ms: 1200);
      expect(rig.router.state.uri.path.contains('/c3'), commits, reason: 'swiping left is the next chapter');
      await disposeReader(tester);
    });
  }

  testWidgets('the chapter swipe is off while zoomed in', (tester) async {
    final rig = await pumpReader(tester);
    await settleReader(tester, ms: 600);
    for (var i = 0; i < 4; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.equal);
      await tester.pump(const Duration(milliseconds: 50));
    }
    await settleReader(tester, ms: 400);
    await tester.dragFrom(const Offset(250, 422), const Offset(-160, 0));
    await settleReader(tester, ms: 1200);
    expect(rig.router.state.uri.path, '/read');
    await disposeReader(tester);
  });

  testWidgets('over-scrolling up 140 px at the top loads the previous chapter; 100 px does not', (tester) async {
    final rig = await pumpReader(
      tester,
      neighbours: {'c2': (prev: 'c0', next: 'c3')},
      failing: {'c0': 'gone'},
    );
    await settleReader(tester, ms: 800);
    final g = await tester.startGesture(const Offset(195, 300));
    await g.moveBy(const Offset(0, 30));
    await tester.pump(const Duration(milliseconds: 50));
    await g.moveBy(const Offset(0, 100));
    await tester.pump(const Duration(milliseconds: 50));
    expect(rig.router.state.uri.path, '/read', reason: '100 px is not enough');
    await g.moveBy(const Offset(0, 60));
    await tester.pump(const Duration(milliseconds: 50));
    await g.moveBy(const Offset(0, 40));
    await tester.pump(const Duration(milliseconds: 50));
    await g.up();
    await settleReader(tester, ms: 1000);
    expect(rig.router.state.uri.path, contains('/c0'), reason: 'past 140 px it loads the previous chapter');
    await disposeReader(tester);
  });

  testWidgets('a full pull to continue fades through black for durFadeCut and opens the next chapter', (tester) async {
    final rig = await pumpReader(
      tester,
      pages: 2,
      failing: {'c3': 'later'},
      neighbours: {'c2': (prev: 'c1', next: 'c3')},
    );
    await _c(tester).read(readerSettingsProvider.notifier).put({'autoNextChapter': false});
    await settleReader(tester);
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
    scroll.position.jumpTo(scroll.position.maxScrollExtent);
    await settleReader(tester, ms: 600);
    expect(find.text('Pull up to continue to the next chapter'), findsNothing);
    final fade = find.byKey(const ValueKey('pull-fade'));
    expect(tester.widget<AnimatedOpacity>(fade).opacity, 0);
    final g = await tester.startGesture(const Offset(195, 600));
    var committed = false;
    for (var i = 0; i < 80 && !committed; i++) {
      await g.moveBy(const Offset(0, -12));
      await tester.pump(const Duration(milliseconds: 16));
      committed = tester.widget<AnimatedOpacity>(fade).opacity == 1;
    }
    expect(committed, isTrue, reason: 'the pull committed: fade to black');
    expect(tester.widget<AnimatedOpacity>(fade).duration, const Duration(milliseconds: 250), reason: 'durFadeCut');
    expect(rig.router.state.uri.path, '/read', reason: 'the chapter opens once the fade has run');
    await tester.pump(const Duration(milliseconds: 260));
    await g.up();
    await settleReader(tester, ms: 1000);
    expect(rig.router.state.uri.path, contains('/c3'));
    await disposeReader(tester);
  });
}

Color _warmthOf(WidgetTester tester) => readerWarmthColor(tester.element(find.byType(ReaderRunningHead)), 50);
