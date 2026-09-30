import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

/// The Droplet timeline (glass 8.2, 12.3, 12.4), pure: the same numbers drive the widget and the tests.
const int kSplashColdMs = 1200;
const int kSplashWarmMs = 400;
const int kSplashReducedMs = 200;

/// The warm variant plays when the app was last seen under 4 hours ago.
const Duration kSplashWarmWindow = Duration(hours: 4);

bool splashIsWarm({required DateTime now, required DateTime? lastSeen, required bool skinSwitchArrival}) =>
    !skinSwitchArrival && lastSeen != null && now.difference(lastSeen) < kSplashWarmWindow;

/// One sampled frame. Lengths are logical px, angles none; [handoff] is 0..1 of the lens morphing into its target.
class SplashFrame {
  const SplashFrame({
    required this.markOpacity,
    required this.dropletVisible,
    required this.dropletDy,
    required this.squashX,
    required this.squashY,
    required this.rippleRadius,
    required this.rippleOpacity,
    required this.lensSide,
    required this.refractBlur,
    required this.chromaOffset,
    required this.wordmark,
    required this.handoff,
    required this.lensOpacity,
  });

  final double markOpacity;
  final bool dropletVisible;

  /// Vertical offset from the resting centre: -180 at 0 ms, 0 at the 200 ms impact.
  final double dropletDy;
  final double squashX;
  final double squashY;
  final double rippleRadius;
  final double rippleOpacity;

  /// 24 px droplet to a 128 px squircle lens (corner 28 %).
  final double lensSide;
  final double refractBlur;
  final double chromaOffset;

  /// LetterReveal progress of "Manhwa" / "Maniacs" 0..1.
  final double wordmark;
  final double handoff;
  final double lensOpacity;
}

const double _fall = 9000; // px/s^2
final SpringSimulation _lens = SpringSimulation(springOf(GlassSprings.lens), 0, 1, 0);
final SpringSimulation _splashLens = SpringSimulation(springOf(GlassSprings.splashLens), 0, 1, 0);

double _t(int ms, int from, int to) => ((ms - from) / (to - from)).clamp(0.0, 1.0);

/// The cold reveal at [ms] (0..1200).
SplashFrame splashCold(int ms) {
  final fallT = math.min(ms, 200) / 1000;
  final dy = ms >= 200 ? 0.0 : -180 + 0.5 * _fall * fallT * fallT;
  // Squash 1.25 / 0.80 at impact, recovering on springLens.
  final since = math.max(ms - 200, 0) / 1000;
  final rec = ms < 200 ? 0.0 : 1 - _lens.x(since).clamp(0.0, 1.5); // 1 at impact, to 0
  final squash = ms < 200 ? 0.0 : rec.clamp(-0.3, 1.0);
  final grow = ms < 200 ? 0.0 : _splashLens.x((ms - 200) / 1000).clamp(0.0, 1.2);
  final double lens = ms < 200 ? 24.0 : 24 + (128 - 24) * grow;
  final rip = _t(ms, 200, 700);
  return SplashFrame(
    markOpacity: ms < 120 ? 1 - ms / 120 : 0,
    dropletVisible: ms >= 0,
    dropletDy: dy,
    squashX: 1 + 0.25 * squash,
    squashY: 1 - 0.20 * squash,
    rippleRadius: ms < 200 ? 0 : 140 * rip,
    rippleOpacity: ms < 200 ? 0 : 0.30 * (1 - rip),
    lensSide: lens,
    refractBlur: 12 * (1 - _t(ms, 200, 700)),
    chromaOffset: 3 * (1 - _t(ms, 200, 700)),
    wordmark: _t(ms, 500, 1000),
    handoff: _t(ms, 1000, 1200),
    lensOpacity: 1,
  );
}

/// The warm variant at [ms] (0..400): the lens materialises for 250 ms and hands off for 150 ms. No fall, no letters.
SplashFrame splashWarm(int ms) => SplashFrame(
      markOpacity: 0,
      dropletVisible: false,
      dropletDy: 0,
      squashX: 1,
      squashY: 1,
      rippleRadius: 0,
      rippleOpacity: 0,
      lensSide: 128,
      refractBlur: 0,
      chromaOffset: 0,
      wordmark: 1,
      handoff: _t(ms, 250, 400),
      lensOpacity: _t(ms, 0, 250),
    );

/// Reduced motion: a 200 ms cross-fade from the neutral mark to the destination.
double splashReducedFade(int ms) => _t(ms, 0, kSplashReducedMs);

/// The frame at [ms] for the chosen kind.
enum SplashKind { cold, warm, reduced }

int splashDuration(SplashKind k) => switch (k) {
      SplashKind.cold => kSplashColdMs,
      SplashKind.warm => kSplashWarmMs,
      SplashKind.reduced => kSplashReducedMs,
    };

/// The hand-off starts here; a tap anywhere jumps to it.
int splashHandoffStart(SplashKind k) => switch (k) {
      SplashKind.cold => 1000,
      SplashKind.warm => 250,
      SplashKind.reduced => 0,
    };
