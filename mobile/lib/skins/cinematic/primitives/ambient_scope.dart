import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/tint.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

class _Ambient extends InheritedWidget {
  const _Ambient({required this.duo, required this.tint, required this.ink, required super.child});
  final Color duo, tint, ink;

  @override
  bool updateShouldNotify(_Ambient o) => o.duo != duo || o.tint != tint || o.ink != ink;
}

/// The series' three runtime colours, each dissolving over 800 ms (`durDissolve`, `turn`) when a
/// new [ambient] arrives (cinematic 2.1.5). Mount it only around what paints them, never at the
/// page root. Reduced motion swaps at once.
class CineAmbient extends StatelessWidget {
  const CineAmbient({super.key, this.ambient, required this.child});
  final AmbientRoles? ambient;
  final Widget child;

  static ({Color duo, Color tint, Color ink}) of(BuildContext context) {
    final a = context.dependOnInheritedWidgetOfExactType<_Ambient>();
    return a == null
        ? (duo: CineColors.ambientFallbackDuo, tint: CineColors.ambientFallbackTint, ink: CineColors.ambientFallbackInk)
        : (duo: a.duo, tint: a.tint, ink: a.ink);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final d = CineMotion.reduced(context) ? Duration.zero : c.durDissolve;
    Widget one(Color target, Widget Function(Color) build) => TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: target),
          duration: d,
          curve: c.easeTurn,
          builder: (_, v, __) => build(v ?? target),
        );
    return one(ambient?.duo ?? c.colorAmbientFallbackDuo, (duo) {
      return one(ambient?.tint ?? c.colorAmbientFallbackTint, (tint) {
        return one(ambient?.ink ?? c.colorAmbientFallbackInk, (ink) => _Ambient(duo: duo, tint: tint, ink: ink, child: child));
      });
    });
  }
}
