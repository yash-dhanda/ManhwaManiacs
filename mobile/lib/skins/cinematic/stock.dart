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
  static Widget stock(CineStockColors colors, Widget child) =>
      _StockScope(colors: colors, child: _rescope(child, (c) => c.copyWith(colorInk45: colors.muted)));

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
