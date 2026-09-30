import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/network/bulk_limiter.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/features/downloads/services/offline_reader.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_signals_provider.dart';
import 'package:manhwamaniacs/features/reader/utils/read_all_feed.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_feed_controller.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

/// What a manifest reader body hands the factory that builds its [ReaderFeedController].
class ReaderFeedArgs {
  const ReaderFeedArgs({required this.anchor, required this.prev, required this.next, required this.order, required this.neighboursOf, required this.loadChapter});

  final ReaderChapter anchor;
  final String? prev, next;
  final List<String>? order;
  final ReaderNeighbourLoader neighboursOf;
  final ReaderChapterLoader loadChapter;
}

typedef ReaderFeedFactory = ReaderFeedController Function(ReaderFeedArgs args);

/// Null keeps the ordinary controller of the legacy reader; the Cinematic read-all route overrides
/// it with [readAllFeedFactory] (windowed batch manifests, cinematic 8.14.4).
final readerFeedFactoryProvider = Provider<ReaderFeedFactory?>((ref) => null, name: 'readerFeedFactory');

/// The read-all controller of [sourceId] / [seriesKey], reading batches through [ref].
ReaderFeedFactory readAllFeedFactory(Ref ref, {required String sourceId, required String seriesKey}) {
  final limiter = ref.read(readAllLimiterProvider);
  return (a) {
    final c = ReadAllFeedController(
        anchor: a.anchor,
        keys: a.order ?? [a.anchor.id],
        loadChapter: a.loadChapter,
        loadWindow: (keys) => loadReadAllWindow(ref, sourceId: sourceId, seriesKey: seriesKey, keys: keys),
        limiter: limiter,
        seriesKey: seriesKey,
        sourceId: sourceId,
        onRateLimited: (d) => ref.read(readerRateLimitedUntilProvider.notifier).state = DateTime.now().add(d),
      );
    Future<void>.microtask(() {
      ref.read(readAllControllerProvider.notifier).state = c;
      // The window fills in behind the first chapter at once, both ways from a mid-series start.
      unawaited(c.extendForward());
      unawaited(c.extendBackward());
    });
    return c;
  };
}

/// One batch of the read-all feed: saved chapters come off the disk, the rest in one
/// `POST /reader/chapters/manifest`. A 429 answers nothing; every other failure is per chapter.
Future<ReadAllWindowResult> loadReadAllWindow(Ref ref, {required String sourceId, required String seriesKey, required List<String> keys}) async {
  final store = ref.read(downloadsStoreProvider);
  final base = ref.read(apiBaseUrlProvider);
  final chapters = <String, ReaderChapter>{};
  final need = <String>[];
  for (final k in keys) {
    ReaderChapter? disk;
    if (store != null) {
      disk = await buildOfflineReaderChapter(store, (sourceId: sourceId, seriesKey: seriesKey, chapterKey: k), hideMature: !ref.read(matureGateOpenProvider));
    }
    if (disk != null) {
      chapters[k] = disk;
    } else {
      need.add(k);
    }
  }
  if (need.isEmpty) return ReadAllWindowResult(chapters: chapters);
  final r = await ref.read(readerRepositoryProvider).manifestWindow(sourceId: sourceId, seriesKey: seriesKey, chapterKeys: need);
  if (r.isErr) {
    final wait = rateLimitWait(r.error);
    if (wait != null) return ReadAllWindowResult(rateLimited: wait);
    final offline = r.error is NetworkError || r.error is TimeoutError;
    return ReadAllWindowResult(chapters: chapters, failed: need.toSet(), offline: offline);
  }
  for (final k in need) {
    final m = r.value.manifests[k];
    if (m == null) continue;
    chapters[k] = await overlayLocalPages(store, m.toReaderChapter(base), id: (sourceId: sourceId, seriesKey: seriesKey, chapterKey: k));
  }
  return ReadAllWindowResult(chapters: chapters, failed: {for (final k in need) if (!chapters.containsKey(k)) k});
}

/// The one limiter of `POST /reader/chapters/manifest` (6 starts per 60 s) for the app session.
final readAllLimiterProvider = Provider<BulkLimiter>((ref) {
  final l = BulkLimiter();
  ref.onDispose(l.dispose);
  return l;
}, name: 'readAllLimiter',);

/// The controller of the read-all feed on screen, for the skin's `Try again` on a failed chapter.
final readAllControllerProvider = StateProvider<ReadAllFeedController?>((ref) => null, name: 'readAllController');
