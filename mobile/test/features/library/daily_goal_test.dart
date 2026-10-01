import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/features/library/providers/daily_goal_provider.dart';
import 'package:manhwamaniacs/features/library/providers/numbers_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('goal progress: no goal, half, exactly met, over', () {
    expect(goalProgress(600, null), 0);
    expect(goalProgress(600, 20), 0.5);
    expect(goalProgress(1200, 20), 1);
    expect(goalProgress(5000, 20), 1);
    expect(const DailyGoal(goalMinutes: 20, todaySeconds: 1200).met, isTrue);
    expect(const DailyGoal(goalMinutes: 20, todaySeconds: 1199).met, isFalse);
    expect(const DailyGoal(goalMinutes: null, todaySeconds: 9999).met, isFalse);
  });

  test('provider reads today from the 1-day statistics and the profile goal', () async {
    final stats = LibraryStatistics.fromJson({
      'daily': [
        {'date': '2026-10-01', 'seconds_read': 900, 'chapters_read': 2},
      ],
    });
    final c = ProviderContainer(overrides: [
      activeDailyGoalMinutesProvider.overrideWith((ref) => 30),
      numbersStatisticsProvider(1).overrideWith((ref) async => NumbersLoad(stats)),
    ],);
    addTearDown(c.dispose);
    final sub = c.listen(dailyGoalProvider, (_, __) {});
    await c.read(numbersStatisticsProvider(1).future);
    final g = sub.read().value!;
    expect(g.todaySeconds, 900);
    expect(g.goalMinutes, 30);
    expect(g.progress, 0.5);
    expect(g.met, isFalse);
  });

  test('empty daily reads as zero', () async {
    final c = ProviderContainer(overrides: [
      activeDailyGoalMinutesProvider.overrideWith((ref) => null),
      numbersStatisticsProvider(1).overrideWith((ref) async => NumbersLoad(LibraryStatistics.fromJson(const {}))),
    ],);
    addTearDown(c.dispose);
    final sub = c.listen(dailyGoalProvider, (_, __) {});
    await c.read(numbersStatisticsProvider(1).future);
    expect(sub.read().value!.todaySeconds, 0);
    expect(sub.read().value!.met, isFalse);
  });
}
