/// The daily-goal choices of glass 9.2.1 in minutes; null is Off. `mobile/40` and `mobile/42` reuse it.
const List<int?> kDailyGoalOptions = <int?>[null, 5, 10, 15, 20, 30, 45, 60];

String dailyGoalLabel(int? minutes) => minutes == null ? 'Off' : '$minutes min';
