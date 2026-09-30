import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/onboarding/models/taste.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/skins/glass/screens/onboarding/glass_steps.dart';

Profile _p(String? step) => Profile(id: 1, name: 'A', avatarKey: 'violet', mood: Mood.neutral, sortOrder: 0, matureContentEnabled: false, createdAt: DateTime.utc(2026), onboardingStep: step);

void main() {
  test('needsOnboarding: null and 1 to 7 need it, done does not, a pending done overrides', () {
    expect(needsOnboarding(_p(null), null), isTrue);
    expect(needsOnboarding(_p('3'), null), isTrue);
    expect(needsOnboarding(_p('7'), null), isTrue);
    expect(needsOnboarding(_p('done'), null), isFalse);
    expect(needsOnboarding(_p('3'), const TasteUpdate(step: OnboardingStep.done)), isFalse);
    expect(needsOnboarding(_p('3'), TasteUpdate(step: OnboardingStep.at(3))), isTrue);
  });

  test('shown steps', () {
    expect(shownGlassSteps(lookShown: true), [1, 2, 3, 4, 5, 6, 7]);
    expect(shownGlassSteps(lookShown: false), [1, 3, 4, 5, 6, 7]);
  });

  test('resume', () {
    expect(resumeGlassStep(null, lookShown: true), 1);
    expect(resumeGlassStep(OnboardingStep.at(4), lookShown: true), 4);
    expect(resumeGlassStep(OnboardingStep.at(2), lookShown: false), 3);
    expect(resumeGlassStep(OnboardingStep.done, lookShown: true), isNull);
  });

  test('next and previous', () {
    expect(nextGlassStep(1, lookShown: true), 2);
    expect(nextGlassStep(1, lookShown: false), 3);
    expect(nextGlassStep(7, lookShown: true), isNull);
    expect(prevGlassStep(3, lookShown: true), 2);
    expect(prevGlassStep(3, lookShown: false), 1);
    expect(prevGlassStep(1, lookShown: true), isNull);
  });

  test('dots read "Step 3 of 7" and "of 6" with Look hidden', () {
    expect(dotsFor(3, lookShown: true), (index: 3, total: 7));
    expect(dotsFor(3, lookShown: false), (index: 2, total: 6));
  });

  test('a URL ahead of the saved step resumes at the saved step', () {
    expect(entryGlassStep(6, OnboardingStep.at(4), lookShown: true), 4);
    expect(entryGlassStep(2, OnboardingStep.at(4), lookShown: true), 2);
    expect(entryGlassStep(null, null, lookShown: true), 1);
    expect(entryGlassStep(2, OnboardingStep.at(5), lookShown: false), 3);
  });
}
