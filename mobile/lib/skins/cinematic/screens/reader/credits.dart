import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_options.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_chapter_provider.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/duotone.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_series.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The pull distance at which pull to continue commits (cinematic 8.14.6).
const double kPullToContinuePx = 150;

/// The chapter-end credits (cinematic 8.14.6). [CreditsMode.compact] in a continuous strip: the end
/// title on one line plus the reactions slot. [CreditsMode.full] when the next chapter is not
/// stitched below: 96 px of ground, `End of chapter 142` through the Letter set, a credits block,
/// the [reactions] slot (`mobile/22`), the Coming up card and pull to continue.
class ReaderCredits extends ConsumerWidget {
  const ReaderCredits({
    super.key,
    required this.engine,
    required this.sourceId,
    required this.seriesKey,
    required this.chapter,
    required this.chapterNumber,
    required this.seriesTitle,
    required this.mode,
    required this.readMinutes,
    required this.onContinue,
    this.onPull,
    this.nextChapterKey,
    this.nextNumber,
    this.nextTitle,
    this.reactions,
  });

  final ReaderEngine engine;
  final String sourceId, seriesKey, seriesTitle;
  final ReaderChapter chapter;

  /// `142`, or `·`.
  final String chapterNumber;
  final CreditsMode mode;

  /// How long the chapter took, in minutes.
  final int readMinutes;
  final String? nextChapterKey, nextTitle;
  final double? nextNumber;

  /// Opens the next chapter (the primary button and a committed pull).
  final VoidCallback onContinue;

  /// A committed pull (K5): the reader fades through black first; falls back to [onContinue].
  final VoidCallback? onPull;

  /// The reactions block between the credits and the card; `mobile/22` fills it.
  final Widget? reactions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final end = 'End of chapter $chapterNumber';
    if (mode == CreditsMode.compact) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: c.space4, vertical: c.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(header: true, child: CineLit(end, CineFace.bodoni, 22, 28, italic: true, color: c.colorInk100, textAlign: TextAlign.center)),
            if (reactions != null) ...[SizedBox(height: c.space4), reactions!],
          ],
        ),
      );
    }
    final sources = ref.watch(sourcesListProvider).valueOrNull;
    final sourceName = sources?.where((s) => s.id == sourceId).firstOrNull?.name ?? sourceId;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: c.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 96),
          SetHeading(
            end,
            id: 'reader.end.${chapter.id}',
            style: CineText.style(context, c.typeSection),
            cap: c.typeSection.cap,
            level: 2,
            trigger: SetTrigger.mount,
          ),
          SizedBox(height: c.space4),
          _CreditsBlock(entries: [
            ('SERIES', seriesTitle),
            ('SOURCE', sourceName),
            ('READ IN', '${readMinutes < 1 ? 1 : readMinutes} MIN'),
            ('PAGES', '${chapter.pages.length}'),
          ],),
          if (reactions != null) ...[SizedBox(height: c.space6), reactions!],
          if (nextChapterKey != null) ...[
            SizedBox(height: c.space8),
            ComingUpCard(
              sourceId: sourceId,
              seriesKey: seriesKey,
              nextChapterKey: nextChapterKey!,
              nextNumber: nextNumber,
              nextTitle: nextTitle,
              onRead: onContinue,
            ),
            SizedBox(height: c.space4),
            PullToContinue(engine: engine, onCommit: onPull ?? onContinue),
          ],
        ],
      ),
    );
  }
}

class _CreditsBlock extends StatelessWidget {
  const _CreditsBlock({required this.entries});
  final List<(String, String)> entries;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Semantics(
      container: true,
      child: Wrap(
        spacing: c.space6,
        runSpacing: c.space3,
        children: [
          for (final (label, value) in entries)
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                CineRoleText(label, c.typeCreditLabel, color: c.colorInk45),
                SizedBox(width: c.space2),
                Flexible(child: CineRoleText(value, c.typeCredit, color: c.colorInk100, maxLines: 2, overflow: TextOverflow.ellipsis)),
              ],
            ),
        ],
      ),
    );
  }
}

/// The Coming up card: a 16:9 panel of the next chapter's first page, blurred and duotoned to the
/// series' `ambient.duo`, the sharp page as an inset 3:4 thumbnail, the text on a `#000000` band at
/// .84. Blur and duotone apply to this card only.
class ComingUpCard extends ConsumerWidget {
  const ComingUpCard({
    super.key,
    required this.sourceId,
    required this.seriesKey,
    required this.nextChapterKey,
    required this.onRead,
    this.nextNumber,
    this.nextTitle,
    this.duo,
  });

  final String sourceId, seriesKey, nextChapterKey;
  final double? nextNumber;
  final String? nextTitle;
  final Color? duo;
  final VoidCallback onRead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final key = (sourceId: sourceId, seriesKey: seriesKey, chapterKey: nextChapterKey);
    final resolved = ref.watch(resolvedReaderChapterProvider(key)).valueOrNull;
    final pages = resolved?.chapter.pages ?? const [];
    final first = pages.isEmpty ? null : pages.first;
    final saved = ref.watch(seriesChapterDownloadStatusProvider((sourceId: sourceId, seriesKey: seriesKey))).valueOrNull?[nextChapterKey]?.state ==
        DownloadChapterState.complete;
    final minutes = pages.isEmpty ? null : (pages.length / 6).ceil().clamp(1, 999);
    final n = chapterNumberText(nextNumber);
    final url = first?.imageUrl;
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final reduced = CineMotion.reduced(context);
    final art = first == null
        ? ColoredBox(color: c.colorPaper1)
        : CineDuotone(
            duo: duo ?? c.colorAmbientFallbackDuo,
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: c.blurCard, sigmaY: c.blurCard),
              child: CineImage(url: url),
            ),
          );
    return Semantics(
      container: true,
      label: 'Coming up, chapter $n',
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ExcludeSemantics(child: art),
            Positioned(
              left: 12,
              top: 12,
              bottom: 12,
              child: AspectRatio(aspectRatio: 3 / 4, child: ExcludeSemantics(child: CineImage(url: url))),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: LayoutBuilder(
                builder: (context, box) => Container(
                  width: box.maxWidth * 0.62,
                  height: box.maxHeight,
                  color: const Color(0xD6000000),
                  padding: EdgeInsets.all(c.space3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CineRoleText('COMING UP', c.typeKicker, color: c.colorInk60),
                      CineRoleText('Chapter $n', c.typeHeadline, maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (nextTitle != null && nextTitle!.isNotEmpty && scale < 1.5)
                        CineRoleText(nextTitle!, c.typeDeck, color: c.colorInk60, maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (minutes != null)
                        CineRoleText(
                          '${pages.length} PAGES · ~$minutes MIN${saved ? ' · SAVED' : ''}',
                          c.typeFolio,
                          color: c.colorInk45,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      SizedBox(height: c.space2),
                      ConstrainedBox(
                        constraints: BoxConstraints(minHeight: 48 * (reduced ? 1 : 1) * (scale > 1 ? scale : 1)),
                        child: CineButton(label: 'Read chapter $n', onPressed: onRead),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pull to continue below the card: a 150 px region with a 2 px `spot` rule that fills from the
/// left as the reader pulls past the end of the strip; at full it commits once.
class PullToContinue extends StatefulWidget {
  const PullToContinue({super.key, required this.engine, required this.onCommit});

  final ReaderEngine engine;
  final VoidCallback onCommit;

  @override
  State<PullToContinue> createState() => _PullToContinueState();
}

class _PullToContinueState extends State<PullToContinue> {
  bool _committed = false;

  @override
  void initState() {
    super.initState();
    widget.engine.endPull.addListener(_check);
  }

  @override
  void dispose() {
    widget.engine.endPull.removeListener(_check);
    super.dispose();
  }

  void _check() {
    if (_committed || widget.engine.endPull.value < kPullToContinuePx) return;
    _committed = true;
    widget.onCommit();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Semantics(
      button: true,
      label: 'Pull up to continue to the next chapter',
      onTap: widget.onCommit,
      excludeSemantics: true,
      child: SizedBox(
        height: kPullToContinuePx,
        child: Align(
          alignment: Alignment.topCenter,
          child: ValueListenableBuilder<double>(
            valueListenable: widget.engine.endPull,
            builder: (context, pull, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: (pull / kPullToContinuePx).clamp(0.0, 1.0),
                    child: SizedBox(height: 2, child: ColoredBox(color: c.colorSpot)),
                  ),
                ),
                SizedBox(height: c.space2),
                CineRoleText('PULL TO CONTINUE', c.typeKicker, color: c.colorInk45),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
