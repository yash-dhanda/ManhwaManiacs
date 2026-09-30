import 'package:manhwamaniacs/features/library/models/library_statistics.dart';

const List<int> kMilestones = [7, 30, 100, 365];

/// The highest milestone at or below the current streak that this profile has
/// not seen, or null.
int? pendingMilestone(ReadingStreak s) {
  int? out;
  for (final m in kMilestones) {
    if (m <= s.currentDays && !s.milestonesSeen.contains(m)) out = m;
  }
  return out;
}

/// Every reached milestone up to [shown] still missing from `milestonesSeen`:
/// the card marks them all, so an older one never queues behind a newer one.
List<int> milestonesToMark(ReadingStreak s, int shown) => [
      for (final m in kMilestones)
        if (m <= shown && m <= s.currentDays && !s.milestonesSeen.contains(m)) m,
    ];
