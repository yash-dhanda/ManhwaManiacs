/// The honest phase lines of an AI request that reports no phases (glass 7.38): on timers, abandoned with the request's own timeout.
const List<(Duration, String)> kThinkingPhases = [
  (Duration.zero, 'Reading your library'),
  (Duration(milliseconds: 1500), 'Asking for ideas'),
  (Duration(seconds: 4), 'Checking which of your sources have them'),
  (Duration(seconds: 15), 'Still working. This can take up to a minute.'),
];

/// The AI answer routinely takes 40 s or more (the server allows 90 s per model call) and is charged even when the client gives up,
/// so this matches `AskRepository`'s 210 s receive timeout instead of cutting a paid answer off early.
const Duration kThinkingAbandon = Duration(seconds: 210);

String? phaseLineAt(Duration elapsed) {
  String? line;
  for (final (at, text) in kThinkingPhases) {
    if (elapsed >= at) line = text;
  }
  return line;
}

bool abandoned(Duration elapsed) => elapsed >= kThinkingAbandon;
