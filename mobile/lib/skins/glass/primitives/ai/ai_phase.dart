import 'dart:async';

import 'package:flutter/foundation.dart';

/// What the AI is doing, for the honest phase lines (glass 9.1.5): picks (For you, More like this) or a recap.
enum AiPhaseKind { picks, recap }

/// A request is abandoned after this long (glass 9.1.5).
const Duration kAiAbandonAfter = Duration(seconds: 40);

/// The timer-driven lines when the server sends no `phase`: `(seconds, line)` per kind.
const Map<AiPhaseKind, List<(double, String)>> kAiPhaseTimeline = {
  AiPhaseKind.picks: [
    (0, 'Reading your library'),
    (1.5, 'Asking for ideas'),
    (4, 'Checking which of your sources have them'),
    (15, 'Still working. This can take up to a minute.'),
  ],
  AiPhaseKind.recap: [(0, 'Writing your recap')],
};

const String kAiTooLongLine = 'That took too long. Try again.';

/// The current phase line of a running AI request. The server's SSE `phase` wins while present; otherwise the timers of
/// [kAiPhaseTimeline] step through the lines. After 40 s it is [abandoned] and the line reads [kAiTooLongLine].
class AiPhaseClock extends ChangeNotifier {
  AiPhaseClock({required bool active, this.serverPhase, required this.kind}) {
    if (active) start();
  }

  final AiPhaseKind kind;
  String? serverPhase;
  String _line = '';
  bool _abandoned = false;
  bool _active = false;
  final List<Timer> _timers = [];

  String get line => _abandoned ? kAiTooLongLine : (serverPhase ?? _line);
  bool get abandoned => _abandoned;
  bool get active => _active;

  void start() {
    stop();
    _active = true;
    _abandoned = false;
    _line = kAiPhaseTimeline[kind]!.first.$2;
    for (final (s, text) in kAiPhaseTimeline[kind]!.skip(1)) {
      _timers.add(Timer(Duration(milliseconds: (s * 1000).round()), () {
        _line = text;
        notifyListeners();
      }),);
    }
    _timers.add(Timer(kAiAbandonAfter, () {
      _abandoned = true;
      _active = false;
      notifyListeners();
    }),);
    notifyListeners();
  }

  /// A phase from the stream; null goes back to the timers.
  void setServerPhase(String? phase) {
    if (serverPhase == phase) return;
    serverPhase = phase;
    notifyListeners();
  }

  void stop() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    _active = false;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
