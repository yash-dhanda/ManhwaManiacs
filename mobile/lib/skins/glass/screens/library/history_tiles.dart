import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart' show contentModeScopeProvider;
import 'package:manhwamaniacs/features/library/models/reading_history_item.dart';
import 'package:manhwamaniacs/features/library/utils/history_continue.dart';
import 'package:manhwamaniacs/features/library/utils/relative_read_time.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/history_tile.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/context_menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/row_shell.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_actions.dart' show openSeries;
import 'package:manhwamaniacs/skins/glass/screens/home/home_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/library_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/shelf_actions.dart';
import 'package:manhwamaniacs/skins/glass/transitions/dive.dart';
import 'package:manhwamaniacs/skins/glass/transitions/poster_zoom.dart' show GlassCoverHero;

/// "Today", "Yesterday", "This week" or "Earlier" for a day header (glass 8.19).
String historyDayHeader(DateTime? at, DateTime now) {
  if (at == null) return 'Earlier';
  final a = at.toLocal(), n = now.toLocal();
  final gap = DateTime(n.year, n.month, n.day).difference(DateTime(a.year, a.month, a.day)).inDays;
  if (gap <= 0) return 'Today';
  if (gap == 1) return 'Yesterday';
  if (gap < 7) return 'This week';
  return 'Earlier';
}

/// "p. 18" (manga) or "42 %" (novel).
String historyPosition(ReadingHistoryItem i, {required bool novel}) {
  if (novel) return '${i.pageCount <= 0 ? 0 : ((i.lastPage / i.pageCount) * 100).round().clamp(0, 100)} %';
  return 'p. ${i.lastPage}';
}

double historyProgress(ReadingHistoryItem i) => i.isCompleted ? 1 : (i.pageCount <= 0 ? 0 : (i.lastPage / i.pageCount).clamp(0.0, 1.0));

String historyWhen(ReadingHistoryItem i, DateTime now) {
  final ch = i.chapterNumber == null ? '' : 'Ch ${i.chapterNumber! % 1 == 0 ? i.chapterNumber!.toInt() : i.chapterNumber}';
  final at = i.lastReadAt == null ? '' : relativeReadTime(i.lastReadAt!, now: now);
  return [ch, at].where((e) => e.isNotEmpty).join(' · ');
}

/// The shared actions of a history row: Continue (the reader at the saved spot, or the next chapter when finished), Open series, Mark finished.
class HistoryActions {
  HistoryActions(this.ref, this.context);
  final WidgetRef ref;
  final BuildContext context;

  Future<void> cont(ReadingHistoryItem item, Rect from) async {
    final r = await ref.read(historyContinueProvider)(item);
    if (!context.mounted) return;
    if (r.toSeriesPage) {
      await openSeries(ref, item.sourceId, item.seriesKey, from: from);
      return;
    }
    final loc = r.isNovel ? Routes.novel(r.sourceId, r.seriesKey, r.chapterKey!) : Routes.reader(r.sourceId, r.seriesKey, r.chapterKey!, {if (r.page != null && r.page! > 1) 'page': r.page});
    await enterReader(context, ref, loc, fromRect: from);
  }

  Future<void> open(ReadingHistoryItem item, Rect from) => openSeries(ref, item.sourceId, item.seriesKey, from: from);

  /// Mark read of this chapter only, through `mark_read.dart` (`manual: true`); no streak, goal or Statistics effect.
  Future<void> markFinished(ReadingHistoryItem item) => ref.read(glassShelfActionsProvider).markChapterRead(item);

  List<GlassMenuEntry> menu(ReadingHistoryItem item, Rect from) => [
        GlassMenuEntry(label: 'Continue', onSelected: () => unawaited(cont(item, from))),
        GlassMenuEntry(label: 'Open series', onSelected: () => unawaited(open(item, from))),
        if (!item.isCompleted)
          GlassMenuEntry(label: 'Mark finished', run: () async {
            await markFinished(item);
            showGlassToast(ref, const GlassToastSpec('Marked finished'));
          },),
      ];
}

/// One By-series tile (glass 8.19): a poster with its progress line and the play orb.
class HistoryTileItem extends ConsumerWidget {
  const HistoryTileItem({super.key, required this.item, required this.width});
  final ReadingHistoryItem item;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(contentModeScopeProvider);
    final novel = scope.novelsEnabled && scope.modeOf(item.sourceId) == ContentMode.novel;
    final now = ref.watch(clockProvider)();
    final acts = HistoryActions(ref, context);
    return Builder(builder: (context) {
      Rect rect() => globalRectOf(context);
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPress: () => unawaited(showGlassContextMenu(context, sourceRect: rect(), preview: ClipRRect(borderRadius: BorderRadius.circular(14), child: HomeCoverImage(url: item.coverUrl, width: width)), kind: GlassPreviewKind.poster, title: item.seriesTitle ?? 'Unknown series', entries: acts.menu(item, rect()))),
        child: GlassHistoryTile(
          width: width,
          cover: GlassCoverHero(sourceId: item.sourceId, seriesKey: item.seriesKey, child: HomeCoverImage(url: item.coverUrl, width: width)),
          title: item.seriesTitle ?? 'Unknown series',
          when: historyWhen(item, now),
          position: item.isCompleted ? 'Next' : historyPosition(item, novel: novel),
          progress: historyProgress(item),
          onOpen: () => unawaited(acts.open(item, rect())),
          onResume: () => unawaited(acts.cont(item, rect())),
        ),
      );
    },);
  }
}

/// A Timeline row: one read chapter as a plain row.
class HistoryTimelineRow extends ConsumerWidget {
  const HistoryTimelineRow({super.key, required this.item});
  final ReadingHistoryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(contentModeScopeProvider);
    final novel = scope.novelsEnabled && scope.modeOf(item.sourceId) == ContentMode.novel;
    final now = ref.watch(clockProvider)();
    final acts = HistoryActions(ref, context);
    final title = item.seriesTitle ?? 'Unknown series';
    return Builder(builder: (context) {
      Rect rect() => globalRectOf(context);
      return GlassRowShell(
        semanticsLabel: '$title, ${historyWhen(item, now)}, ${historyPosition(item, novel: novel)}',
        minHeight: 76,
        onTap: () => unawaited(acts.open(item, rect())),
        onLongPress: () => unawaited(showGlassContextMenu(context, sourceRect: rect(), preview: ClipRRect(borderRadius: BorderRadius.circular(14), child: HomeCoverImage(url: item.coverUrl, width: 64)), kind: GlassPreviewKind.row, title: title, entries: acts.menu(item, rect()))),
        builder: (context, stacked, info) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 44, height: 66, child: HomeCoverImage(url: item.coverUrl, width: 44))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                GlassLabel(title, role: title == 'Unknown series' ? gt.typeSubhead : gt.typeHeadline, color: title == 'Unknown series' ? gt.colorLabel3 : null, maxLines: 2),
                GlassLabel(historyWhen(item, now), role: gt.typeFootnote, color: gt.colorLabel2),
              ],),
            ),
            GlassLabel(item.isCompleted ? 'Done' : historyPosition(item, novel: novel), role: gt.typeMono, color: gt.colorLabel2),
          ],),
        ),
      );
    },);
  }
}
