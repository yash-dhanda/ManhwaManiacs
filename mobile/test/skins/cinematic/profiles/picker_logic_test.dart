import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/profiles/picker_logic.dart';

Profile _p({String? skin, String? step}) => Profile(
      id: 1,
      name: 'A',
      avatarKey: null,
      mood: Mood.neutral,
      sortOrder: 0,
      matureContentEnabled: false,
      createdAt: DateTime(2026),
      skin: skin,
      onboardingStep: step,
    );

void main() {
  PickerOutcome d(Profile p, {String running = 'cinematic', bool glass = false, bool onboarding = false}) =>
      decidePickerOutcome(profile: p, runningSkin: running, glassAvailable: glass, onboardingBuilt: onboarding);

  test('home by default', () {
    expect(d(_p(step: 'done')).kind, PickerOutcomeKind.home);
    expect(d(_p()).kind, PickerOutcomeKind.home, reason: 'onboarding is not built yet');
  });

  test('a new profile goes to onboarding step 2 (step 1 with glass) once it is built', () {
    final o = d(_p(), onboarding: true);
    expect(o.kind, PickerOutcomeKind.onboarding);
    expect(o.route, contains('step=2'));
    expect(d(_p(), onboarding: true, glass: true).route, contains('step=1'));
    expect(d(_p(step: 'done'), onboarding: true).kind, PickerOutcomeKind.home);
  });

  test('a saved skin that differs restarts only when glass is available', () {
    expect(d(_p(skin: 'glass')).kind, PickerOutcomeKind.home);
    expect(d(_p(skin: 'glass'), glass: true).kind, PickerOutcomeKind.restartSkin);
    expect(d(_p(skin: 'cinematic'), glass: true, onboarding: true).kind, PickerOutcomeKind.onboarding);
  });

  test('credit line and grid', () {
    expect(pickerCredit(_p()), 'NEW');
    expect(pickerCredit(_p(step: 'done')), '');
    expect(pickerGridFor(390, 3), (size: 112, perRow: 2));
    expect(pickerGridFor(834, 5), (size: 112, perRow: 4));
    expect(pickerGridFor(1024, 5), (size: 144, perRow: 5));
    expect(pickerGridFor(1024, 2), (size: 144, perRow: 2));
  });
}
