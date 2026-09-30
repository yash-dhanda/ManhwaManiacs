import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/library/models/continue_reading_item.dart';
import 'package:manhwamaniacs/features/library/providers/dashboard_providers.dart';
import 'package:manhwamaniacs/features/library/utils/followed_series_cache.dart';
import 'package:manhwamaniacs/features/novels/novel_text/novel_text_index.dart';
import 'package:manhwamaniacs/features/novels/novel_text/novel_text_tokens.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

enum NovelTextStatus { idle, noDownloads, indexing, ready }

class NovelTextState {
  const NovelTextState({required this.status, this.hits = const [], this.capped = false, this.indexing = 0});
  final NovelTextStatus status;
  final List<NovelTextHit> hits;
  final bool capped;

  /// Chapters still being prepared for search.
  final int indexing;
}

/// Ready novel chapters of the active scope (the "is there anything to search" answer).
final downloadedNovelChaptersProvider = FutureProvider.autoDispose<List<SavedChapter>>((ref) async {
  final store = ref.watch(downloadsStoreProvider);
  ref.watch(downloadQueueControllerProvider.select((s) => s.queueRevision));
  if (store == null) return const [];
  final rows = await store.listChapters();
  return [for (final r in rows) if (r.kind.isNovel && r.state == DownloadChapterState.complete) r];
});

/// The first open of the Novel text scope in a session indexes every ready novel chapter of the scope that is not indexed yet, at
/// most four at a time. The state is the number still to do.
class NovelTextBackfill extends Notifier<int> {
  bool _started = false;
  bool _disposed = false;

  @override
  int build() {
    ref.onDispose(() => _disposed = true);
    return 0;
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    final store = ref.read(downloadsStoreProvider);
    if (store == null) {
      _started = false;
      return;
    }
    final db = await store.database;
    final index = NovelTextIndex(db);
    final rows = [for (final r in await store.listChapters()) if (r.kind.isNovel && r.state == DownloadChapterState.complete) r];
    final missing = <SavedChapter>[];
    for (final r in rows) {
      if (!await index.isIndexed(r.sourceId, r.seriesKey, r.chapterKey)) missing.add(r);
    }
    if (_disposed) return;
    state = missing.length;
    final queue = [...missing];
    Future<void> worker() async {
      while (queue.isNotEmpty) {
        final r = queue.removeLast();
        try {
          final json = await store.readNovelText(r.identity);
          final paras = [for (final p in (json?['paragraphs'] as List<dynamic>? ?? const [])) if (p is String) p];
          if (paras.isNotEmpty) {
            await index.indexChapter(sourceId: r.sourceId, seriesKey: r.seriesKey, chapterKey: r.chapterKey, paragraphs: paras);
          }
        } catch (_) {
          // A chapter that cannot be read is left out; the next session tries again.
        }
        if (!_disposed) state = state > 0 ? state - 1 : 0;
      }
    }

    await Future.wait([for (var i = 0; i < 4; i++) worker()]);
  }
}

final novelTextBackfillProvider = NotifierProvider<NovelTextBackfill, int>(NovelTextBackfill.new);

/// `"source:series"` keys of series the profile is reading: follows with `reading_status == "reading"` (the cached library) and the
/// continue list.
final readingSeriesKeysProvider = Provider.autoDispose<List<String>>((ref) {
  final scope = ref.watch(activeDownloadsScopeIdProvider);
  final out = <String>{};
  if (scope != null) {
    for (final s in readCachedFollowedSeries(ref.watch(sharedPrefsProvider), followedSeriesCacheKeyFor(scope))) {
      if (s.readingStatus == 'reading') out.add('${s.sourceId}:${s.seriesKey}');
    }
  }
  final cont = ref.watch(continueReadingProvider).valueOrNull ?? const <ContinueReadingItem>[];
  for (final c in cont) {
    out.add('${c.sourceId}:${c.seriesKey}');
  }
  return out.toList();
});

/// `{state: idle | noDownloads | indexing | ready, hits, capped, indexing}` for [q]. With chapters still indexing it returns the hits
/// from what is indexed.
final novelTextSearchProvider = FutureProvider.autoDispose.family<NovelTextState, String>((ref, q) async {
  final store = ref.watch(downloadsStoreProvider);
  final pending = ref.watch(novelTextBackfillProvider);
  final gateOpen = ref.watch(matureGateOpenProvider);
  final reading = ref.watch(readingSeriesKeysProvider);
  final downloaded = await ref.watch(downloadedNovelChaptersProvider.future);
  if (store == null || downloaded.isEmpty) return const NovelTextState(status: NovelTextStatus.noDownloads);
  if (novelTextMatchQuery(q) == null) return NovelTextState(status: pending > 0 ? NovelTextStatus.indexing : NovelTextStatus.idle, indexing: pending);
  final result = await NovelTextIndex(await store.database).search(q, scopeId: store.scopeId, gateOpen: gateOpen, readingSeries: reading);
  return NovelTextState(status: pending > 0 ? NovelTextStatus.indexing : NovelTextStatus.ready, hits: result.hits, capped: result.capped, indexing: pending);
});
