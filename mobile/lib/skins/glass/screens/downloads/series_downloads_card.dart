import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_identity.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/models/downloaded_series_group.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/downloads/providers/active_download_queue_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloaded_series_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_storage_providers.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/downloads/utils/format_bytes.dart';
import 'package:manhwamaniacs/features/ocr/controllers/ocr_run_controller.dart';
import 'package:manhwamaniacs/features/ocr/providers/ocr_providers.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/alert.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/download_control.dart';
import 'package:manhwamaniacs/skins/glass/primitives/download_state.dart';
import 'package:manhwamaniacs/skins/glass/primitives/hold_to_confirm.dart';
import 'package:manhwamaniacs/skins/glass/primitives/icon_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/row_shell.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/swipe_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/screens/downloads/queue_tab.dart' show glassChapterLabel;
import 'package:manhwamaniacs/skins/glass/screens/home/home_actions.dart' show openSeries;
import 'package:manhwamaniacs/skins/glass/screens/library/library_common.dart' show globalRectOf, roleButtonIcon, roleIcon;
import 'package:manhwamaniacs/skins/glass/skin_glass.dart' show GlassTwin;
import 'package:manhwamaniacs/skins/glass/transitions/dive.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// "40 chapters · 3 with audio · 1.2 GB", a book "12 chapters of text · 3 with audio · 14 MB", or "12 of 40 chapters saved · 800 MB".
String seriesSummary(DownloadedSeriesGroup g) {
  final text = g.chapters.where((c) => !c.kind.isAudio).toList();
  final saved = text.where((c) => c.state == DownloadChapterState.complete).length;
  final audio = g.chapters.where((c) => c.kind.isAudio && c.state == DownloadChapterState.complete).length;
  final size = formatDownloadBytes(g.totalBytes);
  final book = text.any((c) => c.kind.isNovel);
  if (saved < text.length) return '$saved of ${text.length} chapters saved · $size';
  final ch = book ? '${text.length} ${text.length == 1 ? 'chapter' : 'chapters'} of text' : '${text.length} ${text.length == 1 ? 'chapter' : 'chapters'}';
  return [ch, if (audio > 0) '$audio with audio', size].join(' · ');
}

/// The status line of a chapter row in its tone.
({String text, bool warn}) chapterStatus(SavedChapter c, DownloadQueueState q) {
  final lead = q.currentChapter == c.identity;
  final paused = q.isPaused && q.pauseReason != DownloadQueuePauseReason.none;
  final audio = c.kind.isAudio, novel = c.kind.isNovel;
  switch (c.state) {
    case DownloadChapterState.complete:
      if (audio) return (text: 'Chapter ${c.chapterNumber == null ? c.chapterKey : (c.chapterNumber! % 1 == 0 ? c.chapterNumber!.toInt() : c.chapterNumber)} · audio · ${formatDownloadBytes(c.bytes)}', warn: false);
      if (novel) return (text: 'Text · ${formatDownloadBytes(c.bytes)}', warn: false);
      return (text: '${c.pageCount} pages · ${formatDownloadBytes(c.bytes)}', warn: false);
    case DownloadChapterState.failed:
      return (text: c.error == null || c.error!.isEmpty ? "Couldn't save · tap to try again" : 'Failed: ${c.error}', warn: true);
    case DownloadChapterState.downloading:
    case DownloadChapterState.queued:
      if (paused) {
        return (
          text: switch (q.pauseReason) {
            DownloadQueuePauseReason.freeSpaceFloor => 'Paused: device is full',
            DownloadQueuePauseReason.cap => 'Paused: storage limit reached',
            DownloadQueuePauseReason.backgrounded => 'Paused until you reopen the app',
            _ => 'Paused',
          },
          warn: true,
        );
      }
      if (c.state == DownloadChapterState.queued) return (text: audio ? 'Fetching the audio…' : (novel ? 'Fetching the text…' : 'Waiting'), warn: false);
      if (audio) return (text: 'Saving the audio…', warn: false);
      if (novel) return (text: 'Saving the text…', warn: false);
      return (text: lead && q.pageTotal > 0 ? 'Saving ${q.pagesDone}/${q.pageTotal}' : 'Saving…', warn: false);
  }
}

/// Removes a chapter at once; the toast's "Download again" puts it back in the queue.
Future<void> removeChapterWithUndo(WidgetRef ref, SavedChapter c) async {
  final store = ref.read(downloadsStoreProvider);
  final queue = ref.read(downloadQueueControllerProvider.notifier);
  // deleteDownload also removes the chapter's saved narration; "Download again" must bring both back.
  final hadAudio = !c.kind.isAudio && await store?.getChapter(audioIdentity(c.identity)) != null;
  await store?.deleteDownload(c.identity);
  queue.retryAfterStorageChange();
  ref
    ..invalidate(downloadedSeriesProvider)
    ..invalidate(activeDownloadQueueProvider)
    ..invalidate(totalDeviceDownloadBytesProvider)
    ..invalidate(seriesStorageBreakdownProvider);
  showGlassToast(
    ref,
    GlassToastSpec(
      hadAudio ? 'Removed the chapter and its narration' : 'Removed from this device',
      actionLabel: 'Download again',
      onAction: () => unawaited(queue.enqueueChapters(
        hadAudio
            ? narrationDownloadRequests(chapter: c.identity, chapterNumber: c.chapterNumber, title: c.title, seriesTitle: c.seriesTitle)
            : [(id: c.identity, chapterNumber: c.chapterNumber, title: c.title, seriesTitle: c.seriesTitle, kind: c.kind)],
      ),),
    ),
  );
}

/// One series of Chapters (glass 8.22): title, summary, pin, menu and an expand chevron; expanded it lists its chapters. Removing the
/// whole series collapses the card on `springDismiss` (Drain) while the meter level falls.
class GlassSeriesDownloadsCard extends ConsumerStatefulWidget {
  const GlassSeriesDownloadsCard({super.key, required this.group, this.initiallyExpanded = false, this.onFocus});
  final DownloadedSeriesGroup group;
  final bool initiallyExpanded;
  final VoidCallback? onFocus;

  @override
  ConsumerState<GlassSeriesDownloadsCard> createState() => GlassSeriesDownloadsCardState();
}

class GlassSeriesDownloadsCardState extends ConsumerState<GlassSeriesDownloadsCard> with SingleTickerProviderStateMixin {
  late bool _open = widget.initiallyExpanded;
  late final AnimationController _collapse = AnimationController(vsync: this, value: 1);

  @override
  void dispose() {
    _collapse.dispose();
    super.dispose();
  }

  DownloadedSeriesGroup get g => widget.group;
  String get _title => g.seriesTitle ?? g.seriesKey;

  void toggle() => setState(() => _open = !_open);

  /// The card's height factor: 1 open, 0 drained.
  double get collapseValue => _collapse.value;

  /// Drain: the card collapses on `springDismiss` while the meter's level falls.
  void drain() => unawaited(GlassMotion.play(MotionName.drain, controller: _collapse, target: 0));

  List<SavedChapter> get _rows {
    final rows = [...g.chapters];
    rows.sort((a, b) {
      final an = a.chapterNumber, bn = b.chapterNumber;
      final c = an != null && bn != null ? an.compareTo(bn) : a.chapterKey.compareTo(b.chapterKey);
      return c != 0 ? c : (a.kind.isAudio ? 1 : 0).compareTo(b.kind.isAudio ? 1 : 0);
    });
    return rows;
  }

  void _openSeries(Rect from) {
    final followed = ref.read(updatesProvider).valueOrNull?.followed;
    final id = followed?.where((f) => f.sourceId == g.sourceId && f.seriesKey == g.seriesKey).firstOrNull?.id;
    if (id != null) {
      unawaited(ref.read(skinRouterProvider).push<void>(Routes.featureByFollow(id)));
    } else {
      unawaited(openSeries(ref, g.sourceId, g.seriesKey, from: from));
    }
  }

  void _openChapter(SavedChapter c, Rect from) {
    final key = c.kind.isNovelSide ? c.chapterKey.replaceAll(':audio', '') : c.chapterKey;
    final loc = c.kind.isNovelSide ? Routes.novel(c.sourceId, c.seriesKey, key) : Routes.reader(c.sourceId, c.seriesKey, key);
    unawaited(enterReader(context, ref, loc, fromRect: from));
  }

  void _saveToFiles(SavedChapter? only) {
    final router = ref.read(skinRouterProvider);
    final loc = router.routerDelegate.currentConfiguration.uri;
    router.go(loc.replace(queryParameters: {...loc.queryParameters, 'sheet': 'save-files', 'series': '${g.sourceId}:${g.seriesKey}', if (only != null) 'chapter': only.chapterKey}).toString());
  }

  Future<void> _removeSeries(Rect from) async {
    final ok = await showGlassAlert<bool>(
      context,
      title: 'Remove every saved chapter of $_title?',
      body: 'Your reading progress is kept.',
      sourceRect: from,
      actions: const [GlassAlertAction<bool>('Cancel', role: GlassAlertRole.cancel, value: false)],
      extra: Builder(builder: (ctx) => HoldToConfirm(label: 'Hold to remove', mode: HoldMode.inAlert, fallbackLabel: 'Remove all downloads', onConfirm: () => Navigator.of(ctx).pop(true))),
    );
    if (ok != true || !mounted) return;
    // Drain: the card collapses on springDismiss while the meter's level falls.
    final store = ref.read(downloadsStoreProvider);
    drain();
    for (final c in g.chapters) {
      await store?.deleteDownload(c.identity);
    }
    if (!mounted) return;
    ref.read(downloadQueueControllerProvider.notifier).retryAfterStorageChange();
    ref
      ..invalidate(downloadedSeriesProvider)
      ..invalidate(activeDownloadQueueProvider)
      ..invalidate(totalDeviceDownloadBytesProvider)
      ..invalidate(seriesStorageBreakdownProvider);
  }

  Future<void> _pin() async {
    await ref.read(downloadsStoreProvider)?.setSeriesPinned(series: (sourceId: g.sourceId, seriesKey: g.seriesKey), pinned: !g.pinned);
    ref
      ..invalidate(downloadedSeriesProvider)
      ..invalidate(seriesStorageBreakdownProvider);
  }

  @override
  Widget build(BuildContext context) {
    final rows = _open ? _rows : const <SavedChapter>[];
    final exportable = g.chapters.any((c) => c.state == DownloadChapterState.complete && !c.kind.isNovelSide);
    return AnimatedBuilder(
      animation: _collapse,
      builder: (context, child) => ClipRect(child: Align(alignment: Alignment.topCenter, heightFactor: _collapse.value.clamp(0.0, 1.0), child: Opacity(opacity: _collapse.value.clamp(0.0, 1.0), child: child))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: const Color(0x9E131317), borderRadius: BorderRadius.circular(26), border: Border.all(color: const Color(0x38FFFFFF), width: 0.5)),
        child: Focus(
          canRequestFocus: false,
          onFocusChange: (f) {
            if (f) widget.onFocus?.call();
          },
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Builder(builder: (context) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                child: Row(children: [
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: '$_title, ${seriesSummary(g)}',
                      excludeSemantics: true,
                      onTap: () => _openSeries(globalRectOf(context)),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _openSeries(globalRectOf(context)),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 56),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                            GlassLabel(_title, role: gt.typeHeadline, maxLines: 2),
                            GlassLabel(seriesSummary(g), role: gt.typeFootnote, color: gt.colorLabel2, maxLines: 2),
                          ],),
                        ),
                      ),
                    ),
                  ),
                  GlassIconButton(icon: roleButtonIcon(GlassIconRole.pin), label: g.pinned ? 'Unpin $_title' : 'Pin $_title', toggle: g.pinned, twin: GlassTwin.content, onPressed: () => unawaited(_pin())),
                  GlassIconButton(
                    icon: roleButtonIcon(GlassIconRole.overflow),
                    label: 'More for $_title',
                    twin: GlassTwin.content,
                    onPressed: () => unawaited(showGlassMenu(context, anchor: globalRectOf(context), title: _title, entries: [
                      if (exportable) GlassMenuEntry(label: 'Save to Files…', onSelected: () => _saveToFiles(null)),
                      GlassMenuEntry(label: 'Remove all downloads', destructive: true, onSelected: () => unawaited(_removeSeries(globalRectOf(context)))),
                    ],),),
                  ),
                  Semantics(
                    button: true,
                    expanded: _open,
                    label: _open ? 'Collapse chapters' : 'Expand chapters',
                    excludeSemantics: true,
                    onTap: toggle,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: toggle,
                      child: SizedBox(width: 44, height: 44, child: Center(child: AnimatedRotation(turns: _open ? 0.5 : 0, duration: const Duration(milliseconds: 200), child: Icon(roleIcon(GlassIconRole.back), size: 16, color: gt.colorLabel2)))),
                    ),
                  ),
                ],),
              );
            },),
            if (rows.isNotEmpty) GlassSwipeGroup(child: Column(children: [for (final c in rows) _ChapterRow(key: ValueKey('ch-${c.rowId}'), chapter: c, onOpen: (r) => _openChapter(c, r), onSave: () => _saveToFiles(c))])),
          ],),
        ),
      ),
    );
  }
}

class _ChapterRow extends ConsumerWidget {
  const _ChapterRow({super.key, required this.chapter, required this.onOpen, required this.onSave});
  final SavedChapter chapter;
  final void Function(Rect) onOpen;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = chapter;
    final q = ref.watch(downloadQueueControllerProvider);
    final status = chapterStatus(c, q);
    final lead = q.currentChapter == c.identity;
    final paused = q.isPaused && q.pauseReason != DownloadQueuePauseReason.none;
    final view = chapterDownloadView(ChapterDownloadFacts(
      row: c.state,
      inQueue: c.state == DownloadChapterState.queued || c.state == DownloadChapterState.downloading,
      pagesDone: lead ? q.pagesDone : 0,
      pagesTotal: lead ? q.pageTotal : c.pageCount,
      pauseReason: paused ? _pause(q.pauseReason) : null,
    ),);
    final label = glassChapterLabel(c);
    final saved = c.state == DownloadChapterState.complete;
    final ocrOk = ref.watch(ocrAvailableProvider).valueOrNull ?? false;
    final run = ref.watch(ocrRunControllerProvider);
    final scanning = run.isBusy && run.chapter == c.identity;
    final q2 = ref.read(downloadQueueControllerProvider.notifier);
    return GlassSwipeRow(
      name: label,
      trailing: [SwipeAction(id: 'remove', label: 'Remove', glyph: roleIcon(GlassIconRole.delete), tone: SwipeTone.danger, destructive: true, run: () => removeChapterWithUndo(ref, c))],
      child: Builder(builder: (context) {
        return GlassRowShell(
          semanticsLabel: '$label, ${status.text}',
          minHeight: 60,
          onTap: saved ? () => onOpen(globalRectOf(context)) : (c.state == DownloadChapterState.failed ? () => unawaited(q2.retryChapter(c.identity)) : null),
          builder: (context, stacked, info) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  GlassLabel(c.kind.isAudio ? '$label · audio' : label, role: gt.typeBody),
                  GlassLabel(status.text, role: gt.typeFootnote, color: status.warn ? gt.colorWarning : gt.colorLabel2, maxLines: 2),
                  if (c.state == DownloadChapterState.downloading && !paused && lead && q.pageTotal > 0)
                    Padding(padding: const EdgeInsets.only(top: 6), child: GlassLinearProgress(value: q.pagesDone / q.pageTotal, label: 'Saving $label')),
                ],),
              ),
              if (saved && !c.kind.isNovelSide && ocrOk)
                GlassIconButton(
                  icon: roleButtonIcon(GlassIconRole.contents),
                  label: 'Extract text from $label',
                  twin: GlassTwin.content,
                  loading: scanning,
                  onPressed: run.isBusy ? null : () => unawaited(ref.read(ocrRunControllerProvider.notifier).runChapter(id: c.identity, chapterNumber: c.chapterNumber)),
                ),
              GlassDownloadControl(
                view: view,
                chapterLabel: label,
                quietDone: true,
                onDownload: () => unawaited(q2.retryChapter(c.identity)),
                onCancel: () => unawaited(q2.cancelChapter(c.identity)),
                onRemove: () => unawaited(removeChapterWithUndo(ref, c)),
                onExtractText: ocrOk && saved && !c.kind.isNovelSide ? () => unawaited(ref.read(ocrRunControllerProvider.notifier).runChapter(id: c.identity, chapterNumber: c.chapterNumber)) : null,
                onSaveToFiles: saved && !c.kind.isNovelSide ? onSave : null,
              ),
            ],),
          ),
        );
      },),
    );
  }
}

DownloadPauseReason? _pause(DownloadQueuePauseReason r) => switch (r) {
      DownloadQueuePauseReason.userPaused => DownloadPauseReason.userPaused,
      DownloadQueuePauseReason.freeSpaceFloor => DownloadPauseReason.freeSpaceFloor,
      DownloadQueuePauseReason.cap => DownloadPauseReason.cap,
      DownloadQueuePauseReason.backgrounded => DownloadPauseReason.backgrounded,
      DownloadQueuePauseReason.noScope => DownloadPauseReason.noScope,
      DownloadQueuePauseReason.none => null,
    };
