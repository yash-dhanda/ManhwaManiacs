import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/storage/profile_scoped_key.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/home/utils/front_page.dart' show localDateString;
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

/// The streak flame's tiers (cinematic 9.2.2).
enum StreakTier { none, one, three, ring, sparks }

StreakTier streakTier(int days) => switch (days) {
      <= 0 => StreakTier.none,
      < 7 => StreakTier.one,
      < 30 => StreakTier.three,
      < 100 => StreakTier.ring,
      _ => StreakTier.sparks,
    };

enum StreakLiveState { aliveToday, aliveNotToday, atRisk, none }

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// "Read today" means `lastActiveDate == local today`. At risk: after 20:00, not read today, at
/// least 2 days.
StreakLiveState streakState(HomeStreak s, DateTime now) {
  if (s.currentDays <= 0) return StreakLiveState.none;
  final last = s.lastActiveDate;
  if (last != null && _day(last) == _day(now)) return StreakLiveState.aliveToday;
  if (now.hour >= 20 && s.currentDays >= 2) return StreakLiveState.atRisk;
  return StreakLiveState.aliveNotToday;
}

const _prefix = 'mm.streak.seen.';

/// True once when the last-active date this device saw flips to today (Ignite). Reads and writes
/// `mm.streak.seen.u{user}p{profile}`.
bool justExtended(Ref ref, HomeStreak s, DateTime now) {
  final last = s.lastActiveDate;
  if (last == null) return false;
  final prefs = ref.read(sharedPrefsProvider);
  final key = profileScopedKey(ref, prefix: _prefix, deviceKey: '${_prefix}device', watch: false);
  final seen = prefs.getString(key);
  final lastStr = localDateString(last);
  if (seen != lastStr) prefs.setString(key, lastStr);
  return seen != lastStr && _day(last) == _day(now);
}
