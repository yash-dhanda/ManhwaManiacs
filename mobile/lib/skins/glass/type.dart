import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
    this.shrink = 1,
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

  /// Also fit a one-line text's longest word (multi-line text always does, see [GlassWordFit]).
  final bool fitWords;

  /// A factor on the final (scaled, capped) size: a control that sets its label down a little to keep it on one line.
  final double shrink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final legible = ref.watch(glassA11yProvider.select((a) => a.legible));
    final base = GlassTypeStyle.style(
      context,
      role,
      onGlass: onGlass,
      legible: legible,
      wght: wght,
      size: size,
      height: height,
      maxScale: maxScale,
    ).copyWith(color: color ?? (onGlass ? glassTokens.colorOnGlass : glassTokens.colorLabel1));
    // Setting down never goes under the 11.5 px text floor (glass G9: no text under 11 px).
    final fs = base.fontSize ?? 17;
    final style = shrink == 1 ? base : base.copyWith(fontSize: math.max(math.min(fs, 11.5), fs * shrink));
    Text text0(TextStyle st) => Text(
          text,
          style: st,
          maxLines: maxLines,
          textAlign: textAlign,
          overflow: overflow,
          // The size is already scaled and capped above; the framework scaler must not apply again.
          textScaler: TextScaler.noScaling,
        );
    // A word wider than the line never breaks mid-word: the text sets down until its longest word fits (multi-line text only;
    // one-line text keeps its ellipsis).
    if (maxLines == 1 && !fitWords) return text0(style);
    return GlassWordFit(text: text, style: style, child: text0(style));
  }
}


/// Never breaks a word in the middle: when [text]'s longest word is wider than the incoming max width (a brand name in a large title,
/// a label in a narrow tile at large text), [child] is laid out wider and painted scaled down by the ratio. Intrinsics follow.
class GlassWordFit extends SingleChildRenderObjectWidget {
  GlassWordFit({super.key, required String text, required TextStyle style, required Widget super.child}) : longest = _longestWord(text, style);

  final double longest;

  /// The widest of the two longest words by length (cheap: two measurements whatever the paragraph).
  static double _longestWord(String text, TextStyle style) {
    final words = text.split(RegExp(r'\s+')).where((w) => w.length > 3).toList()..sort((a, b) => b.length.compareTo(a.length));
    var w = 0.0;
    for (final word in words.take(2)) {
      final p = TextPainter(text: TextSpan(text: word, style: style), textDirection: TextDirection.ltr, textScaler: TextScaler.noScaling)..layout();
      w = math.max(w, p.width);
      p.dispose();
    }
    return w;
  }

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderWordFit(longest);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) => (renderObject as _RenderWordFit).longest = longest;
}

class _RenderWordFit extends RenderProxyBox {
  _RenderWordFit(this._longest);
  double _longest;
  set longest(double v) {
    if (v == _longest) return;
    _longest = v;
    markNeedsLayout();
  }

  double _k = 1;

  double _kFor(double maxWidth) => !maxWidth.isFinite || _longest <= maxWidth || _longest <= 0 ? 1 : (maxWidth / _longest) * 0.99;

  @override
  void performLayout() {
    _k = _kFor(constraints.maxWidth);
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    if (_k == 1) {
      child!.layout(constraints, parentUsesSize: true);
      size = child!.size;
      return;
    }
    final inner = BoxConstraints(minWidth: constraints.minWidth / _k, maxWidth: constraints.maxWidth / _k, minHeight: constraints.minHeight / _k, maxHeight: constraints.maxHeight.isFinite ? constraints.maxHeight / _k : double.infinity);
    child!.layout(inner, parentUsesSize: true);
    size = constraints.constrain(child!.size * _k);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final k = _kFor(width);
    return (child?.getMaxIntrinsicHeight(width / k) ?? 0) * k;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    final k = _kFor(width);
    return (child?.getMinIntrinsicHeight(width / k) ?? 0) * k;
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    final b = child?.getDistanceToActualBaseline(baseline);
    return b == null ? null : b * _k;
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) => transform.multiply(Matrix4.diagonal3Values(_k, _k, 1));

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      child != null && result.addWithPaintTransform(transform: Matrix4.diagonal3Values(_k, _k, 1), position: position, hitTest: (r, p) => child!.hitTest(r, position: p));

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;
    if (_k == 1) {
      context.paintChild(child!, offset);
      return;
    }
    context.pushTransform(needsCompositing, offset, Matrix4.diagonal3Values(_k, _k, 1), (c, o) => c.paintChild(child!, o));
  }
}
