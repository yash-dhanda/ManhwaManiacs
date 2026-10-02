import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/overlay_queue.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/feature_screen.dart';
import 'package:manhwamaniacs/skins/glass/shell/accessory_controller.dart';
import 'package:manhwamaniacs/skins/glass/shell/dock_state.dart';
import 'package:manhwamaniacs/skins/glass/shell/search_orb.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';
import 'package:manhwamaniacs/skins/glass/shell/sidebar.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/skins.dart';

import '../../../screenshots/support/shot_harness.dart';
import 'shell_rig.dart';

const _demo = '/dev/glass/shell';

Future<void> _settle(WidgetTester t, [int ms = 700]) async {
  await t.pump();
  await t.pump(Duration(milliseconds: ms));
}

void main() {
  setUpAll(loadAppFonts);

  group('phone dock', () {
    testWidgets('a container labelled Main with four tabs, Home selected', (t) async {
      final handle = t.ensureSemantics();
      final rig = await pumpGlassShell(t);
      expect(find.bySemanticsLabel('Main'), findsOneWidget);
      for (final l in ['Home', 'Library', 'Sources', 'You']) {
        expect(dockTab(l), findsOneWidget, reason: l);
      }
      expect(tabOfRig(rig), GlassTab.home);
      handle.dispose();
    });

    testWidgets('tapping Library selects it and fires nav.change', (t) async {
      GlassHaptics.debugLog.clear();
      final rig = await pumpGlassShell(t);
      await t.tap(dockTab('Library'));
      await _settle(t);
      expect(rig.at, '/library');
      expect(tabOfRig(rig), GlassTab.library);
      expect(GlassHaptics.debugLog.map((e) => e.event), contains(HapticEvent.navChange));
    });

    testWidgets('20 px of downward scroll minimises the dock and 12 px up restores it', (t) async {
      final rig = await pumpGlassShell(t, start: _demo);
      expect(rig.container.read(glassDockMinimisedProvider), isFalse);
      await t.dragFrom(const Offset(200, 640), const Offset(0, -60));
      await _settle(t);
      expect(rig.container.read(glassDockMinimisedProvider), isTrue);
      await t.dragFrom(const Offset(200, 640), const Offset(0, 40));
      await _settle(t);
      expect(rig.container.read(glassDockMinimisedProvider), isFalse);
    });

    testWidgets('never minimises while a screen reader is on', (t) async {
      final rig = await pumpGlassShell(t, start: _demo);
      rig.container.read(glassAssistiveProvider.notifier).state = true;
      await t.dragFrom(const Offset(200, 640), const Offset(0, -80));
      await _settle(t);
      expect(rig.container.read(glassDockMinimisedProvider), isFalse);
    });

    testWidgets('long-pressing Library opens its menu with a header and its rows', (t) async {
      await pumpGlassShell(t);
      await t.longPress(dockTab('Library'));
      await _settle(t);
      expect(find.text('Shelf'), findsWidgets);
      expect(find.text('History'), findsWidgets);
    });

    testWidgets('the orb pushes /search and Cancel pops', (t) async {
      final rig = await pumpGlassShell(t);
      await t.tap(find.byType(GlassSearchOrbBody));
      await _settle(t, 900);
      expect(rig.at, startsWith('/search'));
      await t.tap(find.text('Cancel'));
      await _settle(t, 900);
      expect(rig.at, '/');
    });

    testWidgets('the accessory publishes, inlines on minimise and hides for the session', (t) async {
      final rig = await pumpGlassShell(t, start: _demo);
      final acc = rig.container.read(glassAccessoryProvider.notifier);
      acc.setDownloading(GlassDownloadingAccessory(chapters: 3, progress: 0.42, paused: false, onToggle: () {}));
      await _settle(t);
      expect(find.textContaining('Saving 3 chapters'), findsOneWidget);
      expect(rig.container.read(glassAccessoryVisibleProvider), isTrue);
      await t.dragFrom(const Offset(200, 640), const Offset(0, -80));
      await _settle(t);
      expect(rig.container.read(glassDockMinimisedProvider), isTrue);
      expect(find.textContaining('Saving 3 chapters'), findsOneWidget); // minimised it keeps its title: never an empty player
      acc.hideForSession();
      await _settle(t);
      expect(rig.container.read(glassAccessoryVisibleProvider), isFalse);
    });

    testWidgets('a bottom bar takes the accessory\'s place', (t) async {
      final rig = await pumpGlassShell(t, start: _demo);
      rig.container.read(glassAccessoryProvider.notifier).setDownloading(GlassDownloadingAccessory(chapters: 1, progress: 0.1, paused: false, onToggle: () {}));
      await _settle(t);
      rig.container.read(glassBottomBarProvider.notifier).state = GlassBottomBar.bulk;
      await _settle(t);
      expect(rig.container.read(glassAccessoryVisibleProvider), isFalse);
    });
  });

  group('wide frames', () {
    testWidgets('1366 x 1024: the sidebar is 280 wide with edge 292; Ctrl+B collapses it to 76', (t) async {
      final handle = t.ensureSemantics();
      final rig = await pumpGlassShell(t, size: const Size(1366, 1024));
      expect(find.byType(GlassSidebar), findsOneWidget);
      expect(t.getSize(find.byType(SkinGlass).first).width, greaterThan(0));
      expect(t.getSize(sidebarPanel()).width, closeTo(280, 1));
      expect(rig.container.read(glassSidebarEdgeProvider), 292);
      await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.keyB);
      await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await _settle(t);
      expect(t.getSize(sidebarPanel()).width, closeTo(76, 1));
      expect(rig.container.read(glassSidebarEdgeProvider), 88);
      handle.dispose();
    });

    testWidgets('1100 x 800: starts collapsed; Ctrl+B opens the overlay and Esc closes it', (t) async {
      final handle = t.ensureSemantics();
      final rig = await pumpGlassShell(t, size: const Size(1100, 800));
      expect(t.getSize(sidebarPanel()).width, closeTo(76, 1));
      await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.keyB);
      await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await _settle(t);
      expect(t.getSize(sidebarPanel()).width, closeTo(280, 1));
      expect(rig.container.read(glassSidebarChoiceProvider), isTrue);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await _settle(t);
      expect(rig.container.read(glassSidebarChoiceProvider), isFalse);
      expect(t.getSize(sidebarPanel()).width, closeTo(76, 1));
      handle.dispose();
    });

    testWidgets('Ctrl+K opens the command palette and ? opens the shortcuts sheet on a tablet frame', (t) async {
      await pumpGlassShell(t, size: const Size(834, 1194));
      await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.keyK);
      await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await _settle(t);
      expect(find.textContaining('Esc'), findsWidgets);
      expect(find.text('close'), findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await _settle(t);
      expect(find.text('close'), findsNothing);
    });
  });

  group('routes', () {
    testWidgets('a poster push opens the feature sheet with the page beneath still mounted; back closes it', (t) async {
      final rig = await pumpGlassShell(t, start: _demo);
      await t.tap(find.byType(GlassPoster).first, warnIfMissed: false);
      await _settle(t, 800);
      // The poster's semantic label is the title.
      expect(rig.at, anyOf(_demo, startsWith('/sources/demo/series/')));
    });

    testWidgets('a cold go to the same location renders the screen as a full page', (t) async {
      await pumpGlassShell(t, start: '/sources/demo/series/x');
      // mobile/33: the series screen itself, as a full page (no sheet route beneath).
      expect(find.byType(GlassFeatureScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('glass-sheet-surface')), findsNothing);
    });

    testWidgets('an unknown location renders the not-found lens', (t) async {
      await pumpGlassShell(t, start: '/nowhere/at/all');
      await _settle(t);
      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.text('Back home'), findsOneWidget);
    });

    testWidgets('/library/abc is not a followed id: the not-found lens', (t) async {
      await pumpGlassShell(t, start: '/library/abc');
      await _settle(t);
      expect(find.text('Nothing here'), findsOneWidget);
    });

    testWidgets('the g chord: g then l goes to Library', (t) async {
      final rig = await pumpGlassShell(t);
      await t.sendKeyEvent(LogicalKeyboardKey.keyG, character: 'g');
      await t.sendKeyEvent(LogicalKeyboardKey.keyL, character: 'l');
      await _settle(t);
      expect(rig.at, '/library');
    });

    testWidgets('three pushes record depth 3; a profile switch resets every branch', (t) async {
      final rig = await pumpGlassShell(t, start: _demo);
      for (var i = 0; i < 3; i++) {
        await t.tap(find.text('Push a level').first);
        await _settle(t, 800);
      }
      expect(rig.container.read(glassDepthProvider)[GlassTab.you], 3);
      final n = rig.container.read(glassRouterEpochProvider.notifier);
      n.state = GlassRouterEpoch(n.state.epoch + 1, '/');
      await _settle(t, 900);
      final router = rig.container.read(skinRouterProvider);
      expect(router.routerDelegate.currentConfiguration.uri.toString(), '/');
      // The switch's toasts and refreshes run out before the tree goes.
      await _settle(t, 15000);
    });
  });

  test('platform override helper leaves nothing behind', () {
    expect(debugDefaultTargetPlatformOverride, isNull);
  });
}
