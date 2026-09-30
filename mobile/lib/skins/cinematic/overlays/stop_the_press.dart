import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_oxford_rule.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/cinematic/wipe_geometry.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Stop the press (cinematic 4.5, 8.30.3): the edition switch's exit, 500 ms. The screen racks
/// out of focus (0-160 ms), the column blades close top-down (80-328 ms on phones, 80-392 from
/// 600 dp), the masthead cuts in on black at 456 ms with the `skin.switch` haptic; the caller
/// restarts at 500 ms. Reduced motion: a 200 ms fade to black, the masthead at 160 ms.
class StopThePressTimeline {
  const StopThePressTimeline._();

  static const int totalMs = 500;
  static const int reducedMs = 200;
  static const int rackMs = 160;
  static const int bladeStartMs = 80;
  static const int mastheadMs = 456;
  static const int reducedMastheadMs = 160;

  /// Rack-out amount 0..1 at [ms] (`easeTurn` over the first 160 ms).
  static double rack(double ms) => CineCurves.turn.transform((ms / rackMs).clamp(0.0, 1.0));

  /// One blade's scaleY at [ms]: 200 ms `easeSettle`, 16 ms apart, from t = 80.
  static double blade(int index, double ms) =>
      CineCurves.settle.transform(((ms - bladeStartMs - index * kWipeStaggerMs) / CineDur.wipeClose.inMilliseconds).clamp(0.0, 1.0));

  /// When the last blade lands: 328 ms for 4 blades, 392 ms for 8.
  static int bladesDoneMs(int blades) => bladeStartMs + (blades - 1) * kWipeStaggerMs + CineDur.wipeClose.inMilliseconds;
}

/// One frame of the press at [ms] (forward) or, when [reverse] is set, [ms] into the failure
/// reversal (blades open 200 ms `easeSet`, focus back over 160 ms `easeTurn`). Pure: the overlay
/// drives it with a controller, the proof harness with fixed times.
class StopThePressFrame extends StatelessWidget {
  const StopThePressFrame({super.key, required this.ms, this.reverse = false, this.reduced = false, this.title = 'MANHWAMANIACS'});

  final double ms;
  final bool reverse, reduced;
  final String title;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final width = MediaQuery.sizeOf(context).width;
    final n = wipeBladeCount(width);
    final double rack, fade;
    final bool masthead;
    List<double> blades;
    if (reduced) {
      final t = reverse ? 1 - (ms / CineDur.clip.inMilliseconds).clamp(0.0, 1.0) : (ms / StopThePressTimeline.reducedMs).clamp(0.0, 1.0);
      rack = 0;
      fade = t;
      blades = List.filled(n, 0);
      masthead = !reverse && ms >= StopThePressTimeline.reducedMastheadMs;
    } else if (reverse) {
      final open = CineCurves.easeSet.transform((ms / CineDur.clip.inMilliseconds).clamp(0.0, 1.0));
      blades = List.filled(n, 1 - open);
      rack = 1 - CineCurves.turn.transform((ms / StopThePressTimeline.rackMs).clamp(0.0, 1.0));
      fade = 0;
      masthead = false;
    } else {
      rack = StopThePressTimeline.rack(ms);
      blades = [for (var i = 0; i < n; i++) StopThePressTimeline.blade(i, ms)];
      fade = 0;
      masthead = ms >= StopThePressTimeline.mastheadMs;
    }
    final sigma = 6.0 * rack;
    final b = 1 - 0.7 * rack;
    final geo = wipeBlades(width);
    return ExcludeSemantics(
      child: Stack(fit: StackFit.expand, children: [
        if (rack > 0)
          BackdropFilter(
            filter: ui.ImageFilter.compose(
              outer: ui.ColorFilter.matrix(<double>[b, 0, 0, 0, 0, 0, b, 0, 0, 0, 0, 0, b, 0, 0, 0, 0, 0, 1, 0]),
              inner: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            ),
            child: const SizedBox.expand(),
          ),
        if (fade > 0) Positioned.fill(child: ColoredBox(color: Color.fromRGBO(0, 0, 0, fade))),
        if (!reduced)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, box) => Stack(children: [
                for (var i = 0; i < n; i++)
                  if (blades[i] > 0)
                    Positioned(
                      key: Key('press-blade-$i'),
                      left: geo[i].left,
                      width: geo[i].right - geo[i].left + 0.5,
                      top: 0,
                      height: box.maxHeight * blades[i],
                      child: const ColoredBox(color: Color(0xFF000000)),
                    ),
              ],),
            ),
          ),
        if (masthead)
          Positioned.fill(
            child: ColoredBox(
              color: const Color(0xFF000000),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: c.space6),
                  child: Column(key: const Key('press-masthead'), mainAxisSize: MainAxisSize.min, children: [
                    CineRoleText(title, c.typeMasthead, color: c.colorInk100, textAlign: TextAlign.center),
                    SizedBox(height: c.space3),
                    const CineOxfordRule(),
                  ],),
                ),
              ),
            ),
          ),
      ],),
    );
  }
}

/// Plays Stop the press on the root overlay, above everything.
class StopThePress {
  StopThePress._(this._entry, this._state);

  final OverlayEntry _entry;
  final _PressState _state;

  /// The switch's `outgoing`: forward for 500 ms (200 ms reduced), then resolves; the overlay is
  /// left in place because the restart replaces the whole tree.
  static Future<void> outgoing(BuildContext context) async {
    final p = _mount(context);
    await p._state.forward();
  }

  /// The debug dry run: forward, hold the black frame 600 ms, then reverse. With [failure] the
  /// error toast follows. Writes nothing and never restarts.
  static Future<void> dryRun(BuildContext context, {required void Function(String) onError, bool failure = false}) async {
    final p = _mount(context);
    await p._state.forward();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await p._state.back();
    p._entry.remove();
    if (failure) onError("Couldn't switch editions. Try again.");
  }

  static StopThePress _mount(BuildContext context) {
    final key = GlobalKey<_PressLayerState>();
    final reduced = CineMotion.reduced(context);
    final entry = OverlayEntry(builder: (_) => _PressLayer(key: key, reduced: reduced));
    Overlay.of(context, rootOverlay: true).insert(entry);
    // The state exists after the first frame; callers await forward() which waits for it.
    return StopThePress._(entry, _PressState.pending(key));
  }
}

class _PressState {
  _PressState.pending(this._key);
  final GlobalKey<_PressLayerState> _key;

  Future<_PressLayerState> _ready() async {
    while (_key.currentState == null) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    return _key.currentState!;
  }

  Future<void> forward() async => (await _ready()).forward();
  Future<void> back() async => (await _ready()).back();
}

class _PressLayer extends StatefulWidget {
  const _PressLayer({super.key, required this.reduced});
  final bool reduced;

  @override
  State<_PressLayer> createState() => _PressLayerState();
}

class _PressLayerState extends State<_PressLayer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  bool _reverse = false, _buzzed = false;

  int get _total => widget.reduced ? StopThePressTimeline.reducedMs : StopThePressTimeline.totalMs;

  Future<void> forward() async {
    _reverse = false;
    _buzzed = false;
    _c.duration = Duration(milliseconds: _total);
    final h = CineMotion.track(MotionName.stopThePress, _total);
    _c.addListener(_buzz);
    await _c.forward(from: 0);
    _c.removeListener(_buzz);
    h.end();
  }

  void _buzz() {
    final at = widget.reduced ? StopThePressTimeline.reducedMastheadMs : StopThePressTimeline.mastheadMs;
    if (!_buzzed && _c.value * _total >= at && mounted) {
      _buzzed = true;
      cineFeedback(context, HapticEvent.skinSwitch, sound: SoundEvent.skinSwitch);
    }
  }

  Future<void> back() async {
    _reverse = true;
    _c.duration = Duration(milliseconds: widget.reduced ? CineDur.clip.inMilliseconds : CineDur.clip.inMilliseconds);
    await _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AbsorbPointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) {
            final span = _reverse ? CineDur.clip.inMilliseconds : _total;
            final ms = _c.value * span;
            return StopThePressFrame(ms: ms, reverse: _reverse, reduced: widget.reduced);
          },
        ),
      );
}

