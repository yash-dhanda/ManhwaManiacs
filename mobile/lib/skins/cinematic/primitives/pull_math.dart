/// Pull to reprint maths (cinematic 7.29, pure). The trigger is 96 px of pull.
const double kPullTrigger = 96;

/// The rubber band `d * (1 - 1 / (x * c / d + 1))` with `c = 0.35`.
double pullRubber(double x, {double d = kPullTrigger, double c = 0.35}) => x <= 0 ? 0 : d * (1 - 1 / (x * c / d + 1));

/// How much of the `spot` rule shows, 0..1: it grows from the centre outwards with the pull and is
/// full at the trigger.
double pullRuleFraction(double pull) => (pull / kPullTrigger).clamp(0.0, 1.0);

/// Whether a release at [pull] fires a refresh.
bool pullArmed(double pull) => pull >= kPullTrigger;

/// How far the content sits down while pulled: the rubber band of the pull, capped at [max].
double pullContentOffset(double pull, {double max = 64}) => pullRubber(pull).clamp(0.0, max);
