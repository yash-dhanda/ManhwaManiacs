import 'package:flutter/physics.dart' show SpringSimulation;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The Stepper (glass 7.3): two 36 px `fill2` circles (`wellOnGlass` inside T4 and T5 glass) with a minus and a
/// plus, the value in `mono` 15/20 between them (min width 64), each with a `hitMin` hit. Past a limit the value text
/// stretches 4 px toward the pressed side and springs back, with `detent.limit`.
class GlassStepper extends ConsumerStatefulWidget {
  const GlassStepper({super.key, required this.value, required this.onChanged, required this.label, this.min = 0, this.max = 100, this.step = 1, this.format});
  final int value;
  final ValueChanged<int> onChanged;
  final String label;
  final int min;
  final int max;
  final int step;
  final String Function(int value)? format;

  @override
  ConsumerState<GlassStepper> createState() => _GlassStepperState();
}

class _GlassStepperState extends ConsumerState<GlassStepper> with SingleTickerProviderStateMixin {
  late final AnimationController _stretch = AnimationController.unbounded(vsync: this, value: 0);

  @override
  void dispose() {
    _stretch.dispose();
    super.dispose();
  }

  void _press(int dir) {
    final next = widget.value + dir * widget.step;
    if (next < widget.min || next > widget.max) {
      glassFire(ref, HapticEvent.detentLimit);
      if (!ref.read(glassMotionPrefsProvider).reduced) {
        _stretch.animateWith(SpringSimulation(springOf(gt.springTick), 4.0 * dir, 0, 0));
      }
      return;
    }
    glassFire(ref, HapticEvent.detentTick);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final hit = GlassFrame.hitMin(context);
    final onGlassHost = GlassHost.of(context);
    final text = widget.format?.call(widget.value) ?? '${widget.value}';
    Widget button(int dir, IconData icon, String label) => GlassPressable(
          material: GlassMaterial.content,
          growth: GlassGrowth.light,
          sink: 0.92,
          shape: const GlassShape.circle(),
          onTap: () => _press(dir),
          semanticsLabel: label,
          builder: (context, info) => SizedBox.square(
            dimension: hit,
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(color: onGlassHost ? gt.colorWellOnGlass : gt.colorFill2, shape: BoxShape.circle),
                child: SizedBox.square(dimension: 36, child: Center(child: Icon(icon, size: 18, color: gt.colorOnGlass))),
              ),
            ),
          ),
        );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      value: text,
      increasedValue: '${widget.value + widget.step > widget.max ? widget.max : widget.value + widget.step}',
      decreasedValue: '${widget.value - widget.step < widget.min ? widget.min : widget.value - widget.step}',
      onIncrease: () => _press(1),
      onDecrease: () => _press(-1),
      label: widget.label,
      child: Focus(
        skipTraversal: true,
        onKeyEvent: (n, e) {
          if (e is! KeyDownEvent) return KeyEventResult.ignored;
          if (e.logicalKey == LogicalKeyboardKey.arrowUp) {
            _press(1);
            return KeyEventResult.handled;
          }
          if (e.logicalKey == LogicalKeyboardKey.arrowDown) {
            _press(-1);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            button(-1, GlassGlyph.minus.bold, 'Decrease ${widget.label}'),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 64),
              child: AnimatedBuilder(
                animation: _stretch,
                builder: (context, _) => Transform.translate(
                  offset: Offset(_stretch.value, 0),
                  child: Transform.scale(
                    key: const ValueKey('glass-stepper-value'),
                    scaleX: 1 + _stretch.value.abs() / 24,
                    child: Center(widthFactor: 1, child: GlassText(text, role: gt.typeMono, size: 15, height: 20, onGlass: true, textAlign: TextAlign.center)),
                  ),
                ),
              ),
            ),
            button(1, GlassGlyph.plus.bold, 'Increase ${widget.label}'),
          ],
        ),
      ),
    );
  }
}
