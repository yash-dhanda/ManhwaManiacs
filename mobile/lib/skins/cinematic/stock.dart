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

/// Grounds other than `paper.0` remap the tokens whose contrast would fail there.
abstract final class CineStock {
  /// `paper.1`-`paper.4`, mood grades: `ink.45` reads as `ink.60` inside.
  static Widget raised(Widget child) => _rescope(child, (c) => c.copyWith(colorInk45: c.colorInk60));

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
