import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/network/network_connectivity.dart';
import 'package:manhwamaniacs/features/downloads/providers/download_switches_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/reader/engine/neighbour.dart' show kNeighbourPreloadAt;
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

/// Queues the next chapter for download once the reader is well into the one it is reading — gated
/// on the "Wi-Fi only downloads" setting so idly reading never burns mobile
/// data the user didn't ask to spend — via the same on-device queue a manual
/// "Download" tap uses (spec §3).
///
/// Not on open: the queue fetches four pages at a time, and doing that while the chapter on screen
/// is still loading and prefetching its own pages makes the page being read the slower one. It waits
/// for the same moment the engine starts warming its neighbour, [kNeighbourPreloadAt] of the chapter
/// (a chapter of a few pages crosses it almost at once).
///
/// One instance per reader screen; fires at most once per next chapter, so a continuous feed that
/// reads on through several seams keeps saving one chapter ahead of what it has loaded.
class NextChapterAutoQueue {
  /// [saveNextEnabled] is the per-profile "Save the next chapter while I read" switch (default
  /// on); null reads `saveNextProvider`, which is what `mobile/17` wired.
  NextChapterAutoQueue({this.saveNextEnabled});

  final bool Function()? saveNextEnabled;

  /// What reading far enough into a chapter queues, by that chapter's id. Re-armed on every build, so it follows the feed as
  /// it grows; a chapter's entry stays until it is queued, because the feed appends the next chapter (and the rebuild
  /// re-arms one further on) before a short chapter has been read to the preload mark. Bounded: the oldest goes first.
  final Map<String, ({String sourceId, String seriesKey, String nextId})> _armed = {};

  /// The chapters already queued, so each fires once however often the screen rebuilds. Bounded like [_armed].
  final Set<String> _queued = {};

  static const int _kRemembered = 16;

  /// Says which chapter to save once [afterChapterId] (the last chapter the feed holds) has been
  /// read to [kNeighbourPreloadAt]. Queues nothing itself.
  ///
  /// Guarded on the id being *known*, not merely on the chapter having been shown: a downloaded
  /// chapter paints from disk before anything knows what comes next.
  void arm({
    required String sourceId,
    required String seriesKey,
    required String? nextChapterId,
    required String afterChapterId,
  }) {
    if (nextChapterId == null || _queued.contains(nextChapterId)) return;
    _armed.remove(afterChapterId);
    _armed[afterChapterId] = (sourceId: sourceId, seriesKey: seriesKey, nextId: nextChapterId);
    while (_armed.length > _kRemembered) {
      _armed.remove(_armed.keys.first);
    }
  }

  /// The reader is on [page] (1-based) of [pageCount] pages of [chapterId]: queues the chapter armed after it
  /// when the read share has reached the preload mark.
  void readTo(
    WidgetRef ref, {
    required String chapterId,
    required int page,
    required int pageCount,
  }) {
    final armed = _armed[chapterId];
    if (armed == null || pageCount <= 0) return;
    if (page / pageCount < kNeighbourPreloadAt) return;
    _armed.remove(chapterId);
    if (!_queued.add(armed.nextId)) return;
    while (_queued.length > _kRemembered) {
      _queued.remove(_queued.first);
    }
    unawaited(_queue(ref, sourceId: armed.sourceId, seriesKey: armed.seriesKey, nextId: armed.nextId));
  }

  Future<void> _queue(
    WidgetRef ref, {
    required String sourceId,
    required String seriesKey,
    required String nextId,
  }) async {
    // Everything the widget's ref is needed for is read before the first await: leaving the reader during the
    // connectivity call disposes it, and a later read throws into the zone (a fatal-error overlay in a release build).
    final DownloadQueueController queue;
    final bool wifiOnly;
    final NetworkConnectivity connectivity;
    try {
      if (ref.read(activeDownloadsScopeIdProvider) == null) return;
      // The per-profile "Save the next chapter while I read" switch (default on).
      if (!(saveNextEnabled?.call() ?? ref.read(saveNextProvider))) return;
      wifiOnly = ref.read(preferencesProvider).wifiOnlyDownloads;
      connectivity = ref.read(networkConnectivityProvider);
      queue = ref.read(downloadQueueControllerProvider.notifier);
    } catch (_) {
      return; // the screen is already gone
    }

    try {
      if (wifiOnly && !await connectivity.isOnWifi()) return;
      await queue.enqueueChapter(
        id: (
          sourceId: sourceId,
          seriesKey: seriesKey,
          chapterKey: nextId,
        ),
        automatic: true,
      );
    } catch (_) {
      // Best effort, like the auto-download poll: a failed connectivity check or queue write saves nothing.
    }
  }
}
