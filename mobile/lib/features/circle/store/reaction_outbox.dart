import 'dart:convert';

import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/repositories/circle_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One queued reaction: a [kind] to set, or null to clear.
class OutboxEntry {
  const OutboxEntry({required this.sourceId, required this.seriesKey, required this.chapterKey, required this.kind, required this.at, this.mature = false});
  final String sourceId, seriesKey, chapterKey;
  final ReactionKind? kind;
  final DateTime at;

  /// The chapter belongs to an 18+ series: the gate-close purge drops it (glass 8.0.8 step 5).
  final bool mature;

  String get chapter => '$sourceId:$seriesKey:$chapterKey';

  Map<String, Object?> toJson() => {'source_id': sourceId, 'series_key': seriesKey, 'chapter_key': chapterKey, 'kind': kind?.wire, 'at': at.toUtc().toIso8601String(), if (mature) 'mature': true};

  static OutboxEntry? tryParse(Object? o) {
    if (o is! Map) return null;
    final s = o['source_id'], k = o['series_key'], c = o['chapter_key'];
    if (s is! String || k is! String || c is! String) return null;
    return OutboxEntry(sourceId: s, seriesKey: k, chapterKey: c, kind: ReactionKind.tryParse(o['kind']), at: DateTime.tryParse('${o['at']}') ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true), mature: o['mature'] == true);
  }
}

/// Offline reactions (cinematic 9.3.3: "queued and sent on reconnect, drawn immediately"), kept in
/// SharedPreferences per (user, profile). The last write per chapter wins.
class ReactionOutbox {
  ReactionOutbox(this._prefs, this.scopeId);
  final SharedPreferences _prefs;

  /// `u{user}p{profile}` (the downloads scope id).
  final String scopeId;

  String get key => 'mm.circle.reaction-outbox.$scopeId';

  List<OutboxEntry> entries() {
    try {
      final raw = _prefs.getString(key);
      if (raw == null) return const [];
      return [for (final e in jsonDecode(raw) as List) if (OutboxEntry.tryParse(e) != null) OutboxEntry.tryParse(e)!];
    } catch (_) {
      return const [];
    }
  }

  Future<void> _save(List<OutboxEntry> list) => list.isEmpty ? _prefs.remove(key) : _prefs.setString(key, jsonEncode([for (final e in list) e.toJson()]));

  /// Queue [e], replacing an earlier entry for the same chapter.
  Future<void> enqueue(OutboxEntry e) => _save([...entries().where((x) => x.chapter != e.chapter), e]);

  /// Drops every queued reaction on an 18+ series (the gate closed).
  Future<void> dropMature() => _save([...entries().where((e) => !e.mature)]);

  /// The queued kind for a chapter: `(true, kind)` when queued (kind null = clear).
  (bool, ReactionKind?) pending(String sourceId, String seriesKey, String chapterKey) {
    for (final e in entries()) {
      if (e.chapter == '$sourceId:$seriesKey:$chapterKey') return (true, e.kind);
    }
    return (false, null);
  }

  /// Send every entry oldest first; an entry that fails with a network error stays (and stops the
  /// run), any other failure drops it. Returns how many were sent.
  Future<int> flush(CircleRepository repo, {bool Function(Object error)? isNetwork}) async {
    final list = [...entries()]..sort((a, b) => a.at.compareTo(b.at));
    var sent = 0;
    for (final e in list) {
      final r = e.kind == null
          ? await repo.unreact(sourceId: e.sourceId, seriesKey: e.seriesKey, chapterKey: e.chapterKey)
          : await repo.react(sourceId: e.sourceId, seriesKey: e.seriesKey, chapterKey: e.chapterKey, kind: e.kind!);
      if (r.isErr && (isNetwork?.call(r.error) ?? false)) break;
      await _save([...entries().where((x) => x.chapter != e.chapter || x.at != e.at)]);
      if (r.isOk) sent++;
    }
    return sent;
  }
}
