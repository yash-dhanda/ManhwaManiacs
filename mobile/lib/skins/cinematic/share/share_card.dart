import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/library/utils/streak.dart';
import 'package:manhwamaniacs/skins/cinematic/cine_grain.dart';
import 'package:manhwamaniacs/skins/cinematic/duotone.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/share/share_card_model.dart';
import 'package:manhwamaniacs/skins/cinematic/tint.dart';

/// In debug builds only, every string the card draws (cleared per render), so a
/// test proves that no non-shareable title reaches a card.
final List<String> debugShareCardTexts = [];

const _kInk = Color(0xFFF3F0E8);
const _kMuted = Color(0xFF9A978F);
const _kSpot = Color(0xFFF4D03F);
const _kMargin = 64.0;

/// A share card (cinematic 9.2.5), laid out at logical 1080 x 1920 (Story) or
/// 1080 x 1350 (Post) and captured at pixel ratio 1.0. Every text is drawn,
/// never a screenshot of the UI. Ignores text scale (it is an image).
class ShareCard extends StatelessWidget {
  const ShareCard({super.key, required this.template, required this.format, this.art});

  final ShareTemplate template;
  final ShareFormat format;

  /// The cover of the art band; null (or a failing load) leaves `#0B0B0A` with grain.
  final ImageProvider? art;

  static TextStyle kicker() => const TextStyle(fontFamily: 'Archivo', fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: 0.16 * 32, color: _kMuted, height: 1.1, fontVariations: [FontVariation('wght', 700), FontVariation('wdth', 62)]);

  static TextStyle name() => const TextStyle(fontFamily: 'Newsreader', fontStyle: FontStyle.italic, fontSize: 36, fontWeight: FontWeight.w400, color: _kInk, height: 1.2, fontVariations: [FontVariation('wght', 400), FontVariation('opsz', 36)]);

  static TextStyle mono() => const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 24, fontWeight: FontWeight.w500, color: _kMuted, height: 1.2);

  static TextStyle wordmark({required bool italic}) => TextStyle(fontFamily: 'BodoniModa', fontStyle: italic ? FontStyle.italic : FontStyle.normal, fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1.4, color: _kInk, height: 1.1, fontVariations: const [FontVariation('wght', 800), FontVariation('opsz', 40)]);

  static TextStyle figure(double size) => TextStyle(
        fontFamily: 'BodoniModa',
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: _kInk,
        height: 1,
        fontFeatures: const [FontFeature.liningFigures(), FontFeature.tabularFigures()],
        fontVariations: [const FontVariation('wght', 900), FontVariation('opsz', math.min(size, 96))],
      );

  static TextStyle caption(double size) => TextStyle(fontFamily: 'Newsreader', fontStyle: FontStyle.italic, fontSize: size, fontWeight: FontWeight.w400, color: _kInk, height: 1.25, fontVariations: [const FontVariation('wght', 400), FontVariation('opsz', math.min(size, 72))]);

  static TextPainter _measure(InlineSpan span, double maxWidth, {int? maxLines}) => TextPainter(text: span, textDirection: TextDirection.ltr, textScaler: TextScaler.noScaling, maxLines: maxLines)..layout(maxWidth: maxWidth);

  /// The largest figure size (stepping down 4 px at a time, never below half)
  /// that fits [maxWidth].
  static double fitFigure(String text, double start, double maxWidth) {
    var size = start;
    while (size > start / 2) {
      if (_measure(TextSpan(text: text, style: figure(size)), 100000).width <= maxWidth) return size;
      size -= 4;
    }
    return math.max(size, start / 2);
  }

  @override
  Widget build(BuildContext context) {
    final sz = shareSize(format);
    final w = sz.width;
    final h = sz.height;
    const m = _kMargin;
    final inner = w - 2 * m;
    if (kDebugMode) {
      debugShareCardTexts
        ..clear()
        ..addAll([template.kicker, template.profileName, template.figure, template.caption, 'manhwamaniacs', 'Manhwa', 'Maniacs']);
    }

    final kickerTp = _measure(TextSpan(text: template.kicker, style: kicker()), inner, maxLines: 1);
    final nameTp = _measure(TextSpan(text: template.profileName, style: name()), inner, maxLines: 1);
    final nameTop = m + kickerTp.height + 16;
    final topBottom = nameTop + nameTp.height;

    final monoTp = _measure(TextSpan(text: 'manhwamaniacs', style: mono()), inner, maxLines: 1);
    final wordTp = _measure(TextSpan(children: [TextSpan(text: 'Manhwa', style: wordmark(italic: false)), TextSpan(text: 'Maniacs', style: wordmark(italic: true))]), inner, maxLines: 1);
    final monoAscent = monoTp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    final monoTop = h - m - monoAscent;
    final capTop = h - m - 0.698 * 24;
    final ruleTop = capTop - 24 - 6;
    final wordTop = ruleTop - 12 - wordTp.height;

    final artTop = (h * 0.62 / 4).round() * 4.0;
    final artBottom = wordTop - 48;

    final figStart = format == ShareFormat.story ? 360.0 : 252.0;
    final figSize = fitFigure(template.figure, figStart, inner);
    final figTp = _measure(TextSpan(text: template.figure, style: figure(figSize)), inner, maxLines: 1);
    final capSize = format == ShareFormat.story ? 48.0 : 32.0;
    final capTp = _measure(TextSpan(text: template.caption, style: caption(capSize)), inner, maxLines: 3);
    final figBaseline = figTp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    final flameH = template.tier == null ? 0.0 : 96.0 + 24.0;
    final blockH = flameH + figBaseline + 24 + capTp.height;
    final availTop = topBottom + 64;
    final availBottom = artTop - 48;
    final blockTop = math.max(availTop, availTop + (availBottom - availTop - blockH) / 2);

    Widget text(String s, TextStyle style, {int? maxLines}) => Text(s, style: style, maxLines: maxLines, textScaler: TextScaler.noScaling, softWrap: maxLines != 1, overflow: TextOverflow.clip);

    final artDuo = parseAmbientHex(template.art?.ambient?.duo);
    final oxfordW = wordTp.width;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling, boldText: false),
      child: ExcludeSemantics(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: DefaultTextStyle(
            style: const TextStyle(decoration: TextDecoration.none),
            child: SizedBox(
              width: w,
              height: h,
              child: ColoredBox(
                color: const Color(0xFF000000),
                child: Stack(children: [
                  // The art band: full bleed, duotoned to its ambient, grain 0.06.
                  Positioned(
                    left: 0,
                    top: artTop,
                    width: w,
                    height: math.max(0, artBottom - artTop),
                    child: art == null
                        ? const _DarkBand()
                        : CineGrain(
                            child: CineDuotone(duo: artDuo, child: Image(image: art!, fit: BoxFit.cover, gaplessPlayback: true, errorBuilder: (_, __, ___) => const _DarkBand())),
                          ),
                  ),
                  Positioned(left: m, top: m, width: inner, child: text(template.kicker, kicker(), maxLines: 1)),
                  Positioned(left: m, top: nameTop, width: inner, child: text(template.profileName, name(), maxLines: 1)),
                  if (template.tier != null)
                    Positioned(
                      left: m,
                      top: blockTop,
                      width: 96,
                      height: 96,
                      child: OverflowBox(
                        maxWidth: 400,
                        maxHeight: 400,
                        child: Stack(alignment: Alignment.center, children: [
                          Container(width: 240, height: 240, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0x59F4D03F), Color(0x00F4D03F)]))),
                          Icon(cineIcons[template.tier == StreakTier.one ? CineIconRole.streakShort : CineIconRole.streakLong]![CineIconWeight.fill], size: 96, color: _kSpot),
                        ],),
                      ),
                    ),
                  Positioned(left: m, top: blockTop + flameH, width: inner, child: text(template.figure, figure(figSize), maxLines: 1)),
                  Positioned(left: m, top: blockTop + flameH + figBaseline + 24, width: inner, child: text(template.caption, caption(capSize))),
                  Positioned(left: m, top: wordTop, child: Text.rich(TextSpan(children: [TextSpan(text: 'Manhwa', style: wordmark(italic: false)), TextSpan(text: 'Maniacs', style: wordmark(italic: true))]), textScaler: TextScaler.noScaling, maxLines: 1)),
                  Positioned(left: m, top: ruleTop, width: oxfordW, child: _Oxford(width: oxfordW)),
                  Positioned(left: m, top: monoTop, child: text('manhwamaniacs', mono(), maxLines: 1)),
                ],),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DarkBand extends StatelessWidget {
  const _DarkBand();
  @override
  Widget build(BuildContext context) => const CineGrain(child: ColoredBox(color: Color(0xFF0B0B0A)));
}

/// The Oxford rule: 3 px, a 2 px gap, 1 px; `#F3F0E8` with its first 12 % `#F4D03F`.
class _Oxford extends StatelessWidget {
  const _Oxford({required this.width});
  final double width;

  Widget _line(double height) => SizedBox(
        height: height,
        width: width,
        child: Row(children: [
          Container(width: width * 0.12, height: height, color: _kSpot),
          Expanded(child: Container(height: height, color: _kInk)),
        ],),
      );

  @override
  Widget build(BuildContext context) => SizedBox(width: width, height: 6, child: Column(children: [_line(3), const SizedBox(height: 2), _line(1)]));
}
