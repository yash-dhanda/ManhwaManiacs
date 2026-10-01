import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/downloads/utils/download_mark.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/arm.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_download_mark.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The download mark of the running head (cinematic 7.18, 8.14.3). A tap cycles Download, saving
/// with `12/40 · 30%` and cancel, then SAVED; tapping SAVED asks inline "Remove from this device?"
/// with the 1000 ms arm and reverts after 4 s untouched. Failed and stale ones read `Save again`.
class ChapterDownloadControl extends ConsumerStatefulWidget {
  const ChapterDownloadControl({super.key, required this.sourceId, required this.seriesKey, required this.chapterKey});

  final String sourceId, seriesKey, chapterKey;

  @override
  ConsumerState<ChapterDownloadControl> createState() => _ChapterDownloadControlState();
}

class _ChapterDownloadControlState extends ConsumerState<ChapterDownloadControl> {
  bool _asking = false;
  Timer? _revert;

  ({String sourceId, String seriesKey, String chapterKey}) get _id =>
      (sourceId: widget.sourceId, seriesKey: widget.seriesKey, chapterKey: widget.chapterKey);

  @override
  void dispose() {
    _revert?.cancel();
    super.dispose();
  }

  void _ask() {
    setState(() => _asking = true);
    _revert?.cancel();
    _revert = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _asking = false);
    });
  }

  Future<void> _remove() async {
    _revert?.cancel();
    setState(() => _asking = false);
    final container = ProviderScope.containerOf(context, listen: false);
    await ref.read(downloadsStoreProvider)?.deleteDownload(_id);
    container.invalidate(seriesChapterDownloadStatusProvider((sourceId: widget.sourceId, seriesKey: widget.seriesKey)));
  }

  void _tap(DownloadMarkState mark) {
    final queue = ref.read(downloadQueueControllerProvider.notifier);
    switch (mark) {
      case MarkSaved():
        _ask();
      case MarkDownloading() || MarkQueued() || MarkPaused():
        unawaited(queue.cancelChapter(_id));
      case MarkNone() || MarkFailed() || MarkStale():
        cineFeedback(context, HapticEvent.downloadStart);
        unawaited(queue.enqueueChapter(id: _id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final series = (sourceId: widget.sourceId, seriesKey: widget.seriesKey);
    final status = ref.watch(seriesChapterDownloadStatusProvider(series)).valueOrNull?[widget.chapterKey];
    final active = ref.watch(seriesActiveChapterProgressProvider(series));
    final isActive = active != null && active.chapterKey == widget.chapterKey;
    final done = isActive ? active.progress.pagesDone : 0;
    final total = isActive ? active.progress.pageTotal : 0;
    final fraction = total > 0 ? done / total : 0.0;
    final paused = ref.watch(downloadQueueControllerProvider.select((q) => q.pauseReason)) != DownloadQueuePauseReason.none;
    final mark = downloadMarkState(status?.state, progress: fraction, paused: paused);
    if (_asking && mark is MarkSaved) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CineRoleText('Remove from this device?', c.typeCaption, color: c.colorInk60),
          const SizedBox(width: 8),
          CineArmButton(label: 'Remove', onPressed: _remove),
        ],
      );
    }
    final busy = mark is MarkDownloading;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (busy && total > 0) CineRoleText('$done/$total · ${(fraction * 100).round()}%', c.typeFolio, color: c.colorInk60),
        if (mark is MarkSaved) CineRoleText('SAVED', c.typeMicro, color: c.colorInk45),
        if (mark is MarkStale || (mark is MarkFailed && done == 0)) CineRoleText('Save again', c.typeCaption, color: c.colorProof),
        // An interrupted save that got part-way reads Resume with how far it got (8.14.3).
        if (mark is MarkFailed && done > 0) CineRoleText('Resume $done/$total', c.typeCaption, color: c.colorProof),
        CineDownloadMark(
          state: mark,
          page: isActive ? done : null,
          pageTotal: isActive ? total : null,
          onTap: () => _tap(mark),
        ),
      ],
    );
  }
}
