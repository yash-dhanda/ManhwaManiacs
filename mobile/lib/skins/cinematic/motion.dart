import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/diagnostics/motion_recorder.dart';
import 'package:manhwamaniacs/features/settings/providers/a11y_prefs_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/motion_names.g.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

export 'package:manhwamaniacs/skins/cinematic/motion_names.g.dart' show MotionName;
export 'package:manhwamaniacs/skins/cinematic/primitives/set_heading.dart';
export 'package:manhwamaniacs/skins/cinematic/primitives/typed_headline.dart';

/// Exposes the app-level reduced-motion switch (`appReduceMotionProvider`) to the subtree.
class CineMotionScope extends ConsumerWidget {
  const CineMotionScope({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _MotionScope(appReduced: ref.watch(appReduceMotionProvider), child: child);
}

class _MotionScope extends InheritedWidget {
  const _MotionScope({required this.appReduced, required super.child});
  final bool appReduced;

  @override
  bool updateShouldNotify(_MotionScope o) => o.appReduced != appReduced;
}

class _Move {
  const _Move(this.ms, this.curve);
  final int ms;
  final Curve curve;
}

/// The single entry point for every named move (cinematic 4.5, 4.7).
abstract final class CineMotion {
  /// The OS setting or the app's own switch.
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ||
      (context.dependOnInheritedWidgetOfExactType<_MotionScope>()?.appReduced ?? false);

  static final Map<MotionName, _Move> _moves = {
    MotionName.set: _Move(CineDur.column.inMilliseconds, CineCurves.settle),
    MotionName.ruleDraw: _Move(CineDur.spread.inMilliseconds, CineCurves.settle),
    MotionName.letterSet: _Move(CineDur.letter.inMilliseconds, CineCurves.settle),
    MotionName.type: _Move(CineDur.type.inMilliseconds, CineCurves.linear),
    MotionName.rackFocus: _Move(CineDur.rack.inMilliseconds, CineCurves.settle),
    MotionName.develop: _Move(CineDur.rack.inMilliseconds, CineCurves.settle),
    MotionName.drift: _Move(CineDur.drift.inMilliseconds, CineCurves.drift),
    MotionName.flicker: _Move(CineDur.flicker.inMilliseconds, CineCurves.drift),
    MotionName.slate: _Move(CineDur.column.inMilliseconds, CineCurves.settle),
    MotionName.ruleSlide: _Move(CineDur.column.inMilliseconds, CineCurves.settle),
  };

  /// Runs [name] on [controller] from its current value (or [from]) to [target]. Nothing queues:
  /// calling again retargets from where it is (4.7).
  static Future<void> play(
    MotionName name,
    AnimationController controller, {
    double target = 1.0,
    double? from,
    Duration? duration,
    Curve? curve,
  }) async {
    final move = _moves[name];
    final d = duration ?? Duration(milliseconds: move?.ms ?? 0);
    controller.duration = d;
    final h = MotionRecorder.instance.start(name.label, d.inMilliseconds);
    try {
      if (from != null) controller.value = from;
      await controller.animateTo(target, curve: curve ?? move?.curve ?? Curves.linear).orCancel;
      h.end();
    } on TickerCanceled {
      h.end(interrupted: true);
    }
  }

  /// For widgets that own their own controllers or tickers (Letter set, Type).
  static MotionHandle track(MotionName name, int plannedMs) => MotionRecorder.instance.start(name.label, plannedMs);

  static const int rackCap = 12;
  static int _rackRunning = 0;
  static int get rackRunning => _rackRunning;
  static bool _claimRack() {
    if (_rackRunning >= rackCap) return false;
    _rackRunning++;
    return true;
  }

  static void _releaseRack() => _rackRunning = math.max(0, _rackRunning - 1);
}

/// Whether [context]'s box is at least partly inside the screen; drives the off-screen pauses.
bool cineOnScreen(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize || !box.attached) return true;
  final top = box.localToGlobal(Offset.zero).dy;
  final h = MediaQuery.sizeOf(context).height;
  return top < h && top + box.size.height > 0;
}

/// Set for one item: opacity 0 -> 1 and y 8 -> 0 px over 320 ms, after [delay].
class CineSetIn extends StatefulWidget {
  const CineSetIn({super.key, required this.child, this.delay = Duration.zero, this.animate = true});
  final Widget child;
  final Duration delay;
  final bool animate;

  @override
  State<CineSetIn> createState() => _CineSetInState();
}

class _CineSetInState extends State<CineSetIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!widget.animate) {
      _c.value = 1;
    } else if (CineMotion.reduced(context)) {
      CineMotion.play(MotionName.set, _c, duration: CineDur.beat, curve: Curves.linear);
    } else {
      final total = widget.delay.inMilliseconds + CineDur.column.inMilliseconds;
      CineMotion.play(MotionName.set, _c,
          duration: Duration(milliseconds: total),
          curve: Interval(widget.delay.inMilliseconds / total, 1, curve: CineCurves.settle),);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = CineMotion.reduced(context);
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) => Opacity(
        opacity: _c.value,
        child: Transform.translate(offset: Offset(0, reduced ? 0 : 8 * (1 - _c.value)), child: child),
      ),
    );
  }
}

/// A hairline, strong, heavy, spot or Oxford rule that draws left -> right on entrance.
enum CineRuleKind { hair, strong, ink, heavy, spot }

class CineRuleDraw extends StatefulWidget {
  const CineRuleDraw({super.key, this.kind = CineRuleKind.hair, this.delay = Duration.zero, this.draw = true, this.oxford = false});
  final CineRuleKind kind;
  final Duration delay;
  final bool draw;

  /// The 3 + 2 + 1 px Oxford rule instead of a single line.
  final bool oxford;

  @override
  State<CineRuleDraw> createState() => _CineRuleDrawState();
}

class _CineRuleDrawState extends State<CineRuleDraw> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!widget.draw || CineMotion.reduced(context)) {
      _c.value = 1; // present at rest (4.8)
    } else {
      final total = widget.delay.inMilliseconds + CineDur.spread.inMilliseconds;
      CineMotion.play(MotionName.ruleDraw, _c,
          duration: Duration(milliseconds: total), curve: Interval(widget.delay.inMilliseconds / total, 1, curve: CineCurves.settle),);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final Widget line = widget.oxford
        ? Column(mainAxisSize: MainAxisSize.min, children: [
            Container(height: c.ruleOxford.thick, color: c.ruleOxford.color),
            SizedBox(height: c.ruleOxford.gap),
            Container(height: c.ruleOxford.thin, color: c.ruleOxford.color),
          ],)
        : Container(
            height: switch (widget.kind) { CineRuleKind.heavy => c.ruleHeavy.width, CineRuleKind.spot => c.ruleSpot.width, _ => c.ruleHair.width },
            color: switch (widget.kind) {
              CineRuleKind.hair => c.colorRule1,
              CineRuleKind.strong => c.colorRule2,
              CineRuleKind.ink || CineRuleKind.heavy => c.colorInk100,
              CineRuleKind.spot => c.colorSpot,
            },
          );
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        child: line,
        builder: (_, child) => Transform(alignment: Alignment.centerLeft, transform: Matrix4.diagonal3Values(_c.value, 1, 1), child: child),
      ),
    );
  }
}

List<double> _brightness(double b) => [b, 0, 0, 0, 0, 0, b, 0, 0, 0, 0, 0, b, 0, 0, 0, 0, 0, 1, 0];

/// Rack focus (blur 14 -> 0, brightness .6 -> 1, scale 1.03 -> 1) on first decode; the 13th
/// concurrent image and later run Develop (no blur). Reduced: a 160 ms fade.
class CineRackImage extends StatefulWidget {
  const CineRackImage({super.key, required this.child, this.skip = false});
  final Widget child;

  /// True when the image was loaded synchronously.
  final bool skip;

  @override
  State<CineRackImage> createState() => _CineRackImageState();
}

class _CineRackImageState extends State<CineRackImage> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  bool _started = false, _racking = false, _claimed = false, _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduced = CineMotion.reduced(context);
    if (widget.skip) {
      _c.value = 1;
      return;
    }
    if (_reduced) {
      CineMotion.play(MotionName.develop, _c, duration: CineDur.beat, curve: Curves.linear);
      return;
    }
    _racking = CineMotion._claimRack();
    _claimed = _racking;
    CineMotion.play(_racking ? MotionName.rackFocus : MotionName.develop, _c).whenComplete(_release);
  }

  void _release() {
    if (_claimed) {
      _claimed = false;
      CineMotion._releaseRack();
    }
  }

  @override
  void dispose() {
    _release();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sigma = context.cine.blurRack;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) {
        final t = _c.value;
        if (_reduced) return Opacity(opacity: t, child: child);
        final b = 0.6 + 0.4 * t;
        Widget out = ColorFiltered(colorFilter: ColorFilter.matrix(_brightness(b)), child: child);
        final s = _racking ? sigma * (1 - t) : 0.0;
        if (s >= 0.05) out = ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: s, sigmaY: s), child: out);
        return Opacity(opacity: _racking ? 1 : t, child: Transform.scale(scale: 1.03 - 0.03 * t, child: out));
      },
    );
  }
}

/// Drift: 26 s alternate, scale 1.00 -> 1.06 and translate -1 %, -1.5 %; pauses off screen.
class CineDrift extends StatefulWidget {
  const CineDrift({super.key, required this.child});
  final Widget child;

  @override
  State<CineDrift> createState() => _CineDriftState();
}

class _CineDriftState extends State<CineDrift> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  ScrollPosition? _pos;
  bool _reduced = false, _running = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: CineDur.drift);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = CineMotion.reduced(context);
    _pos?.removeListener(_check);
    _pos = Scrollable.maybeOf(context)?.position;
    _pos?.addListener(_check);
    if (!_reduced && !_running) {
      _running = true;
      _c.repeat(reverse: true);
    }
    if (_reduced && _running) {
      _running = false;
      _c.stop();
    }
  }

  void _check() {
    if (!mounted || _reduced) return;
    final on = cineOnScreen(context);
    if (on && !_running) {
      _running = true;
      _c.repeat(reverse: true);
    } else if (!on && _running) {
      _running = false;
      _c.stop();
    }
  }

  @override
  void dispose() {
    _pos?.removeListener(_check);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (_, child) {
          if (_reduced) return Transform.scale(scale: 1.03, child: child);
          final t = CineCurves.drift.transform(_c.value);
          return FractionalTranslation(
            translation: Offset(-0.01 * t, -0.015 * t),
            child: Transform.scale(scale: 1 + 0.06 * t, child: child),
          );
        },
      );
}

/// Flicker: opacity .55 <-> 1 on a 1400 ms half-period, phase +60 ms per item; static .8 reduced.
class CineFlicker extends StatefulWidget {
  const CineFlicker({super.key, required this.child, this.index = 0});
  final Widget child;
  final int index;

  @override
  State<CineFlicker> createState() => _CineFlickerState();
}

class _CineFlickerState extends State<CineFlicker> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: CineDur.flicker, value: (60 * widget.index % 1400) / 1400);
  bool _reduced = false, _running = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = CineMotion.reduced(context);
    if (_reduced) {
      _running = false;
      _c.stop();
    } else if (!_running) {
      _running = true;
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (_, child) => Opacity(
          opacity: _reduced ? 0.8 : 0.55 + 0.45 * CineCurves.drift.transform(_c.value),
          child: child,
        ),
      );
}
