import 'package:manhwamaniacs/features/library/models/annual.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';

const List<int> kNumbersRanges = [7, 30, 90, 365];

const Map<int, String> kNumbersRangeLabels = {
  7: '7 DAYS',
  30: '30 DAYS',
  90: '90 DAYS',
  365: 'YEAR',
};

/// The day with the most chapters; ties go to the latest date. Null when no
/// day has a chapter.
DailyActivity? bestChapterDay(List<DailyActivity> daily) {
  DailyActivity? best;
  for (final d in daily) {
    if (d.chaptersRead <= 0) continue;
    if (best == null ||
        d.chaptersRead > best.chaptersRead ||
        (d.chaptersRead == best.chaptersRead && d.date.isAfter(best.date))) {
      best = d;
    }
  }
  return best;
}

/// The Annual is out from 1 December (local) or once 30 days are recorded;
/// until then last year's, when there is one, stays on offer.
bool annualAvailable(DateTime nowLocal, Annual? current) =>
    _currentOut(nowLocal, current) ||
    (current?.availableYears.contains(nowLocal.year - 1) ?? false);

bool _currentOut(DateTime nowLocal, Annual? current) =>
    nowLocal.month == 12 || (current?.recordedDays ?? 0) >= 30;

/// The year an Annual entry opens by default: this year once it is out,
/// otherwise last year when it has one.
int annualDefaultYear(DateTime nowLocal, Annual? current) =>
    !_currentOut(nowLocal, current) &&
            (current?.availableYears.contains(nowLocal.year - 1) ?? false)
        ? nowLocal.year - 1
        : nowLocal.year;

/// 1 + the number of available years below [year].
int issueNumber(int year, List<int> availableYears) =>
    1 + availableYears.where((y) => y < year).length;
