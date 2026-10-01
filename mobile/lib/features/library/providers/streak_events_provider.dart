import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/library/providers/daily_goal_provider.dart';
import 'package:manhwamaniacs/features/library/utils/progress_streak.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/reader/models/reading_progress.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

/// The app's one stream of streak events (mobile/42): a broadcast controller owned by the provider and closed on dispose.
final streakEventsProvider = Provider<StreamController<StreakEvent>>((ref) {
  // ignore: close_sinks
  final c = StreamController<StreakEvent>.broadcast();
  ref.onDispose(c.close);
  return c;
}, name: 'streakEvents',);

final streakDayStoreProvider = Provider<StreakDayStore>((ref) {
  final auth = ref.read(authControllerProvider);
  return PrefsStreakDayStore(ref.watch(sharedPrefsProvider), userId: auth is AuthAuthenticated ? auth.user.id : 0);
}, name: 'streakDayStore',);

/// What the progress repository calls with each server answer: records the day, then emits the events it causes.
final progressAnswerHandlerProvider = Provider<void Function(ProgressAnswer answer)>((ref) {
  return (answer) {
    final profile = ref.read(activeProfileProvider);
    if (profile == null) return;
    final events = noteProgressResponse(
      profileId: profile.id,
      answer: answer,
      nowLocal: DateTime.now(),
      goalMinutes: ref.read(dailyGoalProvider).goalMinutes,
      store: ref.read(streakDayStoreProvider),
    );
    // ignore: close_sinks
    final c = ref.read(streakEventsProvider);
    for (final e in events) {
      if (!c.isClosed) c.add(e);
    }
  };
}, name: 'progressAnswerHandler',);
