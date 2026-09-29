import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// `STRIP | SINGLE | DOUBLE` (cinematic 7.5): labels divided by 1 px rules in a 1 px frame 40 px
/// tall, the hit grown to 44/48. A 2 px `spot` underline slides under the active segment.
class CineSegmentedControl extends StatelessWidget {
  const CineSegmentedControl({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.disabledReasons = const {},
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  /// Disabled segments by index, with the tooltip saying why ("Height fit needs a paged layout").
  final Map<int, String> disabledReasons;

  bool _enabled(int i) => !disabledReasons.containsKey(i);

  void _move(BuildContext context, int dir) {
    var i = index;
    for (var step = 0; step < labels.length; step++) {
      i = (i + dir + labels.length) % labels.length;
      if (_enabled(i)) {
        _select(context, i);
        return;
      }
    }
  }

  void _select(BuildContext context, int i) {
    if (i == index) return;
    cineFeedback(context, HapticEvent.select, sound: SoundEvent.select);
    onChanged(i);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final reduced = CineMotion.reduced(context);
    final hit = cineHitMin(context);
    return Focus(
      canRequestFocus: false,
      onKeyEvent: (_, e) {
        if (e is! KeyDownEvent) return KeyEventResult.ignored;
        if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
          _move(context, 1);
          return KeyEventResult.handled;
        }
        if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _move(context, -1);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: hit),
        child: Center(
          child: Container(
            height: 40,
            decoration: BoxDecoration(border: Border.all(color: c.colorRule2)),
            child: LayoutBuilder(builder: (context, box) {
              final w = box.maxWidth / labels.length;
              return Stack(children: [
                Row(children: [
                  for (var i = 0; i < labels.length; i++) ...[
                    if (i > 0) Container(width: 1, color: c.colorRule2),
                    Expanded(child: _segment(context, c, i)),
                  ],
                ],),
                AnimatedPositioned(
                  key: const Key('segment-underline'),
                  duration: reduced ? Duration.zero : c.durColumn,
                  curve: c.easeSettle,
                  left: index * w + 8,
                  width: w - 16,
                  bottom: 4,
                  height: 2,
                  child: IgnorePointer(child: ColoredBox(color: c.colorSpot)),
                ),
              ],);
            },),
          ),
        ),
      ),
    );
  }

  Widget _segment(BuildContext context, CineTokens c, int i) {
    final on = i == index;
    final enabled = _enabled(i);
    final seg = Semantics(
      button: true,
      selected: on,
      enabled: enabled,
      label: labels[i],
      excludeSemantics: true,
      onTap: enabled ? () => _select(context, i) : null,
      child: CinePressable(
        hit: false,
        enabled: enabled,
        onTap: () => _select(context, i),
        builder: (_, st) => Center(
          child: CineRoleText(
            labels[i],
            c.typeNav,
            color: !enabled ? c.colorInk30 : (on || st.hovered ? c.colorInk100 : c.colorInk45),
            upper: true,
            fixedCell: true,
          ),
        ),
      ),
    );
    return enabled ? seg : Tooltip(message: disabledReasons[i], child: seg);
  }
}
