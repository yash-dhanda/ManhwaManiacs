import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/series_audio_provider.dart';
import 'package:manhwamaniacs/features/novels/utils/novel_book.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_galley.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_notice.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_text_field.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/book/contents_row.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_series.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// How many matches the go-to field lists before it says how many more.
const int kNovelContentsMaxMatches = 30;

/// Opens the reader's Contents on phones (cinematic 8.15.6): a `[0.5, 0.92]` sheet in the stock,
/// pre-scrolled to the current chapter. A tap on a chapter closes it and calls [onOpen].
Future<void> showNovelContentsSheet(
  BuildContext context, {
  required String sourceId,
  required String seriesKey,
  required String currentChapterKey,
  required CineStockColors stock,
  required ValueChanged<String> onOpen,
}) =>
    showCineSheet<void>(
      context,
      kicker: 'CONTENTS',
      title: 'Contents',
      builder: (sheetContext) => CineStock.stock(
        stock,
        Material(
          type: MaterialType.transparency,
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * 0.7,
            child: NovelContentsBody(
              sourceId: sourceId,
              seriesKey: seriesKey,
              currentChapterKey: currentChapterKey,
              onOpen: (key) {
                Navigator.of(sheetContext).maybePop();
                onOpen(key);
              },
            ),
          ),
        ),
      ),
    );

/// The left column panel on tablets (cinematic 8.15.6): a kicker header with a quiet close, then
/// the same body, in the stock colours.
class NovelContentsPanel extends StatelessWidget {
  const NovelContentsPanel({super.key, required this.sourceId, required this.seriesKey, required this.currentChapterKey, required this.onOpen, required this.onClose});

  final String sourceId, seriesKey, currentChapterKey;
  final ValueChanged<String> onOpen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Material(
      color: c.colorPaper0,
      child: Padding(
        padding: EdgeInsets.only(top: MediaQuery.viewPaddingOf(context).top),
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: c.space4),
                child: Row(
                  children: [
                    Expanded(child: CineRoleText('CONTENTS', c.typeKicker, color: c.colorInk60)),
                    CineButton(label: 'Close', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: onClose),
                  ],
                ),
              ),
            ),
            SizedBox(height: 1, child: ColoredBox(color: c.colorRule1)),
            Expanded(child: NovelContentsBody(sourceId: sourceId, seriesKey: seriesKey, currentChapterKey: currentChapterKey, onOpen: onOpen)),
          ],
        ),
      ),
    );
  }
}

/// The go-to field, its matches and the rows (cinematic 7.16 novel variant): ordinal, title, dot
/// leaders, length, state mark. A `ListView.builder` of fixed-extent rows, pre-scrolled to the
/// current chapter on its `spot.wash` band.
class NovelContentsBody extends ConsumerStatefulWidget {
  const NovelContentsBody({super.key, required this.sourceId, required this.seriesKey, required this.currentChapterKey, required this.onOpen});

  final String sourceId, seriesKey, currentChapterKey;
  final ValueChanged<String> onOpen;

  @override
  ConsumerState<NovelContentsBody> createState() => _NovelContentsBodyState();
}

class _NovelContentsBodyState extends ConsumerState<NovelContentsBody> {
  final TextEditingController _query = TextEditingController();
  ScrollController? _scroll;
  String _q = '';

  @override
  void dispose() {
    _query.dispose();
    _scroll?.dispose();
    super.dispose();
  }

  ReaderSeriesKey get _key => (sourceId: widget.sourceId, seriesKey: widget.seriesKey);

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final detail = ref.watch(sourceSeriesDetailProvider((sourceId: widget.sourceId, seriesId: widget.seriesKey)));
    final series = ref.watch(readerSeriesProvider(_key));
    final online = ref.watch(deviceOnlineProvider).valueOrNull ?? true;
    final chapters = series?.chapters;

    if (chapters == null) {
      if (detail.hasError || !online) {
        return Padding(
          padding: EdgeInsets.all(c.space4),
          child: !online
              ? CineRoleText('The contents need a connection to load.', c.typeBody)
              : CineNotice(
                  tone: CineNoticeTone.error,
                  kicker: 'CORRECTION',
                  headline: "The contents didn't load.",
                  primary: CineNoticeAction('Try again', () => ref.invalidate(sourceSeriesDetailProvider((sourceId: widget.sourceId, seriesId: widget.seriesKey)))),
                ),
        );
      }
      return Padding(
        padding: EdgeInsets.all(c.space4),
        child: Column(children: [for (var i = 0; i < 10; i++) CineGalleyLine(lineHeight: 48, index: i)]),
      );
    }

    final current = chapters.indexWhere((x) => x.id == widget.currentChapterKey);
    _scroll ??= ScrollController(initialScrollOffset: contentsScrollOffset(current < 0 ? 0 : current, kContentsRowExtent));
    final progress = ref.watch(sourceSeriesProgressProvider((sourceId: widget.sourceId, seriesId: widget.seriesKey)));
    final downloads = ref.watch(seriesChapterDownloadStatusProvider(_key)).valueOrNull ?? const {};
    final narrated = ref.watch(seriesAudioProvider(_key)).valueOrNull?.rendered ?? const <String>{};
    final matches = goToChapterMatches(chapters, _q);
    final n = goToChapterQuery(_q);

    Widget matchList() {
      if (n == null) return const SizedBox.shrink();
      if (matches.isEmpty) {
        return Padding(
          padding: EdgeInsets.fromLTRB(c.space4, c.space2, c.space4, c.space2),
          child: CineRoleText('No chapter ${formatChapterNumber(n)} in this book.', c.typeBody, color: c.colorInk60),
        );
      }
      return Padding(
        padding: EdgeInsets.fromLTRB(c.space4, 0, c.space4, c.space2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final m in matches.take(kNovelContentsMaxMatches)) _MatchRow(chapter: m, row: chapters.indexWhere((x) => x.id == m.id) + 1, onTap: () => widget.onOpen(m.id)),
            if (matches.length > kNovelContentsMaxMatches)
              Padding(padding: EdgeInsets.only(top: c.space2), child: CineRoleText('and ${matches.length - kNovelContentsMaxMatches} more', c.typeCaption, color: c.colorInk60)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(c.space4, c.space2, c.space4, c.space2),
          child: CineTextField(
            label: 'Chapter number',
            controller: _query,
            numeric: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            textInputAction: TextInputAction.done,
            onChanged: (v) => setState(() => _q = v),
            onSubmitted: (v) {
              final m = goToChapterMatches(chapters, v);
              if (m.isNotEmpty) widget.onOpen(m.first.id);
            },
          ),
        ),
        if (n != null) Flexible(flex: 0, child: ConstrainedBox(constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.35), child: SingleChildScrollView(child: matchList()))),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            itemExtent: kContentsRowExtent,
            itemCount: chapters.length,
            itemBuilder: (context, i) {
              final chapter = chapters[i];
              final p = progress[chapter.id];
              final read = p?.completed ?? false;
              final percent = p != null && !read && p.pageCount > 0 ? (p.page * 100 / p.pageCount).round() : null;
              final isCurrent = chapter.id == widget.currentChapterKey;
              return Semantics(
                selected: isCurrent,
                hint: isCurrent ? 'current' : null,
                child: ContentsRow(
                  chapter: chapter,
                  read: read,
                  percent: percent,
                  narrated: narrated.contains(chapter.id),
                  downloadState: downloads[chapter.id]?.state,
                  current: isCurrent,
                  selecting: false,
                  selected: false,
                  onTap: () => widget.onOpen(chapter.id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MatchRow extends StatelessWidget {
  const _MatchRow({required this.chapter, required this.row, required this.onTap});
  final SourceChapterSummary chapter;
  final int row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final e = tocEntry(number: chapter.number, title: chapter.title);
    return Semantics(
      button: true,
      label: '${e.ordinal ?? ''} ${e.title ?? ''}, row $row',
      excludeSemantics: true,
      onTap: onTap,
      child: CineFocusRing(
        onActivate: onTap,
        child: InkWell(
          key: Key('match-${chapter.id}'),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                SizedBox(width: 48, child: CineRoleText(e.ordinal ?? '·', c.typeFolio, color: c.colorSpot, textAlign: TextAlign.right)),
                const SizedBox(width: 12),
                Expanded(child: CineRoleText(e.title ?? '', c.typeBody, maxLines: 1, overflow: TextOverflow.ellipsis)),
                CineRoleText('ROW $row', c.typeFolio, color: c.colorInk60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
