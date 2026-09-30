import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// Whether the wide (tablet) layout applies: 8 columns from 600 px.
bool onboardingWide(BuildContext context) => MediaQuery.sizeOf(context).width >= 600;

/// The 2 px `spot` inset frame of a selected tile, painted over the child.
class SelectFrame extends StatelessWidget {
  const SelectFrame({super.key, required this.selected, required this.child});
  final bool selected;
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(border: selected ? Border.all(width: 2, color: context.cine.colorSpot) : null),
        child: child,
      );
}

/// The 1 px impression of a pressed plate: down over 80 ms `set`, back over 160 ms `settle`.
class Impression extends StatelessWidget {
  const Impression({super.key, required this.pressed, required this.child});
  final bool pressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduced = CineMotion.reduced(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: pressed ? 1 : 0),
      duration: reduced ? Duration.zero : (pressed ? const Duration(milliseconds: 80) : const Duration(milliseconds: 160)),
      curve: pressed ? CineCurves.easeSet : CineCurves.settle,
      builder: (_, v, c) => Transform.translate(offset: Offset(0, v), child: c),
      child: child,
    );
  }
}

/// Arrow keys, Home and End inside a roving group. [scope] holds the group's focusables; the
/// handler returns `handled` for keys it used, so `←` / `→` reach the page's Back and Next only
/// from outside the group.
KeyEventResult rovingKey(FocusNode node, KeyEvent e, {required FocusScopeNode scope, bool grid = false}) {
  if (e is KeyUpEvent) return KeyEventResult.ignored;
  final k = e.logicalKey;
  bool go(TraversalDirection d) => grid ? node.focusInDirection(d) : (d == TraversalDirection.left || d == TraversalDirection.up ? node.previousFocus() : node.nextFocus());
  if (k == LogicalKeyboardKey.arrowRight) return go(TraversalDirection.right) ? KeyEventResult.handled : KeyEventResult.handled;
  if (k == LogicalKeyboardKey.arrowLeft) return go(TraversalDirection.left) ? KeyEventResult.handled : KeyEventResult.handled;
  if (k == LogicalKeyboardKey.arrowDown) return go(TraversalDirection.down) ? KeyEventResult.handled : KeyEventResult.handled;
  if (k == LogicalKeyboardKey.arrowUp) return go(TraversalDirection.up) ? KeyEventResult.handled : KeyEventResult.handled;
  if (k == LogicalKeyboardKey.home || k == LogicalKeyboardKey.end) {
    final l = scope.traversalDescendants.where((n) => n.canRequestFocus).toList();
    if (l.isEmpty) return KeyEventResult.ignored;
    (k == LogicalKeyboardKey.home ? l.first : l.last).requestFocus();
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
}
