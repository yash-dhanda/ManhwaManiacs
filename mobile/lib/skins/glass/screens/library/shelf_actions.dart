import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart' show contentModeScopeProvider;
import 'package:manhwamaniacs/features/downloads/models/chapter_selection.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart' show DownloadKind;
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/library/models/collection.dart' show Collection;
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/models/known_chapter.dart';
import 'package:manhwamaniacs/features/library/models/reading_history_item.dart';
import 'package:manhwamaniacs/features/library/models/series_detail.dart';
import 'package:manhwamaniacs/features/library/providers/history_pages_provider.dart';
import 'package:manhwamaniacs/features/library/providers/library_series_actions.dart';
import 'package:manhwamaniacs/features/library/providers/shelf_provider.dart';
import 'package:manhwamaniacs/features/library/providers/shelf_query_provider.dart';
import 'package:manhwamaniacs/features/library/utils/bulk_runner.dart';
import 'package:manhwamaniacs/features/library/utils/manual_order.dart';
import 'package:manhwamaniacs/features/library/utils/mark_read.dart';
import 'package:manhwamaniacs/features/library/utils/series_chapter_sort.dart';
import 'package:manhwamaniacs/features/library/utils/series_unread.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/features/sources/utils/series_content_kind.dart' show isNovelSource;
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/bulk_toolbar.dart' show BulkResult;
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';

Result<void> _void<T>(Result<T> r) => r.isErr ? Err(r.error) : const Ok(null);

/// The shelf's writes (glass 8.17): one series and every bulk action of select mode. Reads go through the [ProviderContainer], not a
/// `WidgetRef`, so a run that outlives the screen still finishes and never touches a disposed element. The data calls are the shared
/// ones Cinematic uses (`mark_read.dart`, `bulk_runner.dart`, `manual_order.dart`, `LibrarySeriesActions`).
class GlassShelfActions {
  GlassShelfActions(this._c);
  final ProviderContainer _c;

  ShelfNotifier get _shelf => _c.read(shelfProvider.notifier);

  void _toast(GlassToastSpec spec) => _c.read(glassToastProvider.notifier).show(spec);
  void _fire(HapticEvent e) => unawaited(_c.read(glassHapticsProvider).fire(e));

  List<FollowedSeries> rowsOf(Iterable<int> ids) {
    final want = ids.toSet();
    return [for (final s in _c.read(shelfProvider).valueOrNull?.rows ?? const <FollowedSeries>[]) if (want.contains(s.id)) s];
  }

  bool _matchesFilters(FollowedSeries s) {
    final q = _c.read(shelfQueryProvider);
    if (q.fav && !s.isFavorite) return false;
    final w = q.effectiveStatus.wire;
    return w == null || w == s.readingStatus;
  }

  void _counts() => _c.invalidate(shelfCountsProvider);

  // ---- one series ----------------------------------------------------------------------------

  Future<void> favourite(FollowedSeries s) async {
    final want = !s.isFavorite;
    final err = await _c.read(librarySeriesActionsProvider).setFavorite(s, favorite: want);
    if (err != null) {
      _toast(const GlassToastSpec("Couldn't update the favourite", kind: GlassToastKind.error));
      return;
    }
    _fire(HapticEvent.favorite);
    final next = s.copyWith(isFavorite: want);
    _shelf.replace(next);
    if (!_matchesFilters(next)) _c.invalidate(shelfProvider);
    _counts();
  }

  /// `POST /library/follow` or `DELETE /library/follow/{id}` from the hover bell: a followed row is unfollowed with Undo.
  Future<void> toggleFollow(FollowedSeries s) => remove(s);

  /// Takes [s] off the shelf at once; the toast's Undo re-follows and restores favourite, status, notify, override and position.
  Future<void> remove(FollowedSeries s) async {
    final actions = _c.read(librarySeriesActionsProvider);
    final removed = await actions.remove(s);
    if (removed.error != null) {
      _toast(GlassToastSpec("Couldn't remove ${s.title}", kind: GlassToastKind.error));
      return;
    }
    _fire(HapticEvent.followRemove);
    _shelf.removeRow(s.id);
    _counts();
    _toast(GlassToastSpec(
      'Removed ${s.title}',
      undo: () => unawaited(() async {
        final err = await actions.restore(s, slots: removed.slots);
        if (err != null) {
          _toast(const GlassToastSpec("Couldn't undo that", kind: GlassToastKind.error));
          return;
        }
        _fire(HapticEvent.undo);
        _c.invalidate(shelfProvider);
        _counts();
      }()),
    ),);
  }

  /// A manual-order move: the page reorders at once, only the changed `sort_order` values are written (4 at a time), and a
  /// failure puts the old order back. Returns the new position (1-based) for the announcement.
  Future<void> reorderRows(List<FollowedSeries> before, int from, int to) async {
    final moved = reorder(before, from, to);
    final after = [for (var i = 0; i < moved.length; i++) moved[i].copyWith(sortOrder: i)];
    _shelf.setRows(after);
    final changes = changedSortOrders(before, moved);
    final outcome = await runBulk<({int id, int sortOrder})>(changes, (c) async {
      final Result<FollowedSeries> r = await _c.read(libraryRepositoryProvider).patchSeries(c.id, sortOrder: c.sortOrder);
      return _void(r);
    });
    if (outcome.failed > 0) {
      _shelf.setRows(before);
      _toast(const GlassToastSpec("Couldn't save the order", kind: GlassToastKind.error));
    }
  }

  Future<void> addToCollection(Iterable<FollowedSeries> rows, Collection c) async {
    var ok = 0;
    for (final s in rows) {
      final r = await _c.read(libraryRepositoryProvider).addSeriesToCollection(c.id, sourceId: s.sourceId, seriesKey: s.seriesKey);
      if (r.isOk) ok++;
    }
    if (ok > 0) _fire(HapticEvent.followAdd);
    _toast(GlassToastSpec(ok > 0 ? 'Added to ${c.name}' : "Couldn't add that", kind: ok > 0 ? GlassToastKind.success : GlassToastKind.error));
  }

  // ---- bulk (each returns the BulkResult the floating toolbar turns into its toast) ------------------

  Future<BulkResult> _patchAll(Set<int> ids, Future<Result<FollowedSeries>> Function(FollowedSeries) patch, {BulkCancel? cancel}) async {
    final done = <FollowedSeries>[];
    final failed = <String>[];
    await runBulk<FollowedSeries>(rowsOf(ids), (s) async {
      final r = await patch(s);
      if (r.isOk) {
        done.add(r.value);
      } else {
        failed.add('${s.id}');
      }
      return _void(r);
    }, cancel: cancel,);
    _shelf.replaceMany(done);
    _c.invalidate(shelfProvider);
    _counts();
    return BulkResult(ok: done.length, failed: failed);
  }

  Future<BulkResult> setFavourite(Set<int> ids, bool fav, {BulkCancel? cancel}) =>
      _patchAll(ids, (s) => _c.read(libraryRepositoryProvider).patchSeries(s.id, isFavorite: fav), cancel: cancel);

  List<KnownChapter> _chapters(SeriesDetail d) => d.chapters.isNotEmpty ? d.chapters : d.knownChapters;

  /// Keys each `markRead` run posted, by series id, so its Undo deletes only what was not completed before.
  /// Series id -> its identity and the keys [markRead] posted. The identity is kept here because
  /// the series may have left the (filtered) shelf by the time Undo runs.
  final Map<int, ({String sourceId, String seriesKey, List<String> keys})> _marked = {};

  /// Every not-yet-completed chapter of each series, posted `manual: true` in chunks of 200 (`POST /reader/progress/batch`).
  Future<BulkResult> markRead(Set<int> ids, {BulkCancel? cancel}) async {
    final reader = _c.read(readerRepositoryProvider);
    final failed = <String>[];
    var ok = 0;
    await runBulk<FollowedSeries>(rowsOf(ids), (s) async {
      final Result<SeriesDetail> d = await _c.read(libraryRepositoryProvider).getSeries(s.id);
      if (d.isErr) {
        failed.add('${s.id}');
        return Err(d.error);
      }
      final detail = d.value;
      final todo = [for (final k in _chapters(detail)) if (!(detail.progress[k.key]?.isCompleted ?? false)) k];
      if (todo.isNotEmpty) {
        final pushes = manualReadRows([
          for (final k in todo) (sourceId: s.sourceId, seriesKey: s.seriesKey, chapterKey: k.key, chapterNumber: k.number, pageCount: k.pageCount ?? 0, completed: false),
        ]);
        for (final chunk in chunksOf200(pushes)) {
          final r = await reader.saveProgressBatch(chunk);
          if (r.isErr) {
            failed.add('${s.id}');
            return Err(r.error);
          }
        }
        _marked[s.id] = (sourceId: s.sourceId, seriesKey: s.seriesKey, keys: [for (final k in todo) k.key]);
      }
      ok++;
      return const Ok(null);
    }, cancel: cancel,);
    _c.invalidate(shelfProvider);
    _counts();
    return BulkResult(ok: ok, failed: failed);
  }

  /// `DELETE /reader/progress` of only the keys the last [markRead] posted for [ids].
  Future<void> undoMarkRead(Set<int> ids) async {
    final reader = _c.read(readerRepositoryProvider);
    for (final id in ids) {
      final m = _marked.remove(id);
      if (m == null) continue;
      for (final chunk in chunksOf200(m.keys)) {
        await reader.deleteProgress(sourceId: m.sourceId, seriesKey: m.seriesKey, chapterKeys: chunk);
      }
    }
    _c.invalidate(shelfProvider);
    _fire(HapticEvent.undo);
  }

  final Map<int, Future<void> Function()> _unmarked = {};

  /// Deletes the progress of every known chapter of each series, on the server and on this phone; Undo re-posts what was deleted.
  Future<BulkResult> markUnread(Set<int> ids, {BulkCancel? cancel}) async {
    final failed = <String>[];
    var ok = 0;
    await runBulk<FollowedSeries>(rowsOf(ids), (s) async {
      final Result<SeriesDetail> d = await _c.read(libraryRepositoryProvider).getSeries(s.id);
      if (d.isErr) {
        failed.add('${s.id}');
        return Err(d.error);
      }
      final r = await markSeriesUnread(_c, sourceId: s.sourceId, seriesKey: s.seriesKey, keys: [for (final k in _chapters(d.value)) k.key]);
      if (r.isErr) {
        failed.add('${s.id}');
        return Err(r.error);
      }
      _unmarked[s.id] = r.value;
      ok++;
      return const Ok(null);
    }, cancel: cancel,);
    _c.invalidate(shelfProvider);
    _counts();
    return BulkResult(ok: ok, failed: failed);
  }

  Future<void> undoMarkUnread(Set<int> ids) async {
    for (final id in ids) {
      await _unmarked.remove(id)?.call();
    }
    _c.invalidate(shelfProvider);
    _fire(HapticEvent.undo);
  }

  /// Queues the next 10 unread, not yet saved chapters of [s] through the shared chapter-selection planner.
  Future<int> _queueNextTen(FollowedSeries s) async {
    final detail = await _c.read(sourceSeriesDetailProvider((sourceId: s.sourceId, seriesId: s.seriesKey)).future);
    final ordered = sortSeriesChapters(detail.chapters, numberOf: (c) => c.number, order: SeriesChapterSortOrder.oldest);
    final readNumber = s.readState?.chapterNumber;
    final saved = await savedOrQueuedChapterKeys(_c.read(downloadsStoreProvider), (sourceId: s.sourceId, seriesKey: s.seriesKey));
    final keys = nextUnreadUndownloadedKeys([
      for (final c in ordered) (key: c.id, number: c.number, title: c.title, isRead: readNumber != null && c.number != null && c.number! <= readNumber, isDownloaded: saved.contains(c.id)),
    ]);
    final byKey = {for (final c in ordered) c.id: c};
    await _c.read(downloadQueueControllerProvider.notifier).enqueueChapters([
      for (final k in keys)
        (
          id: (sourceId: s.sourceId, seriesKey: s.seriesKey, chapterKey: k),
          chapterNumber: byKey[k]?.number,
          title: byKey[k]?.title,
          seriesTitle: s.title,
          kind: (isNovelSource(_c.read(contentModeScopeProvider), s.sourceId) ?? false) ? DownloadKind.novel : DownloadKind.manga,
        ),
    ]);
    return keys.length;
  }

  Future<BulkResult> downloadNextTen(Set<int> ids, {BulkCancel? cancel}) async {
    _fire(HapticEvent.downloadStart);
    final failed = <String>[];
    var ok = 0;
    await runBulk<FollowedSeries>(rowsOf(ids), (s) async {
      try {
        await _queueNextTen(s);
        ok++;
        return const Ok(null);
      } catch (e) {
        failed.add('${s.id}');
        return Err(e is AppError ? e : UnknownError(message: e.toString(), cause: e));
      }
    }, cancel: cancel,);
    return BulkResult(ok: ok, failed: failed);
  }

  final Map<int, (FollowedSeries, ShelfSlots)> _gone = {};

  /// Unfollows every series; Undo re-follows each with its status, favourite, notify, override and position.
  Future<BulkResult> unfollow(Set<int> ids, {BulkCancel? cancel}) async {
    final actions = _c.read(librarySeriesActionsProvider);
    final failed = <String>[];
    var ok = 0;
    await runBulk<FollowedSeries>(rowsOf(ids), (s) async {
      final r = await actions.remove(s);
      if (r.error != null) {
        failed.add('${s.id}');
        return Err(r.error!);
      }
      _gone[s.id] = (s, r.slots);
      ok++;
      return const Ok(null);
    }, cancel: cancel,);
    _fire(HapticEvent.followRemove);
    _c.invalidate(shelfProvider);
    _counts();
    return BulkResult(ok: ok, failed: failed);
  }

  Future<void> undoUnfollow(Set<int> ids) async {
    final actions = _c.read(librarySeriesActionsProvider);
    for (final id in ids) {
      final g = _gone.remove(id);
      if (g != null) await actions.restore(g.$1, slots: g.$2);
    }
    _fire(HapticEvent.undo);
    _c.invalidate(shelfProvider);
    _counts();
  }

  /// Mark read of one history chapter (`POST /reader/progress/batch`, `manual: true`): no streak, goal or Statistics effect.
  Future<void> markChapterRead(ReadingHistoryItem i) async {
    final rows = manualReadRows([(sourceId: i.sourceId, seriesKey: i.seriesKey, chapterKey: i.chapterKey, chapterNumber: i.chapterNumber, pageCount: i.pageCount, completed: false)]);
    final r = await _c.read(readerRepositoryProvider).saveProgressBatch(rows);
    if (r.isErr) {
      _toast(const GlassToastSpec("Couldn't mark that chapter", kind: GlassToastKind.error));
      throw r.error;
    }
    _c
      ..invalidate(historyPagesProvider(true))
      ..invalidate(historyPagesProvider(false));
  }
}

/// The actions of the active container.
final glassShelfActionsProvider = Provider<GlassShelfActions>((ref) => GlassShelfActions(ref.container), name: 'glassShelfActions');
