import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/home/utils/at_risk.dart' show computeAtRisk;

/// "Good morning, {name}" by local hour (glass 8.8): 05 to 12 morning, 12 to 17 afternoon, 17 to 22 evening, else night.
String greetingFor(DateTime now, String name) {
  final h = now.hour;
  final part = h >= 5 && h < 12
      ? 'morning'
      : h >= 12 && h < 17
          ? 'afternoon'
          : h >= 17 && h < 22
              ? 'evening'
              : 'night';
  return 'Good $part, $name';
}

/// The subline under the greeting: "{n} new chapters" and the streak chip, joined by " · ", each omitted at zero; at risk it is one line.
class GreetingSubline {
  const GreetingSubline({this.newChapters, this.streakDays = 0, this.atRisk = false, this.riskLine});

  final String? newChapters;

  /// 0 hides the chip.
  final int streakDays;
  final bool atRisk;
  final String? riskLine;

  String? get streakLabel => streakDays > 0 ? '$streakDays-day streak' : null;

  bool get isEmpty => riskLine == null && newChapters == null && streakDays <= 0;

  /// The whole subline as one string (semantics, tests).
  String get text => riskLine ?? [if (newChapters != null) newChapters!, if (streakLabel != null) streakLabel!].join(' · ');
}

GreetingSubline greetingSubline({required int unread, required HomeStreak streak, required DateTime now, bool readToday = false}) {
  // [readToday]: this device already counted reading today, which the feed's lastActiveDate may not show yet.
  final atRisk = !readToday && computeAtRisk(streak, now);
  if (atRisk) return GreetingSubline(atRisk: true, streakDays: streak.currentDays, riskLine: 'Read one chapter to keep your ${streak.currentDays}-day streak');
  return GreetingSubline(
    newChapters: unread > 0 ? (unread == 1 ? '1 new chapter' : '$unread new chapters') : null,
    streakDays: streak.currentDays,
  );
}
