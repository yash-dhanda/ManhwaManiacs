import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_identity.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';

/// The 8 s window a removed chapter can still be brought back in.
const Duration kRemovalUndoWindow = Duration(milliseconds: 8000);

/// The handle [PendingRemovals.schedule] returns.
class PendingRemoval {
  PendingRemoval._(this.key, this._undo);
  final String key;
  final void Function() _undo;

  /// Cancels the removal if it has not run yet.
  void undo() => _undo();
}

typedef TimerFactory = Timer Function(Duration delay, void Function() run);

/// Deferred chapter removal: the row reads `REMOVING…` until the timer runs the deletion, and
/// Undo cancels it. Skin-neutral; `flushAll` runs everything now (app paused or detached), so
/// nothing waits on a timer the OS may never wake.
class PendingRemovals {
  PendingRemovals({TimerFactory? timerFactory}) : _timer = timerFactory ?? Timer.new;

  final TimerFactory _timer;
  final Map<String, _Entry> _entries = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// Fires whenever a removal is scheduled, undone or finished.
  Stream<void> get changes => _changes.stream;

  bool isPending(String key) => _entries.containsKey(key);

  Set<String> get keys => {..._entries.keys};

  /// Schedules [run] after [delay]; a second call for the same [key] replaces the first.
  PendingRemoval schedule(
    String key,
    Future<void> Function() run, {
    Duration delay = kRemovalUndoWindow,
  }) {
    _entries.remove(key)?.timer.cancel();
    late final _Entry entry;
    entry = _Entry(run, _timer(delay, () => unawaited(_fire(key, entry))));
    _entries[key] = entry;
    _changes.add(null);
    return PendingRemoval._(key, () {
      if (!identical(_entries[key], entry)) return;
      entry.timer.cancel();
      _entries.remove(key);
      _changes.add(null);
    });
  }

  Future<void> _fire(String key, _Entry entry) async {
    if (!identical(_entries[key], entry)) return;
    _entries.remove(key);
    _changes.add(null);
    await entry.run();
  }

  /// Runs every pending removal at once.
  Future<void> flushAll() async {
    final all = _entries.entries.toList();
    for (final e in all) {
      e.value.timer.cancel();
    }
    _entries.clear();
    if (all.isNotEmpty) _changes.add(null);
    for (final e in all) {
      await e.value.run();
    }
  }

  void dispose() {
    for (final e in _entries.values) {
      e.timer.cancel();
    }
    _entries.clear();
    unawaited(_changes.close());
  }
}

class _Entry {
  _Entry(this.run, this.timer);
  final Future<void> Function() run;
  final Timer timer;
}

/// The key a chapter's pending removal is filed under.
String pendingRemovalKey(ChapterIdentity id) => '${id.sourceId}|${id.seriesKey}|${id.chapterKey}';

/// Kept alive for the whole session so a removal outlives the screen that scheduled it.
final pendingRemovalsProvider = Provider<PendingRemovals>((ref) {
  final p = PendingRemovals();
  ref.onDispose(p.dispose);
  return p;
}, name: 'pendingRemovals',);

/// Rebuilds its watchers whenever the pending set changes; the rows read `REMOVING…` from it.
final pendingRemovalKeysProvider = StreamProvider<Set<String>>((ref) async* {
  final p = ref.watch(pendingRemovalsProvider);
  yield p.keys;
  await for (final _ in p.changes) {
    yield p.keys;
  }
}, name: 'pendingRemovalKeys',);

/// Removes [id]'s bytes now: the deletion `PendingRemovals` runs on expiry.
Future<void> deleteSavedChapter(Ref ref, ChapterIdentity id) async {
  await ref.read(downloadsStoreProvider)?.deleteDownload(id);
}
