// ignore_for_file: avoid_print, require_trailing_commas
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/app/app_restart.dart';
import 'package:manhwamaniacs/app/skin_app.dart';
import 'package:manhwamaniacs/app/skin_boot.dart';
import 'package:manhwamaniacs/app/switch_skin.dart';
import 'package:manhwamaniacs/core/platform/mm_platform.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart' show skinRestartCarriesSessionProvider;
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/glass/liquid.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/routes/nav_extra.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/library_hub.dart';
import 'package:manhwamaniacs/skins/glass/shell/handoff_layer.dart';
import 'package:manhwamaniacs/skins/glass/shell/skin_switch_flow.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/test_overrides.dart';
import '../listen/listen_rig.dart';
import '../novel/novel_rig.dart' show disposeGlassNovel, settle;
import '../shell/shell_rig.dart' show shellTestOverrides;
import 'glass_gpu_probe.dart';
import 'glass_qa_screens.dart';

/// G3, the Glass twin of `cinematic_nav_soak_test.dart`: every tab, sheets opened, dragged and closed, both reader entry points
/// opened, pinched and swiped back, full-width back swipes and a page removed under the finger, three laps through the real
/// router on iOS; listen mode opened and closed; a skin switch round trip. Each step settles inside 120 frames, leaves no user
/// gesture open, keeps the glass layer budget and the blur passes of every frame bounded, and rebuilds nothing once idle
/// beyond looping motion. Under Reduce Motion and Low Power no frame reads the backdrop at all.
///
/// Blur passes are counted in the layer tree (backdrop filters + image filters). Tests run the frost renderer, one backdrop
/// layer per live surface; on Impeller each liquid layer is a blur and a shader pass. The cap is the first frame of a push: both
/// pages, each with its bar glass and two soft edges, plus a letter reveal.
const int kSoakBlurPassCap = 13;

class _LowPower extends MmPlatform {
  @override
  Future<bool> lowPower() async => true;
}

/// Drives one Glass app through every step. [solid]: Reduce Motion or Low Power, where nothing may read the backdrop.
class _Soak {
  _Soak(this.t, this.rig, {this.solid = false});
  final WidgetTester t;
  final GlassQaRig rig;
  final bool solid;
  var peakBlur = 0;
  final peaks = <String, int>{};

  GoRouter get r => rig.shell.router;
  NavigatorState nav() => t.state<NavigatorState>(find.byType(Navigator).first);

  Future<void> idle(String label) async {
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    var rebuilds = 0;
    final who = <String, int>{};
    debugOnRebuildDirtyWidget = (e, __) {
      rebuilds++;
      final k = e.widget.runtimeType.toString();
      who[k] = (who[k] ?? 0) + 1;
    };
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    debugOnRebuildDirtyWidget = null;
    expect(rebuilds, lessThan(60), reason: '$label: $rebuilds rebuilds in 10 idle frames: $who');
  }

  /// Bounded frames until the top route's transition is done and no gesture is open (a frozen one never is).
  Future<void> step(String label, FutureOr<void> Function() go) async {
    await go();
    var frames = 0, stepPeak = 0, backdrop = 0;
    while (frames < 120) {
      await t.pump(const Duration(milliseconds: 16));
      frames++;
      final p = countGpuPasses(t);
      if (p.blur > stepPeak) stepPeak = p.blur;
      if (p.backdrop > backdrop) backdrop = p.backdrop;
      final top = _topRoute(nav());
      if (frames > 4 && (top is! TransitionRoute || top.animation!.isCompleted || top.animation!.isDismissed) && !nav().userGestureInProgress) break;
    }
    peaks[label.substring(2)] = stepPeak;
    if (stepPeak > peakBlur) peakBlur = stepPeak;
    expect(t.takeException(), isNull, reason: label);
    expect(frames, lessThan(120), reason: '$label: the transition never finished');
    expect(nav().userGestureInProgress, isFalse, reason: '$label: a user gesture was left open');
    expect(stepPeak, lessThanOrEqualTo(kSoakBlurPassCap), reason: '$label: $stepPeak blur passes in one frame');
    if (solid) expect(backdrop, 0, reason: '$label: solid glass read the backdrop');
    final reg = rig.shell.container.read(glassRegistryProvider);
    expect(reg.layers, lessThanOrEqualTo(kGlassLayerBudget), reason: label);
    expect(reg.shapes, lessThanOrEqualTo(kGlassShapeBudget), reason: label);
    await idle(label);
  }

  Future<void> drag(Offset from, Offset by, {int steps = 8}) async {
    final g = await t.startGesture(from);
    for (var i = 0; i < steps; i++) {
      await g.moveBy(by / steps.toDouble());
      await t.pump(const Duration(milliseconds: 16));
    }
    await g.up();
  }

  Future<void> pinch() async {
    final a = await t.startGesture(const Offset(150, 420));
    final b = await t.startGesture(const Offset(240, 420));
    for (var i = 0; i < 6; i++) {
      await a.moveBy(const Offset(-10, 0));
      await b.moveBy(const Offset(10, 0));
      await t.pump(const Duration(milliseconds: 16));
    }
    await a.up();
    await b.up();
  }

  /// A full-width swipe (pages) or the 20 px edge strip (readers).
  Future<void> swipeBack({bool edge = false}) => drag(Offset(edge ? 4 : 120, 420), const Offset(300, 0));

  /// A swipe still under the finger when a `go` removes its page.
  Future<void> swipeThenGo(String to) async {
    final g = await t.startGesture(const Offset(120, 420));
    for (var i = 0; i < 4; i++) {
      await g.moveBy(const Offset(30, 0));
      await t.pump(const Duration(milliseconds: 16));
    }
    r.go(to);
    await t.pump();
    await t.pump(const Duration(milliseconds: 16));
    await g.up();
  }

  /// A short swipe released (the page springs back) and a `go` that removes the page while the spring runs.
  Future<void> releaseThenGo(String to) async {
    await drag(const Offset(120, 420), const Offset(60, 0), steps: 3);
    await t.pump(const Duration(milliseconds: 16));
    r.go(to);
    await t.pump();
  }

  Future<void> laps(int n) async {
    for (var lap = 0; lap < n; lap++) {
      await step('$lap home', () => r.go(Routes.tonight()));
      await step('$lap library', () => r.go(Routes.library()));
      await step('$lap library fling', () => drag(const Offset(195, 600), const Offset(0, -400), steps: 4));
      await step('$lap filters sheet open', () => r.go('/library?sheet=filters'));
      final hub = t.state(find.byType(GlassLibraryHub));
      await step('$lap filters sheet drag up', () => drag(const Offset(195, 520), const Offset(0, -300)));
      expect(identical(t.state(find.byType(GlassLibraryHub)), hub), isTrue, reason: '$lap the page behind recedes without being rebuilt');
      await step('$lap filters sheet drag down', () => drag(const Offset(195, 300), const Offset(0, 700)));
      await step('$lap sources', () => r.go(Routes.sources()));
      await step('$lap you', () => r.go(Routes.settings()));
      await step('$lap home again', () => r.go(Routes.tonight()));
      await step('$lap updates page', () => unawaited(r.push<void>(Routes.updates())));
      await step('$lap updates swipe back', swipeBack);
      expect(rig.at, Routes.tonight(), reason: '$lap back home after the swipe');
      await step('$lap updates again', () => unawaited(r.push<void>(Routes.updates())));
      await step('$lap swipe interrupted by go', () => swipeThenGo(Routes.tonight()));
      expect(rig.at, Routes.tonight(), reason: '$lap the go removed the page under the finger');
      await step('$lap updates once more', () => unawaited(r.push<void>(Routes.updates())));
      await step('$lap swipe released, then go', () => releaseThenGo(Routes.tonight()));
      expect(rig.at, Routes.tonight(), reason: '$lap the go removed the page during its spring');
      await step('$lap library after the interrupted swipes', () => r.go(Routes.library()));
      await step('$lap bookmarks pushed over the hub', () => unawaited(r.push<void>(Routes.bookmarks())));
      await step('$lap bookmarks back', r.pop);
      await step('$lap series sheet', () => unawaited(r.push<void>(Routes.feature('demo', 'k'), extra: const GlassNavExtra())));
      await step('$lap series sheet drag', () => drag(const Offset(195, 500), const Offset(0, -250)));
      await step('$lap series sheet close', r.pop);
      await step('$lap reader', () => unawaited(r.push<void>(Routes.reader('shelf', 'series-1', 'ch-1'))));
      await step('$lap reader pinch', pinch);
      await step('$lap reader back', lap.isEven ? () => swipeBack(edge: true) : r.pop);
      expect(rig.at, Routes.library(), reason: '$lap back on the library from the reader');
      await step('$lap read all', () => unawaited(r.push<void>(Routes.readAll('shelf', 'series-1'))));
      await step('$lap read all pinch', pinch);
      await step('$lap read all back', lap.isEven ? r.pop : () => swipeBack(edge: true));
      expect(rig.at, Routes.library(), reason: '$lap back on the library from read-all');
    }
  }
}

void main() {
  glassQaWidgets('Glass soak: tabs, sheets, readers, back swipes; no stuck gesture, no runaway blur, no rebuild storm', (t) async {
    final rig = await pumpGlassQa(t, GlassQaScreen(ScreenId.tonight, Routes.tonight()), settle: false);
    final s = _Soak(t, rig);
    await s.laps(3);
    print('SOAK peak blur passes per frame: ${s.peakBlur} ${s.peaks}');
    await disposeGlassQa(t, rig);
  }, timeout: const Timeout(Duration(minutes: 6)));

  glassQaWidgets('Reduce Motion: every step works and no frame reads the backdrop', (t) async {
    final rig = await pumpGlassQa(t, GlassQaScreen(ScreenId.tonight, Routes.tonight()), reduced: true);
    expect(rig.shell.container.read(glassA11yProvider).solid, isTrue);
    final s = _Soak(t, rig, solid: true);
    await s.laps(1);
    print('SOAK reduced peak blur passes per frame: ${s.peakBlur} ${s.peaks}');
    await disposeGlassQa(t, rig);
  }, timeout: const Timeout(Duration(minutes: 4)));

  glassQaWidgets('Low Power: every step works, no frame reads the backdrop, the light is pinned', (t) async {
    final rig = await pumpGlassQa(t, GlassQaScreen(ScreenId.tonight, Routes.tonight()), extra: [mmPlatformProvider.overrideWithValue(_LowPower())]);
    expect(rig.shell.container.read(glassA11yProvider).solid, isTrue);
    final s = _Soak(t, rig, solid: true);
    await s.laps(1);
    print('SOAK low power peak blur passes per frame: ${s.peakBlur} ${s.peaks}');
    await disposeGlassQa(t, rig);
  }, timeout: const Timeout(Duration(minutes: 4)));

  glassQaWidgets('a melt that no restart follows is undone: the screen never stays black', (t) async {
    final rig = await pumpGlassQa(t, GlassQaScreen(ScreenId.library, Routes.library()));
    final fx = rig.shell.container.read(glassEffectsProvider);
    unawaited(fx.playMelt());
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(fx.melted, isTrue);
    for (var i = 0; i < 60; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(fx.melted, isFalse);
    expect(find.byType(SkinGlass).hitTestable(), findsWidgets, reason: 'the glass came back');
    await disposeGlassQa(t, rig);
  });

  testWidgets('listen mode: the full player opens, drags and closes three times; no stuck gesture, the paused player goes idle', (t) async {
    final l = await pumpGlassListen(t, pushed: false, size: const Size(390, 1800));
    await settle(t);
    await l.startNarration();
    final base = l.novel.location;
    NavigatorState nav() => t.state<NavigatorState>(find.byType(Navigator).first);
    for (var lap = 0; lap < 3; lap++) {
      l.novel.router.go('$base?sheet=player');
      await settle(t, ms: 1200);
      expect(l.novel.location, contains('sheet=player'), reason: '$lap open');
      final g = await t.startGesture(const Offset(195, 900));
      for (var i = 0; i < 6; i++) {
        await g.moveBy(const Offset(0, -40));
        await t.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await settle(t, ms: 800);
      expect(countGpuPasses(t).blur, lessThanOrEqualTo(kSoakBlurPassCap), reason: '$lap blur passes');
      l.novel.router.go(base);
      await settle(t, ms: 1200);
      expect(l.novel.location, isNot(contains('sheet=player')), reason: '$lap closed');
      expect(nav().userGestureInProgress, isFalse, reason: '$lap');
      expect(t.takeException(), isNull, reason: '$lap');
    }
    // Paused with the player open: no ticker left running (the speaking orb used to tick at the display rate).
    l.novel.router.go('$base?sheet=player');
    await settle(t, ms: 1200);
    await t.runAsync(() => l.narration.pause());
    await settle(t, ms: 500);
    // Between the ambient field's 14 s drifts nothing may keep ticking (the speaking orb used to, at the display rate).
    var idleAt = -1;
    for (var i = 0; i < 80 && idleAt < 0; i++) {
      await t.pump(const Duration(milliseconds: 100));
      if (!t.binding.hasScheduledFrame) idleAt = i;
    }
    expect(idleAt, isNot(-1), reason: 'a paused player kept scheduling frames for 8 s');
    await disposeGlassNovel(t);
  });

  testWidgets('skin switch round trip: Glass -> Cinematic -> Glass leaves a live Glass with no gesture open', (t) async {
    resetLiquidGlassReadyForTest();
    liquidGlassInitializer = () async {};
    addTearDown(() => GlassMotion.isReduced = () => false);
    SharedPreferences.setMockInitialValues(testPrefsDefaults({kSkinActiveKey: SkinId.glass.name, kSkinReturnKey: '/library'}));
    final prefs = await SharedPreferences.getInstance();
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    const haptics = MethodChannel('gaimon');
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(haptics, (_) async => null);
    addTearDown(() => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(haptics, null));
    final skins = <SkinId>[];
    await t.pumpWidget(AppRestart(builder: () {
      final boot = SkinBoot.read(prefs);
      skins.add(boot.skin);
      return ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          skinIdProvider.overrideWithValue(boot.skin),
          returnRouteProvider.overrideWithValue(boot.returnRoute),
          skinRestartCarriesSessionProvider.overrideWithValue(boot.carrySession),
          ...shellTestOverrides(),
        ],
        child: const SkinApp(),
      );
    }));
    await t.pump(const Duration(milliseconds: 600));
    await t.pump(const Duration(milliseconds: 600));

    Future<(WidgetRef, BuildContext)> handle() async {
      late WidgetRef ref;
      late BuildContext ctx;
      t.state<NavigatorState>(find.byType(Navigator).first).overlay!.insert(OverlayEntry(builder: (_) => Consumer(builder: (c, r, _) {
            ref = r;
            ctx = c;
            return const SizedBox.shrink();
          })));
      await t.pump();
      return (ref, ctx);
    }

    Future<void> until(int builds) async {
      for (var ms = 0; ms < 5000 && skins.length < builds; ms += 50) {
        await t.pump(const Duration(milliseconds: 50));
        await t.runAsync(() async {});
      }
      expect(skins.length, builds, reason: 'restart $builds happened');
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
    }

    var (ref, ctx) = await handle();
    unawaited(runSkinSwitch(ctx, ref, SkinId.cinematic));
    await until(2);
    expect(skins.last, SkinId.cinematic);
    (ref, ctx) = await handle();
    final done = switchSkinFrom(ctx, ref, to: SkinId.glass, outgoing: () async {});
    await t.pump(const Duration(milliseconds: 300));
    await t.runAsync(() => done);
    await until(3);
    expect(skins.last, SkinId.glass);
    expect(find.byType(SkinGlass), findsWidgets, reason: 'Glass is live again');
    expect(t.state<NavigatorState>(find.byType(Navigator).first).userGestureInProgress, isFalse);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 20));
  });
}

Route<dynamic>? _topRoute(NavigatorState nav) {
  Route<dynamic>? top;
  nav.popUntil((route) {
    top = route;
    return true;
  });
  return top;
}
