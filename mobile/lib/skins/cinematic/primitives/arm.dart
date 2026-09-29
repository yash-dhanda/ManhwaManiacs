import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_announce.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The destructive arm (cinematic 7.10) as a pure state machine over the time since the confirm
/// opened: the committing button is dead until [armedAt] (1000 ms, `dur.arm`), so the double tap
/// that opened a dialog can never confirm it.
class ArmState {
  const ArmState({this.armedAt = CineDur.arm});

  /// When the button becomes live, measured from the moment the confirm opened.
  final Duration armedAt;

  bool isArmed(Duration elapsed) => elapsed >= armedAt;

  /// 0..1 for the filling rule.
  double progress(Duration elapsed) => (elapsed.inMicroseconds / armedAt.inMicroseconds).clamp(0.0, 1.0);

  /// A heavy confirm also needs its [conditionMet] (typed phrase, checkbox, username).
  bool canConfirm(Duration elapsed, {bool conditionMet = true}) => isArmed(elapsed) && conditionMet;

  /// Whether a press at [elapsed] commits.
  bool press(Duration elapsed, {bool conditionMet = true}) => canConfirm(elapsed, conditionMet: conditionMet);
}

/// The committing button under the arm: disabled and `ink.30` while a 2 px `proof` rule fills
/// under it over 1000 ms (Arm), live and `proof` when full. [filled] is the final filled confirm
/// (fill `proof`, `#000` label). Reduced motion: no fill; the rule appears full at 1000 ms.
class CineArmButton extends StatefulWidget {
  const CineArmButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.destructive = true,
    this.filled = false,
    this.conditionMet = true,
    this.loading = false,
    this.focusNode,
    this.arm = const ArmState(),
  });

  final String label;
  final VoidCallback? onPressed;

  /// Non-destructive confirms pass false: no arm, a primary look.
  final bool destructive, filled, conditionMet, loading;
  final FocusNode? focusNode;
  final ArmState arm;

  @override
  State<CineArmButton> createState() => _CineArmButtonState();
}

class _CineArmButtonState extends State<CineArmButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  bool _started = false, _announced = false;

  Duration get _elapsed => Duration(microseconds: (_c.value * widget.arm.armedAt.inMicroseconds).round());
  bool get _armed => !widget.destructive || widget.arm.isArmed(_elapsed);
  bool get _live => _armed && widget.conditionMet && widget.onPressed != null && !widget.loading;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.destructive) {
      _c.addListener(_maybeAnnounce);
      CineMotion.play(MotionName.arm, _c, duration: widget.arm.armedAt, curve: CineCurves.linear, from: 0);
    } else {
      _c.value = 1;
    }
  }

  void _maybeAnnounce() {
    if (_announced || !mounted || !_live) return;
    _announced = true;
    cineAnnounce(context, 'Ready');
    setState(() {});
  }

  @override
  void didUpdateWidget(CineArmButton old) {
    super.didUpdateWidget(old);
    if (!old.conditionMet && widget.conditionMet) _maybeAnnounce();
    if (old.conditionMet && !widget.conditionMet) _announced = false;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _press() {
    if (!_live) return;
    cineFeedback(context, widget.destructive ? HapticEvent.deleteConfirm : HapticEvent.tapPrimary);
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final reduced = CineMotion.reduced(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final live = _live;
        final armed = _armed;
        final fillTo = reduced ? (armed ? 1.0 : 0.0) : widget.arm.progress(_elapsed);
        final Color fg;
        Color? bg;
        Color border;
        if (!widget.destructive) {
          bg = live ? c.colorInk100 : c.colorPaper3;
          fg = live ? const Color(0xFF000000) : c.colorInk30;
          border = const Color(0x00000000);
        } else if (live && widget.filled) {
          bg = c.colorProof;
          fg = const Color(0xFF000000);
          border = c.colorProof;
        } else {
          fg = live ? c.colorProof : c.colorInk30;
          border = live ? c.colorProof : c.colorInk30;
        }
        // Focusable but inert while arming: Enter and Space do nothing until it is live.
        Widget core = CinePressable(
          focusNode: widget.focusNode,
          onTap: _press,
          builder: (context, st) => Container(
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: c.space6),
            decoration: BoxDecoration(color: st.pressed && live ? c.colorProofWash : bg, border: Border.all(color: border)),
            child: CineRoleText(widget.label, c.typeLabel, color: fg, textAlign: TextAlign.center),
          ),
        );
        core = Stack(clipBehavior: Clip.none, children: [
          core,
          if (widget.loading) const Positioned(left: 0, right: 0, bottom: 0, child: IgnorePointer(child: CineIndeterminateRule(track: false))),
          if (widget.destructive && fillTo > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: -6,
              height: 2,
              child: IgnorePointer(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: fillTo,
                  child: ColoredBox(key: const Key('cine-arm-rule'), color: c.colorProof),
                ),
              ),
            ),
        ],);
        return Semantics(
          button: true,
          enabled: live,
          label: widget.label,
          value: widget.loading ? 'Loading' : null,
          excludeSemantics: true,
          onTap: live ? _press : null,
          child: Padding(padding: const EdgeInsets.only(bottom: 6), child: core),
        );
      },
    );
  }
}
