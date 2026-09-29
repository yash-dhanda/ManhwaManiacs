import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/models/known_chapter.dart';
import 'package:manhwamaniacs/features/library/models/series_detail.dart';
import 'package:manhwamaniacs/features/library/providers/library_series_actions.dart';
import 'package:manhwamaniacs/features/library/providers/shelf_provider.dart';
import 'package:manhwamaniacs/features/library/providers/shelf_query_provider.dart';
import 'package:manhwamaniacs/features/library/utils/bulk_runner.dart';
import 'package:manhwamaniacs/features/library/utils/manual_order.dart';
import 'package:manhwamaniacs/features/library/utils/mark_read.dart';
import 'package:manhwamaniacs/features/reader/models/reading_progress.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/quick_look_builders.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// What a bulk run leaves behind: the outcome, the result line and, where the action can be
/// undone, the undo.
typedef BulkResult = ({BulkOutcome outcome, String message, Future<void> Function()? undo});

Result<void> _void<T>(Result<T> r) => r.isErr ? Err(r.error) : const Ok(null);

/// The shelf's writes: one series and every bulk action of select mode (cinematic 8.9).
class ShelfActions {
  ShelfActions(this.context, this.ref);
  final BuildContext context;
  final WidgetRef ref;

  CineToastsNotifier get _toasts => ref.read(cineToastsProvider.notifier);
  ShelfNotifier get _shelf => ref.read(shelfProvider.notifier);

  void _touch({bool counts = true}) {
    if (counts) ref.invalidate(shelfCountsProvider);
  }

  bool _matchesFilters(FollowedSeries s) {
    final q = ref.read(shelfQueryProvider);
    if (q.fav && !s.isFavorite) return false;
    if (q.status.wire != null && q.status.wire != s.readingStatus) return false;
    return true;
  }

  // ---- one series ----------------------------------------------------------------------------

  Future<void> favourite(FollowedSeries s) async {
    final want = !s.isFavorite;
    final err = await ref.read(librarySeriesActionsProvider).setFavorite(s, favorite: want);
    if (err != null) {
      _toasts.error("Couldn't update the favourite.");
      return;
    }
    if (context.mounted) cineFeedback(context, HapticEvent.favorite, sound: SoundEvent.favorite);
    final next = s.copyWith(isFavorite: want);
    _shelf.replace(next);
    if (!_matchesFilters(next)) ref.invalidate(shelfProvider);
    _touch();
  }

  Future<void> notify(FollowedSeries s) async {
    final Result<FollowedSeries> r = await ref.read(libraryRepositoryProvider).patchSeries(s.id, notify: !s.notify);
    if (r.isErr) {
      _toasts.error("Couldn't update notifications.");
      return;
    }
    _shelf.replace(r.value);
  }

  Future<void> setStatus(FollowedSeries s, String status) async {
    final Result<FollowedSeries> r = await ref.read(libraryRepositoryProvider).patchSeries(s.id, readingStatus: status);
    if (r.isErr) {
      _toasts.error("Couldn't change the status.");
      return;
    }
    if (context.mounted) cineFeedback(context, HapticEvent.select);
    _shelf.replace(r.value);
    if (!_matchesFilters(r.value)) ref.invalidate(shelfProvider);
    _touch();
  }

  /// Takes [s] off the shelf at once; the toast's Undo re-follows and restores everything.
  Future<void> remove(FollowedSeries s) async {
    final actions = ref.read(librarySeriesActionsProvider);
    final removed = await actions.remove(s);
    if (removed.error != null) {
      _toasts.error("Couldn't remove ${s.title}.");
      return;
    }
    if (context.mounted) cineFeedback(context, HapticEvent.followRemove);
    _shelf.removeRow(s.id);
    _touch();
    _toasts.action('Removed ${s.title}. Your reading progress is kept.', label: 'Undo', onAction: () async {
      final err = await actions.restore(s, slots: removed.slots);
      if (err != null) {
        _toasts.error("Couldn't undo that.");
        return;
      }
      if (context.mounted) cineFeedback(context, HapticEvent.undo, sound: SoundEvent.undo);
      ref.invalidate(shelfProvider);
      _touch();
    },);
  }

  /// A manual-order drop: the page reorders at once, only the changed `sort_order` values are
  /// written (4 at a time), and a failure puts the old order back.
  Future<void> reorderRows(List<FollowedSeries> before, int from, int to) async {
    final moved = reorder(before, from, to);
    final after = [for (var i = 0; i < moved.length; i++) moved[i].copyWith(sortOrder: i)];
    _shelf.setRows(after);
    final changes = changedSortOrders(before, moved);
    final outcome = await runBulk<({int id, int sortOrder})>(changes, (c) async {
      final Result<FollowedSeries> r = await ref.read(libraryRepositoryProvider).patchSeries(c.id, sortOrder: c.sortOrder);
      return _void(r);
    });
    if (outcome.failed > 0) {
      _shelf.setRows(before);
      _toasts.error("Couldn't save the order.");
    }
  }

  // ---- bulk ----------------------------------------------------------------------------------

  Future<BulkResult> _patchAll(
    List<FollowedSeries> rows,
    Future<Result<FollowedSeries>> Function(FollowedSeries) patch, {
    required String verb,
    BulkCancel? cancel,
    void Function(int, int)? onProgress,
  }) async {
    final done = <FollowedSeries>[];
    final o = await runBulk<FollowedSeries>(rows, (s) async {
      final r = await patch(s);
      if (r.isOk) done.add(r.value);
      return _void(r);
    }, cancel: cancel, onProgress: onProgress,);
    _shelf.replaceMany(done);
    ref.invalidate(shelfProvider);
    _touch();
    return (outcome: o, message: summarizeBulkOutcome(o, verb: verb), undo: null);
  }

  Future<BulkResult> setFavourite(List<FollowedSeries> rows, bool fav, {BulkCancel? cancel, void Function(int, int)? onProgress}) => _patchAll(
        rows,
        (s) => ref.read(libraryRepositoryProvider).patchSeries(s.id, isFavorite: fav),
        verb: fav ? 'Favourited' : 'Unfavourited',
        cancel: cancel,
        onProgress: onProgress,
      );

  Future<BulkResult> setStatusAll(List<FollowedSeries> rows, String status, {BulkCancel? cancel, void Function(int, int)? onProgress}) => _patchAll(
        rows,
        (s) => ref.read(libraryRepositoryProvider).patchSeries(s.id, readingStatus: status),
        verb: 'Updated',
        cancel: cancel,
        onProgress: onProgress,
      );

  List<KnownChapter> _chapters(SeriesDetail d) => d.chapters.isNotEmpty ? d.chapters : d.knownChapters;

  /// Every chapter of each series not yet completed, posted `manual` in chunks of 200. The Undo
  /// deletes only the keys that were not completed before.
  Future<BulkResult> markRead(List<FollowedSeries> rows, {BulkCancel? cancel, void Function(int, int)? onProgress}) async {
    final reader = ref.read(readerRepositoryProvider);
    final marked = <(FollowedSeries, List<String>)>[];
    var chapters = 0;
    final o = await runBulk<FollowedSeries>(rows, (s) async {
      final Result<SeriesDetail> d = await ref.read(libraryRepositoryProvider).getSeries(s.id);
      if (d.isErr) return Err(d.error);
      final detail = d.value;
      final todo = [for (final k in _chapters(detail)) if (!(detail.progress[k.key]?.isCompleted ?? false)) k];
      if (todo.isEmpty) return const Ok(null);
      final pushes = manualReadRows([
        for (final k in todo)
          (sourceId: s.sourceId, seriesKey: s.seriesKey, chapterKey: k.key, chapterNumber: k.number, pageCount: k.pageCount ?? 0, completed: false),
      ]);
      for (final chunk in chunksOf200(pushes)) {
        final r = await reader.saveProgressBatch(chunk);
        if (r.isErr) return Err(r.error);
      }
      marked.add((s, [for (final k in todo) k.key]));
      chapters += todo.length;
      return const Ok(null);
    }, cancel: cancel, onProgress: onProgress,);
    ref.invalidate(shelfProvider);
    _touch();
    final message = o.failed > 0 || o.stopped ? summarizeBulkOutcome(o, verb: 'Marked') : 'Marked $chapters chapters read.';
    Future<void> undo() async {
      for (final (s, keys) in marked) {
        for (final chunk in chunksOf200(keys)) {
          await reader.deleteProgress(sourceId: s.sourceId, seriesKey: s.seriesKey, chapterKeys: chunk);
        }
      }
      ref.invalidate(shelfProvider);
    }

    if (chapters > 0) _toasts.undo(message, onUndo: () => unawaited(undo()));
    return (outcome: o, message: message, undo: null);
  }

  /// Deletes the progress of every known chapter of each series; the Undo re-posts the rows that
  /// were deleted, kept in memory until the toast closes.
  Future<BulkResult> markUnread(List<FollowedSeries> rows, {BulkCancel? cancel, void Function(int, int)? onProgress}) async {
    final reader = ref.read(readerRepositoryProvider);
    final removed = <List<ProgressPush>>[];
    final o = await runBulk<FollowedSeries>(rows, (s) async {
      final Result<SeriesDetail> d = await ref.read(libraryRepositoryProvider).getSeries(s.id);
      if (d.isErr) return Err(d.error);
      final detail = d.value;
      final keys = [for (final k in _chapters(detail)) k.key];
      final restore = [
        for (final k in _chapters(detail))
          if (detail.progress[k.key] != null)
            ProgressPush(
              sourceId: s.sourceId,
              seriesKey: s.seriesKey,
              chapterKey: k.key,
              chapterNumber: k.number,
              lastPage: detail.progress[k.key]!.lastPage,
              pageCount: k.pageCount ?? 0,
              isCompleted: detail.progress[k.key]!.isCompleted,
              manual: true,
            ),
      ];
      for (final chunk in chunksOf200(keys)) {
        final r = await reader.deleteProgress(sourceId: s.sourceId, seriesKey: s.seriesKey, chapterKeys: chunk);
        if (r.isErr) return Err(r.error);
      }
      removed.add(restore);
      return const Ok(null);
    }, cancel: cancel, onProgress: onProgress,);
    ref.invalidate(shelfProvider);
    _touch();
    final message = o.failed > 0 || o.stopped ? summarizeBulkOutcome(o, verb: 'Marked') : 'Marked ${o.done} series unread.';
    Future<void> undo() async {
      for (final rows in removed) {
        for (final chunk in chunksOf200(rows)) {
          await reader.saveProgressBatch(chunk);
        }
      }
      ref.invalidate(shelfProvider);
    }

    if (o.done > 0) _toasts.undo(message, onUndo: () => unawaited(undo()));
    return (outcome: o, message: message, undo: null);
  }

  Future<BulkResult> downloadNext(List<FollowedSeries> rows, {BulkCancel? cancel, void Function(int, int)? onProgress}) async {
    if (context.mounted) cineFeedback(context, HapticEvent.downloadStart);
    final o = await runBulk<FollowedSeries>(rows, (s) async {
      try {
        await downloadNextFive(context, ref, s, haptic: false);
        return const Ok(null);
      } catch (e) {
        return Err(e is AppError ? e : UnknownError(message: e.toString(), cause: e));
      }
    }, cancel: cancel, onProgress: onProgress,);
    return (outcome: o, message: summarizeBulkOutcome(o, verb: 'Queued downloads for'), undo: null);
  }

  /// Unfollows every series; the Undo re-follows each with its status, favourite, notify, override
  /// and position.
  Future<BulkResult> unfollow(List<FollowedSeries> rows, {BulkCancel? cancel, void Function(int, int)? onProgress}) async {
    final actions = ref.read(librarySeriesActionsProvider);
    final gone = <(FollowedSeries, ShelfSlots)>[];
    final o = await runBulk<FollowedSeries>(rows, (s) async {
      final r = await actions.remove(s);
      if (r.error != null) return Err(r.error!);
      gone.add((s, r.slots));
      return const Ok(null);
    }, cancel: cancel, onProgress: onProgress,);
    if (context.mounted) cineFeedback(context, HapticEvent.followRemove);
    ref.invalidate(shelfProvider);
    _touch();
    Future<void> undo() async {
      for (final (s, slots) in gone) {
        await actions.restore(s, slots: slots);
      }
      ref.invalidate(shelfProvider);
      _touch();
    }

    return (outcome: o, message: 'Unfollowed ${o.done} series.', undo: o.done > 0 ? undo : null);
  }
}
