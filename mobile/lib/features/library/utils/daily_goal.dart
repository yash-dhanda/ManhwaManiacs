/// Today's reading against the profile's daily goal (glass 9.2.2): a fraction clamped to 0..1, 0 without a goal.
double goalProgress(int todaySeconds, int? goalMinutes) {
  if (goalMinutes == null || goalMinutes <= 0) return 0;
  return (todaySeconds / (goalMinutes * 60)).clamp(0.0, 1.0);
}

/// The daily goal and today's reading time.
class DailyGoal {
  const DailyGoal({required this.goalMinutes, required this.todaySeconds});
  final int? goalMinutes;
  final int todaySeconds;

  bool get met => goalMinutes != null && todaySeconds >= goalMinutes! * 60;
  double get progress => goalProgress(todaySeconds, goalMinutes);
  int get todayMinutes => todaySeconds ~/ 60;
}
