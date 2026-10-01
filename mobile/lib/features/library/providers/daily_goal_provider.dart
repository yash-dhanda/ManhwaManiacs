import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/library/providers/streak_events_provider.dart';
import 'package:manhwamaniacs/features/library/utils/progress_streak.dart';
import 'package:manhwamaniacs/features/profiles/models/profile_extras.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';

export 'package:manhwamaniacs/features/profiles/utils/daily_goal_options.dart' show kDailyGoalOptions, dailyGoalLabel;

class DailyGoalState {
  const DailyGoalState({this.goalMinutes, this.todaySeconds = 0});
  final int? goalMinutes;
  final int todaySeconds;

  int get minutes => todaySeconds ~/ 60;
  bool get met => goalMinutes != null && todaySeconds >= goalMinutes! * 60;

  DailyGoalState copyWith({Object? goalMinutes = _keep, int? todaySeconds}) =>
      DailyGoalState(goalMinutes: identical(goalMinutes, _keep) ? this.goalMinutes : goalMinutes as int?, todaySeconds: todaySeconds ?? this.todaySeconds);
}

const Object _keep = Object();

/// The active profile's daily goal and today's reading seconds: the goal from the profile, the seconds from the server's progress
/// answers (`StreakToday`), kept per local day. Null goal is Off.
class DailyGoalNotifier extends Notifier<DailyGoalState> {
  StreamSubscription<StreakEvent>? _sub;

  @override
  DailyGoalState build() {
    final profile = ref.watch(activeProfileProvider);
    // Rebuilds only when this profile's goal changes, not on every profiles refresh.
    final goal = ref.watch(profilesProvider.select((v) => v.valueOrNull?.where((p) => p.id == profile?.id).firstOrNull?.dailyGoalMinutes));
    var seconds = 0;
    if (profile != null) {
      final day = ref.read(streakDayStoreProvider).read(profile.id);
      final n = DateTime.now();
      final today = '${n.year.toString().padLeft(4, '0')}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
      if (day != null && day.day == today) seconds = day.todaySeconds;
    }
    _sub?.cancel();
    _sub = ref.read(streakEventsProvider).stream.listen((e) {
      if (e is StreakToday) state = state.copyWith(todaySeconds: e.seconds);
    });
    ref.onDispose(() => _sub?.cancel());
    return DailyGoalState(goalMinutes: goal, todaySeconds: seconds);
  }

  /// Raises today's seconds to at least [seconds] (the statistics payload knows today's total on a cold start).
  void seedToday(int seconds) {
    if (seconds > state.todaySeconds) state = state.copyWith(todaySeconds: seconds);
  }

  /// `PATCH /profiles/{id} {daily_goal_minutes}`, optimistic. Returns the error when it failed, after rolling back: the caller
  /// shows "Couldn't change this setting".
  Future<AppError?> setDailyGoal(int? minutes) async {
    final profile = ref.read(activeProfileProvider);
    if (profile == null) return null;
    final before = state;
    state = state.copyWith(goalMinutes: minutes);
    final error = await ref.read(profilesProvider.notifier).edit(profile.id, extras: ProfileExtras(dailyGoal: (minutes: minutes)));
    if (error != null) state = state.copyWith(goalMinutes: before.goalMinutes);
    return error;
  }
}

final dailyGoalProvider = NotifierProvider<DailyGoalNotifier, DailyGoalState>(DailyGoalNotifier.new, name: 'dailyGoal');
