import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A recommendation on its way out (glass 9.3.4).
class LetterDraft {
  const LetterDraft({required this.toProfileIds, required this.sourceId, required this.seriesKey, required this.mature, this.note});
  final List<int> toProfileIds;
  final String sourceId, seriesKey;
  final bool mature;
  final String? note;

  LetterDraft withNote(String? n) => LetterDraft(toProfileIds: toProfileIds, sourceId: sourceId, seriesKey: seriesKey, mature: mature, note: n);
}

/// A deferred letter: it is sent once, when the Undo window ends, at once with a note, or on [flush]; [undo] cancels it.
class PendingLetter {
  PendingLetter._(this.draft, Duration delay, this._send, this._onDone) {
    _timer = Timer(delay, () => unawaited(_fire(null)));
  }

  final LetterDraft draft;
  final Future<void> Function(LetterDraft) _send;
  final void Function(PendingLetter)? _onDone;
  late final Timer _timer;
  bool _done = false;
  bool _cancelled = false;

  bool get done => _done;
  bool get cancelled => _cancelled;

  void undo() {
    if (_done) return;
    _done = true;
    _cancelled = true;
    _timer.cancel();
    _onDone?.call(this);
  }

  /// Stops the window without sending (the note sheet holds the letter until its Send, or until it closes and flushes).
  void hold() {
    if (!_done) _timer.cancel();
    _held = true;
  }

  bool _held = false;
  bool get held => _held;

  /// Sends now with [note] (the letter-note sheet's Send).
  Future<void> sendWithNote(String note) => _fire(note.trim().isEmpty ? null : note.trim());

  /// Sends now (the app is leaving the foreground).
  Future<void> flush() => _fire(null);

  Future<void> _fire(String? note) async {
    if (_done) return;
    _done = true;
    _timer.cancel();
    _onDone?.call(this);
    await _send(draft.withNote(note));
  }
}

/// Schedules [send] for the end of [delay] (the Undo toast's 10 s window).
PendingLetter scheduleLetter({
  required List<int> toProfileIds,
  required String sourceId,
  required String seriesKey,
  required bool mature,
  Duration delay = const Duration(seconds: 10),
  required Future<void> Function(LetterDraft) send,
  void Function(PendingLetter)? onDone,
}) =>
    PendingLetter._(LetterDraft(toProfileIds: toProfileIds, sourceId: sourceId, seriesKey: seriesKey, mature: mature), delay, send, onDone);

/// Every pending letter of this session. They are flushed when the app is paused or detached (the phone's `pagehide`), and
/// mature ones are dropped by the 18+ purge.
class PendingLetters extends Notifier<List<PendingLetter>> with WidgetsBindingObserver {
  @override
  List<PendingLetter> build() {
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
    ref.onDispose(() {
      try {
        WidgetsBinding.instance.removeObserver(this);
      } catch (_) {}
    });
    return const [];
  }

  PendingLetter schedule({required List<int> toProfileIds, required String sourceId, required String seriesKey, required bool mature, required Future<void> Function(LetterDraft) send, Duration delay = const Duration(seconds: 10)}) {
    final p = scheduleLetter(toProfileIds: toProfileIds, sourceId: sourceId, seriesKey: seriesKey, mature: mature, delay: delay, send: send, onDone: _remove);
    state = [...state, p];
    return p;
  }

  void _remove(PendingLetter p) => state = [for (final x in state) if (!identical(x, p)) x];

  Future<void> flushPendingLetters() async {
    await Future.wait([for (final p in [...state]) p.flush()]);
  }

  /// Cancels every pending letter for an 18+ series.
  void dropMature() {
    for (final p in [...state]) {
      if (p.draft.mature) p.undo();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) unawaited(flushPendingLetters());
  }
}

final pendingLettersProvider = NotifierProvider<PendingLetters, List<PendingLetter>>(PendingLetters.new, name: 'pendingLetters');
