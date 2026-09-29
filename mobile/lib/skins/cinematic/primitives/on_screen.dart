import 'dart:math' as math;

import 'package:flutter/material.dart';

/// How much of [box] is inside a screen [screenHeight] tall, in px (0 when off screen).
double visiblePixels(RenderBox box, double screenHeight) {
  if (!box.hasSize || !box.attached) return 0;
  final top = box.localToGlobal(Offset.zero).dy, h = box.size.height;
  return (math.min(top + h, screenHeight) - math.max(top, 0.0)).clamp(0.0, h);
}

/// Reports whether its box intersects the viewport, following the nearest [ScrollPosition]. Loops
/// (the streak flame, Drift) wrap themselves in `TickerMode(enabled: onScreen)` from it.
class OnScreen extends StatefulWidget {
  const OnScreen({super.key, required this.builder});
  final Widget Function(BuildContext context, bool onScreen) builder;

  @override
  State<OnScreen> createState() => _OnScreenState();
}

class _OnScreenState extends State<OnScreen> {
  ScrollPosition? _pos;
  bool _on = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pos?.removeListener(_check);
    _pos = Scrollable.maybeOf(context)?.position;
    _pos?.addListener(_check);
  }

  void _check() {
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return;
    final on = visiblePixels(box, MediaQuery.sizeOf(context).height) > 0;
    if (on != _on) setState(() => _on = on);
  }

  @override
  void dispose() {
    _pos?.removeListener(_check);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _on);
}
