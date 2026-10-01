import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/downloads/models/downloaded_series_group.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/downloads/providers/active_download_queue_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloaded_series_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_storage_providers.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/downloads/utils/next_chapters.dart';
import 'package:manhwamaniacs/features/downloads/utils/pending_removals.dart';
import 'package:manhwamaniacs/features/downloads/utils/queue_summary.dart';
import 'package:manhwamaniacs/features/library/models/continue_reading_item.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/features/sources/utils/series_content_kind.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/skin_haptics.dart';

/// What the Downloads screen does to the store. Every action refreshes the lists it changed.
class DownloadsActions {
  DownloadsActions(this.ref);
  final WidgetRef ref;

  void _refresh() {
    ref
      ..invalidate(downloadedSeriesProvider)
      ..invalidate(activeDownloadQueueProvider)
      ..invalidate(totalDeviceDownloadBytesProvider)
      ..invalidate(seriesStorageBreakdownProvider);
    ref.read(downloadQueueControllerProvider.notifier).retryAfterStorageChange();
  }

  /// "Removed chapter 12." with an 8 s Undo. The deletion is deferred through [PendingRemovals]
  /// so Undo can cancel it; backgrounding the app flushes it.
  void removeChapter(SavedChapter c) {
    final pending = ref.read(pendingRemovalsProvider);
    // Captured now, not when the timer fires: by then this widget may be disposed (its ref
    // throws) or another profile active (a different store).
    final store = ref.read(downloadsStoreProvider);
    final queue = ref.read(downloadQueueControllerProvider.notifier);
    final handle = pending.schedule(pendingRemovalKey(c.identity), () async {
      await store?.deleteDownload(c.identity);
      // Bumps the queue revision, so every store-backed list re-reads.
      try {
        queue.retryAfterStorageChange();
      } catch (_) {
        // The controller went with its container (sign-out): nothing left to refresh.
      }
    });
    final label = chapterLabelOf(c);
    final what = c.kind.isAudio ? 'saved audio' : label.toLowerCase().replaceFirst('ch ', 'chapter ');
    ref.read(cineToastsProvider.notifier).undo(
      'Removed $what.',
      onUndo: () {
        handle.undo();
        unawaited(ref.read(skinHapticsProvider).fire(HapticEvent.undo));
      },
    );
  }

  Future<void> removeSeries(DownloadedSeriesGroup g) async {
    final store = ref.read(downloadsStoreProvider);
    if (store == null) return;
    for (final c in g.chapters) {
      await store.deleteDownload(c.identity);
    }
    _refresh();
  }

  Future<void> setPinned(DownloadedSeriesGroup g, {required bool pinned}) async {
    unawaited(ref.read(skinHapticsProvider).fire(HapticEvent.select));
    await ref.read(downloadsStoreProvider)?.setSeriesPinned(
          series: (sourceId: g.sourceId, seriesKey: g.seriesKey),
          pinned: pinned,
        );
    ref
      ..invalidate(downloadedSeriesProvider)
      ..invalidate(seriesStorageBreakdownProvider);
  }
}

/// "Download next 5" on the empty state's rail: the next five unread chapters of [item]'s series,
/// through the same queue every download button uses. Returns how many were queued.
Future<int> downloadNextFive(WidgetRef ref, ContinueReadingItem item) async {
  final data = await ref.read(
    sourceSeriesDetailProvider((sourceId: item.sourceId, seriesId: item.seriesKey)).future,
  );
  final numbered = data.chapters.where((c) => c.number != null).toList()..sort((a, b) => a.number!.compareTo(b.number!));
  final order = [...numbered, ...data.chapters.where((c) => c.number == null)];
  final saved = <String>{
    for (final g in ref.read(downloadedSeriesProvider).valueOrNull ?? const <DownloadedSeriesGroup>[])
      if (g.sourceId == item.sourceId && g.seriesKey == item.seriesKey)
        for (final c in g.chapters) c.chapterKey,
  };
  final keys = nextUnreadKeys(
    [for (final c in order) c.id],
    currentKey: item.chapterKey,
    currentFinished: item.pageCount > 0 && item.lastPage >= item.pageCount,
    saved: saved,
  );
  final byId = {for (final c in order) c.id: c};
  final novel = isNovelSource(ref.read(contentModeScopeProvider), item.sourceId) ?? false;
  final requests = <ChapterQueueRequest>[
    for (final k in keys)
      (
        id: (sourceId: item.sourceId, seriesKey: item.seriesKey, chapterKey: k),
        chapterNumber: byId[k]?.number,
        title: byId[k]?.title,
        seriesTitle: item.title,
        kind: novel ? DownloadKind.novel : DownloadKind.manga,
      ),
  ];
  if (requests.isEmpty) return 0;
  unawaited(ref.read(skinHapticsProvider).fire(HapticEvent.downloadStart));
  await ref.read(downloadQueueControllerProvider.notifier).enqueueChapters(requests);
  return requests.length;
}
