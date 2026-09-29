import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_selection.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/downloads/utils/download_mark.dart';
import 'package:manhwamaniacs/features/library/utils/mark_read.dart';
import 'package:manhwamaniacs/features/novels/utils/novel_book.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/reader/models/reading_progress.dart';
import 'package:manhwamaniacs/features/sources/models/source_chapter_progress.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/features/sources/utils/chapter_date.dart';
import 'package:manhwamaniacs/features/sources/utils/chapter_label.dart';
import 'package:manhwamaniacs/features/sources/utils/chapter_sort_store.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/downloads/run_summary_line.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/downloads/series_download_card.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_data.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_states.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Requests for [chapters] (all `manga` kind unless [kind] says otherwise),
/// in the one shape `enqueueChapters` takes.
List<ChapterQueueRequest> queueRequests(
  FeatureData d,
  Iterable<SourceChapterSummary> chapters, {
  DownloadKind kind = DownloadKind.manga,
}) =>
    [
      for (final c in chapters)
        (
          id: (sourceId: d.sourceId, seriesKey: d.seriesKey, chapterKey: c.id),
          chapterNumber: c.number,
          title: c.title,
          seriesTitle: d.title,
          kind: kind,
        ),
    ];

/// Pushes `completed` progress rows (200 at a time) for [chapters].
Future<void> markChaptersRead(
    WidgetRef ref, FeatureData d, List<SourceChapterSummary> chapters,) async {
  final repo = ref.read(readerRepositoryProvider);
  for (final chunk in chunked(chapters)) {
    // TODO(mobile/08): send `manual: true` rows through manualReadRows().
    await repo.saveProgressBatch([
      for (final c in chunk)
        ProgressPush(
          sourceId: d.sourceId,
          seriesKey: d.seriesKey,
          chapterKey: c.id,
          chapterNumber: c.number,
          lastPage: c.pageCount,
          pageCount: c.pageCount,
          isCompleted: true,
        ),
    ]);
  }
  ref.invalidate(sourceSeriesServerProgressProvider((sourceId: d.sourceId, seriesId: d.seriesKey)));
}

/// The CHAPTERS tab: toolbar, download card, schedule rows.
class ChaptersPanel extends ConsumerStatefulWidget {
  const ChaptersPanel({super.key, required this.data, required this.selection});

  final FeatureData data;
  final ChapterSelectionController selection;

  @override
  ConsumerState<ChaptersPanel> createState() => _ChaptersPanelState();
}

class _ChaptersPanelState extends ConsumerState<ChaptersPanel> {
  static const double rowExtent = 56;
  String? _order;
  String? _highlight;
  String _goToCaption = 'Type a chapter number.';
  String? _lastToggled;
  Set<String> _run = {};
  int _runAlreadySaved = 0;

  FeatureData get d => widget.data;
  String? get _profileId => ref.read(activeProfileProvider)?.id.toString();

  String get order =>
      _order ??
      chapterSortFor(
        ref.read(sharedPrefsProvider),
        profileId: _profileId,
        sourceId: d.sourceId,
        seriesKey: d.seriesKey,
        novel: false,
      );

  void _setOrder(String o) {
    setState(() => _order = o);
    saveChapterSort(
      ref.read(sharedPrefsProvider),
      profileId: _profileId,
      sourceId: d.sourceId,
      seriesKey: d.seriesKey,
      order: o,
    );
  }

  List<SourceChapterSummary> get _shown =>
      order == 'newest' ? d.readingOrder.reversed.toList() : d.readingOrder;

  void _goTo(String text) {
    final matches = goToChapterMatches(d.chapters, text);
    if (matches.isEmpty) {
      setState(() {
        _highlight = null;
        _goToCaption = goToChapterQuery(text) == null
            ? 'Type a chapter number.'
            : 'No chapter ${goToChapterQuery(text)!.toInt()} in this series.';
      });
      return;
    }
    final i = _shown.indexWhere((c) => c.id == matches.first.id);
    setState(() {
      _highlight = matches.first.id;
      _goToCaption = 'Type a chapter number.';
    });
    final c = PrimaryScrollController.maybeOf(context);
    if (c != null && c.hasClients) {
      c.animateTo(
        (i * rowExtent).clamp(0, c.position.maxScrollExtent),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _open(SourceChapterSummary c) => context.push(Routes.reader(d.sourceId, d.seriesKey, c.id));

  Future<void> _download(List<SourceChapterSummary> chapters) async {
    final ctl = ref.read(downloadQueueControllerProvider.notifier);
    final statuses =
        ref.read(seriesChapterDownloadStatusProvider(d.identity)).valueOrNull ?? const {};
    final already =
        chapters.where((c) => statuses[c.id]?.state == DownloadChapterState.complete).length;
    setState(() {
      _run = {for (final c in chapters) c.id};
      _runAlreadySaved = already;
    });
    await ctl.enqueueChapters(queueRequests(d, chapters));
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _rowMenu(SourceChapterSummary c) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: cineOf(context).colorPaper2,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (id, label) in const [
              ('read', 'Mark read'),
              ('upto', 'Mark read up to here'),
              ('download', 'Download'),
            ])
              ListTile(
                minVerticalPadding: 12,
                title: Text(label),
                onTap: () => Navigator.pop(ctx, id),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    switch (choice) {
      case 'read':
        await markChaptersRead(ref, d, [c]);
        _toast('Marked chapter ${c.number?.toString() ?? ''} read.');
      case 'upto':
        final progress =
            ref.read(sourceSeriesProgressProvider((sourceId: d.sourceId, seriesId: d.seriesKey)));
        final refs = [
          for (final x in d.chapters)
            (key: x.id, number: x.number, completed: progress[x.id]?.completed ?? false),
        ];
        final keys = chaptersUpTo(refs, c.number ?? double.infinity).map((r) => r.key).toSet();
        final chapters = d.chapters.where((x) => keys.contains(x.id)).toList();
        await markChaptersRead(ref, d, chapters);
        _toast('Marked ${chapters.length} chapters read.');
      case 'download':
        await _download([c]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = cineOf(context);
    final progress =
        ref.watch(sourceSeriesProgressProvider((sourceId: d.sourceId, seriesId: d.seriesKey)));
    final statuses =
        ref.watch(seriesChapterDownloadStatusProvider(d.identity)).valueOrNull ?? const {};
    final shown = _shown;
    final savedCount =
        statuses.values.where((s) => s.state == DownloadChapterState.complete).length;
    final current = _currentKey(progress);

    return ListenableBuilder(
      listenable: widget.selection,
      builder: (context, _) {
        final selecting = widget.selection.isActive;
        return CustomScrollView(
          key: const PageStorageKey('chapters'),
          slivers: [
            SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SegmentedButton<String>(
                          key: const Key('chapter-order'),
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(value: 'newest', label: Text('NEWEST')),
                            ButtonSegment(value: 'oldest', label: Text('OLDEST')),
                          ],
                          selected: {order},
                          onSelectionChanged: (s) => _setOrder(s.first),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                          onPressed: selecting ? widget.selection.end : widget.selection.begin,
                          child: Text(selecting ? 'Done' : 'Select'),
                        ),
                        SizedBox(
                          width: 160,
                          child: TextField(
                            key: const Key('go-to'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textInputAction: TextInputAction.go,
                            decoration:
                                const InputDecoration(labelText: 'Chapter number', isDense: true),
                            onSubmitted: _goTo,
                          ),
                        ),
                      ],
                    ),
                    Text(_goToCaption, style: TextStyle(fontSize: 12, color: t.colorInk60)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('$savedCount OF ${d.chapters.length} SAVED',
                            style: kickerStyle(context),),
                        const Spacer(),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
                          onPressed: widget.selection.begin,
                          child: const Text('Download'),
                        ),
                      ],
                    ),
                    SeriesDownloadCard(series: d.identity, listed: d.chapters.length),
                    DownloadRunLine(
                      series: d.identity,
                      runKeys: _run,
                      alreadySaved: _runAlreadySaved,
                      onDismiss: () => setState(() => _run = {}),
                      onManage: () => context.go(ScreenId.downloads.path),
                    ),
                  ],
                ),
              ),
            ),
            SliverFixedExtentList(
              itemExtent: rowExtent,
              delegate: SliverChildBuilderDelegate(
                childCount: shown.length,
                (context, i) {
                  final c = shown[i];
                  final p = progress[c.id];
                  final st = statuses[c.id];
                  return _ScheduleRow(
                    chapter: c,
                    progress: p,
                    downloadState: st?.state,
                    selecting: selecting,
                    selected: widget.selection.isSelected(c.id),
                    current: c.id == current,
                    highlighted: c.id == _highlight,
                    onTap: () {
                      if (selecting) {
                        if (st?.state == DownloadChapterState.complete) return;
                        widget.selection.toggle(c.id);
                        _lastToggled = c.id;
                      } else {
                        _open(c);
                      }
                    },
                    onLongPress: () {
                      if (selecting && _lastToggled != null) {
                        final a = shown.indexWhere((x) => x.id == _lastToggled);
                        final lo = a < i ? a : i, hi = a < i ? i : a;
                        widget.selection.replaceWith({
                          ...widget.selection.selected,
                          for (final x in shown.sublist(lo, hi + 1))
                            if (statuses[x.id]?.state != DownloadChapterState.complete) x.id,
                        });
                      } else {
                        _rowMenu(c);
                      }
                    },
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        );
      },
    );
  }

  /// The chapter to continue: the most recently touched, or none.
  String? _currentKey(Map<String, SourceChapterProgress> progress) {
    String? best;
    DateTime? at;
    for (final e in progress.entries) {
      if (e.value.completed) continue;
      if (at == null || e.value.updatedAt.isAfter(at)) {
        best = e.key;
        at = e.value.updatedAt;
      }
    }
    return best;
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.chapter,
    required this.progress,
    required this.downloadState,
    required this.selecting,
    required this.selected,
    required this.current,
    required this.highlighted,
    required this.onTap,
    required this.onLongPress,
  });

  final SourceChapterSummary chapter;
  final SourceChapterProgress? progress;
  final DownloadChapterState? downloadState;
  final bool selecting;
  final bool selected;
  final bool current;
  final bool highlighted;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final t = cineOf(context);
    final label = chapterLabel(number: chapter.number, title: chapter.title);
    final n = chapter.number;
    final read = progress?.completed ?? false;
    final saved = downloadState == DownloadChapterState.complete;
    final mark = downloadMarkState(downloadState);
    final date = chapterDateLabel(chapter.releaseDate);
    final caption = [
      if (date != null) date,
      if (chapter.pageCount > 0) '${chapter.pageCount} PAGES',
    ].join(' · ');
    final ink = read ? t.colorInk45 : t.colorInk100;
    return Semantics(
      button: true,
      selected: selected,
      label: '${label.primary}${label.secondary != null ? ', ${label.secondary}' : ''}'
          '${read ? ', read' : ''}, ${downloadMarkLabel(mark)}',
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            color: selected
                ? t.colorPaper3
                : (current || highlighted)
                    ? t.colorSpotWash
                    : null,
            border: selected ? Border(left: BorderSide(color: t.colorSpot, width: 2)) : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              if (selecting)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    (selected || saved) ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 20,
                    color: saved ? t.colorInk30 : t.colorInk100,
                  ),
                ),
              SizedBox(
                width: 56,
                child: Text(
                  n == null ? '·' : (n % 1 == 0 ? n.toInt().toString() : n.toString()),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: t.colorSpot,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.secondary ?? label.primary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 16, color: ink),
                    ),
                    if (caption.isNotEmpty || current)
                      Text(
                        current ? 'READING · $caption' : caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, letterSpacing: 0.8, color: t.colorInk60),
                      ),
                  ],
                ),
              ),
              if (progress != null && !read && progress!.pageCount > 0)
                Text('${progress!.page}/${progress!.pageCount}',
                    style: TextStyle(fontSize: 12, color: t.colorSpot),)
              else if (read)
                Text('READ', style: TextStyle(fontSize: 10, color: t.colorInk45)),
              _MarkBox(mark: mark, spot: t.colorSpot, ink: t.colorInk45),
            ],
          ),
        ),
      ),
    );
  }
}

/// TODO(mobile/04): replace with `CineDownloadMark`; a stand-in that already
/// speaks [downloadMarkLabel] / [downloadMarkTooltip].
class _MarkBox extends StatelessWidget {
  const _MarkBox({required this.mark, required this.spot, required this.ink});
  final DownloadMarkState mark;
  final Color spot;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final icon = switch (mark) {
      MarkNone() => Icons.cloud_download_outlined,
      MarkQueued() => Icons.schedule,
      MarkDownloading() => Icons.downloading,
      MarkSaved() => Icons.check_box,
      MarkFailed() => Icons.error_outline,
      MarkPaused() => Icons.pause_circle_outline,
      MarkStale() => Icons.cloud_download_outlined,
    };
    final color =
        switch (mark) { MarkDownloading() || MarkPaused() || MarkStale() => spot, _ => ink };
    return Tooltip(
      message: downloadMarkTooltip(mark),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Semantics(label: downloadMarkLabel(mark), child: Icon(icon, size: 16, color: color)),
      ),
    );
  }
}
