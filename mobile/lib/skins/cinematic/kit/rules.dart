import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/cine_text.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// A rule drawn left to right (Rule draw, 480 ms `durSpread` on `settle`).
/// Reduced motion: present at rest.
class DrawnRule extends StatefulWidget {
  const DrawnRule({
    super.key,
    this.height = 3,
    this.color = CineColors.ink100,
    this.delay = Duration.zero,
    this.duration = CineDur.spread,
    this.animate = true,
  });

  final double height;
  final Color color;
  final Duration delay;
  final Duration duration;
  final bool animate;

  @override
  State<DrawnRule> createState() => _DrawnRuleState();
}

class _DrawnRuleState extends State<DrawnRule> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!widget.animate || cineReduced(context)) {
      _c.value = 1;
      return;
    }
    _c.duration = widget.delay + widget.duration;
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final total = _c.duration?.inMilliseconds ?? 0;
            final t = total == 0 ? 1.0 : ((_c.value * total - widget.delay.inMilliseconds) / widget.duration.inMilliseconds).clamp(0.0, 1.0);
            return Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: CineCurves.settle.transform(t),
                child: SizedBox(height: widget.height, child: ColoredBox(color: widget.color)),
              ),
            );
          },
        ),
      );
}

/// A determinate rule of [value] (0..1): track `rule.1`, fill `spot`, 2 px (§7.18).
class ShareRule extends StatelessWidget {
  const ShareRule({super.key, required this.value, this.height = 2, this.fill = CineColors.spot, this.track = CineColors.rule1});

  final double value;
  final double height;
  final Color fill;
  final Color track;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox(
          height: height,
          child: Stack(fit: StackFit.expand, children: [
            ColoredBox(color: track),
            Align(alignment: Alignment.centerLeft, child: FractionallySizedBox(widthFactor: value.clamp(0.0, 1.0), child: ColoredBox(color: fill))),
          ],),
        ),
      );
}

/// A 1 px hairline.
class HairRule extends StatelessWidget {
  const HairRule({super.key, this.color = CineColors.rule1, this.height = 1});
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(child: SizedBox(height: height, width: double.infinity, child: ColoredBox(color: color)));
}

/// An indeterminate rule (the Annual's loading state): a `spot` segment sliding across.
class IndeterminateRule extends StatefulWidget {
  const IndeterminateRule({super.key});
  @override
  State<IndeterminateRule> createState() => _IndeterminateRuleState();
}

class _IndeterminateRuleState extends State<IndeterminateRule> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: CineDur.loopRule)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox(
          height: 2,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => Stack(fit: StackFit.expand, children: [
              const ColoredBox(color: CineColors.rule1),
              Align(
                alignment: Alignment(-1 + 2 * _c.value, 0),
                child: const FractionallySizedBox(widthFactor: 0.25, child: ColoredBox(color: CineColors.spot)),
              ),
            ],),
          ),
        ),
      );
}
