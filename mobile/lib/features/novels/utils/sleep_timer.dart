/// The Listen sleep timer (cinematic 8.16.6): `Off · 5 · 10 · 15 · 30 · 45 · 60 min · End of
/// chapter · End of next chapter · Custom`, a live remaining time, an 8 s linear fade of the
/// player volume, then pause and restore.
///
/// Pure of widgets and audio: the controller hands in `setVolume`, `pause` and the haptic, and a
/// test drives it with `fakeAsync`. Time is counted in ticks rather than read from a clock, so a
/// fake clock and the real one agree.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

/// What the sleep timer is set to.
enum SleepKind { off, minutes, endOfChapter, endOfNextChapter }

class SleepChoice {
  const SleepChoice(this.kind, [this.minutes = 0]);

  static const off = SleepChoice(SleepKind.off);
  static const endOfChapter = SleepChoice(SleepKind.endOfChapter);
  static const endOfNextChapter = SleepChoice(SleepKind.endOfNextChapter);

  /// The presets, in menu order. Custom is 1-180 minutes.
  static const presets = [5, 10, 15, 30, 45, 60];
  static const minCustom = 1, maxCustom = 180;

  factory SleepChoice.minutes(int m) => SleepChoice(SleepKind.minutes, m.clamp(minCustom, maxCustom));

  /// The stored `sleepDefault` spelling: `off`, `5`..`60`, `chapter`, `nextChapter`.
  factory SleepChoice.parse(String? stored) => switch (stored) {
        'chapter' => endOfChapter,
        'nextChapter' => endOfNextChapter,
        final String s when int.tryParse(s) != null => SleepChoice.minutes(int.parse(s)),
        _ => off,
      };

  final SleepKind kind;
  final int minutes;

  String get label => switch (kind) {
        SleepKind.off => 'Off',
        SleepKind.minutes => '$minutes min',
        SleepKind.endOfChapter => 'End of chapter',
        SleepKind.endOfNextChapter => 'End of next chapter',
      };

  /// The tile's value: `SLEEP END OF CH.`, `SLEEP 15 MIN`, `SLEEP OFF`.
  String get tileLabel => switch (kind) {
        SleepKind.off => 'OFF',
        SleepKind.minutes => '$minutes MIN',
        SleepKind.endOfChapter => 'END OF CH.',
        SleepKind.endOfNextChapter => 'END OF NEXT',
      };

  @override
  bool operator ==(Object other) => other is SleepChoice && other.kind == kind && other.minutes == minutes;

  @override
  int get hashCode => Object.hash(kind, minutes);
}

/// What the timer shows.
class SleepState {
  const SleepState({this.choice = SleepChoice.off, this.remaining, this.fading = false, this.armed = false});

  /// What was chosen (for the tile when there is no countdown).
  final SleepChoice choice;

  /// Time left for a minutes timer; null for `off` and the chapter kinds.
  final Duration? remaining;

  /// In the last 8 s: the volume is ramping down.
  final bool fading;

  /// A timer of any kind is running.
  final bool armed;

  /// Inside the last minute (or the fade): the shake detector listens only then.
  bool get inLastMinute => remaining != null && remaining! <= const Duration(minutes: 1);

  /// `12:04` for a running countdown; null otherwise.
  String? get countdown {
    final r = remaining;
    if (r == null) return null;
    final s = (r.inMilliseconds / 1000).ceil();
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }
}

/// What a chapter's end does to the timer.
enum SleepBoundary {
  /// Carry on as usual (no chapter timer running, or a minutes timer: it ignores boundaries).
  proceed,

  /// Stop here: no post-play card, playback stays paused.
  stop,
}

class SleepTimer {
  SleepTimer({
    required this.setVolume,
    required this.pause,
    required this.onFadeStart,
    this.tick = const Duration(milliseconds: 50),
  });

  /// The last 8 s ramp the volume to 0.
  static const Duration fade = Duration(seconds: 8);

  /// One shake adds this much.
  static const Duration extension = Duration(minutes: 5);

  final void Function(double volume) setVolume;
  final Future<void> Function() pause;
  final VoidCallback onFadeStart;
  final Duration tick;

  final ValueNotifier<SleepState> state = ValueNotifier(const SleepState());
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _fading = false;
  int _shownSecond = -1;
  SleepChoice _choice = SleepChoice.off;
  // How many chapter boundaries the timer still lets pass before it stops.
  int _passes = 0;

  bool get armed => _choice.kind != SleepKind.off;

  void set(SleepChoice choice) {
    _stopTimer();
    if (_fading) setVolume(1);
    _fading = false;
    _choice = choice;
    switch (choice.kind) {
      case SleepKind.off:
        _publish();
      case SleepKind.minutes:
        _remaining = Duration(minutes: choice.minutes);
        _timer = Timer.periodic(tick, _onTick);
        _shownSecond = -1;
        _publish(force: true);
      case SleepKind.endOfChapter:
        _passes = 0;
        _publish();
      case SleepKind.endOfNextChapter:
        _passes = 1;
        _publish();
    }
  }

  void cancel() => set(SleepChoice.off);

  /// A shake: five more minutes. Restores the volume and cancels a fade in progress. A no-op
  /// unless a minutes timer is running.
  bool extend() {
    if (_choice.kind != SleepKind.minutes || _timer == null) return false;
    _remaining += extension;
    if (_fading) {
      _fading = false;
      setVolume(1);
    }
    _publish(force: true);
    return true;
  }

  /// A chapter ended. `End of chapter` stops here; `End of next chapter` lets one boundary pass.
  SleepBoundary onChapterBoundary() {
    switch (_choice.kind) {
      case SleepKind.endOfChapter:
        _choice = SleepChoice.off;
        _publish();
        return SleepBoundary.stop;
      case SleepKind.endOfNextChapter:
        if (_passes > 0) {
          _passes--;
          _choice = SleepChoice.endOfChapter;
          _publish();
          return SleepBoundary.proceed;
        }
        _choice = SleepChoice.off;
        _publish();
        return SleepBoundary.stop;
      case SleepKind.off:
      case SleepKind.minutes:
        return SleepBoundary.proceed;
    }
  }

  void _onTick(Timer _) {
    _remaining -= tick;
    if (_remaining <= Duration.zero) {
      _remaining = Duration.zero;
      _finish();
      return;
    }
    if (_remaining <= fade) {
      if (!_fading) {
        _fading = true;
        onFadeStart();
      }
      setVolume(_remaining.inMicroseconds / fade.inMicroseconds);
    }
    _publish();
  }

  void _finish() {
    _stopTimer();
    _fading = false;
    _choice = SleepChoice.off;
    _publish();
    // Pause first, then restore, so the restored volume is never heard.
    unawaited(pause().whenComplete(() => setVolume(1)));
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _publish({bool force = false}) {
    final second = (_remaining.inMilliseconds / 1000).ceil();
    final running = _timer != null;
    // The folio changes once per second; the fade publishes every tick so `fading` is live.
    if (!force && running && second == _shownSecond && !_fading) return;
    _shownSecond = second;
    state.value = SleepState(
      choice: _choice,
      remaining: running ? _remaining : null,
      fading: _fading,
      armed: _choice.kind != SleepKind.off,
    );
  }

  void dispose() {
    _stopTimer();
    state.dispose();
  }
}
