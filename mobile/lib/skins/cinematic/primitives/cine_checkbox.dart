import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

class _CheckPainter extends CustomPainter {
  const _CheckPainter(this.color, this.dash);
  final Color color;
  final bool dash;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;
    if (dash) {
      canvas.drawLine(Offset(size.width / 2 - 5, size.height / 2), Offset(size.width / 2 + 5, size.height / 2), p);
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(size.width * 0.24, size.height * 0.52)
          ..lineTo(size.width * 0.43, size.height * 0.70)
          ..lineTo(size.width * 0.77, size.height * 0.31),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_CheckPainter o) => o.color != color || o.dash != dash;
}

/// The checkbox (cinematic 7.21): a 20 px square, 1 px `ink.45` outline; checked fills `ink.100`
/// with a drawn `#000` check, indeterminate (a null [value]) with a 10 x 2 dash. 120 ms fill.
class CineCheckbox extends StatelessWidget {
  const CineCheckbox({super.key, required this.value, required this.onChanged, this.label, this.semanticLabel});

  /// `true`, `false`, or `null` for indeterminate.
  final bool? value;
  final ValueChanged<bool>? onChanged;

  /// A visible label after the box; tapping it toggles too.
  final String? label;
  final String? semanticLabel;

  void _toggle(BuildContext context) {
    cineFeedback(context, HapticEvent.select);
    onChanged?.call(!(value ?? false));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final enabled = onChanged != null;
    final reduced = CineMotion.reduced(context);
    Widget box(CinePressState st) {
      final on = value ?? true;
      final outline = !enabled ? c.colorRule1 : (st.hovered || st.focused ? c.colorInk100 : c.colorInk45);
      return AnimatedContainer(
        duration: reduced ? Duration.zero : (st.hovered ? c.durTick : c.durSnap),
        width: 20,
        height: 20,
        decoration: BoxDecoration(color: on ? (enabled ? c.colorInk100 : c.colorInk30) : const Color(0x00000000), border: Border.all(color: on ? const Color(0x00000000) : outline)),
        child: on ? CustomPaint(painter: _CheckPainter(const Color(0xFF000000), value == null)) : null,
      );
    }

    final visible = CinePressable(
      enabled: enabled,
      onTap: () => _toggle(context),
      builder: (context, st) => label == null
          ? box(st)
          : Row(mainAxisSize: MainAxisSize.min, children: [
              box(st),
              SizedBox(width: c.space3),
              Flexible(child: CineRoleText(label!, c.typeBody, color: enabled ? c.colorInk100 : c.colorInk30)),
            ],),
    );
    return Semantics(
      checked: value ?? false,
      mixed: value == null,
      enabled: enabled,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      onTap: enabled ? () => _toggle(context) : null,
      child: visible,
    );
  }
}
