import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/platform/gravity.dart';
import 'package:manhwamaniacs/features/library/providers/streak_events_provider.dart';
import 'package:manhwamaniacs/features/reader/models/reading_progress.dart';
import 'package:manhwamaniacs/skins/glass/glass/light_angle.dart';
import 'package:manhwamaniacs/skins/glass/parts/streak/streak_ui.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/streak_flame.dart';

import 'stats_rig.dart';

Future<void> _frames(WidgetTester t, [int n = 3]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('the hero flame holds the one gravity subscription only while visible and while the light follows the device', (t) async {
    // The tilt light is the other gravity consumer on every Glass surface: pinned here so the flame's own subscription is what counts.
    final rig = await pumpStats(t, FakeNumbers(), extra: [glassLightAngleProvider.overrideWith((ref) => Stream.value(kLightAngleRest))]);
    final g = rig.container.read(gravityProvider);
    expect(g.sensorSubscriptions, 1, reason: 'the hero flame is on screen');
    final scroll = find.ancestor(of: find.byType(StreakFlame).first, matching: find.byType(Scrollable)).first;
    await t.drag(scroll, const Offset(0, -1600));
    await _frames(t, 6);
    expect(g.sensorSubscriptions, 0, reason: 'the hero scrolled away');
    await t.drag(scroll, const Offset(0, 1600));
    await _frames(t, 6);
    expect(g.sensorSubscriptions, 1);
    rig.container.read(glassInAppPrefsProvider.notifier).setLightFollowsDevice(false);
    await _frames(t);
    expect(g.sensorSubscriptions, 0, reason: '"Light follows the device" off');
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('reduced motion: no flare or embers, the toast and the count still arrive', (t) async {
    t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final repo = FakeNumbers();
    final rig = await pumpStats(t, repo);
    StreakFlame.debugEmbers = 0;
    final handle = rig.container.read(progressAnswerHandlerProvider);
    handle(const ProgressAnswer(streak: StreakSnapshot(currentDays: 12, extendedToday: false), todaySeconds: 60));
    handle(const ProgressAnswer(streak: StreakSnapshot(currentDays: 13, extendedToday: true), todaySeconds: 120));
    await _frames(t, 6);
    expect(rig.container.read(streakUiProvider).flare, 1);
    expect(StreakFlame.debugEmbers, 0, reason: 'a static flame');
    expect(find.text('13-day streak'), findsOneWidget);
    expect(rig.container.read(gravityProvider).sensorSubscriptions, 0, reason: 'frozen: no lean');
    await t.pump(const Duration(minutes: 11));
  });
}
