import 'dart:async';

import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The "slug switch" (cinematic 7.21): a 44 x 24 rectangle, 1 px `ink.45` outline, a 16 x 16 square
/// knob inset 4 px. On, the track fills `spot` and the knob turns `#000`. The knob slides in 160 ms
/// `easeSet` and widens to 20 px while pressed (a squash, not a bounce).
///
/// [onChanged] may return a `Future` (server-backed switches such as 18+ or notify): the switch
/// shows the new value at once with a 12 px leader dial for a knob and announces "Loading"; if the
/// future throws it reverts, the outline turns `proof` for 2000 ms and an error line appears.
class CineSwitch extends StatefulWidget {
  const CineSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.errorLine = 'That didn’t save. Try again.',
    this.disabledReason,
  });

  final bool value;
  final FutureOr<void> Function(bool)? onChanged;

  /// The accessible name (the row label).
  final String? label;
  final String errorLine;
  final String? disabledReason;

  @override
  State<CineSwitch> createState() => _CineSwitchState();
}

class _CineSwitchState extends State<CineSwitch> {
  bool? _optimistic;
  bool _loading = false, _error = false;
  Timer? _errTimer;

  bool get _on => _optimistic ?? widget.value;

  @override
  void didUpdateWidget(CineSwitch old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && !_loading) _optimistic = null;
  }

  @override
  void dispose() {
    _errTimer?.cancel();
    super.dispose();
  }

  Future<void> _toggle() async {
    final cb = widget.onChanged;
    if (cb == null || _loading) return;
    final next = !_on;
    cineFeedback(context, next ? HapticEvent.toggleOn : HapticEvent.toggleOff, sound: next ? SoundEvent.toggleOn : SoundEvent.toggleOff);
    setState(() {
      _optimistic = next;
      _error = false;
    });
    try {
      final r = cb(next);
      if (r is Future<void>) {
        setState(() => _loading = true);
        await r;
      }
      if (mounted) {
        setState(() {
          _loading = false;
          _optimistic = null;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _optimistic = null;
        _error = true;
      });
      _errTimer?.cancel();
      _errTimer = Timer(CineDur.holdError, () {
        if (mounted) setState(() => _error = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final enabled = widget.onChanged != null;
    final reduced = CineMotion.reduced(context);
    Widget sw(CinePressState st) {
      final on = _on;
      final outline = _error
          ? c.colorProof
          : !enabled
              ? c.colorRule1
              : (on ? c.colorSpot : (st.hovered || st.focused ? c.colorInk100 : c.colorInk45));
      final w = st.pressed && enabled ? 20.0 : 16.0;
      final left = on ? 44 - 4 - w : 4.0;
      final knob = !enabled ? c.colorInk30 : (on ? const Color(0xFF000000) : c.colorInk45);
      final d = reduced ? Duration.zero : CineDur.beat;
      return AnimatedContainer(
        duration: d,
        curve: CineCurves.easeSet,
        width: 44,
        height: 24,
        decoration: BoxDecoration(color: on && enabled ? c.colorSpot : const Color(0x00000000), border: Border.all(color: outline)),
        child: Stack(children: [
          AnimatedPositioned(
            duration: d,
            curve: CineCurves.easeSet,
            left: left - 1,
            top: 3,
            width: w,
            height: 16,
            child: _loading ? const Center(child: CineLeaderDial(size: 12, showAfter: Duration.zero)) : ColoredBox(key: const Key('cine-switch-knob'), color: knob),
          ),
        ],),
      );
    }

    Widget core = CinePressable(enabled: enabled && !_loading, onTap: _toggle, builder: (context, st) => sw(st));
    core = Semantics(
      toggled: _on,
      enabled: enabled,
      label: widget.label,
      value: _loading ? 'Loading' : null,
      excludeSemantics: true,
      onTap: enabled && !_loading ? _toggle : null,
      child: core,
    );
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
      core,
      if (_error) Semantics(liveRegion: true, child: CineRoleText(widget.errorLine, c.typeCaption, color: c.colorProof)),
    ],);
  }
}
