import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_poll.dart';
import 'package:manhwamaniacs/features/circle/repositories/circle_repository.dart';
import 'package:manhwamaniacs/features/circle/repositories/circle_repository_impl.dart';
import 'package:manhwamaniacs/features/circle/store/reaction_outbox.dart';
import 'package:manhwamaniacs/features/circle/utils/letters.dart';
import 'package:manhwamaniacs/features/circle/utils/reaction_kinds.dart';
import 'package:manhwamaniacs/features/circle/utils/sharing_patch.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

final circleRepositoryProvider = Provider<CircleRepository>((ref) => CircleRepositoryImpl(ref.watch(dioProvider)), name: 'circleRepository');

typedef CircleSeriesKey = ({String sourceId, String seriesKey});

T _ok<T>(Result<T> result) {
  if (result.isErr) throw result.error;
  return result.value;
}

/// The Circle's readers, followers and reactions for one series. `null` means the Circle is not
/// deployed (404): the reader removes the tab. An error throws, for the tab's `CORRECTION` line.
final circleSeriesProvider = FutureProvider.autoDispose.family<CircleSeriesData?, CircleSeriesKey>((ref, key) async {
  final r = await ref.watch(circleRepositoryProvider).series(sourceId: key.sourceId, seriesKey: key.seriesKey);
  return _ok(r);
}, name: 'circleSeries',);

// ── Polling ─────────────────────────────────────────────────────────────────

/// One controller for every Circle surface; a `CirclePollScope` registers each surface with it.
final circlePollControllerProvider = Provider<CirclePollController>((ref) {
  final c = CirclePollController(onTick: () {
    ref.invalidate(circleMembersProvider);
    ref.invalidate(lettersProvider);
    ref.invalidate(circleMemberProvider);
  },);
  try {
    WidgetsBinding.instance.addObserver(c);
  } catch (_) {
    // No binding in a bare unit test: setResumed drives it.
  }
  ref.onDispose(() {
    try {
      WidgetsBinding.instance.removeObserver(c);
    } catch (_) {}
    c.dispose();
  });
  return c;
}, name: 'circlePollController',);

// ── Members ─────────────────────────────────────────────────────────────────

class CircleMembersNotifier extends AsyncNotifier<List<CircleMember>> {
  @override
  Future<List<CircleMember>> build() async => _ok(await ref.watch(circleRepositoryProvider).members());
}

final circleMembersProvider = AsyncNotifierProvider<CircleMembersNotifier, List<CircleMember>>(CircleMembersNotifier.new, name: 'circleMembers');

/// The member page. `ApiError(code: circle_member_not_sharing)` when they stopped sharing.
final circleMemberProvider = FutureProvider.autoDispose.family<MemberPage, int>((ref, id) async => _ok(await ref.watch(circleRepositoryProvider).member(id)), name: 'circleMember');

/// Members who can receive this series (`canReceive`), for Pass it on.
final recipientsProvider = FutureProvider.autoDispose.family<List<CircleMember>, CircleSeriesKey>((ref, key) async {
  final all = _ok(await ref.watch(circleRepositoryProvider).members(sourceId: key.sourceId, seriesKey: key.seriesKey));
  return [for (final m in all) if (m.canReceive ?? false) m];
}, name: 'recipients',);

// ── Feed ────────────────────────────────────────────────────────────────────

class CircleFeedState {
  const CircleFeedState({this.items = const [], this.nextCursor, this.loadingMore = false});
  final List<FeedItem> items;
  final String? nextCursor;
  final bool loadingMore;
  bool get hasMore => nextCursor != null;
}

/// The feed for a kind (`null` all, `reading`, `reaction`), paging on `next_cursor`.
class CircleFeedNotifier extends FamilyAsyncNotifier<CircleFeedState, String?> {
  @override
  Future<CircleFeedState> build(String? arg) async {
    final p = _ok(await ref.watch(circleRepositoryProvider).feed(kind: arg));
    return CircleFeedState(items: p.items, nextCursor: p.nextCursor);
  }

  Future<void> loadMore() async {
    final s = state.valueOrNull;
    if (s == null || !s.hasMore || s.loadingMore) return;
    state = AsyncData(CircleFeedState(items: s.items, nextCursor: s.nextCursor, loadingMore: true));
    final r = await ref.read(circleRepositoryProvider).feed(kind: arg, cursor: s.nextCursor);
    if (r.isErr) {
      state = AsyncData(CircleFeedState(items: s.items, nextCursor: s.nextCursor));
      return;
    }
    final seen = {for (final i in s.items) i.id};
    state = AsyncData(CircleFeedState(items: [...s.items, for (final i in r.value.items) if (!seen.contains(i.id)) i], nextCursor: r.value.nextCursor));
  }

  /// After the viewer follows a series from a dispatch.
  void markFollowed(String sourceId, String seriesKey) {
    final s = state.valueOrNull;
    if (s == null) return;
    state = AsyncData(CircleFeedState(
      items: [for (final i in s.items) i.sourceId == sourceId && i.seriesKey == seriesKey ? i.copyWith(followedByViewer: true) : i],
      nextCursor: s.nextCursor,
      loadingMore: s.loadingMore,
    ),);
  }
}

final circleFeedProvider = AsyncNotifierProvider.family<CircleFeedNotifier, CircleFeedState, String?>(CircleFeedNotifier.new, name: 'circleFeed');

// ── Reactions ───────────────────────────────────────────────────────────────

final reactionOutboxProvider = Provider<ReactionOutbox?>((ref) {
  final scope = ref.watch(activeDownloadsScopeIdProvider);
  return scope == null ? null : ReactionOutbox(ref.watch(sharedPrefsProvider), scope);
}, name: 'reactionOutbox',);

bool _isNetwork(Object e) => e is NetworkError || e is TimeoutError;

/// Sends queued reactions when the connection is back and when the app resumes; refetches after.
final circleOutboxFlusherProvider = Provider<Future<void> Function()>((ref) {
  Future<void> flush() async {
    final box = ref.read(reactionOutboxProvider);
    if (box == null || box.entries().isEmpty) return;
    final sent = await box.flush(ref.read(circleRepositoryProvider), isNetwork: _isNetwork);
    if (sent > 0) ref.invalidate(chapterReactionsProvider);
  }

  ref.listen<AsyncValue<bool>>(deviceOnlineProvider, (prev, next) {
    if ((next.valueOrNull ?? false) && prev?.valueOrNull == false) unawaited(flush());
  });
  final observer = _ResumeObserver(() => unawaited(flush()));
  try {
    WidgetsBinding.instance.addObserver(observer);
  } catch (_) {}
  ref.onDispose(() {
    try {
      WidgetsBinding.instance.removeObserver(observer);
    } catch (_) {}
  });
  return flush;
}, name: 'circleOutboxFlusher',);

class _ResumeObserver with WidgetsBindingObserver {
  _ResumeObserver(this.onResume);
  final void Function() onResume;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResume();
  }
}

/// The reactions on every chapter of a series with an optimistic [press].
class ChapterReactionsNotifier extends FamilyAsyncNotifier<List<ChapterReactions>, CircleSeriesKey> {
  @override
  Future<List<ChapterReactions>> build(CircleSeriesKey arg) async {
    ref.watch(circleOutboxFlusherProvider);
    return _ok(await ref.watch(circleRepositoryProvider).reactions(sourceId: arg.sourceId, seriesKey: arg.seriesKey));
  }

  ChapterReactions? reactionsOf(String chapterKey) {
    for (final c in state.valueOrNull ?? const <ChapterReactions>[]) {
      if (c.chapterKey == chapterKey) return c;
    }
    return null;
  }

  static ChapterReactions _apply(ChapterReactions base, ReactionKind? next) {
    final counts = {...base.counts};
    final prev = base.mine;
    if (prev != null) counts[prev] = ((counts[prev] ?? 1) - 1).clamp(0, 1 << 30);
    if (next != null) counts[next] = (counts[next] ?? 0) + 1;
    final total = (base.total + (next != null ? 1 : 0) - (prev != null ? 1 : 0)).clamp(0, 1 << 30);
    return base.copyWith(counts: counts, total: total, mine: next, clearMine: next == null);
  }

  /// Press a stamp: sets, moves or clears the viewer's reaction on [chapterKey]. Drawn at once;
  /// rolled back on a server refusal, queued in the outbox on a network failure.
  Future<void> press(String chapterKey, ReactionKind kind, {double? chapterNumber}) async {
    final before = state.valueOrNull ?? const <ChapterReactions>[];
    final cur = reactionsOf(chapterKey) ?? ChapterReactions(chapterKey: chapterKey, chapterNumber: chapterNumber, counts: {for (final k in ReactionKind.values) k: 0}, sealed: false);
    final action = pressReaction(cur.mine, kind);
    final next = action is SetReaction ? action.kind : null;
    final drawn = _apply(cur, next);
    state = AsyncData([for (final c in before) if (c.chapterKey != chapterKey) c, drawn]..sort(_byNumber));
    final repo = ref.read(circleRepositoryProvider);
    final Result<Object?> r;
    if (next == null) {
      r = await repo.unreact(sourceId: arg.sourceId, seriesKey: arg.seriesKey, chapterKey: chapterKey);
    } else {
      final sent = await repo.react(sourceId: arg.sourceId, seriesKey: arg.seriesKey, chapterKey: chapterKey, kind: next);
      if (sent.isOk) {
        state = AsyncData([for (final c in state.valueOrNull ?? const <ChapterReactions>[]) if (c.chapterKey != chapterKey) c, sent.value]..sort(_byNumber));
        return;
      }
      r = Err(sent.error);
    }
    if (r.isOk) return;
    if (_isNetwork(r.error)) {
      await ref.read(reactionOutboxProvider)?.enqueue(OutboxEntry(sourceId: arg.sourceId, seriesKey: arg.seriesKey, chapterKey: chapterKey, kind: next, at: DateTime.now().toUtc()));
      return;
    }
    state = AsyncData(before);
  }

  static int _byNumber(ChapterReactions a, ChapterReactions b) {
    final x = a.chapterNumber, y = b.chapterNumber;
    if (x != null && y != null && x != y) return y.compareTo(x);
    if (x == null && y != null) return 1;
    if (x != null && y == null) return -1;
    return a.chapterKey.compareTo(b.chapterKey);
  }
}

final chapterReactionsProvider = AsyncNotifierProvider.family<ChapterReactionsNotifier, List<ChapterReactions>, CircleSeriesKey>(ChapterReactionsNotifier.new, name: 'chapterReactions');

// ── Letters ─────────────────────────────────────────────────────────────────

class LettersNotifier extends AsyncNotifier<List<Letter>> {
  @override
  Future<List<Letter>> build() async => _ok(await ref.watch(circleRepositoryProvider).letters());

  /// Optimistic; the card is restored (and false returned) when the server refuses.
  Future<bool> patch(int id, LetterState to) async {
    final before = state.valueOrNull;
    if (before == null) return false;
    state = AsyncData([for (final l in before) if (l.id != id) l else if (to != LetterState.dismissed) l.copyWith(state: to)]);
    final r = await ref.read(circleRepositoryProvider).patchLetter(id, to);
    if (r.isErr) {
      state = AsyncData(before);
      return false;
    }
    return true;
  }
}

final lettersProvider = AsyncNotifierProvider<LettersNotifier, List<Letter>>(LettersNotifier.new, name: 'letters');

/// The `new` letters (Index folio, thumb-index badge, LETTERS tab).
final newLetterCountProvider = Provider<int>((ref) => newCount(ref.watch(lettersProvider).valueOrNull ?? const []), name: 'newLetterCount');

// ── Sharing ─────────────────────────────────────────────────────────────────

class SharingNotifier extends FamilyAsyncNotifier<Sharing, int> {
  @override
  Future<Sharing> build(int arg) async => _ok(await ref.watch(circleRepositoryProvider).sharing(arg));

  /// Sends only the changed keys ([sharingPatch]); reverts and returns false on failure.
  Future<bool> patch(Sharing after) async {
    final before = state.valueOrNull;
    if (before == null) return false;
    final body = sharingPatch(before, after);
    if (body.isEmpty) return true;
    state = AsyncData(after);
    final r = await ref.read(circleRepositoryProvider).patchSharing(arg, body);
    if (r.isErr) {
      state = AsyncData(before);
      return false;
    }
    state = AsyncData(r.value);
    if (body.containsKey('activity') || body.containsKey('include_mature') || body.containsKey('excluded_series')) {
      ref.invalidate(circleFeedProvider);
    }
    return true;
  }
}

final sharingProvider = AsyncNotifierProvider.family<SharingNotifier, Sharing, int>(SharingNotifier.new, name: 'sharing');

// ── Actions ─────────────────────────────────────────────────────────────────

class CircleActions {
  CircleActions(this._ref);
  final Ref _ref;

  CircleRepository get _repo => _ref.read(circleRepositoryProvider);

  /// `POST /circle/letters`; on success the sent letters are the recipients' business.
  Future<Object?> sendLetter({required List<int> toProfileIds, required String sourceId, required String seriesKey, String? note}) async {
    final r = await _repo.sendLetter(toProfileIds: toProfileIds, sourceId: sourceId, seriesKey: seriesKey, note: note);
    return r.isErr ? r.error : null;
  }

  /// `DELETE /circle/activity`; true on success.
  Future<bool> clearActivity() async {
    final r = await _repo.clearActivity();
    if (r.isOk) _ref.invalidate(circleFeedProvider);
    return r.isOk;
  }
}

final circleActionsProvider = Provider<CircleActions>(CircleActions.new, name: 'circleActions');
