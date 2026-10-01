import 'package:manhwamaniacs/features/onboarding/utils/onboarding_steps.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/skin.dart';

/// What the picker does after a profile is chosen (cinematic 8.5 steps 3 and 4).
enum PickerOutcomeKind { home, onboarding, restartSkin }

class PickerOutcome {
  const PickerOutcome(this.kind, {this.route = '/'});
  final PickerOutcomeKind kind;

  /// Where `context.go` lands for [PickerOutcomeKind.home] and [PickerOutcomeKind.onboarding].
  final String route;

  @override
  bool operator ==(Object other) => other is PickerOutcome && other.kind == kind && other.route == route;
  @override
  int get hashCode => Object.hash(kind, route);
  @override
  String toString() => 'PickerOutcome($kind, $route)';
}

PickerOutcome decidePickerOutcome({
  required Profile profile,
  required String runningSkin,
  required bool glassAvailable,
  required bool onboardingBuilt,
  bool pendingDone = false,
}) {
  // A retired or unknown name (`legacy`) is no restart: the running skin is the default already.
  final saved = skinIdFromName(profile.skin)?.name;
  if (glassAvailable && saved != null && saved != runningSkin) {
    return const PickerOutcome(PickerOutcomeKind.restartSkin);
  }
  final resume = onboardingResumeRoute(profile, glassAvailable: glassAvailable, onboardingBuilt: onboardingBuilt, pendingDone: pendingDone);
  if (resume != null) return PickerOutcome(PickerOutcomeKind.onboarding, route: resume);
  return const PickerOutcome(PickerOutcomeKind.home);
}

/// Not finished, and no finished save waiting to be sent: the onboarding step to resume at. Null when
/// the profile is done. The picker and Tonight's redirect (cold start, Manage's Use, a restart in from
/// Glass) both read it.
String? onboardingResumeRoute(Profile profile, {required bool glassAvailable, required bool onboardingBuilt, bool pendingDone = false}) {
  final step = profile.onboarding;
  if (step?.isDone == true || pendingDone || !onboardingBuilt) return null;
  return Routes.onboarding({'step': resumeStep(step, glassAvailable).n});
}

/// The credit line under a name: `NEW` until onboarding is done, never reading activity.
String pickerCredit(Profile p) => p.onboardingStep != 'done' ? 'NEW' : '';

/// The columns of avatars in one row by width (cinematic 8.0.9): phones use a 2-column grid of
/// 112 px avatars, tablets a centred row up to four, from 900 px one row of 144 px (up to five).
({double size, int perRow}) pickerGridFor(double width, int cells) {
  if (width >= 900) return (size: 144, perRow: cells < 5 ? cells : 5);
  if (width >= 600) return (size: 112, perRow: cells < 4 ? cells : 4);
  return (size: 112, perRow: 2);
}
