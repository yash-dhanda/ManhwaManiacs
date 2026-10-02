import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/library/providers/numbers_providers.dart';
import 'package:manhwamaniacs/features/library/providers/streak_events_provider.dart';
import 'package:manhwamaniacs/features/library/utils/daily_goal.dart';
import 'package:manhwamaniacs/features/library/utils/progress_streak.dart';
import 'package:manhwamaniacs/features/profiles/models/profile_extras.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';

export 'package:manhwamaniacs/features/library/utils/daily_goal.dart';
export 'package:manhwamaniacs/features/profiles/utils/daily_goal_options.dart' show kDailyGoalOptions, dailyGoalLabel;

/// The active profile's `daily_goal_minutes` (null: no goal). Reads the active profile rather than watching it (see
/// `numbersScopeProvider`), so the profile switch invalidates it through `profileScopedInvalidators`.
final activeDailyGoalMinutesProvider = Provider<int?>((ref) {
  final id = ref.read(activeProfileProvider)?.id;
  if (id == null) return null;
  return ref.watch(profilesProvider.select((v) => v.valueOrNull?.where((p) => p.id == id).firstOrNull?.dailyGoalMinutes));
}, name: 'activeDailyGoalMinutes',);

/// Today's seconds from `GET /library/statistics?days=1` (glass 8.24, 9.2.2), refetched on resume: the goal ring's cold-start
/// value before any `POST /reader/progress` answer arrives. Null while loading.
final statsTodaySecondsProvider = Provider.autoDispose<int?>((ref) {
  final listener = AppLifecycleListener(onResume: () => ref.invalidate(numbersStatisticsProvider(1)));
  ref.onDispose(listener.dispose);
  final daily = ref.watch(numbersStatisticsProvider(1)).valueOrNull?.data.daily;
  if (daily == null) return null;
  return daily.isEmpty ? 0 : daily.last.secondsRead;
}, name: 'statsTodaySeconds',);

class DailyGoalState extends DailyGoal {
  const DailyGoalState({super.goalMinutes, super.todaySeconds = 0});

  int get minutes => todaySeconds ~/ 60;

  DailyGoalState copyWith({Object? goalMinutes = _keep, int? todaySeconds}) =>
      DailyGoalState(goalMinutes: identical(goalMinutes, _keep) ? this.goalMinutes : goalMinutes as int?, todaySeconds: todaySeconds ?? this.todaySeconds);
}

const Object _keep = Object();

/// The active profile's daily goal and today's reading seconds: the goal from the profile, the seconds from the server's progress
/// answers (`StreakToday`), kept per local day. Null goal is Off. The active profile is read, not watched: the profile switch
/// invalidates this through `profileScopedInvalidators`.
class DailyGoalNotifier extends Notifier<DailyGoalState> {
  StreamSubscription<StreakEvent>? _sub;

  /// The local day [state] counts; a different day on resume or seed starts again from that day's own figure.
  String _day = '';

  static String _today() {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  @override
  DailyGoalState build() {
    final profile = ref.read(activeProfileProvider);
    // Rebuilds only when this profile's goal changes, not on every profiles refresh.
    final goal = ref.watch(activeDailyGoalMinutesProvider);
    var seconds = 0;
    if (profile != null) {
      final day = ref.read(streakDayStoreProvider).read(profile.id);
      if (day != null && day.day == _today()) seconds = day.todaySeconds;
    }
    _day = _today();
    _sub?.cancel();
    _sub = ref.read(streakEventsProvider).stream.listen((e) {
      if (e is StreakToday) {
        _day = _today();
        state = state.copyWith(todaySeconds: e.seconds);
      }
    });
    // Keep-alive: past local midnight yesterday's minutes must not count for today.
    final life = AppLifecycleListener(onResume: () {
      if (_day != _today()) ref.invalidateSelf();
    });
    ref.onDispose(() {
      _sub?.cancel();
      life.dispose();
    });
    return DailyGoalState(goalMinutes: goal, todaySeconds: seconds);
  }

  /// Raises today's seconds to at least [seconds] (the statistics payload knows today's total on a cold start).
  void seedToday(int seconds) {
    if (_day != _today()) {
      _day = _today();
      state = state.copyWith(todaySeconds: seconds);
    } else if (seconds > state.todaySeconds) {
      state = state.copyWith(todaySeconds: seconds);
    }
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
