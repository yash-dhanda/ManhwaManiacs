import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_selection.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/downloads/providers/bookmark_outbox_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/library/utils/mark_read.dart';
import 'package:manhwamaniacs/features/novels/utils/novel_book.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/reader/models/bookmark.dart';
import 'package:manhwamaniacs/features/reader/models/reading_progress.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/models/source_chapter_progress.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/features/sources/utils/chapter_sort_store.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/navigation.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/chapter_reaction_folio.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_segmented_control.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/downloads/run_feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/downloads/run_summary_line.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/downloads/series_download_card.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_data.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_shortcuts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_states.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/schedule_row.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/features/sources/utils/resume_order.dart';

const kNeedsConnection = 'Needs a connection.';

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

/// Toast with an optional Undo (8 s for an Undo, `durHoldToast` otherwise).
void featureToast(BuildContext context, String message,
    {String? undoLabel, VoidCallback? onUndo,}) {
  final t = cineOf(context);
  final m = ScaffoldMessenger.maybeOf(context);
  if (m == null) return;
  m
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: onUndo == null ? t.durHoldToast : t.durHoldToastUndo,
        action: onUndo == null
            ? null
            : SnackBarAction(label: undoLabel ?? 'Undo', onPressed: onUndo),
      ),
    );
}

/// The chapter-marking calls of §8.17, shared by the Feature and Book pages so
/// both send the same requests: Mark read (`manual: true` rows, 200 a time),
/// Mark unread (`DELETE` keys) and their Undos.
class ChapterMarks {
  ChapterMarks(this.ref, this.d);
  final WidgetRef ref;
  final FeatureData d;

  SourceSeriesRef get _key => (sourceId: d.sourceId, seriesId: d.seriesKey);

  void _refresh() => ref.invalidate(sourceSeriesServerProgressProvider(_key));

  /// Marks [chapters] read. Returns the keys that were newly marked.
  Future<List<String>> markRead(
    List<SourceChapterSummary> chapters, {
    required Set<String> previouslyCompleted,
  }) async {
    final repo = ref.read(readerRepositoryProvider);
    final rows = manualReadRows([
      for (final c in chapters)
        (sourceId: d.sourceId, seriesKey: d.seriesKey, chapterKey: c.id, chapterNumber: c.number, pageCount: c.pageCount, completed: false),
    ], at: manualMarkStamp(ref.read(sourceSeriesProgressProvider(_key))));
    for (final chunk in chunksOf200(rows)) {
      await repo.saveProgressBatch(chunk);
    }
    _refresh();
    return [for (final c in chapters) c.id];
  }

  /// The Undo of [markRead]: deletes only the rows that were not completed before.
  Future<void> undoMarkRead(Set<String> previouslyCompleted, List<String> marked) async {
    final keys = undoMarkReadKeys(previouslyCompleted, marked);
    if (keys.isEmpty) return;
    for (final chunk in chunksOf200(keys)) {
      await ref.read(readerRepositoryProvider).deleteProgress(sourceId: d.sourceId, seriesKey: d.seriesKey, chapterKeys: chunk);
    }
    _refresh();
  }

  /// Mark unread. Returns what was deleted, for the Undo.
  Future<Map<String, SourceChapterProgress>> markUnread(List<String> keys) async {
    // The merged (phone + server) positions, so an Undo re-posts rows that
    // exist only on the server too.
    final merged = ref.read(sourceSeriesProgressProvider(_key));
    final prior = {
      for (final k in keys)
        if (merged[k] != null) k: merged[k]!,
    };
    await ref
        .read(sourceProgressProvider.notifier)
        .forget(sourceId: d.sourceId, seriesId: d.seriesKey, chapterIds: keys);
    for (final chunk in chunksOf200(keys)) {
      await ref.read(readerRepositoryProvider).deleteProgress(sourceId: d.sourceId, seriesKey: d.seriesKey, chapterKeys: chunk);
    }
    _refresh();
    return prior;
  }

  /// The Undo of [markUnread]: re-posts the deleted rows.
  Future<void> undoMarkUnread(
    Map<String, SourceChapterProgress> deleted,
    Map<String, double?> numbers,
  ) async {
    final repo = ref.read(readerRepositoryProvider);
    final rows = [
      for (final e in deleted.entries)
        ProgressPush(
          sourceId: d.sourceId,
          seriesKey: d.seriesKey,
          chapterKey: e.key,
          chapterNumber: numbers[e.key],
          lastPage: e.value.page,
          pageCount: e.value.pageCount,
          isCompleted: e.value.completed,
          lastReadAt: e.value.updatedAt,
        ),
    ];
    for (final chunk in chunksOf200(rows)) {
      await repo.saveProgressBatch(chunk);
    }
    await ref.read(sourceProgressProvider.notifier).restoreRecords(
          sourceId: d.sourceId,
          seriesId: d.seriesKey,
          records: deleted,
        );
    _refresh();
  }

  /// A bookmark at page 1 of [c], through the bookmark outbox.
  Future<bool> bookmarkStart(SourceChapterSummary c, {BookmarkMedia media = BookmarkMedia.manga}) async {
    final b = await ref.read(bookmarkOutboxControllerProvider).create(
          id: (sourceId: d.sourceId, seriesKey: d.seriesKey, chapterKey: c.id),
          media: media,
          anchorIndex: 1,
          anchorFraction: 0,
          anchorTotal: c.pageCount,
          seriesTitle: d.title,
          chapterNumber: c.number,
        );
    return b != null;
  }
}

/// The row menu (long-press or the trailing dots): Mark read, Mark read up to
/// here, Mark unread, Download, Bookmark start. Offline the mark items are
/// disabled with "Needs a connection.". Returns the chosen id.
Future<String?> showChapterMenu(
  BuildContext context, {
  required bool online,
  bool showDownload = true,
}) {
  final t = cineOf(context);
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: t.colorPaper2,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (id, label, needsNet) in [
            ('read', 'Mark read', true),
            ('upto', 'Mark read up to here', true),
            ('unread', 'Mark unread', true),
            if (showDownload) ('download', 'Download', false),
            ('bookmark', 'Bookmark start', false),
          ])
            Tooltip(
              message: needsNet && !online ? kNeedsConnection : '',
              child: ListTile(
                minVerticalPadding: 12,
                enabled: !(needsNet && !online),
                title: Text(label),
                onTap: () => Navigator.pop(ctx, id),
              ),
            ),
        ],
      ),
    ),
  );
}

/// The CHAPTERS tab: toolbar, download card, schedule rows.
class ChaptersPanel extends ConsumerStatefulWidget {
  const ChaptersPanel({
    super.key,
    required this.data,
    required this.selection,
    this.commands,
  });

  final FeatureData data;
  final ChapterSelectionController selection;
  final FeatureCommands? commands;

  @override
  ConsumerState<ChaptersPanel> createState() => _ChaptersPanelState();
}

class _ChaptersPanelState extends ConsumerState<ChaptersPanel> {
  static const double _baseExtent = 56;

  /// A row is 56 at text scale 1.0 and grows with the scale (every height is a minimum, 7 intro).
  double get rowExtent => _baseExtent * math.max(1.0, MediaQuery.textScalerOf(context).scale(16) / 16 * 0.75);
  final _goToFocus = FocusNode();
  String? _order;
  String? _highlight;
  String _goToCaption = 'Type a chapter number.';
  String? _lastToggled;
  int? _cursor;
  Set<String> _run = {};
  int _runAlreadySaved = 0;
  final _runFeedback = RunFeedback();

  FeatureData get d => widget.data;
  String? get _profileId => ref.read(activeProfileProvider)?.id.toString();
  ChapterMarks get _marks => ChapterMarks(ref, d);
  SourceSeriesRef get _pkey => (sourceId: d.sourceId, seriesId: d.seriesKey);

  String get order =>
      _order ??
      chapterSortFor(
        ref.read(sharedPrefsProvider),
        profileId: _profileId,
        sourceId: d.sourceId,
        seriesKey: d.seriesKey,
        novel: false,
      );

  @override
  void initState() {
    super.initState();
    final cmd = widget.commands;
    if (cmd != null) {
      cmd.goTo = _goToFocus.requestFocus;
      cmd.toggleOrder = () => _setOrder(order == 'newest' ? 'oldest' : 'newest');
      cmd.chapterBy = _moveCursor;
    }
    // The first two rows warm their manifests as the page loads (P3).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pf = readerPrefetchOf(ref);
      for (final c in _shown.take(2)) {
        pf.onDwell(ReaderTarget.manifest(d.sourceId, d.seriesKey, c.id));
      }
    });
  }

  @override
  void dispose() {
    _goToFocus.dispose();
    super.dispose();
  }

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

  void _scrollToRow(int i) {
    final c = PrimaryScrollController.maybeOf(context);
    if (c != null && c.hasClients) {
      unawaited(c.animateTo(
        (i * rowExtent).clamp(0, c.position.maxScrollExtent),
        duration: CineMotion.reduced(context)
            ? const Duration(milliseconds: 150)
            : CineDur.column,
        curve: CineCurves.settle,
      ),);
    }
  }

  void _moveCursor(int delta) {
    final n = _shown.length;
    if (n == 0) return;
    setState(() => _cursor = ((_cursor ?? (delta > 0 ? -1 : n)) + delta).clamp(0, n - 1));
    _scrollToRow(_cursor!);
    final c = _shown[_cursor!];
    readerPrefetchOf(ref).onDwell(ReaderTarget.manifest(d.sourceId, d.seriesKey, c.id));
  }

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
    _scrollToRow(i);
  }

  void _open(SourceChapterSummary c) {
    final target = ReaderTarget.manifest(d.sourceId, d.seriesKey, c.id);
    readerPrefetchOf(ref).onPress(target);
    enterReader(context, target, entry: ReaderEntry.wipe);
  }

  Future<void> _download(List<SourceChapterSummary> chapters) async {
    final ctl = ref.read(downloadQueueControllerProvider.notifier);
    final statuses =
        ref.read(seriesChapterDownloadStatusProvider(d.identity)).valueOrNull ?? const {};
    final already =
        chapters.where((c) => statuses[c.id]?.state == DownloadChapterState.complete).length;
    _runFeedback.reset();
    setState(() {
      _run = {for (final c in chapters) c.id};
      _runAlreadySaved = already;
    });
    feedback(ref, HapticEvent.downloadStart);
    await ctl.enqueueChapters(queueRequests(d, chapters));
  }

  Set<String> _completed() {
    final p = ref.read(sourceSeriesProgressProvider(_pkey));
    return {
      for (final e in p.entries)
        if (e.value.completed) e.key,
    };
  }

  String _num(SourceChapterSummary c) =>
      c.number == null ? '' : ' ${c.number! % 1 == 0 ? c.number!.toInt() : c.number}';

  Future<void> _markRead(List<SourceChapterSummary> chapters, String message) async {
    final before = _completed();
    final marked = await _marks.markRead(chapters, previouslyCompleted: before);
    if (!mounted) return;
    feedback(ref, HapticEvent.select);
    featureToast(context, message,
        onUndo: () => unawaited(_marks.undoMarkRead(before, marked)),);
  }

  Future<void> _markUnread(SourceChapterSummary c) async {
    final deleted = await _marks.markUnread([c.id]);
    if (!mounted) return;
    feedback(ref, HapticEvent.select);
    featureToast(
      context,
      'Marked chapter${_num(c)} unread.',
      onUndo: () => unawaited(_marks.undoMarkUnread(deleted, {c.id: c.number})),
    );
  }

  Future<void> _rowMenu(SourceChapterSummary c) async {
    feedback(ref, HapticEvent.longpressOpen);
    final choice = await showChapterMenu(context, online: isOnline(ref));
    if (choice == null || !mounted) return;
    switch (choice) {
      case 'read':
        await _markRead([c], 'Marked chapter${_num(c)} read.');
      case 'upto':
        final progress = ref.read(sourceSeriesProgressProvider(_pkey));
        final refs = [
          for (final x in d.chapters)
            (key: x.id, number: x.number, completed: progress[x.id]?.completed ?? false),
        ];
        final keys = chaptersUpTo(refs, c.number ?? double.infinity).map((r) => r.key).toSet();
        final chapters = d.chapters.where((x) => keys.contains(x.id)).toList();
        await _markRead(chapters, 'Marked ${chapters.length} chapters read.');
      case 'unread':
        await _markUnread(c);
      case 'download':
        await _download([c]);
      case 'bookmark':
        final ok = await _marks.bookmarkStart(c);
        if (!mounted) return;
        if (ok) feedback(ref, HapticEvent.bookmarkAdd, SoundEvent.bookmarkAdd);
        featureToast(context, ok ? 'Bookmarked chapter${_num(c)}.' : "Couldn't bookmark it.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = cineOf(context);
    final online = isOnline(ref);
    final progress = ref.watch(sourceSeriesProgressProvider(_pkey));
    final statuses =
        ref.watch(seriesChapterDownloadStatusProvider(d.identity)).valueOrNull ?? const {};
    final shown = _shown;
    final savedCount =
        statuses.values.where((s) => s.state == DownloadChapterState.complete).length;
    final current = _currentKey(progress);
    final pf = readerPrefetchOf(ref);
    final active = ref.watch(seriesActiveChapterProgressProvider(d.identity));
    final pauseReason = ref.watch(downloadQueueControllerProvider.select((q) => q.pauseReason));
    final paused = pauseReason == DownloadQueuePauseReason.freeSpaceFloor ||
        pauseReason == DownloadQueuePauseReason.cap ||
        pauseReason == DownloadQueuePauseReason.userPaused;

    ref.listen(seriesChapterDownloadStatusProvider(d.identity), (prev, next) {
      _runFeedback.check(ref, _run, next.valueOrNull ?? const {});
    });

    if (d.chapters.isEmpty) {
      return CustomScrollView(
        key: const PageStorageKey('chapters'),
        slivers: [
          SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
          SliverToBoxAdapter(child: _ChaptersNotice(data: d, online: online)),
        ],
      );
    }

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
                        SizedBox(
                          width: 200,
                          child: CineSegmentedControl(
                            key: const Key('chapter-order'),
                            labels: const ['NEWEST', 'OLDEST'],
                            index: order == 'newest' ? 0 : 1,
                            onChanged: (i) => _setOrder(i == 0 ? 'newest' : 'oldest'),
                          ),
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
                            focusNode: _goToFocus,
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
                    SeriesDownloadCard(
                      series: d.identity,
                      listed: d.chapters.length,
                      onStorage: () => context.go(ScreenId.downloads.path),
                    ),
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
                  final canMark = online && !selecting;
                  return ScheduleRow(
                    chapter: c,
                    progress: p,
                    downloadState: st?.state,
                    selecting: selecting,
                    selected: widget.selection.isSelected(c.id),
                    current: c.id == current,
                    highlighted: c.id == _highlight,
                    cursor: i == _cursor,
                    paused: paused,
                    pauseReason: paused ? pauseReason : null,
                    markProgress: active != null &&
                            active.chapterKey == c.id &&
                            active.progress.pageTotal > 0
                        ? active.progress.pagesDone / active.progress.pageTotal
                        : 0,
                    markPage: active != null && active.chapterKey == c.id && active.progress.pageTotal > 0
                        ? active.progress.pagesDone
                        : null,
                    reactionSlot: ChapterReactionFolio(sourceId: d.sourceId, seriesKey: d.seriesKey, chapterKey: c.id, chapterNumber: c.number),
                    onPress: () => pf.onPress(ReaderTarget.manifest(d.sourceId, d.seriesKey, c.id)),
                    onDwell: () => pf.onDwell(ReaderTarget.manifest(d.sourceId, d.seriesKey, c.id)),
                    onSwipeRead: canMark
                        ? () => unawaited(_markRead([c], 'Marked chapter${_num(c)} read.'))
                        : null,
                    onMarkTap: () => unawaited(_download([c])),
                    onMenu: () => unawaited(_rowMenu(c)),
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
                        _lastToggled = c.id;
                      } else if (selecting) {
                        if (st?.state != DownloadChapterState.complete) {
                          widget.selection.toggle(c.id);
                          _lastToggled = c.id;
                        }
                      } else {
                        unawaited(_rowMenu(c));
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

/// The three empty CHAPTERS states: offline, unavailable, none.
class _ChaptersNotice extends ConsumerWidget {
  const _ChaptersNotice({required this.data, required this.online});
  final FeatureData data;
  final bool online;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = cineOf(context);
    final source = ref.watch(sourcesListProvider).valueOrNull?.cast<SourceSummary?>().firstWhere(
          (x) => x!.id == data.sourceId,
          orElse: () => null,
        );
    final name = source?.name ?? data.sourceId;
    final n = data.series.chapterCount;
    String text;
    Widget? action;
    if (!online) {
      text = 'The chapter list needs a connection.';
    } else if (n > 0) {
      text = '$name lists $n chapters but returned none just now — usually the source, not you.';
      action = TextButton(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        onPressed: () => ref.invalidate(
            sourceSeriesDetailProvider((sourceId: data.sourceId, seriesId: data.seriesKey)),),
        child: const Text('Try again'),
      );
    } else {
      text = "No chapters yet. The source hasn't published any.";
      action = TextButton(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        onPressed: () =>
            context.canPop() ? context.pop() : context.go('/sources/${data.sourceId}'),
        child: const Text('Back to the source'),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, key: const Key('chapters-notice'), style: TextStyle(color: t.colorInk80)),
          if (action != null) action,
        ],
      ),
    );
  }
}
