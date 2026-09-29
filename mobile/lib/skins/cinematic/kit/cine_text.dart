import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

// TODO(mobile/04..06): this `kit/` folder is the smallest local stand-in for the
// Cinematic primitives that steps mobile/04 (SetHeading, TypedHeadline, StatBlock,
// duotone, rules), mobile/05 (sheet, contents tabs, toast) and mobile/06 (Dip,
// shortcut registry) own. Mobile/21 only needs these behaviours, so each file
// here is deliberately small; swap the imports when those steps are integrated.

/// A [Text] set in a Cinematic type role with that role's text-scale cap.
class CineText extends StatelessWidget {
  const CineText(
    this.text,
    this.role, {
    super.key,
    this.color,
    this.maxLines,
    this.textAlign,
    this.overflow,
    this.semanticsLabel,
    this.features,
    this.excludeSemantics = false,
  });

  final String text;
  final CineTextRole role;
  final Color? color;
  final int? maxLines;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final String? semanticsLabel;
  final List<FontFeature>? features;
  final bool excludeSemantics;

  @override
  Widget build(BuildContext context) {
    final w = Text(
      role.upper ? text.toUpperCase() : text,
      style: cineStyle(context, role, color: color, features: features),
      textScaler: CineType.scaler(context, role),
      maxLines: maxLines,
      textAlign: textAlign,
      overflow: overflow,
      semanticsLabel: semanticsLabel,
    );
    return excludeSemantics ? ExcludeSemantics(child: w) : w;
  }
}

TextStyle cineStyle(BuildContext context, CineTextRole role, {Color? color, List<FontFeature>? features, double? size}) {
  final s = CineType.style(context, role);
  return s.copyWith(
    color: color ?? CineColors.ink100,
    fontFeatures: features,
    fontSize: size,
    height: size == null ? null : (s.height! * s.fontSize!) / size,
  );
}

/// 44 (iOS) or 48 (Android) logical pixels: the smallest hit target of §14.
double minHit(BuildContext context) => Theme.of(context).platform == TargetPlatform.iOS ? 44 : 48;

/// Lining and tabular figures (§3.1) for numerals.
const List<FontFeature> kNumeralFeatures = [FontFeature.liningFigures(), FontFeature.tabularFigures()];

bool cineReduced(BuildContext context) => MediaQuery.disableAnimationsOf(context);
