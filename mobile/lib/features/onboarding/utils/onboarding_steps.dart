import 'package:manhwamaniacs/features/onboarding/models/taste.dart';

/// The steps a skin shows: Formats, Genres, Art style, Seeds (2 to 5), and Edition (1) with Glass.
List<int> shownSteps(bool glassAvailable) => glassAvailable ? const [1, 2, 3, 4, 5] : const [2, 3, 4, 5];

/// `(index, total)` for the folio, 1-based; a step not shown clamps to the first.
(int, int) folioFor(int step, bool glassAvailable) {
  final s = shownSteps(glassAvailable);
  final i = s.indexOf(step);
  return (i < 0 ? 1 : i + 1, s.length);
}

/// Where a saved step resumes: done stays done; nothing saved starts at the first shown step; a
/// step not shown (1 without Glass) moves to the first, one beyond the last (Glass's 6 and 7) to
/// the last.
OnboardingStep resumeStep(OnboardingStep? saved, bool glassAvailable) {
  final s = shownSteps(glassAvailable);
  if (saved == null) return OnboardingStep.at(s.first);
  if (saved.isDone) return saved;
  final n = saved.n!;
  if (n < s.first) return OnboardingStep.at(s.first);
  if (n > s.last) return OnboardingStep.at(s.last);
  return saved;
}

/// The step after [step], or null after the last.
int? nextStep(int step, bool glassAvailable) {
  final s = shownSteps(glassAvailable);
  final i = s.indexOf(step);
  return i < 0 || i + 1 >= s.length ? null : s[i + 1];
}

/// The step before [step]; null before the first shown step means "leave to the picker".
int? prevStep(int step, bool glassAvailable) {
  final s = shownSteps(glassAvailable);
  final i = s.indexOf(step);
  return i <= 0 ? null : s[i - 1];
}

/// The step a `/welcome?step=` link opens: never beyond the resume step, never one not shown.
int entryStep(int? requested, OnboardingStep resume, bool glassAvailable) {
  final s = shownSteps(glassAvailable);
  final max = resume.n ?? s.last;
  var n = requested ?? s.first;
  if (n < s.first) n = s.first;
  if (n > max) n = max;
  return n;
}
