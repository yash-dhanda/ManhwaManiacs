import 'dart:async';

import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

enum SetTrigger { signal, mount }

/// Type role step-down for long titles (DESIGN §3.1): one role smaller past 24
/// graphemes, two past 40. [sizes] runs largest to smallest.
double setHeadingSize(String text, List<double> sizes) {
  final n = text.characters.length;
  final step = n > 40 ? 2 : (n > 24 ? 1 : 0);
  return sizes[step.clamp(0, sizes.length - 1)];
}

/// A heading whose letters set one after another (Letter set, 640 ms each,
/// 24 ms apart). With [SetTrigger.signal] it starts when the route animation
/// completes (480 ms after a match cut), or 160 ms after the first frame when
/// there is none. It never reads or writes the seen set. Reduced motion: a
/// 200 ms fade. TODO(mobile/04): replaced by the shared primitive.
class SetHeading extends StatefulWidget {
  const SetHeading(
    this.text, {
    super.key,
    required this.style,
    this.level = 1,
    this.trigger = SetTrigger.signal,
    this.startDelay,
    this.maxLines,
  });

  final String text;
  final TextStyle style;
  final int level;
  final SetTrigger trigger;
  final Duration? startDelay;
  final int? maxLines;

  @override
  State<SetHeading> createState() => _SetHeadingState();
}

class _SetHeadingState extends State<SetHeading> with SingleTickerProviderStateMixin {
  static const _stagger = Duration(milliseconds: 24);
  late final AnimationController _c = AnimationController(vsync: this);
  Timer? _timer;
  Animation<double>? _route;
  bool _started = false;

  Duration get _total {
    final n = widget.text.characters.length;
    return CineDur.letter + _stagger * (n > 0 ? n - 1 : 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _started = true;
      _c
        ..duration = const Duration(milliseconds: 200)
        ..forward();
      return;
    }
    _c.duration = _total;
    final route = ModalRoute.of(context)?.animation;
    if (widget.trigger == SetTrigger.signal && route != null && route.value < 1) {
      _route = route..addStatusListener(_onRoute);
    } else {
      _timer = Timer(widget.startDelay ?? const Duration(milliseconds: 160), _go);
      _started = true;
    }
  }

  void _onRoute(AnimationStatus s) {
    if (s == AnimationStatus.completed && !_started) {
      _started = true;
      _go();
    }
  }

  void _go() {
    if (mounted) _c.forward();
  }

  @override
  void dispose() {
    _route?.removeStatusListener(_onRoute);
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final letters = widget.text.characters.toList();
    return Semantics(
      header: true,
      headingLevel: widget.level,
      label: widget.text,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final base = widget.style.color ?? Colors.white;
          if (reduced) {
            return Text(widget.text,
                maxLines: widget.maxLines,
                style: widget.style.copyWith(color: base.withValues(alpha: _c.value)),);
          }
          final ms = _c.value * _total.inMilliseconds;
          return Text.rich(
            TextSpan(
              children: [
                for (var i = 0; i < letters.length; i++)
                  TextSpan(
                    text: letters[i],
                    style: TextStyle(
                      color: base.withValues(
                        alpha: CineCurves.settle
                            .transform(((ms - i * _stagger.inMilliseconds) /
                                    CineDur.letter.inMilliseconds)
                                .clamp(0.0, 1.0),),
                      ),
                    ),
                  ),
              ],
            ),
            maxLines: widget.maxLines,
            style: widget.style,
          );
        },
      ),
    );
  }
}
