import 'dart:ui' show FontFeature, ImageFilter;

import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_oxford_rule.dart';
import 'package:manhwamaniacs/skins/cinematic/splash/splash_timeline.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The stacked lockup as live text (cinematic 12.2): `Manhwa` in Bodoni Moda Roman over `Maniacs`
/// in Bodoni Moda Italic, `wght` 800, `opsz` 96, tracking -0.035 em, leading 0.86, flush left, at
/// `typeMasthead` size, over the Oxford rule (the first 12 % `spot`). Two `SetHeading`s with
/// `SetTrigger.mount`, ids `splash-manhwa` and `splash-maniacs`, start delays 0 and 144, so the 13
/// letters start 24 ms apart from t = 252. With [frozenMs] the letters and the rule are drawn at
/// that time instead (the gallery and the harness).
class CineWordmark extends StatelessWidget {
  const CineWordmark({super.key, this.frozenMs, this.showText = true, this.ruleProgress = 1});

  final double? frozenMs;

  /// False while the monogram still has the stage.
  final bool showText;

  /// 0..1: how much of the rule has drawn (700 - 1180 ms).
  final double ruleProgress;

  TextStyle _style(BuildContext context, {required bool italic}) {
    final c = context.cine;
    final base = CineText.style(context, c.typeMasthead);
    final size = base.fontSize ?? 48;
    return CineText.literal(context, CineFace.bodoni, size, size, italic: italic, wght: 800).copyWith(
      color: c.colorInk100,
      letterSpacing: -0.035 * size,
      height: 0.86,
      fontFeatures: const [FontFeature.disable('kern')],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final roman = _style(context, italic: false);
    final italic = _style(context, italic: true);
    final Widget text;
    if (frozenMs != null) {
      text = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _frozen(context, 'Manhwa', roman, 0, frozenMs!),
        _frozen(context, 'Maniacs', italic, 6, frozenMs!),
      ],);
    } else if (!showText) {
      text = const SizedBox.shrink();
    } else {
      text = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SetHeading('Manhwa', id: 'splash-manhwa', style: roman, cap: c.typeMasthead.cap, level: null, trigger: SetTrigger.mount, startDelayMs: 0),
        SetHeading('Maniacs', id: 'splash-maniacs', style: italic, cap: c.typeMasthead.cap, level: null, trigger: SetTrigger.mount, startDelayMs: 144),
      ],);
    }
    return Semantics(
      label: 'ManhwaManiacs',
      excludeSemantics: true,
      child: SizedBox(
        width: _width(context, roman, italic),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          Opacity(opacity: showText || frozenMs != null ? 1 : 0, child: text),
          SizedBox(height: c.space3),
          ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: ruleProgress.clamp(0.0, 1.0),
              child: const CineOxfordRule(spotLead: true),
            ),
          ),
        ],),
      ),
    );
  }

  /// The widest of the two lines: the rule is as wide as the lockup (an `IntrinsicWidth` cannot
  /// measure the `SetHeading`s' layout builders).
  static double _width(BuildContext context, TextStyle roman, TextStyle italic) {
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: context.cine.typeMasthead.cap);
    double one(String word, TextStyle style) {
      final p = TextPainter(text: TextSpan(text: word, style: style), textScaler: scaler, textDirection: TextDirection.ltr, maxLines: 1)..layout();
      final w = p.width;
      p.dispose();
      return w;
    }

    return (one('Manhwa', roman) > one('Maniacs', italic) ? one('Manhwa', roman) : one('Maniacs', italic)) + 2;
  }

  Widget _frozen(BuildContext context, String word, TextStyle style, int first, double ms) {
    final c = context.cine;
    return FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < word.length; i++)
        Builder(builder: (context) {
          final p = splashLetterAt(first + i, ms);
          final blur = c.blurLetter * (1 - p.sharp);
          final ch = Text(word[i], style: style);
          return Opacity(
            opacity: p.t,
            child: Transform.translate(
              offset: Offset(0, c.scalarLetterRise * (style.fontSize ?? 48) * (1 - p.t)),
              child: blur < 0.05 ? ch : ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur), child: ch),
            ),
          );
        },),
    ],),);
  }
}
