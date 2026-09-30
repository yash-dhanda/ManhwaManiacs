import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/novels/models/novel_typography.dart';
import 'package:manhwamaniacs/features/novels/utils/novel_book.dart';
import 'package:manhwamaniacs/skins/cinematic/a11y/folio.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The facts line of an opener: `3.4K WORDS · 14 MIN`, from the 250 wpm estimate.
String novelFactsLine(int wordCount) {
  if (wordCount <= 0) return '';
  final words = wordCount >= 1000 ? '${(wordCount / 1000).toStringAsFixed(1)}K' : '$wordCount';
  return '$words WORDS · ${readingMinutes(wordCount)} MIN';
}

/// The chapter opener (cinematic 8.15.2): the kicker `CHAPTER 12`, the title in Bodoni Moda Roman
/// at 1.9 x the body size, a 48 px rule and the facts line. `mobile/15` adds the Listen button
/// under it through [trailing].
class NovelChapterOpener extends StatelessWidget {
  const NovelChapterOpener({
    super.key,
    required this.chapterNumberText,
    required this.title,
    required this.wordCount,
    required this.type,
    required this.stock,
    this.trailing,
  });

  /// `12`, or null for an unnumbered chapter.
  final String? chapterNumberText;
  final String title;
  final int wordCount;
  final NovelType type;
  final CineStockColors stock;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final size = type.fontSize * 1.9;
    final facts = novelFactsLine(wordCount);
    final titleStyle = TextStyle(
      fontFamily: 'BodoniModa',
      fontSize: size,
      height: 1.15,
      color: stock.ink,
      fontVariations: [FontVariation('opsz', math.min(size, 96)), const FontVariation('wght', 400)],
    );
    return Padding(
      padding: const EdgeInsets.only(top: 56, bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (chapterNumberText != null) ...[
            ExcludeSemantics(child: CineRoleText('CHAPTER $chapterNumberText', c.typeKicker, color: stock.muted)),
            const SizedBox(height: 12),
          ],
          Semantics(
            header: true,
            headingLevel: 1,
            child: Text(title, style: titleStyle, textScaler: TextScaler.noScaling),
          ),
          const SizedBox(height: 20),
          SizedBox(width: 48, height: 1, child: ColoredBox(color: stock.muted)),
          if (facts.isNotEmpty) ...[
            const SizedBox(height: 16),
            Semantics(label: folioLabel(facts), excludeSemantics: true, child: CineRoleText(facts, c.typeFolio, color: stock.muted)),
          ],
          if (trailing != null) ...[const SizedBox(height: 20), trailing!],
        ],
      ),
    );
  }
}

/// The height [NovelChapterOpener] takes in a column [width] wide: what the paginator reserves
/// on the first page of the paged layout.
double novelOpenerHeight(
  BuildContext context, {
  required bool hasNumber,
  required String title,
  required int wordCount,
  required NovelType type,
  required double width,
}) {
  final c = context.cine;
  double lineOf(CineTextRole role, String text, double w) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: CineText.style(context, role)),
      textDirection: TextDirection.ltr,
      textScaler: CineText.scaler(context, role),
    )..layout(maxWidth: w);
    final h = tp.height;
    tp.dispose();
    return h;
  }

  final size = type.fontSize * 1.9;
  final titlePainter = TextPainter(
    text: TextSpan(text: title, style: TextStyle(fontFamily: 'BodoniModa', fontSize: size, height: 1.15)),
    textDirection: TextDirection.ltr,
    textScaler: TextScaler.noScaling,
  )..layout(maxWidth: width);
  final titleHeight = titlePainter.height;
  titlePainter.dispose();
  final facts = novelFactsLine(wordCount);
  var h = 56.0 + titleHeight + 20 + 1 + 40;
  if (hasNumber) h += lineOf(c.typeKicker, 'CHAPTER 1', width) + 12;
  if (facts.isNotEmpty) h += 16 + lineOf(c.typeFolio, facts, width);
  return h;
}
