/// Listen sessions (cinematic 9.2.7): a contiguous stretch of playback of one chapter.
///
/// A session closes on a pause lasting 30 s, on a chapter change, on leaving the reader and when
/// the app is detached. `seconds` is wall-clock PLAYING time, not audio time, so a 2x listen does
/// not double it. Sessions under 10 s are dropped (`backend/03` rejects them). `voice_ids` are the
/// up to 3 voices with the most played time.
///
/// Pure: the controller feeds it play, pause and segment events, with an injected clock and timer
/// so a test drives a whole evening in microseconds.
library;

import 'dart:async';

/// A session that ended, ready for the outbox.
class ClosedListenSession {
  const ClosedListenSession({
    required this.sourceId,
    required this.seriesKey,
    required this.chapterKey,
    required this.seconds,
    required this.voiceIds,
    required this.startedAt,
  });

  final String sourceId, seriesKey, chapterKey;
  final int seconds;
  final List<String> voiceIds;

  /// UTC.
  final DateTime startedAt;

  /// The `POST /novels/listen-sessions` item.
  Map<String, Object?> toJson() => {
        'source_id': sourceId,
        'series_key': seriesKey,
        'chapter_key': chapterKey,
        'seconds': seconds,
        'voice_ids': voiceIds,
        'started_at': startedAt.toUtc().toIso8601String(),
      };
}

/// The floor the backend enforces.
const int kMinListenSessionSeconds = 10;

/// A pause this long ends the session.
const Duration kListenPauseClose = Duration(seconds: 30);

class ListenSessionTracker {
  ListenSessionTracker({
    required this.onClosed,
    DateTime Function()? now,
    Timer Function(Duration, void Function())? timer,
  })  : _now = now ?? DateTime.now,
        _timer = timer ?? Timer.new;

  final void Function(ClosedListenSession) onClosed;
  final DateTime Function() _now;
  final Timer Function(Duration, void Function()) _timer;

  ({String sourceId, String seriesKey, String chapterKey})? _chapter;
  DateTime? _startedAt;
  DateTime? _playingSince;
  int _playingMs = 0;
  String? _voice;
  DateTime? _voiceSince;
  final Map<String, int> _voiceMs = {};
  Timer? _pauseTimer;

  bool get open => _startedAt != null;

  /// Playback of [chapter] started or resumed. A different chapter than the open session's closes
  /// it first.
  void play(({String sourceId, String seriesKey, String chapterKey}) chapter, {String? voice}) {
    if (_chapter != null && _chapter != chapter) close();
    _pauseTimer?.cancel();
    _pauseTimer = null;
    final now = _now();
    _chapter = chapter;
    _startedAt ??= now.toUtc();
    _playingSince ??= now;
    _voice = voice;
    _voiceSince = voice == null ? null : now;
  }

  /// The active segment's voice changed while playing.
  void voiceChanged(String? voice) {
    if (_playingSince == null || voice == _voice) return;
    _flushVoice();
    _voice = voice;
    _voiceSince = voice == null ? null : _now();
  }

  /// Playback paused: the session stays open for [kListenPauseClose], then closes.
  void pause() {
    if (_startedAt == null || _playingSince == null) return;
    _accumulate();
    _pauseTimer?.cancel();
    _pauseTimer = _timer(kListenPauseClose, close);
  }

  /// The chapter changed under the player, the reader closed, or the app detached.
  void close() {
    _pauseTimer?.cancel();
    _pauseTimer = null;
    final chapter = _chapter, started = _startedAt;
    if (chapter == null || started == null) {
      _reset();
      return;
    }
    if (_playingSince != null) _accumulate();
    final seconds = (_playingMs / 1000).round();
    final voices = (_voiceMs.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(3).map((e) => e.key).toList();
    _reset();
    if (seconds < kMinListenSessionSeconds) return;
    onClosed(
      ClosedListenSession(
        sourceId: chapter.sourceId,
        seriesKey: chapter.seriesKey,
        chapterKey: chapter.chapterKey,
        seconds: seconds,
        voiceIds: voices,
        startedAt: started,
      ),
    );
  }

  void _accumulate() {
    final since = _playingSince;
    if (since == null) return;
    _playingMs += _now().difference(since).inMilliseconds;
    _playingSince = null;
    _flushVoice();
    _voiceSince = null;
  }

  void _flushVoice() {
    final voice = _voice, since = _voiceSince;
    if (voice == null || since == null) return;
    _voiceMs[voice] = (_voiceMs[voice] ?? 0) + _now().difference(since).inMilliseconds;
    _voiceSince = _now();
  }

  void _reset() {
    _chapter = null;
    _startedAt = null;
    _playingSince = null;
    _playingMs = 0;
    _voice = null;
    _voiceSince = null;
    _voiceMs.clear();
  }

  void dispose() {
    _pauseTimer?.cancel();
  }
}
