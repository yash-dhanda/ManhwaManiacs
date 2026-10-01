import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

import 'qa_fixtures.dart';
import 'qa_screens.dart';

/// The owner's 3.5.3 freeze ("stuck mid-animation, never moves again"): drive Tonight -> Library
/// -> Discover -> Series -> Reader -> back, three times, through the real router and app frame on
/// iOS, mixing button pops with edge swipes. Every step must finish its transition inside a
/// bounded number of frames, leave the navigator out of a user gesture, and rebuild nothing once
/// it is idle beyond the screen's own looping motion.
void main() {
  testWidgets('frames keep pumping across the navigation loop; no stuck gesture, no rebuild storm', (t) async {
    final rig = await pumpQaScreen(
      t,
      QaScreen(ScreenId.tonight, Routes.tonight(), more: qaFeatureOverrides),
      settle: false,
    );
    final r = rig.router;
    NavigatorState nav() => t.state<NavigatorState>(find.byType(Navigator).first);

    /// Bounded frames until the top route's transition is done (a frozen one never is).
    Future<void> step(String label, FutureOr<void> Function() go) async {
      await go();
      var frames = 0;
      while (frames < 120) {
        await t.pump(const Duration(milliseconds: 16));
        frames++;
        final top = _topRoute(nav());
        if (frames > 4 && (top is! TransitionRoute || top.animation!.isCompleted) && !nav().userGestureInProgress) break;
      }
      expect(t.takeException(), isNull, reason: label);
      expect(frames, lessThan(120), reason: '$label: the transition never finished');
      expect(nav().userGestureInProgress, isFalse, reason: label);

      // Idle (entrances done): a setState-in-build or provider ping-pong rebuilds the same
      // widgets every frame without end; a looping motion rebuilds one or two.
      for (var i = 0; i < 30; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      var rebuilds = 0;
      debugOnRebuildDirtyWidget = (_, __) => rebuilds++;
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      debugOnRebuildDirtyWidget = null;
      expect(rebuilds, lessThan(60), reason: '$label: $rebuilds rebuilds in 10 idle frames');
    }

    Future<void> edgeSwipeBack() async {
      final g = await t.startGesture(const Offset(4, 400));
      await g.moveBy(const Offset(20, 0));
      await t.pump();
      await g.moveBy(const Offset(300, 0));
      await t.pump();
      await g.up();
    }

    for (var lap = 0; lap < 3; lap++) {
      await step('$lap tonight', () => r.go(Routes.tonight()));
      await step('$lap library', () => r.go(Routes.library()));
      await step('$lap discover', () => r.go(Routes.discover()));
      await step('$lap series', () => unawaited(r.push<void>(Routes.feature('demo', 'k'))));
      await step('$lap reader', () => unawaited(r.push<void>(Routes.reader('shelf', 'series-1', 'ch-1'))));
      await step('$lap reader back', lap.isEven ? edgeSwipeBack : r.pop);
      expect(rig.at, startsWith('/sources/demo/series/'), reason: '$lap back on the series');
      await step('$lap series back', lap.isEven ? r.pop : edgeSwipeBack);
      expect(rig.at, Routes.discover(), reason: '$lap back on Discover');
    }
    await disposeQa(t, rig);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS),);
}

Route<dynamic>? _topRoute(NavigatorState nav) {
  Route<dynamic>? top;
  nav.popUntil((route) {
    top = route;
    return true;
  });
  return top;
}
