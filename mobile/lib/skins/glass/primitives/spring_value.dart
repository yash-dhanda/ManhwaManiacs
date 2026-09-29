import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/token_types.g.dart';
import 'package:motor/motor.dart';

/// Follows [value] on a spring through a `motor` [SingleMotionController]; the builder gets the live value
/// and its velocity, so a jump can slosh (the liquid meniscus) and a catch keeps its momentum. Under
/// reduced motion the value jumps (glass 4.11).
class SpringValue extends ConsumerStatefulWidget {
  const SpringValue({super.key, required this.value, required this.spring, required this.builder, this.name});

  final double value;
  final SpringToken spring;
  final MotionName? name;
  final Widget Function(BuildContext context, double value, double velocity) builder;

  @override
  ConsumerState<SpringValue> createState() => _SpringValueState();
}

class _SpringValueState extends ConsumerState<SpringValue> with SingleTickerProviderStateMixin {
  late final SingleMotionController _c = SingleMotionController(
    motion: SpringMotion(springOf(widget.spring)),
    vsync: this,
    initialValue: widget.value,
  );

  @override
  void didUpdateWidget(SpringValue old) {
    super.didUpdateWidget(old);
    if (old.value == widget.value) return;
    if (ref.read(glassMotionPrefsProvider).reduced) {
      _c.stop();
      _c.value = widget.value;
    } else if (widget.name != null) {
      GlassMotion.playMotor(widget.name!, _c, widget.value, withVelocity: _c.velocity);
    } else {
      _c.motion = SpringMotion(springOf(widget.spring));
      _c.animateTo(widget.value, withVelocity: _c.velocity);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _c, builder: (context, _) => widget.builder(context, _c.value, _c.velocity));
}
