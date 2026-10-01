import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/axes.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

/// Resolves a [GlassTypeRole] to a [TextStyle] for the current frame (glass 3.3 to 3.7).
///
/// The generated `GlassType` (tokens.g.dart) keeps its base helpers; this adds the frame, text scale,
/// Legible text and the material-aware axes. It is named `GlassTypeStyle` because a second `GlassType`
/// would collide with the generated one, which cannot be edited outside `design/`.
abstract final class GlassTypeStyle {
  static const String legibleFamily = 'AtkinsonHyperlegibleNext';
  static const double legibleTrackingEm = 0.01;

  static FontWeight _weight(double wght) => FontWeight.values[((wght / 100).round() - 1).clamp(0, 8)];

  /// The scaled, capped size (`min(base x scaler, cap)`, never below the role's floor).
  static double scaledSize(BuildContext context, GlassTypeRole role, {double? size, double maxScale = double.infinity}) {
    final base = size ?? role.at(GlassFrame.of(context).index).$1;
    final cap = role.capAt;
    var v = MediaQuery.textScalerOf(context).scale(base);
    if (maxScale.isFinite) v = math.min(v, base * maxScale);
    if (cap != null) v = math.min(v, cap);
    return math.max(v, role.floor ?? 0);
  }

  /// The largest scale factor the role allows (capAt / base size).
  static double maxScaleFor(BuildContext context, GlassTypeRole role) {
    final cap = role.capAt;
    return cap == null ? double.infinity : cap / role.at(GlassFrame.of(context).index).$1;
  }

  static TextStyle style(
    BuildContext context,
    GlassTypeRole role, {
    bool onGlass = false,
    bool legible = false,
    int? wght,
    double? size,
    double? height,
    double maxScale = double.infinity,
  }) {
    final (baseSize, baseLine) = role.at(GlassFrame.of(context).index);
    final rendered = scaledSize(context, role, size: size, maxScale: maxScale);
    final swap = legible && !role.isMono;
    var w = (wght ?? role.wght).toDouble();
    if (MediaQuery.boldTextOf(context)) w = math.min(w + 100, 800);
    final axes = onGlass ? GlassTextAxes.of(context) : null;
    final lineRatio = height != null ? height / (size ?? baseSize) : baseLine / baseSize;
    final tracking = role.trackingEm + (swap ? legibleTrackingEm : 0);
    return TextStyle(
      fontFamily: swap ? legibleFamily : role.family,
      fontSize: rendered,
      height: lineRatio,
      letterSpacing: tracking * rendered,
      fontWeight: _weight(w),
      decoration: TextDecoration.none,
      fontVariations: [
        FontVariation('wght', w),
        if (!role.isMono) ...[
          FontVariation('opsz', rendered),
          FontVariation('ROND', axes?.rond ?? role.rond ?? 0),
          FontVariation('GRAD', axes?.grad.toDouble() ?? 0),
        ],
      ],
    );
  }
}

/// The one text widget of the Glass skin. Only the overrides glass 7 to 10 name are allowed
/// (mono keycaps 12/16 at 600, the stepper value, chapter-row number and go-to well 15/20).
class GlassText extends ConsumerWidget {
  const GlassText(
    this.text, {
    super.key,
    required this.role,
    this.wght,
    this.size,
    this.height,
    this.onGlass = false,
    this.color,
    this.maxScale = double.infinity,
    this.maxLines,
    this.textAlign,
    this.overflow,
    this.fitWords = false,
  });

  final String text;
  final GlassTypeRole role;
  final int? wght;
  final double? size;
  final double? height;
  final bool onGlass;
  final Color? color;
  final double maxScale;
  final int? maxLines;
  final TextAlign? textAlign;
  final TextOverflow? overflow;

  /// Never break inside a word: when the longest word is wider than the line (a brand name in a large title, a long label in a
  /// narrow tile at large text), the text sets down until it fits. Uses a `LayoutBuilder`: not inside intrinsic sizing.
  final bool fitWords;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final legible = ref.watch(glassA11yProvider.select((a) => a.legible));
    final style = GlassTypeStyle.style(
      context,
      role,
      onGlass: onGlass,
      legible: legible,
      wght: wght,
      size: size,
      height: height,
      maxScale: maxScale,
    ).copyWith(color: color ?? (onGlass ? glassTokens.colorOnGlass : glassTokens.colorLabel1));
    Text build(TextStyle st) => Text(
          text,
          style: st,
          maxLines: maxLines,
          textAlign: textAlign,
          overflow: overflow,
          // The size is already scaled and capped above; the framework scaler must not apply again.
          textScaler: TextScaler.noScaling,
        );
    if (!fitWords) return build(style);
    return LayoutBuilder(builder: (context, box) {
      if (!box.hasBoundedWidth) return build(style);
      var longest = 0.0;
      for (final w in text.split(RegExp(r'\s+'))) {
        if (w.isEmpty) continue;
        final p = TextPainter(text: TextSpan(text: w, style: style), textDirection: TextDirection.ltr, textScaler: TextScaler.noScaling)..layout();
        if (p.width > longest) longest = p.width;
        p.dispose();
      }
      if (longest <= box.maxWidth) return build(style);
      return build(style.copyWith(fontSize: (style.fontSize ?? 17) * box.maxWidth / longest * 0.98));
    },);
  }
}
