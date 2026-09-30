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
