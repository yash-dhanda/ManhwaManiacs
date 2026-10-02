import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/rendering.dart' show RenderSliver;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_selection.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart' show downloadsStoreProvider;
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/novels/utils/toc_window.dart';
import 'package:manhwamaniacs/features/ocr/controllers/ocr_run_controller.dart';
import 'package:manhwamaniacs/features/ocr/providers/ocr_providers.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/features/sources/utils/chapter_sort_store.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/parts/reactions/chapter_reactions.dart' show ChapterReactionSummary;
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/download_control.dart';
import 'package:manhwamaniacs/skins/glass/primitives/download_state.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/liquid_progress.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/chapter_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/swipe_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/segmented.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/floating_bar.dart';
import 'package:manhwamaniacs/skins/glass/primitives/text_field.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/routes/sheet_registry.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/chapter_extents.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/download_card.dart' show openSaveToFiles;
import 'package:manhwamaniacs/skins/glass/screens/series/series_actions.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/series_data.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/series_header.dart' show rectOf;
import 'package:manhwamaniacs/skins/glass/screens/series/series_states.dart';
import 'package:manhwamaniacs/skins/glass/transitions/dive.dart';

/// The chapter list's own state (glass 8.12 Chapters section, Select mode).
class SeriesChapters extends ChangeNotifier {
  SeriesChapters();
  final selection = ChapterSelectionController();
  final goTo = TextEditingController();
  final goToFocus = FocusNode(debugLabel: 'go to chapter');
  final rowsKey = GlobalKey(debugLabel: 'chapter rows');
  String order = 'newest';
  String? pulse;
  String? goToMessage;

  /// The keys of the running download, for the liquid progress, Stop and the summary toast.
  Set<String> run = {};
  int runAlreadySaved = 0;

  /// The run's keys the status stream has shown: one that then disappears was cancelled or removed
  /// (from its row, Downloads or elsewhere) and will never finish.
  final Set<String> runSeen = {};

  void setOrder(String o) {
    order = o;
    notifyListeners();
  }

  void ping() => notifyListeners();

  @override
  void dispose() {
    selection.dispose();
    goTo.dispose();
    goToFocus.dispose();
    super.dispose();
  }
}

/// The capped `body` text scale the row extents follow.
double rowTextScale(BuildContext context) => math.min(MediaQuery.textScalerOf(context).scale(1), 1.6);

/// The rows in display order.
List<SourceChapterSummary> shownChapters(GlassSeriesData d, String order) {
  final o = d.readingOrder;
  return order == 'oldest' ? o : o.reversed.toList();
}

/// The facts of one row's download control.
ChapterDownloadView rowDownloadView(ChapterDownloadStatus? s, ({String chapterKey, ChapterDownloadProgress progress})? active, String key, bool paused) {
  final isActive = active?.chapterKey == key;
  return chapterDownloadView(
    ChapterDownloadFacts(
      row: s?.state,
      pagesDone: isActive ? active!.progress.pagesDone : 0,
      pagesTotal: isActive ? active!.progress.pageTotal : 0,
      pauseReason: paused && (s?.state == DownloadChapterState.queued || s?.state == DownloadChapterState.downloading) ? DownloadPauseReason.userPaused : null,
    ),
  );
}

/// Scrolls the sheet's list so [index] of the rows sliver sits near the top third (springCamera), then focuses it.
void scrollToRow(BuildContext context, SeriesChapters c, List<double> extents, int index) {
  final ro = c.rowsKey.currentContext?.findRenderObject();
  final pos = c.rowsKey.currentContext == null ? null : Scrollable.maybeOf(c.rowsKey.currentContext!)?.position;
  if (ro is! RenderSliver || pos == null) return;
  var before = 0.0;
  for (var i = 0; i < index && i < extents.length; i++) {
    before += extents[i];
  }
  final target = (ro.constraints.precedingScrollExtent + before - pos.viewportDimension / 3).clamp(pos.minScrollExtent, pos.maxScrollExtent);
  unawaited(pos.animateTo(target, duration: const Duration(milliseconds: 520), curve: SpringCurveLite.camera));
}

/// The spring of `springCamera` as a plain curve.
abstract final class SpringCurveLite {
  static const Curve camera = Cubic(0.2, 0.9, 0.25, 1);
}

/// The chapters header (pins with `edgeHard`): title, the downloaded count and Download trigger, OCR coverage, Newest/Oldest, Select.
class ChaptersHeader extends ConsumerWidget {
  const ChaptersHeader({super.key, required this.data, required this.chapters, required this.onSelect});
  final GlassSeriesData data;
  final SeriesChapters chapters;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = data;
    final statuses = ref.watch(seriesChapterDownloadStatusProvider(d.identity)).valueOrNull ?? const {};
    final saved = statuses.values.where((s) => s.state == DownloadChapterState.complete).length;
    final coverage = d.novel ? null : ref.watch(ocrCoverageProvider(d.identity)).valueOrNull;
    final indexed = coverage?.coveredChapterCount ?? 0;
    final profile = ref.watch(activeProfileProvider) != null;
    return ColoredBox(
      color: const Color(0xFF000000),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: Semantics(header: true, headingLevel: 2, child: GlassLabel(d.novel ? 'Contents' : 'Chapters', role: gt.typeTitle2, wght: 700))),
                GlassButton(
                    key: const ValueKey('chapters-select'),
                    label: chapters.selection.isActive ? 'Done' : 'Select',
                    variant: GlassButtonVariant.plain,
                    size: GlassButtonSize.small,
                    onPressed: onSelect,),
              ],
            ),
            Row(
              children: [
                Expanded(child: GlassLabel('$saved of ${d.chapters.length} downloaded', key: const ValueKey('chapters-count'), role: gt.typeFootnote, color: gt.colorLabel2)),
                if (profile)
                  GlassButton(label: 'Download', variant: GlassButtonVariant.plain, size: GlassButtonSize.small, icon: GlassButtonIcon(GlassGlyph.cloudArrowDown.regular), onPressed: onSelect),
              ],
            ),
            if (!profile) GlassLabel('Downloads belong to a reading profile. Choose one to save chapters here.', role: gt.typeCaption1, color: gt.colorLabel3, maxLines: 2),
            if (indexed > 0) GlassLabel('Dialogue indexed for $indexed chapters', key: const ValueKey('chapters-ocr'), role: gt.typeCaption1, color: gt.colorLabel3),
            const SizedBox(height: 10), // 8 px clear of the Download button's hit rect (14.6)
            GlassSegmented<String>(
              key: const ValueKey('chapters-order'),
              compact: true,
              segments: d.novel
                  ? const [GlassSegment(value: 'oldest', label: 'First → last'), GlassSegment(value: 'newest', label: 'Last → first')]
                  : const [GlassSegment(value: 'newest', label: 'Newest'), GlassSegment(value: 'oldest', label: 'Oldest')],
              selected: chapters.order,
              onSelected: (o) => setChapterOrder(ref, d, chapters, o),
            ),
          ],
        ),
      ),
    );
  }
}

/// The go-to field (more than 50 chapters): Enter scrolls to the first match on `springCamera` and pulses that row.
class GoToField extends ConsumerWidget {
  const GoToField({super.key, required this.data, required this.chapters, required this.onJump});
  final GlassSeriesData data;
  final SeriesChapters chapters;
  final void Function(String key) onJump;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void submit(String q) {
      final r = goToMatches([for (final c in data.readingOrder) (key: c.id, number: c.number, title: c.title)], q);
      chapters.goToMessage = r.message ?? (r.more > 0 ? 'and ${r.more} more' : null);
      chapters.ping();
      if (r.matches.isNotEmpty) onJump(r.matches.first.key);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () {
            chapters.goTo.clear();
            chapters.goToMessage = null;
            chapters.ping();
          },
        },
        child: GlassTextField(
          key: const ValueKey('go-to-field'),
          controller: chapters.goTo,
          focusNode: chapters.goToFocus,
          hint: 'Go to chapter',
          helper: chapters.goToMessage,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.go,
          onSubmitted: submit,
        ),
      ),
    );
  }
}

/// The rows: one [SliverVariedExtentList] in the sheet's scroll view, built lazily (1,000 and 3,000 rows build only what is visible).
class ChapterRowsSliver extends ConsumerWidget {
  const ChapterRowsSliver({super.key, required this.data, required this.chapters, required this.shown, required this.onToggleRun});
  final GlassSeriesData data;
  final SeriesChapters chapters;
  final List<SourceChapterSummary> shown;
  final VoidCallback onToggleRun;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = data;
    final online = isOnline(ref);
    final progress = ref.watch(sourceSeriesProgressProvider(d.progressKey));
    final statuses = ref.watch(seriesChapterDownloadStatusProvider(d.identity)).valueOrNull ?? const {};
    final active = ref.watch(seriesActiveChapterProgressProvider(d.identity));
    final paused = ref.watch(downloadQueueControllerProvider.select((q) => q.pauseReason == DownloadQueuePauseReason.userPaused));
    final ocr = ref.watch(ocrFeatureVisibleProvider);
    final scale = rowTextScale(context);
    final sel = chapters.selection;
    // From text scale 1.6 a row stacks and its meta line may wrap: rows size themselves (a fixed extent would clip them); below
    // it the fixed extent keeps scroll-to-chapter exact.
    Widget list(NullableIndexedWidgetBuilder itemBuilder) => scale >= 1.6
        ? SliverList.builder(key: chapters.rowsKey, itemCount: shown.length, itemBuilder: itemBuilder)
        : SliverVariedExtentList.builder(
            key: chapters.rowsKey,
            itemCount: shown.length,
            itemExtentBuilder: (i, _) => i >= shown.length ? null : chapterRowExtent(hasSecondary: false, textScale: scale),
            itemBuilder: itemBuilder,
          );
    return list((context, i) {
        final c = shown[i];
        final p = progress[c.id];
        final s = statuses[c.id];
        final isSaved = s?.state == DownloadChapterState.complete;
        final view = rowDownloadView(s, active, c.id, paused);
        final read = p?.completed ?? false;
        final dimmed = !online && !isSaved;
        final label = 'chapter ${chapterNum(c.number) ?? c.title}';
        final row = GlassChapterRow(
          key: ValueKey('chapter-${c.id}'),
          number: c.number,
          title: c.title.isEmpty ? null : c.title,
          date: c.releaseDate == null ? null : DateTime.tryParse(c.releaseDate!),
          pageCount: c.pageCount > 0 ? c.pageCount : null,
          progress: p != null && !p.completed ? p.page : null,
          read: read,
          enabled: !dimmed && !(sel.isActive && isSaved),
          disabledHint: sel.isActive && isSaved ? 'Already on this device' : (dimmed ? 'Needs a connection' : null),
          selectMode: sel.isActive,
          selected: sel.isSelected(c.id),
          onTap: sel.isActive ? () => _toggle(c.id) : () => _open(context, ref, c),
          onLongPress: () => _rowMenu(context, ref, c, read: read, saved: isSaved),
          customActions: {
            CustomSemanticsAction(label: read ? 'Mark unread' : 'Mark read'): () => read ? fire(_unread(ref, c)) : fire(_read(ref, [c])),
            CustomSemanticsAction(label: isSaved ? 'Remove download' : 'Download'): () => isSaved ? fire(_remove(ref, c)) : fire(enqueueSeriesChapters(ref, d, [c.id])),
          },
          trailing: sel.isActive
              ? null
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  ChapterReactionSummary(sourceId: d.sourceId, seriesKey: d.seriesKey, chapterKey: c.id),
                  GlassDownloadControl(
                  view: view,
                  chapterLabel: label,
                  onDownload: () => fire(enqueueSeriesChapters(ref, d, [c.id])),
                  onCancel: () => fire(ref.read(downloadQueueControllerProvider.notifier).cancelChapter((sourceId: d.sourceId, seriesKey: d.seriesKey, chapterKey: c.id))),
                  onRemove: () => fire(_remove(ref, c)),
                  onExtractText: ocr && !d.novel
                      ? () => fire(ref.read(ocrRunControllerProvider.notifier).runChapter(id: (sourceId: d.sourceId, seriesKey: d.seriesKey, chapterKey: c.id), chapterNumber: c.number))
                      : null,
                  onSaveToFiles: glassSheetRegistered('save-files') ? () => _saveToFiles(context, ref, c) : null,
                ),
                ],),
        );
        final pulsed = chapters.pulse == c.id;
        final body = pulsed ? _Pulse(key: ValueKey('pulse-${c.id}'), child: row) : row;
        if (sel.isActive) return body;
        return GlassSwipeRow(
          name: label,
          showMore: false,
          leading: [
            SwipeAction(id: 'read', label: read ? 'Mark unread' : 'Mark read', glyph: GlassGlyph.check.regular, tone: SwipeTone.iris, run: () => read ? _unread(ref, c) : _read(ref, [c])),
          ],
          trailing: [
            if (isSaved)
              SwipeAction(id: 'remove', label: 'Remove download', glyph: GlassGlyph.trash.regular, tone: SwipeTone.danger, run: () => _remove(ref, c))
            else
              SwipeAction(id: 'download', label: 'Download', glyph: GlassGlyph.cloudArrowDown.regular, tone: SwipeTone.success, run: () => enqueueSeriesChapters(ref, d, [c.id])),
          ],
          child: body,
        );
      });
  }

  void _toggle(String key) {
    chapters.selection.toggle(key);
    final n = chapters.selection.count;
    unawaited(SemanticsService.sendAnnouncement(View.of(chapters.rowsKey.currentContext!), '$n selected', TextDirection.ltr));
  }

  void _open(BuildContext context, WidgetRef ref, SourceChapterSummary c) {
    final p = ref.read(sourceSeriesProgressProvider(data.progressKey))[c.id];
    unawaited(enterReader(context, ref, readerLocation(data, c.id, page: p != null && !p.completed ? p.page : null), fromRect: rectOf(context)));
  }

  Future<void> _read(WidgetRef ref, List<SourceChapterSummary> cs) => markChaptersRead(ref, data, cs);
  Future<void> _unread(WidgetRef ref, SourceChapterSummary c) => markChapterUnread(ref, data, c);

  Future<void> _remove(WidgetRef ref, SourceChapterSummary c) async {
    await ref.read(downloadsStoreProvider)?.deleteDownload((sourceId: data.sourceId, seriesKey: data.seriesKey, chapterKey: c.id));
    ref.invalidate(seriesChapterDownloadStatusProvider(data.identity));
  }

  void _saveToFiles(BuildContext context, WidgetRef ref, SourceChapterSummary c) => openSaveToFiles(context, ref, data, chapter: c.id);

  void _rowMenu(BuildContext context, WidgetRef ref, SourceChapterSummary c, {required bool read, required bool saved}) {
    fire(ref.read(glassHapticsProvider).fire(HapticEvent.longpressOpen));
    final online = onlineNow(ref);
    unawaited(
      showGlassMenu(
        context,
        anchor: rectOf(context),
        title: 'Chapter ${chapterNum(c.number) ?? ''}',
        entries: [
          GlassMenuEntry(label: 'Mark read', enabled: online && !read, onSelected: () => fire(_read(ref, [c]))),
          GlassMenuEntry(label: 'Mark unread', enabled: online && read, onSelected: () => fire(_unread(ref, c))),
          if (saved)
            GlassMenuEntry(label: 'Remove download', onSelected: () => fire(_remove(ref, c)))
          else
            GlassMenuEntry(label: 'Download', onSelected: () => fire(enqueueSeriesChapters(ref, data, [c.id]))),
          GlassMenuEntry(
            label: 'Select',
            separatorBefore: true,
            onSelected: () {
              if (saved) return chapters.selection.begin();
              chapters.selection.replaceWith([c.id]);
            },
          ),
        ],
      ),
    );
  }
}

/// Sets and remembers the chapter order for this series (the segmented control and the keyboard toggle).
void setChapterOrder(WidgetRef ref, GlassSeriesData d, SeriesChapters chapters, String o) {
  chapters.setOrder(o);
  fire(saveChapterSort(ref.read(sharedPrefsProvider), profileId: ref.read(activeProfileProvider)?.id.toString(), sourceId: d.sourceId, seriesKey: d.seriesKey, order: o));
}

/// Mark read: the batch call, "Marked 42 chapters read · Undo" (Undo deletes only the keys that were not completed before).
Future<void> markChaptersRead(WidgetRef ref, GlassSeriesData d, List<SourceChapterSummary> cs) async {
  if (!onlineNow(ref)) return;
  final marks = SeriesMarks(ref, d);
  final before = marks.completed();
  final marked = await marks.markRead(cs);
  if (marked == null) return showGlassToast(ref, const GlassToastSpec("Couldn't mark them read. Try again", kind: GlassToastKind.error));
  fire(ref.read(glassHapticsProvider).fire(HapticEvent.select));
  final msg = cs.length == 1 ? 'Marked chapter ${chapterNum(cs.first.number) ?? ''} read'.replaceAll('  ', ' ') : 'Marked ${cs.length} chapters read';
  showGlassToast(ref, GlassToastSpec(msg, undo: () => fire(marks.undoMarkRead(before, marked))));
}

/// Mark unread: the delete call, "Marked chapter 142 unread · Undo" (Undo re-posts the deleted rows).
Future<void> markChapterUnread(WidgetRef ref, GlassSeriesData d, SourceChapterSummary c) async {
  if (!onlineNow(ref)) return;
  final marks = SeriesMarks(ref, d);
  final deleted = await marks.markUnread([c.id]);
  if (deleted == null) return showGlassToast(ref, const GlassToastSpec("Couldn't mark it unread. Try again", kind: GlassToastKind.error));
  fire(ref.read(glassHapticsProvider).fire(HapticEvent.select));
  showGlassToast(ref, GlassToastSpec('Marked chapter ${chapterNum(c.number) ?? ''} unread', undo: () => fire(marks.undoMarkUnread(deleted))));
}

/// Row pulse (glass 4.10): `iris600` at 14 % fading over 900 ms; reduced motion shows it 900 ms, then removes it.
class _Pulse extends StatefulWidget {
  const _Pulse({super.key, required this.child});
  final Widget child;
  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        hint: 'current location',
        child: AnimatedBuilder(
          animation: _c,
          child: widget.child,
          builder: (context, child) => DecoratedBox(
            decoration: BoxDecoration(color: _c.isCompleted ? const Color(0x00000000) : gt.colorIris600.withValues(alpha: 0.14 * (1 - _c.value))),
            child: child,
          ),
        ),
      );
}

/// Select-mode helper chips (Next 10, All unread (n), All (n), None; books add Whole book).
class SelectHelpers extends ConsumerWidget {
  const SelectHelpers({super.key, required this.data, required this.chapters});
  final GlassSeriesData data;
  final SeriesChapters chapters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = data;
    final statuses = ref.watch(seriesChapterDownloadStatusProvider(d.identity)).valueOrNull ?? const {};
    final saved = {
      for (final e in statuses.entries)
        if (e.value.state == DownloadChapterState.complete) e.key,
    };
    final rows = selectableChapters(d.readingOrder, ref.watch(sourceSeriesProgressProvider(d.progressKey)), saved);
    final unread = unreadUndownloadedKeys(rows), all = undownloadedKeys(rows);
    final sel = chapters.selection;
    Widget chip(String label, Iterable<String> keys) => GlassButton(key: ValueKey('helper-$label'), label: label, size: GlassButtonSize.small, onPressed: () => sel.replaceWith(keys));
    return Semantics(
      container: true,
      label: 'Select chapters',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            chip('Next 10', nextUnreadUndownloadedKeys(rows)),
            chip('All unread (${unread.length})', unread),
            if (d.novel) chip('Whole book', all) else chip('All (${all.length})', all),
            chip('None', const []),
          ],
        ),
      ),
    );
  }
}

/// The floating select toolbar: "{n} selected · {k} already saved", Download {n}, Mark read, Mark unread, Done; while running a liquid
/// progress "Downloading 3 of 12" and Stop.
class ChapterSelectToolbar extends ConsumerWidget {
  const ChapterSelectToolbar({super.key, required this.data, required this.chapters});
  final GlassSeriesData data;
  final SeriesChapters chapters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = data;
    final sel = chapters.selection;
    final statuses = ref.watch(seriesChapterDownloadStatusProvider(d.identity)).valueOrNull ?? const {};
    final run = chapters.run;
    final done = run.where((k) => statuses[k]?.state == DownloadChapterState.complete || statuses[k]?.state == DownloadChapterState.failed || (statuses[k] == null && chapters.runSeen.contains(k))).length;
    final running = run.isNotEmpty && done < run.length;
    final online = isOnline(ref);
    final picked = d.chapters.where((c) => sel.isSelected(c.id)).toList();
    final already = picked.where((c) => statuses[c.id]?.state == DownloadChapterState.complete).length;
    final n = picked.length - already;
    return GlassFloatingBar(
      key: const ValueKey('select-toolbar'),
      visible: sel.isActive || running,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: running
            ? Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GlassLabel('Downloading ${done + 1 > run.length ? run.length : done + 1} of ${run.length}', key: const ValueKey('select-running'), role: gt.typeFootnote, onGlass: true),
                        const SizedBox(height: 4),
                        LiquidProgress(value: run.isEmpty ? 0 : done / run.length, height: 6, meniscus: false),
                      ],
                    ),
                  ),
                  GlassButton(label: 'Stop', variant: GlassButtonVariant.plain, size: GlassButtonSize.small, onPressed: () => fire(_stop(ref))),
                ],
              )
            : Row(
                children: [
                  Flexible(child: GlassLabel('${picked.length} selected${already > 0 ? ' · $already already saved' : ''}', key: const ValueKey('select-count'), role: gt.typeFootnote, onGlass: true)),
                  Expanded(
                    flex: 3,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Row(
                        children: [
                          GlassButton(
                            key: const ValueKey('select-download'),
                            label: 'Download $n',
                            variant: GlassButtonVariant.plain,
                            size: GlassButtonSize.small,
                            onPressed: n == 0 || ref.read(activeProfileProvider) == null ? null : () => fire(_download(ref, picked)),
                          ),
                          GlassButton(
                              key: const ValueKey('select-read'),
                              label: 'Mark read',
                              variant: GlassButtonVariant.plain,
                              size: GlassButtonSize.small,
                              disabledReason: online ? null : 'Needs a connection',
                              onPressed: picked.isEmpty || !online ? null : () => fire(markChaptersRead(ref, d, picked).then((_) => sel.end())),),
                          GlassButton(
                              key: const ValueKey('select-unread'),
                              label: 'Mark unread',
                              variant: GlassButtonVariant.plain,
                              size: GlassButtonSize.small,
                              disabledReason: online ? null : 'Needs a connection',
                              onPressed: picked.length != 1 || !online ? null : () => fire(markChapterUnread(ref, d, picked.first).then((_) => sel.end())),),
                          GlassButton(key: const ValueKey('select-done'), label: 'Done', variant: GlassButtonVariant.plain, size: GlassButtonSize.small, onPressed: sel.end),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _download(WidgetRef ref, List<SourceChapterSummary> picked) async {
    final statuses = ref.read(seriesChapterDownloadStatusProvider(data.identity)).valueOrNull ?? const {};
    final keys = [
      for (final c in picked)
        if (statuses[c.id]?.state != DownloadChapterState.complete) c.id,
    ];
    chapters.run = keys.toSet();
    chapters.runSeen.clear();
    chapters.runAlreadySaved = picked.length - keys.length;
    chapters.selection.end();
    chapters.ping();
    await enqueueSeriesChapters(ref, data, keys);
  }

  Future<void> _stop(WidgetRef ref) async {
    final ctl = ref.read(downloadQueueControllerProvider.notifier);
    final statuses = ref.read(seriesChapterDownloadStatusProvider(data.identity)).valueOrNull ?? const {};
    for (final k in chapters.run) {
      if (statuses[k]?.state != DownloadChapterState.complete) await ctl.cancelChapter((sourceId: data.sourceId, seriesKey: data.seriesKey, chapterKey: k));
    }
    chapters.run = {};
    chapters.ping();
  }
}

/// The summary toast once every chapter of a run has finished (glass 8.12 Select mode).
/// A key in [seen] that is no longer in [statuses] was cancelled and counts as finished; '' when every
/// chapter was cancelled (the run ends without a toast).
String? runSummary(Set<String> run, Map<String, ChapterDownloadStatus> statuses, {Set<String> seen = const {}, int? freeMb}) {
  if (run.isEmpty) return null;
  final ok = run.where((k) => statuses[k]?.state == DownloadChapterState.complete).length;
  final failed = run.where((k) => statuses[k]?.state == DownloadChapterState.failed).length;
  final dropped = run.where((k) => statuses[k] == null && seen.contains(k)).length;
  if (ok + failed + dropped < run.length) return null;
  if (ok + failed == 0) return '';
  if (failed == 0) return dropped == 0 ? '$ok chapter${ok == 1 ? '' : 's'} downloaded' : '$ok of ${run.length} downloaded';
  return '$ok of ${run.length} downloaded, $failed failed';
}

/// The chapter list's state for a series with no chapter rows.
ChapterListState? chapterListState(GlassSeriesData d, {required bool online}) {
  if (d.chapters.isNotEmpty) return null;
  if (!online) return ChapterListState.offline;
  if (d.series.chapterCount > 0) return ChapterListState.unavailable;
  return ChapterListState.empty;
}

/// The initial order: the stored per-series choice, newest for manga and first → last for books.
String initialOrder(WidgetRef ref, GlassSeriesData d) =>
    chapterSortFor(ref.read(sharedPrefsProvider), profileId: ref.read(activeProfileProvider)?.id.toString(), sourceId: d.sourceId, seriesKey: d.seriesKey, novel: d.novel);

/// Keeps a run's summary toast and `download.done` (once per batch).
void watchRun(WidgetRef ref, GlassSeriesData d, SeriesChapters c) {
  ref.listen<AsyncValue<Map<String, ChapterDownloadStatus>>>(seriesChapterDownloadStatusProvider(d.identity), (prev, next) {
    final statuses = next.valueOrNull ?? const {};
    c.runSeen.addAll(c.run.where(statuses.containsKey));
    final s = runSummary(c.run, statuses, seen: c.runSeen);
    if (s == null) return;
    c.run = {};
    c.ping();
    if (s.isEmpty) return;
    fire(ref.read(glassHapticsProvider).fire(s.contains('failed') ? HapticEvent.downloadFail : HapticEvent.downloadDone));
    showGlassToast(ref, GlassToastSpec(s, kind: s.contains('failed') ? GlassToastKind.error : GlassToastKind.success));
  });
}
