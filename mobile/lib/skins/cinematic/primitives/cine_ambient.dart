import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// The series' issue colours: `duo` (duotone), `tint` (page spill) and `ink`
/// (kicker, folios). DESIGN §2.1.5.
class CineAmbientColors {
  const CineAmbientColors({required this.duo, required this.tint, required this.ink});
  final Color duo, tint, ink;

  static CineAmbientColors fallback(CineTokens t) => CineAmbientColors(
        duo: t.colorAmbientFallbackDuo,
        tint: t.colorAmbientFallbackTint,
        ink: t.colorAmbientFallbackInk,
      );

  /// TODO(mobile/04): the series payload carries no `ambient` yet, so a
  /// stable hue is derived from the series key until it does.
  static CineAmbientColors forSeries(String key) {
    var h = 0;
    for (final u in key.codeUnits) {
      h = (h * 31 + u) & 0x7fffffff;
    }
    final hue = (h % 360).toDouble();
    return CineAmbientColors(
      duo: HSLColor.fromAHSL(1, hue, 0.35, 0.16).toColor(),
      tint: HSLColor.fromAHSL(1, hue, 0.30, 0.09).toColor(),
      ink: HSLColor.fromAHSL(1, hue, 0.45, 0.78).toColor(),
    );
  }

  static CineAmbientColors lerp(CineAmbientColors a, CineAmbientColors b, double t) =>
      CineAmbientColors(
        duo: Color.lerp(a.duo, b.duo, t)!,
        tint: Color.lerp(a.tint, b.tint, t)!,
        ink: Color.lerp(a.ink, b.ink, t)!,
      );
}

/// Dissolves from the neutral fallback to [target] over 800 ms `turn` when
/// the page opens (the signature moment) and exposes the running colours to
/// [builder]. Reduced motion: the colours swap at once.
class CineAmbient extends StatelessWidget {
  const CineAmbient({super.key, required this.target, required this.builder});

  final CineAmbientColors target;
  final Widget Function(BuildContext context, CineAmbientColors colors) builder;

  static CineAmbientColors of(BuildContext context) =>
      _Scope.maybeOf(context) ??
      CineAmbientColors.fallback(Theme.of(context).extension<CineTokens>()!);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<CineTokens>()!;
    final from = CineAmbientColors.fallback(t);
    if (MediaQuery.disableAnimationsOf(context)) {
      return _Scope(colors: target, child: Builder(builder: (c) => builder(c, target)));
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: CineDur.dissolve,
      curve: CineCurves.turn,
      builder: (context, v, _) {
        final c = CineAmbientColors.lerp(from, target, v);
        return _Scope(colors: c, child: Builder(builder: (ctx) => builder(ctx, c)));
      },
    );
  }
}

class _Scope extends InheritedWidget {
  const _Scope({required this.colors, required super.child});
  final CineAmbientColors colors;

  static CineAmbientColors? maybeOf(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<_Scope>()?.colors;

  @override
  bool updateShouldNotify(_Scope old) => old.colors.duo != colors.duo ||
      old.colors.tint != colors.tint ||
      old.colors.ink != colors.ink;
}
