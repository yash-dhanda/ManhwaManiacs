import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/diagnostics/motion_recorder.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';
import 'package:manhwamaniacs/skins/token_types.g.dart';
import 'package:motor/motor.dart';

/// What a move becomes under Reduce Motion (glass 4.10, last column).
enum GlassReducedKind { fade, instant, none, frozen, same }

class GlassReduced {
  const GlassReduced._(this.kind, this.ms);

  /// A cross-fade of [ms] (120, 150, 160 or 200).
  const GlassReduced.fade(int ms) : this._(GlassReducedKind.fade, ms);
  static const GlassReduced instant = GlassReduced._(GlassReducedKind.instant, 0);
  static const GlassReduced none = GlassReduced._(GlassReducedKind.none, 0);
  static const GlassReduced frozen = GlassReduced._(GlassReducedKind.frozen, 0);
  static const GlassReduced same = GlassReduced._(GlassReducedKind.same, 0);

  final GlassReducedKind kind;
  final int ms;
}

/// One row of glass 4.10: the planned settle, the spring or curve that drives it, and the reduced form.
class GlassMoveSpec {
  const GlassMoveSpec({required this.ms, this.spring, this.curve, required this.reduced});
  final int ms;
  final SpringToken? spring;
  final CurveToken? curve;
  final GlassReduced reduced;
}

/// The motion table, one entry per [MotionName] (a test asserts full coverage). Transcribed from
/// glass/DESIGN.md 4.10: `ms` is the row's planned settle, `spring` or `curve` its first named token.
const Map<MotionName, GlassMoveSpec> glassMotionTable = {
  MotionName.materialise: GlassMoveSpec(ms: 250, curve: GlassCurves.materialize, reduced: GlassReduced.fade(150)),
  MotionName.dematerialise: GlassMoveSpec(ms: 350, curve: GlassCurves.dematerialize, reduced: GlassReduced.fade(120)),
  MotionName.pressSwell: GlassMoveSpec(ms: 253, spring: GlassSprings.press, reduced: GlassReduced.none),
  MotionName.contentSink: GlassMoveSpec(ms: 253, spring: GlassSprings.press, reduced: GlassReduced.instant),
  MotionName.stretch: GlassMoveSpec(ms: 0, spring: GlassSprings.track, reduced: GlassReduced.none),
  MotionName.bloom: GlassMoveSpec(ms: 434, spring: GlassSprings.morph, reduced: GlassReduced.fade(150)),
  MotionName.push: GlassMoveSpec(ms: 615, spring: GlassSprings.page, reduced: GlassReduced.fade(200)),
  MotionName.pop: GlassMoveSpec(ms: 615, spring: GlassSprings.page, reduced: GlassReduced.fade(200)),
  MotionName.stackFan: GlassMoveSpec(ms: 436, spring: GlassSprings.smooth, reduced: GlassReduced.fade(200)),
  MotionName.zoom: GlassMoveSpec(ms: 558, spring: GlassSprings.zoom, reduced: GlassReduced.fade(200)),
  MotionName.dive: GlassMoveSpec(ms: 558, spring: GlassSprings.zoom, reduced: GlassReduced.fade(200)),
  MotionName.bookOpen: GlassMoveSpec(ms: 615, spring: GlassSprings.page, reduced: GlassReduced.fade(200)),
  MotionName.surface: GlassMoveSpec(ms: 0, spring: GlassSprings.settle, reduced: GlassReduced.fade(150)),
  MotionName.tabDroplet: GlassMoveSpec(ms: 518, spring: GlassSprings.tab, reduced: GlassReduced.fade(150)),
  MotionName.tabSwitch: GlassMoveSpec(ms: 120, curve: GlassCurves.fadeIn, reduced: GlassReduced.fade(120)),
  MotionName.minimise: GlassMoveSpec(ms: 473, spring: GlassSprings.minimize, reduced: GlassReduced.instant),
  MotionName.sheetPresent: GlassMoveSpec(ms: 447, spring: GlassSprings.sheet, reduced: GlassReduced.fade(150)),
  MotionName.sheetSnap: GlassMoveSpec(ms: 342, spring: GlassSprings.sheetSnap, reduced: GlassReduced.fade(150)),
  MotionName.recede: GlassMoveSpec(ms: 0, reduced: GlassReduced.instant),
  MotionName.toastFall: GlassMoveSpec(ms: 431, spring: GlassSprings.snappy, reduced: GlassReduced.fade(150)),
  MotionName.wave: GlassMoveSpec(ms: 431, spring: GlassSprings.snappy, reduced: GlassReduced.instant),
  MotionName.surfaceFromDepth: GlassMoveSpec(ms: 431, spring: GlassSprings.snappy, reduced: GlassReduced.fade(150)),
  MotionName.deal: GlassMoveSpec(ms: 431, spring: GlassSprings.snappy, reduced: GlassReduced.instant),
  MotionName.letterReveal: GlassMoveSpec(ms: 345, spring: GlassSprings.letter, reduced: GlassReduced.instant),
  MotionName.typingReveal: GlassMoveSpec(ms: 50, spring: GlassSprings.tick, reduced: GlassReduced.instant),
  MotionName.wordStream: GlassMoveSpec(ms: 120, curve: GlassCurves.fadeIn, reduced: GlassReduced.instant),
  MotionName.lightFollowsTheStory: GlassMoveSpec(ms: 900, curve: GlassCurves.tintShift, reduced: GlassReduced.fade(200)),
  MotionName.dimShift: GlassMoveSpec(ms: 400, curve: GlassCurves.dimShift, reduced: GlassReduced.instant),
  MotionName.stepIntoTheLight: GlassMoveSpec(ms: 1100, spring: GlassSprings.celebrate, reduced: GlassReduced.fade(200)),
  MotionName.throwMove: GlassMoveSpec(ms: 558, spring: GlassSprings.zoom, reduced: GlassReduced.fade(150)),
  MotionName.catchMove: GlassMoveSpec(ms: 0, reduced: GlassReduced.same),
  MotionName.rubberBand: GlassMoveSpec(ms: 414, spring: GlassSprings.settle, reduced: GlassReduced.instant),
  MotionName.meniscusRefresh: GlassMoveSpec(ms: 467, spring: GlassSprings.lens, reduced: GlassReduced.frozen),
  MotionName.scrubLens: GlassMoveSpec(ms: 467, spring: GlassSprings.lens, reduced: GlassReduced.fade(150)),
  MotionName.chapterCardRise: GlassMoveSpec(ms: 558, spring: GlassSprings.zoom, reduced: GlassReduced.fade(200)),
  MotionName.novelNext: GlassMoveSpec(ms: 615, spring: GlassSprings.page, reduced: GlassReduced.fade(200)),
  MotionName.seamChip: GlassMoveSpec(ms: 1200, curve: GlassCurves.materialize, reduced: GlassReduced.fade(150)),
  MotionName.cruiseRamp: GlassMoveSpec(ms: 400, reduced: GlassReduced.instant),
  MotionName.panelCamera: GlassMoveSpec(ms: 392, spring: GlassSprings.camera, reduced: GlassReduced.fade(120)),
  MotionName.hitLens: GlassMoveSpec(ms: 392, spring: GlassSprings.camera, reduced: GlassReduced.fade(120)),
  MotionName.pageSlide: GlassMoveSpec(ms: 615, spring: GlassSprings.page, reduced: GlassReduced.fade(160)),
  MotionName.pageLift: GlassMoveSpec(ms: 615, spring: GlassSprings.page, reduced: GlassReduced.fade(160)),
  MotionName.paperRipple: GlassMoveSpec(ms: 615, spring: GlassSprings.page, reduced: GlassReduced.fade(200)),
  MotionName.liquidFill: GlassMoveSpec(ms: 467, spring: GlassSprings.lens, reduced: GlassReduced.instant),
  MotionName.holdFill: GlassMoveSpec(ms: 1000, spring: GlassSprings.dismiss, reduced: GlassReduced.instant),
  MotionName.skinMelt: GlassMoveSpec(ms: 615, curve: GlassCurves.dematerialize, reduced: GlassReduced.fade(200)),
  MotionName.dropletReveal: GlassMoveSpec(ms: 1200, spring: GlassSprings.lens, reduced: GlassReduced.fade(200)),
  MotionName.cardFlip: GlassMoveSpec(ms: 436, spring: GlassSprings.smooth, reduced: GlassReduced.fade(200)),
  MotionName.deckLiftOff: GlassMoveSpec(ms: 436, spring: GlassSprings.smooth, reduced: GlassReduced.fade(150)),
  MotionName.storyStack: GlassMoveSpec(ms: 615, spring: GlassSprings.page, reduced: GlassReduced.fade(200)),
  MotionName.thinkingOrbit: GlassMoveSpec(ms: 1400, reduced: GlassReduced.instant),
  MotionName.causticPress: GlassMoveSpec(ms: 150, curve: GlassCurves.glowIn, reduced: GlassReduced.none),
  MotionName.followRing: GlassMoveSpec(ms: 700, curve: GlassCurves.followRing, reduced: GlassReduced.none),
  MotionName.specularSweep: GlassMoveSpec(ms: 520, curve: GlassCurves.sweep, reduced: GlassReduced.none),
  MotionName.streakFlare: GlassMoveSpec(ms: 643, spring: GlassSprings.celebrate, reduced: GlassReduced.instant),
  MotionName.recordSparks: GlassMoveSpec(ms: 900, curve: GlassCurves.fadeOut, reduced: GlassReduced.none),
  MotionName.goalRingClose: GlassMoveSpec(ms: 600, spring: GlassSprings.snappy, reduced: GlassReduced.instant),
  MotionName.reactionBloomAndArc: GlassMoveSpec(ms: 467, spring: GlassSprings.lens, reduced: GlassReduced.fade(150)),
  MotionName.presenceDrift: GlassMoveSpec(ms: 1064, spring: GlassSprings.drift, reduced: GlassReduced.instant),
  MotionName.liveRingBreathe: GlassMoveSpec(ms: 2400, reduced: GlassReduced.frozen),
  MotionName.rainOnGlass: GlassMoveSpec(ms: 0, reduced: GlassReduced.frozen),
  MotionName.beadFlicker: GlassMoveSpec(ms: 120, reduced: GlassReduced.instant),
  MotionName.beadPulse: GlassMoveSpec(ms: 289, spring: GlassSprings.tick, reduced: GlassReduced.none),
  MotionName.genreField: GlassMoveSpec(ms: 0, reduced: GlassReduced.frozen),
  MotionName.densityReflow: GlassMoveSpec(ms: 431, spring: GlassSprings.snappy, reduced: GlassReduced.instant),
  MotionName.pinFly: GlassMoveSpec(ms: 558, spring: GlassSprings.zoom, reduced: GlassReduced.instant),
  MotionName.fanOpen: GlassMoveSpec(ms: 643, spring: GlassSprings.celebrate, reduced: GlassReduced.none),
  MotionName.drain: GlassMoveSpec(ms: 467, spring: GlassSprings.lens, reduced: GlassReduced.instant),
  MotionName.ambientDrift: GlassMoveSpec(ms: 1064, spring: GlassSprings.drift, reduced: GlassReduced.frozen),
  MotionName.lightFollow: GlassMoveSpec(ms: 0, spring: GlassSprings.track, reduced: GlassReduced.frozen),
  MotionName.heroTilt: GlassMoveSpec(ms: 0, spring: GlassSprings.track, reduced: GlassReduced.frozen),
  MotionName.orbIdleDrift: GlassMoveSpec(ms: 0, reduced: GlassReduced.frozen),
  MotionName.lensBob: GlassMoveSpec(ms: 0, reduced: GlassReduced.frozen),
  MotionName.errorShake: GlassMoveSpec(ms: 420, reduced: GlassReduced.frozen),
  MotionName.skeletonShimmer: GlassMoveSpec(ms: 1400, reduced: GlassReduced.frozen),
  MotionName.titleCapsule: GlassMoveSpec(ms: 431, curve: GlassCurves.materialize, reduced: GlassReduced.fade(150)),
  MotionName.dockMerge: GlassMoveSpec(ms: 0, spring: GlassSprings.track, reduced: GlassReduced.instant),
  MotionName.addressDrain: GlassMoveSpec(ms: 558, spring: GlassSprings.zoom, reduced: GlassReduced.fade(200)),
  MotionName.slabCondense: GlassMoveSpec(ms: 558, curve: GlassCurves.fadeOut, reduced: GlassReduced.fade(200)),
  MotionName.lensSplit: GlassMoveSpec(ms: 643, spring: GlassSprings.celebrate, reduced: GlassReduced.instant),
  MotionName.fieldRipple: GlassMoveSpec(ms: 600, curve: GlassCurves.fadeIn, reduced: GlassReduced.none),
  MotionName.orbitingCovers: GlassMoveSpec(ms: 0, spring: GlassSprings.drift, reduced: GlassReduced.frozen),
  MotionName.orbLift: GlassMoveSpec(ms: 558, spring: GlassSprings.zoom, reduced: GlassReduced.fade(200)),
  MotionName.dotsMerge: GlassMoveSpec(ms: 431, spring: GlassSprings.snappy, reduced: GlassReduced.fade(200)),
  MotionName.coverArc: GlassMoveSpec(ms: 289, spring: GlassSprings.tick, reduced: GlassReduced.fade(150)),
  MotionName.avatarArc: GlassMoveSpec(ms: 280, spring: GlassSprings.tick, reduced: GlassReduced.fade(150)),
  MotionName.orbsFlyOut: GlassMoveSpec(ms: 558, spring: GlassSprings.zoom, reduced: GlassReduced.fade(150)),
  MotionName.tagFlight: GlassMoveSpec(ms: 558, spring: GlassSprings.zoom, reduced: GlassReduced.fade(200)),
  MotionName.plusOne: GlassMoveSpec(ms: 643, spring: GlassSprings.celebrate, reduced: GlassReduced.fade(150)),
  MotionName.rowPulse: GlassMoveSpec(ms: 900, curve: GlassCurves.fadeOut, reduced: GlassReduced.instant),
  MotionName.skinPreview: GlassMoveSpec(ms: 0, reduced: GlassReduced.instant),
  MotionName.flameFlicker: GlassMoveSpec(ms: 0, spring: GlassSprings.drift, reduced: GlassReduced.frozen),
  MotionName.countUp: GlassMoveSpec(ms: 0, spring: GlassSprings.drift, reduced: GlassReduced.instant),
  MotionName.pagePile: GlassMoveSpec(ms: 0, reduced: GlassReduced.frozen),
  MotionName.podiumDrop: GlassMoveSpec(ms: 120, reduced: GlassReduced.fade(150)),
  MotionName.liquidSpinner: GlassMoveSpec(ms: 900, reduced: GlassReduced.frozen),
  MotionName.buttonDots: GlassMoveSpec(ms: 0, spring: GlassSprings.tick, reduced: GlassReduced.frozen),
  MotionName.countPop: GlassMoveSpec(ms: 0, spring: GlassSprings.tick, reduced: GlassReduced.fade(150)),
  MotionName.queuedRing: GlassMoveSpec(ms: 4000, reduced: GlassReduced.frozen),
  MotionName.orbBreathe: GlassMoveSpec(ms: 2000, reduced: GlassReduced.frozen),
  MotionName.spotlightDrop: GlassMoveSpec(ms: 0, spring: GlassSprings.lens, reduced: GlassReduced.fade(200)),
  MotionName.lensPop: GlassMoveSpec(ms: 0, spring: GlassSprings.lens, reduced: GlassReduced.fade(150)),
  MotionName.chartRise: GlassMoveSpec(ms: 0, spring: GlassSprings.snappy, reduced: GlassReduced.fade(150)),
  MotionName.spoilerUnseal: GlassMoveSpec(ms: 160, reduced: GlassReduced.instant),
  MotionName.tapLight: GlassMoveSpec(ms: 300, reduced: GlassReduced.same),
  MotionName.sceneGlyphLoops: GlassMoveSpec(ms: 0, reduced: GlassReduced.frozen),
  MotionName.quickType: GlassMoveSpec(ms: 12, reduced: GlassReduced.instant),
  MotionName.speakingOrbPulse: GlassMoveSpec(ms: 0, reduced: GlassReduced.frozen),
  MotionName.previewOrbPulse: GlassMoveSpec(ms: 0, reduced: GlassReduced.frozen),
  MotionName.levelBars: GlassMoveSpec(ms: 0, reduced: GlassReduced.frozen),
  MotionName.cruiseDiscSpin: GlassMoveSpec(ms: 0, reduced: GlassReduced.frozen),
  MotionName.highlightBand: GlassMoveSpec(ms: 431, spring: GlassSprings.snappy, reduced: GlassReduced.fade(120)),
  MotionName.lozengeMorph: GlassMoveSpec(ms: 431, spring: GlassSprings.snappy, reduced: GlassReduced.fade(120)),
  MotionName.followScroll: GlassMoveSpec(ms: 414, spring: GlassSprings.settle, reduced: GlassReduced.instant),
  MotionName.lensHop: GlassMoveSpec(ms: 643, spring: GlassSprings.celebrate, reduced: GlassReduced.fade(150)),
  MotionName.cardDrop: GlassMoveSpec(ms: 643, spring: GlassSprings.celebrate, reduced: GlassReduced.fade(150)),
};

/// The one helper every Glass move goes through (glass 4.10): it passes the release velocity (law 4),
/// swaps in the reduced replacement, asserts on a missing name in debug and records the move.
abstract final class GlassMotion {
  /// Reads the reduced-motion answer (OS flag or in-app switch). The Glass root installs the real one;
  /// tests replace it.
  static bool Function() isReduced = () => false;

  static MotionRecorder recorder = MotionRecorder.instance;

  static GlassMoveSpec _spec(MotionName name) {
    final spec = glassMotionTable[name];
    assert(spec != null, 'GlassMotion: $name has no entry in the motion table (glass 4.10)');
    return spec!;
  }

  static Duration _fade(GlassReduced r) => Duration(milliseconds: r.ms);

  /// Drives [controller] to [target]. [velocityPxPerS] over [travelPx] is the release velocity.
  static Future<void> play(
    MotionName name, {
    required AnimationController controller,
    required double target,
    double velocityPxPerS = 0,
    double travelPx = 1,
  }) {
    final spec = _spec(name);
    final reduced = isReduced();
    final entry = recorder.begin(name.label, reduced && spec.reduced.kind == GlassReducedKind.fade ? spec.reduced.ms : spec.ms);
    final TickerFuture run;
    if (reduced && spec.reduced.kind != GlassReducedKind.same) {
      if (spec.reduced.kind == GlassReducedKind.fade) {
        run = controller.animateTo(target, duration: _fade(spec.reduced));
      } else {
        controller.value = target;
        run = TickerFuture.complete();
      }
    } else if (spec.spring != null) {
      run = controller.springTo(target, spec.spring!, velocityPxPerS: velocityPxPerS, travelPx: travelPx);
    } else if (spec.curve != null) {
      run = controller.animateTo(target, duration: spec.curve!.duration, curve: spec.curve!.curve);
    } else if (spec.ms > 0) {
      run = controller.animateTo(target, duration: Duration(milliseconds: spec.ms));
    } else {
      controller.value = target;
      run = TickerFuture.complete();
    }
    return run.orCancel.then<void>((_) {}, onError: (Object _) {}).whenComplete(() => recorder.end(entry));
  }

  /// The motor 1.1.0 twin of [play].
  static Future<void> playMotor(MotionName name, SingleMotionController controller, double target, {double? withVelocity}) {
    final spec = _spec(name);
    final reduced = isReduced();
    final entry = recorder.begin(name.label, reduced && spec.reduced.kind == GlassReducedKind.fade ? spec.reduced.ms : spec.ms);
    final TickerFuture run;
    if (reduced && spec.reduced.kind != GlassReducedKind.same) {
      if (spec.reduced.kind == GlassReducedKind.fade) {
        controller.motion = Motion.linear(_fade(spec.reduced));
        run = controller.animateTo(target);
      } else {
        controller.motion = const Motion.none();
        run = controller.animateTo(target);
      }
    } else if (spec.spring != null) {
      controller.motion = SpringMotion(springOf(spec.spring!));
      run = controller.animateTo(target, withVelocity: withVelocity);
    } else {
      controller.motion = Motion.curved(spec.curve?.duration ?? Duration(milliseconds: spec.ms), spec.curve?.curve ?? Curves.linear);
      run = controller.animateTo(target);
    }
    return run.orCancel.then<void>((_) {}, onError: (Object _) {}).whenComplete(() => recorder.end(entry));
  }
}

/// "Show motion timings" (per device, off after a restart).
final glassShowMotionTimingsProvider = StateProvider<bool>((ref) => false);

/// A 320 px panel bottom-left listing the last 20 moves (glass 15.8). Mirrors Cinematic's overlay in
/// behaviour and does not import it.
class GlassMotionTimingsOverlay extends StatefulWidget {
  const GlassMotionTimingsOverlay({super.key, MotionRecorder? recorder}) : _recorder = recorder;
  final MotionRecorder? _recorder;

  @override
  State<GlassMotionTimingsOverlay> createState() => _GlassMotionTimingsOverlayState();
}

class _GlassMotionTimingsOverlayState extends State<GlassMotionTimingsOverlay> {
  MotionRecorder get _rec => widget._recorder ?? GlassMotion.recorder;

  @override
  void initState() {
    super.initState();
    _rec.addListener(_changed);
    _rec.attach();
  }

  @override
  void dispose() {
    _rec.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  static String line(MotionEntry e) {
    if (e.marker) return e.label;
    return '${e.label.padRight(13)} ${e.plannedMs} → ${e.actualMs.round()} MS   ${e.frames}/${e.expectedFrames} F   ${e.dropped} DROP';
  }

  @override
  Widget build(BuildContext context) {
    const t = glassTokens;
    final hit = GlassFrame.hitMin(context);
    final last = _rec.entries.reversed.take(20).toList();
    final mono = GlassTypeStyleMono.of(context);
    Widget button(String label, VoidCallback onTap) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: hit, minWidth: hit),
            child: Center(child: Text(label, style: mono.copyWith(color: t.colorIris300))),
          ),
        );
    return Positioned(
      left: 8,
      bottom: 8,
      width: 320,
      child: SafeArea(
        child: ColoredBox(
          color: const Color(0xE6000000),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('MOTION TIMINGS', style: mono.copyWith(color: t.colorLabel2))),
                    button('Clear', _rec.clear),
                    button('Copy log', () => Clipboard.setData(ClipboardData(text: _rec.toJsonLog()))),
                  ],
                ),
                for (final e in last)
                  Text(
                    line(e),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: mono.copyWith(color: e.flagged ? t.colorDanger : t.colorLabel1),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The overlay's own `mono` 11/16 style, without a `Theme`.
abstract final class GlassTypeStyleMono {
  static TextStyle of(BuildContext context) => const TextStyle(
        fontFamily: 'GoogleSansCodeMM',
        fontSize: 11,
        height: 16 / 11,
        decoration: TextDecoration.none,
        fontVariations: [FontVariation('wght', 400)],
      );
}
