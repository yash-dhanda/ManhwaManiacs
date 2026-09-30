import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// Re-provides [CineTokens] with the given overrides for the subtree (cinematic 2.1.1, 14.4).
Widget _rescope(Widget child, CineTokens Function(CineTokens) remap) => Builder(builder: (context) {
      final theme = Theme.of(context);
      final cine = context.cine;
      return Theme(
        data: theme.copyWith(extensions: [
          for (final e in theme.extensions.values)
            if (e is! CineTokens) e,
          remap(cine),
        ],),
        child: child,
      );
    },);

/// The three colours of a reader page stock: page, ink and muted ink (cinematic 2.1.6).
@immutable
class CineStockColors {
  const CineStockColors(this.page, this.ink, this.muted);
  final Color page, ink, muted;

  @override
  bool operator ==(Object other) => other is CineStockColors && other.page == page && other.ink == ink && other.muted == muted;

  @override
  int get hashCode => Object.hash(page, ink, muted);
}

class _StockScope extends InheritedWidget {
  const _StockScope({required this.colors, required super.child});
  final CineStockColors colors;

  @override
  bool updateShouldNotify(_StockScope old) => old.colors != colors;
}

/// Grounds other than `paper.0` remap the tokens whose contrast would fail there.
abstract final class CineStock {
  /// `paper.1`-`paper.4`, mood grades: `ink.45` reads as `ink.60` inside.
  static Widget raised(Widget child) => _rescope(child, (c) => c.copyWith(colorInk45: c.colorInk60));

  /// A novel page stock (cinematic 2.1.6): everything below paints from [colors], and every
  /// `ink.45` role renders the stock's muted ink (2.1.1).
  ///
  /// The surface and ink tokens are re-provided from the stock (paper.0-4 read as the page, ink.100
  /// as the ink, ink.60 and ink.45 as the muted ink, rules as the muted ink at 30 % / 50 %), so a
  /// sheet, a panel or a toast built from tokens paints in the stock with no per-widget colour.
  static Widget stock(CineStockColors colors, Widget child) => _StockScope(
        colors: colors,
        child: _rescope(
          child,
          (c) => c.copyWith(
            colorPaper0: colors.page,
            colorPaper1: colors.page,
            colorPaper2: colors.page,
            colorPaper3: Color.lerp(colors.page, colors.muted, 0.18),
            colorPaper4: Color.lerp(colors.page, colors.muted, 0.28),
            colorInk100: colors.ink,
            colorInk80: Color.lerp(colors.ink, colors.muted, 0.4),
            colorInk60: colors.muted,
            colorInk45: colors.muted,
            colorRule1: colors.muted.withValues(alpha: 0.3),
            colorRule2: colors.muted.withValues(alpha: 0.5),
          ),
        ),
      );

  /// The stock in effect, or null outside a novel page.
  static CineStockColors? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_StockScope>()?.colors;

  /// The stock in effect; Nitrate outside a novel page.
  static CineStockColors of(BuildContext context) =>
      maybeOf(context) ??
      const CineStockColors(CineColors.stockNitratePage, CineColors.stockNitrateInk, CineColors.stockNitrateMuted);

  /// `spot.wash`, `proof.wash`: `ink.45` and `ink.60` both read as `ink.80`.
  static Widget wash(Widget child) => _rescope(child, (c) => c.copyWith(colorInk45: c.colorInk80, colorInk60: c.colorInk80));
}

/// High contrast (14.4): `ink.45` -> `ink.80`, `rule.1` -> `rule.2`.
class CineContrastScope extends StatelessWidget {
  const CineContrastScope({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!MediaQuery.highContrastOf(context)) return child;
    return _rescope(child, (c) => c.copyWith(colorInk45: c.colorInk80, colorRule1: c.colorRule2));
  }
}
