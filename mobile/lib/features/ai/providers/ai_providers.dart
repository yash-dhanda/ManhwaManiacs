import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/ai/models/similar_result.dart';
import 'package:manhwamaniacs/features/ai/providers/suggested_tags_provider.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';

/// `GET /ai/similar` for one query. A failure reads as an unavailable desk with the genre
/// fallback still to come, never an exception on screen.
final similarProvider = FutureProvider.autoDispose.family<SimilarResult, SimilarQuery>((ref, q) async {
  try {
    return await ref.watch(aiRepositoryProvider).similar(q);
  } catch (_) {
    return SimilarResult(available: false, reason: 'failed', basis: q.fallbackGenres ? 'genres' : 'ai');
  }
});

/// A stable id of a card across Picks, Tonight and Quick look: the AniList id, else the source row.
String pickId(WorldItem i) {
  if (i.anilistId > 0) return 'a${i.anilistId}';
  final a = i.available.firstOrNull;
  return a == null ? 't${i.title}' : 's${a.sourceId}:${a.seriesKey}';
}

/// Cards dismissed with Not for me this app session, per profile: gone from Picks and from
/// Tonight's rails until the app restarts. Cleared with the profile-scoped providers.
final dismissedPicksProvider = NotifierProvider<DismissedPicks, Set<String>>(DismissedPicks.new, name: 'dismissedPicks');

class DismissedPicks extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void add(String id) => state = {...state, id};
  void remove(String id) => state = {...state}..remove(id);

  /// Undo: the card may show again.
  void restore(String id) => remove(id);
}

/// `POST /ai/feedback` behind Not for me, More like this and rejected tags.
class AiFeedback {
  AiFeedback(this._ref);
  final Ref _ref;

  Future<bool> _send(String signal, {int? anilistId, String? sourceId, String? seriesKey, String? tag}) async {
    final r = await _ref.read(aiRepositoryProvider).sendFeedback(signal: signal, anilistId: anilistId, sourceId: sourceId, seriesKey: seriesKey, tag: tag);
    return r is Ok;
  }

  /// Tells the server [i] is not for this reader and, unless [hide] is false (the card is still
  /// fading out), hides it for the session.
  Future<bool> notInterested(WorldItem i, {bool hide = true}) {
    if (hide) _ref.read(dismissedPicksProvider.notifier).add(pickId(i));
    final a = i.available.firstOrNull;
    return i.anilistId > 0 ? _send('not_interested', anilistId: i.anilistId) : _send('not_interested', sourceId: a?.sourceId, seriesKey: a?.seriesKey);
  }

  Future<bool> likedPick(WorldItem i) {
    final a = i.available.firstOrNull;
    return i.anilistId > 0 ? _send('liked_pick', anilistId: i.anilistId) : _send('liked_pick', sourceId: a?.sourceId, seriesKey: a?.seriesKey);
  }

  /// Takes back a `not_interested` (the Undo of the toast) and shows the card again.
  Future<bool> undoNotInterested(WorldItem i) {
    _ref.read(dismissedPicksProvider.notifier).restore(pickId(i));
    final a = i.available.firstOrNull;
    return i.anilistId > 0 ? _send('undo', anilistId: i.anilistId) : _send('undo', sourceId: a?.sourceId, seriesKey: a?.seriesKey);
  }

  /// `signal: clear`: forget every Not interested of this profile.
  Future<bool> clearAll() => _send('clear');

  Future<bool> tagRejected(String sourceId, String seriesKey, String tag) => _send('tag_rejected', sourceId: sourceId, seriesKey: seriesKey, tag: tag);
}

final aiFeedbackProvider = Provider<AiFeedback>(AiFeedback.new, name: 'aiFeedback');
