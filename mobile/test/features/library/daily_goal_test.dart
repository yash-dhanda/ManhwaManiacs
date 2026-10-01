import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/library/providers/daily_goal_provider.dart';
import 'package:manhwamaniacs/features/library/providers/streak_events_provider.dart';
import 'package:manhwamaniacs/features/library/utils/progress_streak.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/profiles/repositories/profiles_repository.dart';
import 'package:manhwamaniacs/features/reader/models/reading_progress.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_overrides.dart';

class _Repo implements ProfilesRepository {
  int? goal;
  @override
  Future<Result<List<Profile>>> list() async => Ok([
        Profile(id: 1, name: 'Tester', avatarKey: 'violet', mood: Mood.neutral, sortOrder: 0, matureContentEnabled: false, createdAt: DateTime.utc(2024), dailyGoalMinutes: goal),
      ]);
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.repo, {this.fail = false});
  final _Repo repo;
  final bool fail;
  final calls = <({String method, String path, Object? body})>[];
  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<List<int>>? s, Future<void>? c) async {
    calls.add((method: o.method, path: o.path, body: o.data));
    final h = {Headers.contentTypeHeader: ['application/json']};
    if (fail) return ResponseBody.fromString('{"error":{"code":"boom","message":"no"}}', 500, headers: h);
    final goal = (o.data as Map)['daily_goal_minutes'] as int?;
    repo.goal = goal;
    return ResponseBody.fromString(
        '{"id":1,"name":"Tester","avatar_key":"violet","mood":"default","sort_order":0,"mature_content_enabled":false,"created_at":"2024-01-01T00:00:00Z","daily_goal_minutes":${goal ?? 'null'}}',
        200,
        headers: h,);
  }

  @override
  void close({bool force = false}) {}
}

class _Mem implements StreakDayStore {
  final m = <int, StreakDay>{};
  @override
  StreakDay? read(int p) => m[p];
  @override
  void write(int p, StreakDay d) => m[p] = d;
}

Future<(ProviderContainer, _Adapter)> _rig({bool fail = false}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final repo = _Repo();
  final a = _Adapter(repo, fail: fail);
  final c = ProviderContainer(overrides: [
    sharedPrefsProvider.overrideWithValue(prefs),
    profilesRepositoryProvider.overrideWithValue(repo),
    dioProvider.overrideWithValue(Dio(BaseOptions(baseUrl: 'http://x'))..httpClientAdapter = a),
    activeProfileOverride(),
    streakDayStoreProvider.overrideWithValue(_Mem()),
  ],);
  addTearDown(c.dispose);
  await c.read(profilesProvider.future);
  c.listen(dailyGoalProvider, (_, __) {});
  return (c, a);
}

void main() {
  test('the goal options', () => expect(kDailyGoalOptions, <int?>[null, 5, 10, 15, 20, 30, 45, 60]));

  test('setDailyGoal sends one PATCH and applies at once', () async {
    final (c, a) = await _rig();
    expect(c.read(dailyGoalProvider).goalMinutes, isNull);
    final f = c.read(dailyGoalProvider.notifier).setDailyGoal(10);
    expect(c.read(dailyGoalProvider).goalMinutes, 10, reason: 'optimistic');
    expect(await f, isNull);
    expect(a.calls.single.method, 'PATCH');
    expect(a.calls.single.path, '/profiles/1');
    expect(a.calls.single.body, {'daily_goal_minutes': 10});
    expect(c.read(dailyGoalProvider).goalMinutes, 10);
  });

  test('a failed PATCH rolls the goal back and returns the error', () async {
    final (c, _) = await _rig(fail: true);
    final f = c.read(dailyGoalProvider.notifier).setDailyGoal(30);
    expect(c.read(dailyGoalProvider).goalMinutes, 30);
    expect(await f, isNotNull);
    expect(c.read(dailyGoalProvider).goalMinutes, isNull);
  });

  test('the progress answers drive today and the goal crossing', () async {
    final (c, _) = await _rig();
    await c.read(dailyGoalProvider.notifier).setDailyGoal(10);
    final events = <StreakEvent>[];
    final sub = c.read(streakEventsProvider).stream.listen(events.add);
    addTearDown(sub.cancel);
    final handle = c.read(progressAnswerHandlerProvider);
    handle(const ProgressAnswer(streak: StreakSnapshot(currentDays: 12, extendedToday: false), todaySeconds: 480));
    await Future<void>.delayed(Duration.zero);
    expect(c.read(dailyGoalProvider).minutes, 8);
    expect(c.read(dailyGoalProvider).met, isFalse);
    handle(const ProgressAnswer(streak: StreakSnapshot(currentDays: 13, extendedToday: true), todaySeconds: 610));
    handle(const ProgressAnswer(streak: StreakSnapshot(currentDays: 13, extendedToday: true), todaySeconds: 700));
    await Future<void>.delayed(Duration.zero);
    expect(c.read(dailyGoalProvider).met, isTrue);
    expect(events.whereType<GoalMet>(), hasLength(1));
    expect(events.whereType<StreakFlare>(), hasLength(1));
    expect(events.whereType<StreakFlare>().single.currentDays, 13);
  });
}
