import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/badge.dart' show GlassPop;
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

/// The checkbox (glass 7.22): a 24 px squircle, radius 7. Off `fill1` with a 1.5 px `g600` border; on an `iris600`
/// fill with a white check whose stroke draws over 160 ms while the box pops 1, 1.12, 1 on `springTick`;
/// indeterminate (`value == null`) a white bar. Hit `hitMin`.
class GlassCheckbox extends ConsumerStatefulWidget {
  const GlassCheckbox({super.key, required this.value, required this.onChanged, required this.label, this.forceStates = GlassWidgetStates.none});

  /// true, false, or null for indeterminate.
  final bool? value;
  final ValueChanged<bool>? onChanged;
  final String label;
  final GlassWidgetStates forceStates;

  @override
  ConsumerState<GlassCheckbox> createState() => _GlassCheckboxState();
}

class _GlassCheckboxState extends ConsumerState<GlassCheckbox> with SingleTickerProviderStateMixin {
  late final AnimationController _draw = AnimationController(vsync: this, duration: const Duration(milliseconds: 160), value: widget.value == true ? 1 : 0);

  @override
  void didUpdateWidget(GlassCheckbox old) {
    super.didUpdateWidget(old);
    if (old.value == widget.value) return;
    if (ref.read(glassMotionPrefsProvider).reduced) {
      _draw.value = widget.value == true ? 1 : 0;
    } else if (widget.value == true) {
      _draw.forward(from: 0);
    } else {
      _draw.value = 0;
    }
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onChanged != null && !widget.forceStates.disabled;
    final v = widget.value;
    return Semantics(
      checked: v == true,
      mixed: v == null,
      label: widget.label,
      child: GlassPressable(
        material: GlassMaterial.content,
        growth: GlassGrowth.light,
        sink: 0.92,
        shape: GlassShape.superellipse(7),
        enabled: enabled,
        noSemantics: true,
        forceStates: widget.forceStates,
        haptic: v == true ? HapticEvent.toggleOff : HapticEvent.toggleOn,
        onTap: () => widget.onChanged?.call(v != true),
        builder: (context, info) => SizedBox.square(
          dimension: GlassFrame.hitMin(context),
          child: Center(
            child: Opacity(
              opacity: enabled ? 1 : 0.4,
              child: GlassPop(
                trigger: v ?? 'mixed',
                peak: 1.12,
                child: AnimatedBuilder(
                  animation: _draw,
                  builder: (context, _) => CustomPaint(
                    size: const Size.square(24),
                    painter: _BoxPainter(on: v != false, indeterminate: v == null, draw: _draw.value),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BoxPainter extends CustomPainter {
  const _BoxPainter({required this.on, required this.indeterminate, required this.draw});
  final bool on;
  final bool indeterminate;
  final double draw;

  @override
  void paint(Canvas canvas, Size size) {
    final box = RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(7)).getOuterPath(Offset.zero & size);
    if (on) {
      canvas.drawPath(box, Paint()..color = gt.colorIris600);
    } else {
      canvas.drawPath(box, Paint()..color = gt.colorFill1);
      canvas.drawPath(RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(7)).getOuterPath((Offset.zero & size).deflate(0.75)), Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5..color = GlassColors.g600);
    }
    final white = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (indeterminate) {
      canvas.drawLine(Offset(size.width * 0.3, size.height / 2), Offset(size.width * 0.7, size.height / 2), white);
    } else if (on) {
      final path = Path()
        ..moveTo(size.width * 0.27, size.height * 0.52)
        ..lineTo(size.width * 0.43, size.height * 0.68)
        ..lineTo(size.width * 0.74, size.height * 0.33);
      for (final m in path.computeMetrics()) {
        canvas.drawPath(m.extractPath(0, m.length * draw.clamp(0.0, 1.0)), white);
      }
    }
  }

  @override
  bool shouldRepaint(_BoxPainter old) => old.on != on || old.indeterminate != indeterminate || old.draw != draw;
}
