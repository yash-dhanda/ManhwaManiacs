import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart' show contentModeScopeProvider;
import 'package:manhwamaniacs/features/library/models/reading_history_item.dart';
import 'package:manhwamaniacs/features/library/providers/history_pages_provider.dart';
import 'package:manhwamaniacs/features/library/providers/local_read_marks_provider.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/swipe_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/pull_to_refresh.dart';
import 'package:manhwamaniacs/skins/glass/primitives/segmented.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/history_tiles.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/library_common.dart' show roleIcon;
import 'package:manhwamaniacs/skins/glass/screens/library/library_keys.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/library_section.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/shelf_actions.dart' show glassShelfActionsProvider;
import 'package:manhwamaniacs/skins/glass/shell/global_keys.dart' show useGlassRefresh;

enum _HistoryView { series, timeline }

/// History (glass 8.19): By series or Timeline, day headers, history tiles (a poster, its progress line and the play orb), "Load more"
/// 50 at a time, and every state. Offline it lists this device's own recent reads under the lens.
class GlassHistoryPage extends ConsumerStatefulWidget {
  const GlassHistoryPage({super.key});

  @override
  ConsumerState<GlassHistoryPage> createState() => _GlassHistoryPageState();
}

class _GlassHistoryPageState extends ConsumerState<GlassHistoryPage> {
  _HistoryView _view = _HistoryView.series;
  final GlassPullToRefreshController _pull = GlassPullToRefreshController();
  bool _loadingMore = false;
  bool _moreFailed = false;
  VoidCallback? _offRefresh;

  bool get _bySeries => _view == _HistoryView.series;

  @override
  void initState() {
    super.initState();
    _offRefresh = useGlassRefresh(() => unawaited(_pull.refresh()));
  }

  @override
  void dispose() {
    _offRefresh?.call();
    _pull.dispose();
    super.dispose();
  }

  Future<RefreshResult> _refresh() async {
    ref.invalidate(historyPagesProvider(_bySeries));
    try {
      await ref.read(historyPagesProvider(_bySeries).future);
      return RefreshResult.changed;
    } catch (_) {
      return RefreshResult.unchanged;
    }
  }

  Future<void> _more() async {
    if (_loadingMore) return;
    setState(() {
      _loadingMore = true;
      _moreFailed = false;
    });
    final ok = await ref.read(historyPagesProvider(_bySeries).notifier).loadEarlier();
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      _moreFailed = !ok;
    });
    if (!ok) showGlassToast(ref, const GlassToastSpec("Couldn't load more", kind: GlassToastKind.error));
  }

  Widget _lens(LensSituation s, String title, {String? description, LensAction? primary, GlassLensTone tone = GlassLensTone.empty}) =>
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(vertical: 32), child: GlassObjectLens(situation: s, title: title, description: description, tone: tone, primary: primary)));

  /// This device's own recent reads, newest first, at most 20, behind the 18+ gate.
  List<ReadingHistoryItem> _local() {
    final records = ref.read(sourceProgressProvider);
    final marks = ref.read(localReadMarksProvider);
    final out = <({String source, String series, String chapter, DateTime at, int page, int count, bool done})>[];
    for (final e in records.entries) {
      final a = e.key.indexOf(':');
      if (a <= 0) continue;
      final source = e.key.substring(0, a);
      final rest = e.key.substring(a + 1);
      final b = rest.lastIndexOf(':');
      if (b <= 0) continue;
      final series = rest.substring(0, b);
      if (marks.of(sourceId: source, seriesKey: series) == null) continue;
      out.add((source: source, series: series, chapter: rest.substring(b + 1), at: e.value.updatedAt, page: e.value.page, count: e.value.pageCount, done: e.value.completed));
    }
    out.sort((x, y) => y.at.compareTo(x.at));
    var id = 0;
    return [
      for (final r in out.take(20))
        ReadingHistoryItem(id: --id, sourceId: r.source, seriesKey: r.series, chapterKey: r.chapter, lastPage: r.page, pageCount: r.count, isCompleted: r.done, lastReadAt: r.at, seriesTitle: r.series.replaceAll(RegExp(r'[-_]+'), ' ')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(historyPagesProvider(_bySeries));
    final scope = ref.watch(contentModeScopeProvider);
    final now = ref.watch(clockProvider)();
    final frame = GlassFrame.of(context);
    final wide = frame != GlassFrameKind.phone;
    final pages = async.valueOrNull;
    final rows = <ReadingHistoryItem>[
      if (pages != null) for (final p in pages) ...scope.filter(p, (r) => r.sourceId),
    ];
    final hasEarlier = pages != null && nextHistoryOffset(pages) != null;

    final slivers = <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassSegmented<_HistoryView>(
            asTabs: true,
            segments: const [GlassSegment(value: _HistoryView.series, label: 'By series'), GlassSegment(value: _HistoryView.timeline, label: 'Timeline')],
            selected: _view,
            onSelected: (v) => setState(() => _view = v),
          ),
        ),
      ),
    ];

    if (async.isLoading && pages == null) {
      slivers.add(SliverToBoxAdapter(child: GlassSkeletonGroup(child: Wrap(spacing: 12, runSpacing: 12, children: [for (var i = 0; i < 10; i++) GlassSkeleton(width: 110, height: 190, index: i)]))));
    } else if (async.hasError && pages == null) {
      final offline = async.error is NetworkError || async.error is TimeoutError;
      slivers.add(offline
          ? _lens(LensSituation.offline, 'Reading history needs a connection', tone: GlassLensTone.offline)
          : _lens(LensSituation.loadError, "Couldn't load your history", tone: GlassLensTone.error, primary: LensAction('Try again', () => ref.invalidate(historyPagesProvider(_bySeries)))),);
      if (offline) {
        final local = _local();
        if (local.isNotEmpty) {
          slivers.add(SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.only(bottom: 8), child: GlassLabel('On this device', role: gt.typeFootnote, upper: true, color: gt.colorLabel2))));
          slivers.add(SliverList.builder(itemCount: local.length, itemBuilder: (context, i) => HistoryTimelineRow(item: local[i])));
        }
      }
    } else if (rows.isEmpty) {
      slivers.add(_lens(LensSituation.history, 'Nothing read yet', description: 'Open a chapter and it will appear here as you go.', primary: LensAction('Go to library', () => GoRouter.of(context).go(Routes.library()))));
    } else {
      // Day groups in order.
      final groups = <(String, List<ReadingHistoryItem>)>[];
      for (final r in rows) {
        final h = historyDayHeader(r.lastReadAt, now);
        if (groups.isEmpty || groups.last.$1 != h) groups.add((h, []));
        groups.last.$2.add(r);
      }
      for (final g in groups) {
        slivers.add(SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.only(top: 12, bottom: 8), child: Semantics(header: true, headingLevel: 2, child: GlassLabel(g.$1, role: gt.typeFootnote, wght: 600, upper: true, color: gt.colorLabel2)))));
        if (_bySeries) {
          slivers.add(SliverLayoutBuilder(builder: (context, c) {
            const gap = 12.0;
            final cols = wide ? (c.crossAxisExtent / 140).floor().clamp(3, 8) : 3;
            final w = (c.crossAxisExtent - gap * (cols - 1)) / cols;
            return SliverToBoxAdapter(child: Wrap(spacing: gap, runSpacing: gap, children: [for (final r in g.$2) HistoryTileItem(key: ValueKey('h-${r.id}'), item: r, width: w)]));
          },),);
        } else {
          slivers.add(SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: GlassSwipeGroup(
                  child: Column(children: [
                    for (final r in g.$2)
                      GlassSwipeRow(
                        key: ValueKey('t-${r.id}'),
                        name: r.seriesTitle ?? 'Unknown series',
                        leading: [
                          SwipeAction(id: 'finish', label: 'Mark finished', glyph: roleIcon(GlassIconRole.select), tone: SwipeTone.success, run: () => ref.read(glassHistoryMarkProvider)(r)),
                        ],
                        child: HistoryTimelineRow(item: r),
                      ),
                  ],),
                ),
              ),
            ),
          ),);
        }
      }
      if (hasEarlier || _moreFailed) {
        slivers.add(SliverToBoxAdapter(
          child: Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Center(child: GlassButton(label: 'Load more', loading: _loadingMore, onPressed: () => unawaited(_more())))),
        ),);
      }
    }

    return LibraryKeys(
      group: 'History',
      section: LibrarySection.history,
      bindings: [
        LibraryKey(description: 'Move through the list', keys: const ['↑', '↓'], match: kKey(LogicalKeyboardKey.arrowDown), action: () => FocusManager.instance.primaryFocus?.nextFocus()),
        LibraryKey(description: '', keys: const [], match: kKey(LogicalKeyboardKey.arrowUp), action: () => FocusManager.instance.primaryFocus?.previousFocus()),
      ],
      child: LibrarySectionFrame(
        section: LibrarySection.history,
        physics: kGlassRefreshPhysics,
        refreshSliver: GlassPullToRefresh(controller: _pull, onRefresh: _refresh),
        slivers: [...slivers, const SliverToBoxAdapter(child: SizedBox(height: 24))],
      ),
    );
  }
}

/// Mark finished for a Timeline swipe (a Provider so a swipe action outlives the row).
final glassHistoryMarkProvider = Provider<Future<void> Function(ReadingHistoryItem)>((ref) => (i) => ref.read(glassShelfActionsProvider).markChapterRead(i));
