import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The three labelled tap-zone bands of the paged layouts (cinematic 8.14.7): `BACK · MENU ·
/// NEXT`, 1 px `ink.30` outlines, labels in `type.kicker`, held for `durHoldGlance` (1500 ms) and
/// faded over `durFadeHint` (1000 ms). Reduced motion fades in 150 ms after the hold. Pointer
/// transparent. [replay] restarts it (a changed zone layout, `Show zones`).
class TapZoneBands extends StatefulWidget {
  const TapZoneBands({super.key, required this.labels, required this.replay, this.onDone});

  /// Three labels, left to right.
  final List<String> labels;
  final int replay;
  final VoidCallback? onDone;

  @override
  State<TapZoneBands> createState() => _TapZoneBandsState();
}

class _TapZoneBandsState extends State<TapZoneBands> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  Duration _hold = Duration.zero, _fade = Duration.zero;

  void _run() {
    final c = context.cine;
    _hold = c.durHoldGlance;
    _fade = CineMotion.reduced(context) ? c.durReduced : c.durFadeHint;
    _c
      ..duration = _hold + _fade
      ..forward(from: 0).whenComplete(() {
        if (mounted) widget.onDone?.call();
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_c.isAnimating && _c.value == 0) _run();
  }

  @override
  void didUpdateWidget(covariant TapZoneBands old) {
    super.didUpdateWidget(old);
    if (old.replay != widget.replay) _run();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double get _opacity {
    final total = (_hold + _fade).inMilliseconds;
    if (total == 0) return 1;
    final t = _c.value * total;
    final h = _hold.inMilliseconds.toDouble();
    if (t <= h) return 1;
    return (1 - (t - h) / _fade.inMilliseconds).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            if (_c.isCompleted) return const SizedBox.shrink();
            return Opacity(
              opacity: _opacity,
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    Expanded(
                      flex: i == 1 ? 40 : 30,
                      child: DecoratedBox(
                        key: ValueKey('zone-band-$i'),
                        decoration: BoxDecoration(color: const Color(0x66000000), border: Border.all(color: c.colorInk30)),
                        child: Center(child: CineRoleText(widget.labels[i], c.typeKicker, color: c.colorInk80)),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
