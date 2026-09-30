/// Why the 12 s auto-continue countdown is paused.
enum PauseReason { pointerContinue, pointerText, pointerCast, touch, focusText, focusCast, hidden, space, key }

const int kRecapCountdownMs = 12000;

class CountdownState {
  const CountdownState({this.remainingMs = kRecapCountdownMs, this.started = false, this.pausedBy = const {}});
  final int remainingMs;
  final bool started;
  final Set<PauseReason> pausedBy;

  bool get running => started && pausedBy.isEmpty && remainingMs > 0;
  bool get finished => started && remainingMs <= 0;

  /// The whole second shown in the folio (`CH 143 · 12 S`).
  int get seconds => (remainingMs / 1000).ceil();

  CountdownState _with({int? ms, bool? started, Set<PauseReason>? by}) =>
      CountdownState(remainingMs: ms ?? remainingMs, started: started ?? this.started, pausedBy: by ?? pausedBy);
}

/// The reducer: `start`, `tick(ms)`, `pause`, `resume`, `reset` (scrolling back up) and
/// `toggleSpace`. `space` is the only reason `toggleSpace` clears, and `key` stays until Space
/// resumes.
class RecapCountdown {
  const RecapCountdown._();

  static CountdownState start(CountdownState s) => s.started ? s : s._with(started: true);

  static CountdownState tick(CountdownState s, int ms) =>
      s.running ? s._with(ms: (s.remainingMs - ms).clamp(0, kRecapCountdownMs)) : s;

  static CountdownState pause(CountdownState s, PauseReason r) => s._with(by: {...s.pausedBy, r});

  static CountdownState resume(CountdownState s, PauseReason r) => s._with(by: {...s.pausedBy}..remove(r));

  static CountdownState reset(CountdownState s) => s._with(ms: kRecapCountdownMs);

  /// Space pauses, or resumes: it clears `space` and a lingering `key` pause.
  static CountdownState toggleSpace(CountdownState s) {
    if (s.pausedBy.contains(PauseReason.space) || s.pausedBy.contains(PauseReason.key)) {
      return s._with(by: {...s.pausedBy}..removeAll({PauseReason.space, PauseReason.key}));
    }
    return pause(s, PauseReason.space);
  }
}
