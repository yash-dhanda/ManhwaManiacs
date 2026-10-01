import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/novels/models/novel_palette.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_preferences_provider.dart' show novelPaletteControllerProvider;
import 'package:manhwamaniacs/features/novels/providers/novel_series_providers.dart';
import 'package:manhwamaniacs/features/novels/utils/novel_book.dart';
import 'package:manhwamaniacs/features/novels/utils/toc_window.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/sources/models/source_chapter_progress.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/glass_motion_recorder.dart' show GlassMotionEntry;
import 'package:manhwamaniacs/skins/glass/listen/audiobook_button.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/parts/reactions/chapter_reactions.dart' show ChapterReactionSummary;
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/download_control.dart';
import 'package:manhwamaniacs/skins/glass/primitives/download_state.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_common.dart' show HomeCoverImage;
import 'package:manhwamaniacs/skins/glass/screens/series/chapters_section.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/series_actions.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/series_data.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/series_detail.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/series_header.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/series_states.dart';
import 'package:manhwamaniacs/skins/glass/transitions/book_open_page.dart';
import 'package:manhwamaniacs/skins/skins.dart';

const double kTocRowExtent = 60;

TextStyle literata(double size, {double? height, FontStyle? style, double wght = 400, Color? color}) =>
    TextStyle(fontFamily: 'Literata', fontSize: size, height: height == null ? null : height / size, fontStyle: style, fontVariations: [FontVariation('wght', wght), FontVariation('opsz', size.clamp(12, 36))], color: color ?? gt.colorLabel1);

/// The book plate (glass 8.13 Header): radius 6, a 1 px paper-edge highlight on the right and a 2 px spine shadow on the left; it takes
/// the hero tilt.
class BookPlate extends ConsumerWidget {
  const BookPlate({super.key, required this.data, required this.width, required this.height});
  final GlassSeriesData data;
  final double width, height;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SeriesTiltGate(
        child: Container(
          key: const ValueKey('book-plate'),
          width: width,
          height: height,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 16, offset: Offset(0, 8))]),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(fit: StackFit.expand, children: [
              HomeCoverImage(url: data.series.coverUrl, width: width),
              const Positioned(right: 0, top: 0, bottom: 0, width: 1, child: ColoredBox(color: Color(0x66FFFFFF))),
              const Positioned(left: 0, top: 0, bottom: 0, width: 2, child: ColoredBox(color: Color(0x99000000))),
            ],),
          ),
        ),
      );
}

/// The book page (glass 8.13): the plate, the Literata front matter and the windowed Contents.
class BookVariant implements SeriesVariant {
  const BookVariant({this.mature = false});
  final bool mature;

  @override
  Widget header(BuildContext context, SeriesPageState page) => Consumer(builder: (context, ref, _) {
        final d = page.data;
        final progress = ref.watch(sourceSeriesProgressProvider(d.progressKey));
        final resume = seriesResume(d.readingOrder, progress, novel: true);
        final desktop = page.layout == SeriesLayout.desktop;
        final words = ref.watch(novelSeriesWordCountsProvider(d.identity)).valueOrNull ?? const {};
        final est = estimateSeriesLength(d.chapters.isEmpty ? d.series.chapterCount : d.chapters.length, words.values);
        final status = formatStatus(d.series.status);
        final facts = [
          '${d.chapters.isEmpty ? d.series.chapterCount : d.chapters.length} chapters',
          if (formatEstimatedWords(est) case final w?) w,
          if (formatEstimatedTotal(est) case final h?) h,
          if (status != null) status,
        ].join(' · ');
        final statuses = ref.watch(seriesChapterDownloadStatusProvider(d.identity)).valueOrNull ?? const {};
        final unsaved = d.chapters.where((c) => statuses[c.id]?.state != DownloadChapterState.complete).length;
        final running = statuses.values.any((s) => s.state == DownloadChapterState.queued || s.state == DownloadChapterState.downloading);
        final profile = ref.watch(activeProfileProvider) != null;
        final plate = KeyedSubtree(key: page.coverKey, child: BookPlate(data: d, width: desktop ? 180 : 144, height: desktop ? 260 : 208));
        final front = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Focus(focusNode: page.titleFocus, child: Semantics(header: true, child: Text(d.title, key: const ValueKey('book-title'), maxLines: 4, overflow: TextOverflow.ellipsis, style: literata(30, height: 36, wght: 560)))),
            if ((d.series.author ?? '').isNotEmpty) ...[const SizedBox(height: 6), Text('by ${d.series.author}', style: literata(17, style: FontStyle.italic, color: gt.colorLabel2))],
            const SizedBox(height: 10),
            SizedBox(width: 56, height: 1, child: ColoredBox(color: gt.colorSeparator)),
            const SizedBox(height: 10),
            GlassLabel(facts, key: const ValueKey('book-facts'), role: gt.typeMono, size: 13, color: gt.colorLabel2, maxLines: 2),
            if (est.sampleSize > 0) GlassLabel('Length estimated from ${est.sampleSize} chapters read so far', role: gt.typeCaption1, color: gt.colorLabel3, maxLines: 2),
          ],
        );
        final primary = GlassButton(
          key: const ValueKey('book-primary'),
          twin: windowTwin(context),
          label: resume.label,
          variant: GlassButtonVariant.primary,
          fullWidth: true,
          onPressed: resume.chapterKey == null ? null : page.commands.continueReading,
        );
        final follow = GlassButton(
          key: page.followKey,
          twin: windowTwin(context),
          label: d.followed == null ? 'Add to library' : 'In library',
          selected: d.followed != null,
          loading: followPending(ref),
          onPressed: isOnline(ref) ? page.commands.toggleFollow : null,
        );
        final download = !running && unsaved > 0
            ? GlassButton(key: const ValueKey('book-download'), label: 'Download book', semanticsLabel: 'Download book, $unsaved chapters', onPressed: profile ? page.downloadSeries : null, disabledReason: profile ? null : 'Downloads belong to a reading profile')
            : null;
        final more = Builder(builder: (c) => GlassButton(key: const ValueKey('book-more'), label: '⋯', semanticsLabel: 'More', variant: GlassButtonVariant.plain, onPressed: () => page.openMenu(rectOf(c))));
        final actions = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          primary,
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [follow, if (download != null) download, if (unsaved > 0 && download != null) GlassLabel('$unsaved', role: gt.typeMono, color: gt.colorLabel2), more]),
          // The Audiobook button with its live status (glass 8.13, mobile/37).
          const SizedBox(height: 8),
          GlassAudiobookButton(sourceId: d.sourceId, seriesKey: d.seriesKey),
        ],);
        final tags = SeriesTags(data: d, mature: mature, limit: 24);
        if (desktop) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [plate, const SizedBox(height: 16), front, const SizedBox(height: 16), actions, const SizedBox(height: 12), tags]);
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [plate, const SizedBox(width: 16), Expanded(child: front)]),
          const SizedBox(height: 16),
          actions,
          const SizedBox(height: 12),
          tags,
        ],);
      },);

  @override
  List<Widget> chapterSlivers(BuildContext context, SeriesPageState page) => [
        Consumer(builder: (context, ref, _) {
          final d = page.data;
          final state = chapterListState(d, online: isOnline(ref));
          if (state != null) {
            return SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: ChapterListNotice(state: state, sourceId: d.sourceId, listed: d.series.chapterCount, book: true)));
          }
          return BookContentsSliver(page: page);
        },),
      ];

  @override
  void primary(BuildContext context, SeriesPageState page) {
    final ref = page.ref;
    final d = page.data;
    final r = seriesResume(d.readingOrder, ref.read(sourceSeriesProgressProvider(d.progressKey)), novel: true);
    final key = r.chapterKey;
    if (key == null) return;
    openBook(context, ref, d, key, page: r.page, plateRect: rectOf(page.coverKey.currentContext ?? context));
  }
}

/// Pushes the novel route with the Book open extra (the plate rotates open while the paper expands).
/// [page] is the saved progress bucket of a half-read chapter, so it reopens where it was left.
void openBook(BuildContext context, WidgetRef ref, GlassSeriesData d, String chapterKey, {required Rect plateRect, int? page}) {
  final appDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  final paletteId = NovelPalettes.resolveChoice(ref.read(novelPaletteControllerProvider), appIsDark: appDark);
  final paper = NovelPalettes.byId(paletteId)?.bg ?? const Color(0xFFF4EEE2);
  final url = resolveCover(ref, d.series.coverUrl);
  GlassMotionEntry? e;
  if (!ref.read(glassMotionPrefsProvider).reduced) e = GlassMotion.recorder.begin(MotionName.bookOpen.label, kBookOpenDuration.inMilliseconds);
  unawaited(ref.read(skinRouterProvider).push<void>(Routes.novel(d.sourceId, d.seriesKey, chapterKey, {if (page != null && page > 1) 'page': page}), extra: bookOpenExtra(plateRect: plateRect, cover: url.isEmpty ? null : NetworkImage(url), paper: paper)));
  if (e != null) Future<void>.delayed(kBookOpenDuration, () => GlassMotion.recorder.end(e!));
}

/// The windowed Contents (glass 8.13): 400 rows around the focus with "Show earlier chapters (n)" and "Show more chapters (n)".
class BookContentsSliver extends ConsumerStatefulWidget {
  const BookContentsSliver({super.key, required this.page});
  final SeriesPageState page;

  @override
  ConsumerState<BookContentsSliver> createState() => _BookContentsSliverState();
}

class _BookContentsSliverState extends ConsumerState<BookContentsSliver> {
  int? _start, _end;

  @override
  Widget build(BuildContext context) {
    final page = widget.page;
    final d = page.data;
    final shown = shownChapters(d, page.chapters.order);
    final progress = ref.watch(sourceSeriesProgressProvider(d.progressKey));
    final statuses = ref.watch(seriesChapterDownloadStatusProvider(d.identity)).valueOrNull ?? const {};
    final active = ref.watch(seriesActiveChapterProgressProvider(d.identity));
    final words = ref.watch(novelSeriesWordCountsProvider(d.identity)).valueOrNull ?? const {};
    final focusKey = page.chapters.pulse ?? seriesResume(d.readingOrder, progress, novel: true).chapterKey;
    final focus = focusKey == null ? 0 : shown.indexWhere((c) => c.id == focusKey).clamp(0, shown.length - 1);
    final w = tocWindow(shown.length, focus);
    final start = _start ?? w.start, end = _end ?? w.end;
    final sel = page.chapters.selection;
    final slice = shown.sublist(start, end);
    return SliverMainAxisGroup(slivers: [
      if (start > 0)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GlassButton(key: const ValueKey('toc-earlier'), label: 'Show earlier chapters ($start)', variant: GlassButtonVariant.plain, onPressed: () => setState(() => _start = (start - 400).clamp(0, start))),
          ),
        ),
      SliverFixedExtentList.builder(
        key: page.chapters.rowsKey,
        itemExtent: kTocRowExtent * rowTextScale(context),
        itemCount: slice.length,
        itemBuilder: (context, i) {
          final c = slice[i];
          final row = TocRow(
            chapter: c,
            progress: progress[c.id],
            words: words[c.id],
            view: rowDownloadView(statuses[c.id], active, c.id, false),
            selectMode: sel.isActive,
            selected: sel.isSelected(c.id),
            saved: statuses[c.id]?.state == DownloadChapterState.complete,
            onTap: () {
              if (sel.isActive) return sel.toggle(c.id);
              final p = progress[c.id];
              openBook(context, ref, d, c.id, page: p == null || p.completed ? null : p.page, plateRect: rectOf(context));
            },
            onDownload: () => fire(enqueueSeriesChapters(ref, d, [c.id])),
          );
          return page.chapters.pulse == c.id ? Semantics(hint: 'current location', child: DecoratedBox(decoration: BoxDecoration(color: gt.colorIris600.withValues(alpha: 0.14)), child: row)) : row;
        },
      ),
      if (end < shown.length)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GlassButton(key: const ValueKey('toc-more'), label: 'Show more chapters (${(shown.length - end).clamp(0, 400)})', variant: GlassButtonVariant.plain, onPressed: () => setState(() => _end = (end + 400).clamp(0, shown.length))),
          ),
        ),
    ],);
  }
}

/// One contents row: a right-aligned Literata tabular ordinal in a 44 column, the title in Literata 16 (read rows in `label3`), meta
/// "3.4k words · 14 min", "42 %" in `iris400` while reading, and the download control.
class TocRow extends StatelessWidget {
  const TocRow({super.key, required this.chapter, required this.view, this.progress, this.words, this.selectMode = false, this.selected = false, this.saved = false, this.onTap, this.onDownload});
  final SourceChapterSummary chapter;
  final SourceChapterProgress? progress;
  final int? words;
  final ChapterDownloadView view;
  final bool selectMode, selected, saved;
  final VoidCallback? onTap, onDownload;

  @override
  Widget build(BuildContext context) {
    final e = tocEntry(number: chapter.number, title: chapter.title);
    final read = progress?.completed ?? false;
    final pct = progress != null && !read && progress!.pageCount > 0 ? '${(100 * progress!.page / progress!.pageCount).round()} %' : null;
    final meta = [
      if (words != null && words! > 0) '${words! >= 1000 ? '${(words! / 1000).toStringAsFixed(1)}k' : '$words'} words · ${(words! / 250).ceil()} min',
    ].join(' · ');
    return GlassPressable(
      key: ValueKey('toc-${chapter.id}'),
      material: GlassMaterial.content,
      shape: const GlassShape.superellipse(10),
      selected: selected,
      enabled: !(selectMode && saved),
      semanticsLabel: [if (e.ordinal != null) 'Chapter ${e.ordinal}', if (e.title != null) e.title!, if (read) 'Read', if (pct != null) pct].join(', '),
      semanticsHint: selectMode && saved ? 'Already on this device' : null,
      onTap: onTap,
      builder: (context, info) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
        child: Row(children: [
          if (selectMode) Padding(padding: const EdgeInsets.only(right: 8), child: Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, color: selected ? gt.colorIris500 : const Color(0x00000000), border: Border.all(color: gt.colorLabel3)))),
          SizedBox(width: 44, child: Text(e.ordinal ?? '·', textAlign: TextAlign.right, style: literata(16, color: gt.colorLabel2).copyWith(fontFeatures: const [FontFeature.tabularFigures()]))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.title ?? 'Chapter ${e.ordinal ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: literata(16, color: read ? gt.colorLabel3 : gt.colorLabel1)),
              if (meta.isNotEmpty || pct != null)
                Row(children: [
                  if (meta.isNotEmpty) GlassLabel(meta, role: gt.typeCaption1, color: gt.colorLabel3),
                  if (pct != null) ...[const SizedBox(width: 8), GlassLabel(pct, role: gt.typeCaption1, color: gt.colorIris400)],
                ],),
            ],),
          ),
          if (!selectMode) ...[
            ChapterReactionSummary(sourceId: chapter.sourceId, seriesKey: chapter.seriesId, chapterKey: chapter.id),
            GlassDownloadControl(view: view, chapterLabel: 'chapter ${e.ordinal ?? ''}', onDownload: onDownload),
          ],
        ],),
      ),
    );
  }
}
