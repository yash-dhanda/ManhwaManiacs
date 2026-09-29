import 'package:manhwamaniacs/features/library/models/library_statistics.dart';

// TODO(mobile/08): mobile/08 owns `utils/streak.dart` (`HomeStreak`, `streakTier`,
// `streakState`, `justExtended`). This is the smallest local stand-in with the
// same names; delete it when that step is integrated and point the imports there.

enum StreakTier { ember, one, three, ring, sparks }

enum StreakState { readToday, notYetToday, atRisk, broken }

class HomeStreak {
  const HomeStreak({
    required this.currentDays,
    required this.longestDays,
    this.atRisk = false,
    this.lastActiveDate,
    this.milestonesSeen = const [],
  });

  final int currentDays;
  final int longestDays;
  final bool atRisk;
  final DateTime? lastActiveDate;
  final List<int> milestonesSeen;

  factory HomeStreak.fromReadingStreak(ReadingStreak s) => HomeStreak(
        currentDays: s.currentDays,
        longestDays: s.longestDays,
        atRisk: s.atRisk,
        lastActiveDate: s.lastActiveDate,
        milestonesSeen: s.milestonesSeen,
      );
}

/// 0 ember, 1-6 flame-1, 7-29 flame-3, 30-99 ring, 100+ sparks.
StreakTier streakTier(int days) => days <= 0
    ? StreakTier.ember
    : days < 7
        ? StreakTier.one
        : days < 30
            ? StreakTier.three
            : days < 100
                ? StreakTier.ring
                : StreakTier.sparks;

/// Local calendar day.
DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

/// [now] is local. `broken`: a streak of zero, or a last day before yesterday.
/// `atRisk`: the server's flag, or 20:00 or later without reading today.
StreakState streakState(HomeStreak s, DateTime now) {
  if (s.currentDays <= 0) return StreakState.broken;
  final last = s.lastActiveDate == null ? null : _day(s.lastActiveDate!);
  final today = _day(now);
  if (last != null && last == today) return StreakState.readToday;
  if (last != null && today.difference(last).inDays > 1) return StreakState.broken;
  if (s.atRisk || now.hour >= 20) return StreakState.atRisk;
  return StreakState.notYetToday;
}

/// True the first time this visit sees `lastActiveDate` flip to today. [seen] is
/// the per-profile `mm.streak.seen.` value (an ISO date); the caller stores
/// [todayKey] afterwards so it plays once.
bool justExtended(HomeStreak s, DateTime now, String? seen) {
  if (s.currentDays <= 0 || s.lastActiveDate == null) return false;
  if (_day(s.lastActiveDate!) != _day(now)) return false;
  return seen != todayKey(now);
}

String todayKey(DateTime now) =>
    '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
