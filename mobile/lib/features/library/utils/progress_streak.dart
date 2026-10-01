import 'dart:convert';

import 'package:manhwamaniacs/features/reader/models/reading_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What a progress answer tells the app (mobile/42). The app never computes a streak: it reacts to these.
sealed class StreakEvent {
  const StreakEvent();
}

/// The server's `extended_today` went false to true: today's first chapter just counted.
class StreakFlare extends StreakEvent {
  const StreakFlare(this.currentDays);
  final int currentDays;
}

/// Today's reading seconds, from every answer that carries them.
class StreakToday extends StreakEvent {
  const StreakToday(this.seconds);
  final int seconds;
}

/// Today's seconds crossed the daily goal (once per local day).
class GoalMet extends StreakEvent {
  const GoalMet();
}

/// The per-profile record of the local day this device last heard about.
class StreakDay {
  const StreakDay({required this.day, required this.extended, required this.todaySeconds, required this.goalMet});
  final String day;
  final bool extended;
  final int todaySeconds;
  final bool goalMet;

  Map<String, Object?> toJson() => {'day': day, 'extended': extended, 'todaySeconds': todaySeconds, 'goalMet': goalMet};

  static StreakDay? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final day = raw['day'];
    if (day is! String) return null;
    return StreakDay(
      day: day,
      extended: raw['extended'] == true,
      todaySeconds: (raw['todaySeconds'] as num?)?.toInt() ?? 0,
      goalMet: raw['goalMet'] == true,
    );
  }
}

abstract interface class StreakDayStore {
  StreakDay? read(int profileId);
  void write(int profileId, StreakDay day);
}

/// `mm.streak.progress.u{user}p{profile}` in SharedPreferences.
class PrefsStreakDayStore implements StreakDayStore {
  const PrefsStreakDayStore(this._prefs, {required this.userId});
  final SharedPreferences _prefs;
  final int userId;

  String _key(int profileId) => 'mm.streak.progress.u${userId}p$profileId';

  @override
  StreakDay? read(int profileId) {
    final raw = _prefs.getString(_key(profileId));
    if (raw == null || raw.isEmpty) return null;
    try {
      return StreakDay.tryParse(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  @override
  void write(int profileId, StreakDay day) => _prefs.setString(_key(profileId), jsonEncode(day.toJson()));
}

String _ymd(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Keeps the per-profile, per-day record and returns the events one progress answer causes.
///
/// A flare needs a stored `false` for today and a new `true`: with nothing stored for today the value is stored and nothing
/// flares, so a second device that sees `true` first stays quiet. The goal fires once per day, only as a crossing.
List<StreakEvent> noteProgressResponse({
  required int profileId,
  required ProgressAnswer answer,
  required DateTime nowLocal,
  required int? goalMinutes,
  required StreakDayStore store,
}) {
  final today = _ymd(nowLocal);
  final stored = store.read(profileId);
  final same = stored != null && stored.day == today;
  final events = <StreakEvent>[];
  var extended = same ? stored.extended : false;
  var goalMet = same ? stored.goalMet : false;
  var seconds = same ? stored.todaySeconds : 0;

  final streak = answer.streak;
  if (streak != null) {
    if (same && !stored.extended && streak.extendedToday) events.add(StreakFlare(streak.currentDays));
    extended = streak.extendedToday || (same && stored.extended);
  }
  final secs = answer.todaySeconds;
  if (secs != null) {
    seconds = secs;
    events.add(StreakToday(secs));
    if (goalMinutes != null && goalMinutes > 0 && same && !goalMet && secs >= goalMinutes * 60) {
      goalMet = true;
      events.add(const GoalMet());
    }
  }
  store.write(profileId, StreakDay(day: today, extended: extended, todaySeconds: seconds, goalMet: goalMet));
  return events;
}
