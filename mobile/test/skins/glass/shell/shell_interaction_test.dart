import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/primitives/drag_owner.dart';
import 'package:manhwamaniacs/skins/glass/shell/dock.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';

import '../../../screenshots/support/shot_harness.dart';
import 'shell_rig.dart';

Future<void> _ms(WidgetTester t, [int ms = 800]) async {
  await t.pump();
  await t.pump(Duration(milliseconds: ms));
}

void main() {
  setUpAll(loadAppFonts);

  group('dock physics', () {
    test('the droplet stretches with speed: scaleX 1 + min(|v| / 2000, 0.25)', () {
      expect(dropletStretch(0).x, 1);
      expect(dropletStretch(1000).x, closeTo(1.25, 1e-9));
      expect(dropletStretch(400).x, closeTo(1.2, 1e-9));
      expect(dropletStretch(400).y, closeTo(1 / 1.2.sqrt(), 1e-9));
      expect(dropletStretch(-5000).x, 1.25);
    });

    test('a release projects to the nearest tab', () {
      expect(dropletTarget(posPx: 100, velocityPxPerS: 0, tabWidth: 80), 1);
      expect(dropletTarget(posPx: 100, velocityPxPerS: 3000, tabWidth: 80), 3);
      expect(dropletTarget(posPx: 100, velocityPxPerS: -3000, tabWidth: 80), 0);
    });

    testWidgets('dragging across the dock ticks nav.scrub, then selects the tab it lands on', (t) async {
      GlassHaptics.debugLog.clear();
      final rig = await pumpGlassShell(t);
      final main = find.bySemanticsLabel('Main');
      final r = t.getRect(main);
      final gesture = await t.startGesture(Offset(r.left + 30, r.center.dy));
      for (var i = 0; i < 12; i++) {
        await gesture.moveBy(const Offset(14, 0));
        await t.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await _ms(t, 900);
      final events = GlassHaptics.debugLog.map((e) => e.event).toList();
      expect(events, contains(HapticEvent.navScrub));
      expect(events, contains(HapticEvent.navChange));
      expect(tabOfRig(rig), isNot(GlassTab.home));
    });

    testWidgets('tapping the active tab at its root fires nav.reselect', (t) async {
      GlassHaptics.debugLog.clear();
      await pumpGlassShell(t, start: '/dev/glass/shell');
      await t.tap(dockTab('You'));
      await _ms(t);
      expect(GlassHaptics.debugLog.map((e) => e.event), contains(HapticEvent.navReselect));
    });
  });

  group('back order', () {
    testWidgets('back on a branch root that is not Home goes to Home; on Home it leaves the app', (t) async {
      final rig = await pumpGlassShell(t);
      await t.tap(dockTab('Library'));
      await _ms(t);
      expect(rig.at, '/library');
      expect(await t.binding.handlePopRoute(), isTrue);
      await _ms(t);
      expect(rig.at, '/');
      // Home's root: nothing pops; the system leaves the app (handlePopRoute reports it was not handled by the app).
      expect(tabOfRig(rig), GlassTab.home);
    });

    testWidgets('back pops a pushed level before anything else', (t) async {
      final rig = await pumpGlassShell(t, start: '/dev/glass/shell');
      await t.tap(find.text('Push a level').first);
      await _ms(t);
      expect(rig.container.read(glassDepthProvider)[GlassTab.you], 1);
      await t.binding.handlePopRoute();
      await _ms(t);
      expect(rig.container.read(glassDepthProvider)[GlassTab.you], 0);
    });

    testWidgets('an open menu closes first', (t) async {
      final rig = await pumpGlassShell(t);
      await t.longPress(dockTab('Library'));
      await _ms(t);
      expect(find.text('Shelf'), findsWidgets);
      await t.binding.handlePopRoute();
      await _ms(t);
      expect(find.text('Shelf'), findsNothing);
      expect(rig.at, '/');
    });
  });

  group('iOS full-width back swipe', () {
    testWidgets('a rightward drag anywhere on a pushed page pops it, with the threshold haptic', (t) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      GlassHaptics.debugLog.clear();
      final rig = await pumpGlassShell(t, start: '/dev/glass/shell');
      await t.tap(find.text('Push a level').first);
      await _ms(t);
      expect(rig.container.read(glassDepthProvider)[GlassTab.you], 1);
      await t.dragFrom(const Offset(200, 500), const Offset(260, 0));
      await _ms(t, 1000);
      expect(rig.container.read(glassDepthProvider)[GlassTab.you], 0);
      expect(GlassHaptics.debugLog.map((e) => e.event), contains(HapticEvent.thresholdCross));
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('a horizontal-drag owner keeps its drag: the page is not popped', (t) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final rig = await pumpGlassShell(t, start: '/dev/glass/shell');
      await t.tap(find.text('Push a level').first);
      await _ms(t);
      final reg = rig.container.read(glassDragOwnerRegistryProvider);
      reg.register('test-row', kind: GlassDragOwnerKind.row, rect: () => const Rect.fromLTWH(0, 380, 390, 120));
      await t.dragFrom(const Offset(200, 440), const Offset(220, 0));
      await _ms(t, 1000);
      expect(rig.container.read(glassDepthProvider)[GlassTab.you], 1);
      reg.unregister('test-row');
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('a drag that starts in the leading 24 px still pops through an owner', (t) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final rig = await pumpGlassShell(t, start: '/dev/glass/shell');
      await t.tap(find.text('Push a level').first);
      await _ms(t);
      final reg = rig.container.read(glassDragOwnerRegistryProvider);
      reg.register('test-row', kind: GlassDragOwnerKind.row, rect: () => const Rect.fromLTWH(0, 380, 390, 120));
      await t.dragFrom(const Offset(10, 440), const Offset(260, 0));
      await _ms(t, 1000);
      expect(rig.container.read(glassDepthProvider)[GlassTab.you], 0);
      reg.unregister('test-row');
      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('command palette', () {
    testWidgets('typing filters, Enter opens the active result and closes the palette', (t) async {
      final rig = await pumpGlassShell(t, size: const Size(834, 1194));
      await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.keyK);
      await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await _ms(t);
      await t.enterText(find.byType(EditableText).last, 'histo');
      await _ms(t, 600);
      expect(find.text('History'), findsWidgets);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await _ms(t, 900);
      expect(rig.at, '/library/history');
      expect(find.text('close'), findsNothing);
    });

    testWidgets('an empty result says so', (t) async {
      await pumpGlassShell(t, size: const Size(834, 1194));
      await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.keyK);
      await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await _ms(t);
      await t.enterText(find.byType(EditableText).last, 'qqqzzz');
      await _ms(t, 900);
      expect(find.text('Nothing matches “qqqzzz”.'), findsOneWidget);
    });
  });
}

extension on double {
  double sqrt() => this <= 0 ? 0 : _sqrt(this);
}

double _sqrt(double x) {
  var r = x;
  for (var i = 0; i < 30; i++) {
    r = 0.5 * (r + x / r);
  }
  return r;
}
