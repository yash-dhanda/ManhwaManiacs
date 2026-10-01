import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/library/providers/daily_goal_provider.dart';
import 'package:manhwamaniacs/features/library/providers/streak_events_provider.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/models/profile_extras.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/reader/models/reading_progress.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/primitives/goal_ring.dart';

import 'stats_rig.dart';

/// One profile (id 1, the seeded active one) with a 10-minute goal; `edit` is recorded (daily_goal_test proves it is one PATCH).
class _GoalProfiles extends ProfilesNotifier {
  static final edits = <(int, int?)>[];
  int? goal = 10;
  @override
  Future<List<Profile>> build() async =>
      [Profile(id: 1, name: 'Tester', avatarKey: 'violet', mood: Mood.neutral, sortOrder: 0, matureContentEnabled: false, createdAt: DateTime.utc(2024), dailyGoalMinutes: goal)];

  @override
  Future<AppError?> edit(int profileId, {String? name, String? avatarKey, Mood? mood, bool? matureContentEnabled, String? skin, int? sortOrder, bool? notifyEnabled, ProfileExtras? extras}) async {
    final g = extras?.dailyGoal;
    if (g != null) {
      edits.add((profileId, g.minutes));
      goal = g.minutes;
      ref.invalidateSelf();
    }
    return null;
  }
}

/// The shell rig has no profiles (a picker would open with some), so the 10-minute goal is set on the notifier itself; the progress
/// answers still flow through it.
class _TenMinutes extends DailyGoalNotifier {
  @override
  DailyGoalState build() => super.build().copyWith(goalMinutes: 10);
}

ProgressAnswer _secs(int s, {bool ext = true}) => ProgressAnswer(streak: StreakSnapshot(currentDays: 12, extendedToday: ext), todaySeconds: s);

void main() {
  for (final (name, size) in [('phone', const Size(390, 844)), ('tablet', const Size(1180, 820))]) {
    testWidgets('$name: crossing the goal closes every ring once, with one goal.met', (t) async {
      final rig = await pumpStats(t, FakeNumbers(), size: size, start: '/', extra: [dailyGoalProvider.overrideWith(_TenMinutes.new)]);
      await t.pump(const Duration(milliseconds: 300));
      final rings = find.byType(GlassGoalRing);
      expect(rings, findsWidgets, reason: 'the orbs wear the ring');
      List<int> minutes() => [for (final r in t.widgetList<GlassGoalRing>(rings)) r.minutes];
      expect(t.widgetList<GlassGoalRing>(rings).every((r) => r.goal == 10), isTrue);
      GlassHaptics.debugLog.clear();
      final handle = rig.container.read(progressAnswerHandlerProvider);
      handle(_secs(480, ext: false));
      await t.pump(const Duration(milliseconds: 300));
      expect(minutes(), everyElement(8));
      handle(_secs(610));
      await t.pump(const Duration(milliseconds: 100));
      await t.pump(const Duration(milliseconds: 700));
      expect(minutes(), everyElement(10), reason: 'every ring closed: nav-row orb, dock tab or sidebar capsule');
      expect(GlassHaptics.debugLog.where((e) => e.event == HapticEvent.goalMet), hasLength(1));
      handle(_secs(700));
      await t.pump(const Duration(milliseconds: 300));
      expect(GlassHaptics.debugLog.where((e) => e.event == HapticEvent.goalMet), hasLength(1), reason: 'once per day');
      await t.pump(const Duration(minutes: 11));
    });
  }

  testWidgets('the goal menu (shift+g) sets 10 minutes and the hero shows the ring line', (t) async {
    _GoalProfiles.edits.clear();
    final rig = await pumpStats(t, FakeNumbers(), extra: [profilesProvider.overrideWith(_GoalProfiles.new)]);
    await rig.container.read(profilesProvider.future);
    await t.pump(const Duration(milliseconds: 300));
    await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.keyG);
    await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('15 min'), findsWidgets, reason: 'the goal menu is open');
    await t.tap(find.text('15 min').last);
    await t.pump(const Duration(milliseconds: 600));
    expect(_GoalProfiles.edits, [(1, 15)]);
    expect(find.textContaining('of 15 min today'), findsOneWidget);
    await t.pump(const Duration(minutes: 11));
  });
}
