import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/ocr/models/ocr_search_result.dart';
import 'package:manhwamaniacs/features/ocr/providers/dialogue_still_provider.dart';
import 'package:manhwamaniacs/features/ocr/services/ocr_snippet.dart';
import 'package:manhwamaniacs/features/ocr/utils/engine_label.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_extras.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_poster.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/dialogue/subtitled_still.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// One dialogue hit: the still (when the page is known), the full transcript
/// with highlighted terms, the credit line and the series cover.
class TranscriptBlock extends ConsumerWidget {
  const TranscriptBlock({
    super.key,
    required this.hit,
    required this.series,
    required this.index,
    required this.onTap,
  });

  final OcrSearchResult hit;
  final FollowedSeries? series;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.cine;
    final tablet = isTablet(context);
    final title = (series?.title ?? hit.seriesKey).toUpperCase();
    final credit = [
      title,
      'CH ${hit.chapterKey}',
      if (hit.page != null) 'PAGE ${hit.page}',
      '${hit.wordCount} WORDS',
      engineLabel(hit.engine),
    ].join(' · ');

    final page = hit.page;
    final failed = page != null &&
        ref.watch(dialogueStillProvider((chapter: hit.identity, page: page))).maybeWhen(
              data: (s) => s == null || (s.file == null && s.bytes == null),
              error: (_, __) => true,
              orElse: () => false,
            );
    final transcript = SweepHighlightText(
      hit.snippet,
      style: cineText(context, t.typeBody),
      textAlign: TextAlign.start,
    );
    void quickLook() => unawaited(
          showQuickLook(
            context,
            ref,
            title: series?.title ?? hit.seriesKey,
            coverUrl: series?.coverUrl,
            kicker: 'DIALOGUE',
            caption: credit,
            onOpen: onTap,
            openLabel: 'Open in reader',
          ),
        );
    final meta = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        transcript,
        const SizedBox(height: CineSpace.s3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(credit, style: cineText(context, t.typeCredit, color: t.colorInk60)),
            ),
            SizedBox(
              width: tablet ? 40 : 32,
              height: tablet ? 60 : 48,
              child: CineCover(url: series?.coverUrl, displayWidth: 40),
            ),
            IconButton(
              tooltip: 'More for this line',
              onPressed: quickLook,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: Icon(PhosphorRegular.dotsThree, size: 24, color: t.colorInk100),
            ),
          ],
        ),
      ],
    );
    final still = hit.page == null
        ? null
        : SubtitledStill(hit: hit, rack: index < 12);

    return Semantics(
      button: true,
      label: '$credit. ${ocrSnippetSpans(hit.snippet).map((s) => s.text).join()}'
          '${failed ? " Page didn't load" : ''}',
      excludeSemantics: true,
      onLongPress: quickLook,
      child: CineFocusRing(
        child: CineLongPress(
          onLongPress: quickLook,
          child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tablet ? CineSpace.s8 : CineSpace.s4,
            vertical: CineSpace.s3,
          ),
          child: tablet && still != null
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: still),
                    const SizedBox(width: CineSpace.s4),
                    Expanded(child: meta),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (still != null) ...[still, const SizedBox(height: CineSpace.s3)],
                    meta,
                  ],
                ),
        ),
      ),
      ),
      ),
    );
  }
}
