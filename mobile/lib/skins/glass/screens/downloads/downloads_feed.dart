import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/models/downloaded_series_group.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/downloads/providers/active_download_queue_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloaded_series_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/downloads/utils/active_download_count.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/shell/accessory_controller.dart';

/// Feeds the Downloading accessory from the shared queue and announces completions (glass 7.15, 8.22): "Saving 3 chapters · 42 %" with
/// the pause control, `download.done` once per batch ("12 chapters of Solo Leveling downloaded") and `download.fail` on a failure.
/// Mount it once near the shell; it draws nothing.
class GlassDownloadsFeed extends ConsumerStatefulWidget {
  const GlassDownloadsFeed({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<GlassDownloadsFeed> createState() => _GlassDownloadsFeedState();
}

class _GlassDownloadsFeedState extends ConsumerState<GlassDownloadsFeed> {
  Map<int, DownloadChapterState> _seen = const {};
  int _batchDone = 0;
  String? _batchSeries;
  final Set<String> _batchSeriesSet = {};
  bool _failed = false;

  void _accessory() {
    final rows = ref.read(activeDownloadQueueProvider).valueOrNull ?? const <SavedChapter>[];
    final q = ref.read(downloadQueueControllerProvider);
    final n = ref.read(glassActiveDownloadCountProvider);
    final acc = ref.read(glassAccessoryProvider.notifier);
    final owed = rows.where((c) => c.state == DownloadChapterState.queued || c.state == DownloadChapterState.downloading).length;
    if (owed == 0 || n == 0) {
      if (ref.read(glassAccessoryProvider).downloading != null) acc.setDownloading(null);
      return;
    }
    final lead = q.pageTotal > 0 ? (q.pagesDone / q.pageTotal).clamp(0.0, 1.0) : 0.0;
    final paused = q.isPaused && q.pauseReason != DownloadQueuePauseReason.none;
    final overall = ((_batchDone + lead) / (_batchDone + owed)).clamp(0.0, 1.0);
    acc.setDownloading(GlassDownloadingAccessory(
      chapters: owed,
      progress: overall,
      paused: paused,
      onToggle: () {
        final c = ref.read(downloadQueueControllerProvider.notifier);
        if (paused) {
          c.resume();
        } else {
          c.pause();
        }
      },
    ),);
  }

  void _transitions(List<DownloadedSeriesGroup> groups) {
    final now = <int, DownloadChapterState>{};
    final titles = <int, String>{};
    for (final g in groups) {
      for (final c in g.chapters) {
        now[c.rowId] = c.state;
        titles[c.rowId] = c.seriesTitle ?? c.seriesKey;
      }
    }
    var done = 0;
    var failed = false;
    for (final e in now.entries) {
      final was = _seen[e.key];
      if (was == null) continue;
      if (e.value == DownloadChapterState.complete && was != DownloadChapterState.complete) {
        done++;
        _batchSeriesSet.add(titles[e.key] ?? '');
        _batchSeries = titles[e.key];
      }
      if (e.value == DownloadChapterState.failed && was != DownloadChapterState.failed) failed = true;
    }
    _seen = now;
    _batchDone += done;
    final unfinished = now.values.where((s) => s == DownloadChapterState.queued || s == DownloadChapterState.downloading).length;
    if (failed && !_failed) unawaited(ref.read(glassHapticsProvider).fire(HapticEvent.downloadFail));
    _failed = failed;
    if (unfinished == 0 && _batchDone > 0) {
      unawaited(ref.read(glassHapticsProvider).fire(HapticEvent.downloadDone));
      final msg = _batchDone == 1 ? 'Chapter downloaded' : (_batchSeriesSet.length == 1 ? '$_batchDone chapters of $_batchSeries downloaded' : '$_batchDone chapters downloaded');
      try {
        unawaited(SemanticsService.sendAnnouncement(View.of(context), msg, TextDirection.ltr));
      } catch (_) {}
      _batchDone = 0;
      _batchSeriesSet.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(downloadedSeriesProvider, (p, n) {
      final v = n.valueOrNull;
      if (v != null) _transitions(v);
      WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _accessory() : null);
    });
    ref.listen(downloadQueueControllerProvider, (p, n) => WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _accessory() : null));
    ref.listen(activeDownloadQueueProvider, (p, n) => WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _accessory() : null));
    return widget.child;
  }
}
