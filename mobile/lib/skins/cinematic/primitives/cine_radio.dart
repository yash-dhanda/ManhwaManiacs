import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The radio (cinematic 7.21): a 20 px circle (round is allowed here), 1 px `ink.45`, selected a
/// 10 px `ink.100` dot; 120 ms; hit 44/48.
class CineRadio<T> extends StatelessWidget {
  const CineRadio({super.key, required this.value, required this.groupValue, required this.onChanged, this.label, this.semanticLabel});

  final T value;
  final T? groupValue;
  final ValueChanged<T>? onChanged;
  final String? label, semanticLabel;

  bool get _selected => value == groupValue;

  void _pick(BuildContext context) {
    if (_selected) return;
    cineFeedback(context, HapticEvent.select);
    onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final enabled = onChanged != null;
    final reduced = CineMotion.reduced(context);
    Widget disc(CinePressState st) => AnimatedContainer(
          duration: reduced ? Duration.zero : (st.hovered ? c.durTick : c.durSnap),
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: !enabled ? c.colorRule1 : (st.hovered || st.focused || _selected ? c.colorInk100 : c.colorInk45)),
          ),
          child: AnimatedContainer(
            duration: reduced ? Duration.zero : c.durSnap,
            width: _selected ? 10 : 0,
            height: _selected ? 10 : 0,
            decoration: BoxDecoration(shape: BoxShape.circle, color: enabled ? c.colorInk100 : c.colorInk30),
          ),
        );
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: _selected,
      enabled: enabled,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      onTap: enabled ? () => _pick(context) : null,
      child: CinePressable(
        enabled: enabled,
        round: label == null,
        onTap: () => _pick(context),
        builder: (context, st) => label == null
            ? disc(st)
            : Row(mainAxisSize: MainAxisSize.min, children: [
                disc(st),
                SizedBox(width: c.space3),
                Flexible(child: CineRoleText(label!, c.typeBody, color: enabled ? c.colorInk100 : c.colorInk30)),
              ],),
      ),
    );
  }
}
