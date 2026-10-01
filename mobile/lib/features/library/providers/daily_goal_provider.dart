import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/providers/numbers_providers.dart';
import 'package:manhwamaniacs/features/library/utils/daily_goal.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';

export 'package:manhwamaniacs/features/library/utils/daily_goal.dart';

/// The active profile's `daily_goal_minutes` (null: no goal). Reads the active profile rather than watching it (see
/// `numbersScopeProvider`), so the profile switch invalidates it through `profileScopedInvalidators`.
final activeDailyGoalMinutesProvider = Provider.autoDispose<int?>((ref) {
  final id = ref.read(activeProfileProvider)?.id;
  final list = ref.watch(profilesProvider).valueOrNull;
  if (id == null || list == null) return null;
  return list.where((p) => p.id == id).firstOrNull?.dailyGoalMinutes;
}, name: 'activeDailyGoalMinutes',);

/// The goal ring's data (glass 8.24, 9.2.2): the goal and today's seconds from `GET /library/statistics?days=1`, refetched on
/// resume. `mobile/42` adds the live updates from `POST /reader/progress`.
final dailyGoalProvider = Provider.autoDispose<AsyncValue<DailyGoal>>((ref) {
  final listener = AppLifecycleListener(onResume: () => ref.invalidate(numbersStatisticsProvider(1)));
  ref.onDispose(listener.dispose);
  final goal = ref.watch(activeDailyGoalMinutesProvider);
  return ref.watch(numbersStatisticsProvider(1)).whenData((load) {
    final daily = load.data.daily;
    return DailyGoal(goalMinutes: goal, todaySeconds: daily.isEmpty ? 0 : daily.last.secondsRead);
  });
}, name: 'dailyGoal',);
