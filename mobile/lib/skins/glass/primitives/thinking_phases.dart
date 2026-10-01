/// The honest phase lines of an AI request that reports no phases (glass 7.38): on timers, abandoned at 40 s.
const List<(Duration, String)> kThinkingPhases = [
  (Duration.zero, 'Reading your library'),
  (Duration(milliseconds: 1500), 'Asking for ideas'),
  (Duration(seconds: 4), 'Checking which of your sources have them'),
  (Duration(seconds: 15), 'Still working. This can take up to a minute.'),
];

const Duration kThinkingAbandon = Duration(seconds: 40);

String? phaseLineAt(Duration elapsed) {
  String? line;
  for (final (at, text) in kThinkingPhases) {
    if (elapsed >= at) line = text;
  }
  return line;
}

bool abandoned(Duration elapsed) => elapsed >= kThinkingAbandon;
