import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/novels/utils/novel_book.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/set_heading.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// What follows the last paragraph (cinematic 8.15.2): 96 px of air, a 96 px rule, `End of chapter
/// 12` through the Letter set, `READ IN 14 MIN`, the reactions slot (`mobile/22`), then the next
/// card in stock colours, or the reason there is none, then `Previous chapter` and `Back to the
/// book`.
class NovelEndMatter extends StatelessWidget {
  const NovelEndMatter({
    super.key,
    required this.chapterKey,
    required this.chapterNumberText,
    required this.wordCount,
    required this.stock,
    required this.onBackToBook,
    this.next,
    this.onNext,
    this.onPrevious,
    this.offline = false,
    this.onBackToDownloads,
    this.reactions,
    this.theEnd,
  });

  final String chapterKey;

  /// `12`, or null for an unnumbered chapter.
  final String? chapterNumberText;
  final int wordCount;
  final CineStockColors stock;

  /// The chapter after this one: its number text and title; null when there is none.
  final ({String? number, String title})? next;
  final VoidCallback? onNext, onPrevious;
  final VoidCallback onBackToBook;

  /// Reading a saved copy: with no next chapter the end reads "End of the downloaded copy.".
  final bool offline;
  final VoidCallback? onBackToDownloads;

  /// `mobile/22`'s reactions.
  final Widget? reactions;

  /// The Completed book's end block (`THE END`, the Up next rail), in stock colours.
  final Widget? theEnd;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final minutes = readingMinutes(wordCount);
    final heading = chapterNumberText == null ? 'End of chapter' : 'End of chapter $chapterNumberText';
    return Padding(
      padding: const EdgeInsets.only(top: 96, bottom: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 96, height: 1, child: ColoredBox(color: stock.muted)),
          const SizedBox(height: 24),
          SetHeading(
            heading,
            id: 'novel.end.$chapterKey',
            style: CineText.style(context, c.typeSection).copyWith(color: stock.ink),
            cap: c.typeSection.cap,
            level: 2,
          ),
          if (minutes > 0) ...[
            const SizedBox(height: 8),
            CineRoleText('READ IN $minutes MIN', c.typeFolio, color: stock.muted),
          ],
          if (reactions != null) ...[const SizedBox(height: 24), reactions!],
          const SizedBox(height: 32),
          if (next != null && onNext != null)
            _NextCard(next: next!, stock: stock, onNext: onNext!)
          else if (theEnd != null)
            theEnd!
          else if (offline) ...[
            CineRoleText('End of the downloaded copy.', c.typeBody, color: stock.ink),
            const SizedBox(height: 16),
            if (onBackToDownloads != null) CineButton(label: 'Back to Downloads', variant: CineButtonVariant.quiet, onPressed: onBackToDownloads),
          ] else
            CineRoleText("You've reached the last chapter this source has published.", c.typeBody, color: stock.ink),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            children: [
              if (onPrevious != null) CineButton(label: 'Previous chapter', variant: CineButtonVariant.quiet, onPressed: onPrevious),
              CineButton(label: 'Back to the book', variant: CineButtonVariant.quiet, onPressed: onBackToBook),
            ],
          ),
        ],
      ),
    );
  }
}

class _NextCard extends StatelessWidget {
  const _NextCard({required this.next, required this.stock, required this.onNext});
  final ({String? number, String title}) next;
  final CineStockColors stock;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final headline = next.number == null ? 'Next chapter' : 'Chapter ${next.number}';
    final subhead = CineText.style(context, c.typeSubhead).copyWith(fontFamily: 'BodoniModa', color: stock.ink);
    return Semantics(
      button: true,
      label: 'Next: $headline, ${next.title}',
      excludeSemantics: true,
      onTap: onNext,
      child: CineFocusRing(
        onActivate: onNext,
        child: InkWell(
          onTap: onNext,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 88),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: stock.page, border: Border.all(color: stock.muted.withValues(alpha: 0.5))),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CineRoleText('NEXT', c.typeKicker, color: stock.muted),
                      const SizedBox(height: 8),
                      Text(headline, style: subhead, textScaler: CineText.scaler(context, c.typeSubhead)),
                      if (next.title.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        CineRoleText(next.title, c.typeBody, color: stock.ink, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                CineRoleText('→', c.typeSubhead, color: stock.ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
