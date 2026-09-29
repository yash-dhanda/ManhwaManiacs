import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// The "Press start" choreography (cinematic 12.4): one clock from the first Flutter frame.
class SplashSpan {
  const SplashSpan(this.element, this.startMs, this.endMs, this.curve);
  final String element;
  final int startMs, endMs;
  final Curve curve;

  /// 0..1 progress of this span at [ms] (curved).
  double at(double ms) => curve.transform(((ms - startMs) / (endMs - startMs)).clamp(0.0, 1.0));
}

const int kSplashLetterStartMs = 252;
const int kSplashLetterStaggerMs = 24;
const int kSplashLetterMs = 640;
const int kSplashGraphemes = 13;
const int kSplashImpressionMs = 1180;
const int kSplashHandoffMs = 220;
const int kSplashDialMs = 2400;
const int kSplashWarmFadeMs = 200;

/// Start of the last letter: 252 + 12 x 24 = 540.
const int kSplashLastLetterStartMs = kSplashLetterStartMs + (kSplashGraphemes - 1) * kSplashLetterStaggerMs;

/// Where the last letter lands: 540 + 640 = 1180.
const int kSplashLettersLandMs = kSplashLastLetterStartMs + kSplashLetterMs;

const List<SplashSpan> splashTimeline = [
  SplashSpan('monogram-in', 0, 100, CineCurves.settle),
  SplashSpan('intersection', 100, 420, CineCurves.settle),
  SplashSpan('monogram-out', 252, 572, CineCurves.lift),
  SplashSpan('wordmark-letters', kSplashLetterStartMs, kSplashLettersLandMs, CineCurves.settle),
  SplashSpan('oxford-rule', 700, 1180, CineCurves.settle),
  SplashSpan('impression', 1180, 1260, Curves.linear),
  SplashSpan('handoff', 1180, 1180 + kSplashHandoffMs, CineCurves.settle),
];

SplashSpan splashSpan(String element) => splashTimeline.firstWhere((s) => s.element == element);

/// The hand-off starts at `max(probeDone, 1180)`; the reveal is never stretched. Null while the
/// probe is pending.
int? splashHandoffAt(int? probeDoneMs) => probeDoneMs == null ? null : math.max(probeDoneMs, kSplashImpressionMs);

/// Whether the 24 px dial and `CONNECTING` show: the probe is still pending at 2400 ms.
bool splashShowsDial(int nowMs, int? probeDoneMs) => probeDoneMs == null && nowMs >= kSplashDialMs;

/// A warm start (a hand-off under 4 h ago and no skin restart) plays only the fades.
bool splashIsWarm({required int? lastHandoffEpochMs, required bool skinRestart, required int nowEpochMs}) =>
    !skinRestart && lastHandoffEpochMs != null && nowEpochMs - lastHandoffEpochMs < const Duration(hours: 4).inMilliseconds;

/// Letter [index] (0..12) of the wordmark: starts at 252 + 24 x index and takes 640 ms `settle`
/// (blur over the first 440 ms). Returns (opacity/rise progress, blur progress), both 0..1.
({double t, double sharp}) splashLetterAt(int index, double ms) {
  final start = kSplashLetterStartMs + index * kSplashLetterStaggerMs;
  return (
    t: CineCurves.settle.transform(((ms - start) / kSplashLetterMs).clamp(0.0, 1.0)),
    sharp: CineCurves.settle.transform(((ms - start) / 440).clamp(0.0, 1.0)),
  );
}

/// The impression at 1180: the lockup translates 1 px down and back over 80 ms.
double splashImpressionOffset(double ms) {
  final t = ((ms - kSplashImpressionMs) / 80).clamp(0.0, 1.0);
  return t < 0.5 ? 2 * t : 2 * (1 - t);
}
