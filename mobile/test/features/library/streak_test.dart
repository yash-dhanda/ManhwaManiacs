// ignore_for_file: require_trailing_commas, avoid_redundant_argument_values, library_private_types_in_public_api, directives_ordering
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/library/utils/streak.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_overrides.dart';

HomeStreak s(int days, {DateTime? last}) => HomeStreak(currentDays: days, longestDays: days, lastActiveDate: last);

void main() {
  test('tiers by days', () {
    expect([0, 1, 6, 7, 29, 30, 99, 100, 400].map(streakTier), [
      StreakTier.none, StreakTier.one, StreakTier.one, StreakTier.three, StreakTier.three, //
      StreakTier.ring, StreakTier.ring, StreakTier.sparks, StreakTier.sparks,
    ]);
  });

  test('state by the clock: read today, alive, at risk after 20:00, none', () {
    final today = DateTime(2026, 9, 30), yesterday = DateTime(2026, 9, 29);
    expect(streakState(s(12, last: today), DateTime(2026, 9, 30, 23)), StreakLiveState.aliveToday);
    expect(streakState(s(12, last: yesterday), DateTime(2026, 9, 30, 19, 59)), StreakLiveState.aliveNotToday);
    expect(streakState(s(12, last: yesterday), DateTime(2026, 9, 30, 20)), StreakLiveState.atRisk);
    expect(streakState(s(1, last: yesterday), DateTime(2026, 9, 30, 21)), StreakLiveState.aliveNotToday, reason: 'a 1-day streak is never at risk');
    expect(streakState(s(0), DateTime(2026, 9, 30, 21)), StreakLiveState.none);
  });

  test('justExtended is true once when the date flips to today', () async {
    SharedPreferences.setMockInitialValues({'mm.streak.seen.u1p1': '2026-09-29'});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [sharedPrefsProvider.overrideWithValue(prefs), authenticatedAuthOverride(), activeProfileOverride()]);
    addTearDown(c.dispose);
    final read = Provider<bool Function(HomeStreak, DateTime)>((ref) => (st, now) => justExtended(ref, st, now));
    final f = c.read(read);
    final now = DateTime(2026, 9, 30, 18);
    expect(f(s(13, last: DateTime(2026, 9, 30)), now), isTrue);
    expect(f(s(13, last: DateTime(2026, 9, 30)), now), isFalse, reason: 'once');
    expect(prefs.getString('mm.streak.seen.u1p1'), '2026-09-30');
    expect(f(s(12, last: DateTime(2026, 9, 29)), now), isFalse, reason: 'not today');
  });
}
