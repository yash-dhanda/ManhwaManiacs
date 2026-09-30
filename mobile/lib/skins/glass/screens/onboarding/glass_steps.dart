import 'package:manhwamaniacs/features/onboarding/models/taste.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';

/// Which onboarding steps Glass shows and how they order (glass 8.7). Pure.
///
/// True when the profile has not finished onboarding: its saved step is null or 1 to 7, and no pending `done` is stored.
bool needsOnboarding(Profile p, TasteUpdate? pending) {
  if (pending != null && pending.step.isDone) return false;
  final s = p.onboarding;
  return s == null || !s.isDone;
}

/// `[1..7]`, or `[1, 3..7]` while the Look step is hidden.
List<int> shownGlassSteps({required bool lookShown}) => lookShown ? const [1, 2, 3, 4, 5, 6, 7] : const [1, 3, 4, 5, 6, 7];

/// The step to open: null becomes 1, 1 to 7 itself (2 while hidden becomes 3), `done` is null (never shown).
int? resumeGlassStep(OnboardingStep? saved, {required bool lookShown}) {
  if (saved == null) return 1;
  if (saved.isDone) return null;
  final n = saved.n!;
  return !lookShown && n == 2 ? 3 : n;
}

int? nextGlassStep(int step, {required bool lookShown}) {
  final s = shownGlassSteps(lookShown: lookShown);
  final i = s.indexOf(step);
  return i < 0 || i + 1 >= s.length ? null : s[i + 1];
}

/// The step before [step]; null on the first shown step.
int? prevGlassStep(int step, {required bool lookShown}) {
  final s = shownGlassSteps(lookShown: lookShown);
  final i = s.indexOf(step);
  return i <= 0 ? null : s[i - 1];
}

/// `(index, total)`, both one-based total: "Step 3 of 7".
({int index, int total}) dotsFor(int step, {required bool lookShown}) {
  final s = shownGlassSteps(lookShown: lookShown);
  final i = s.indexOf(step);
  return (index: i < 0 ? 1 : i + 1, total: s.length);
}

/// A `/welcome?step=n` URL whose step is ahead of the saved step resumes at the saved step.
int entryGlassStep(int? requested, OnboardingStep? saved, {required bool lookShown}) {
  final resume = resumeGlassStep(saved, lookShown: lookShown) ?? 1;
  final r = requested ?? 1;
  final shown = shownGlassSteps(lookShown: lookShown);
  var n = r > resume ? resume : r;
  if (!shown.contains(n)) n = shown.firstWhere((x) => x >= n, orElse: () => shown.last);
  return n;
}
