/// The Audiobook sheet's toasts (glass 8.16.5, B7).
library;

const String kNothingToNarrate = 'Nothing to narrate.';

const List<(String, String)> _reasons = [
  ('already_rendered', 'already narrated'),
  ('chapter_not_cached', 'not on the server yet'),
  ('chapter_unreadable', "couldn't be read"),
  ('already_queued', 'already waiting'),
];

/// "Queued 5 chapters for narration. Skipped: 2 already narrated, 1 not on the server yet." ([skipped] maps chapter key to reason code.)
String queuedToast({required int queued, required Map<String, String> skipped}) {
  if (queued <= 0) return kNothingToNarrate;
  final head = 'Queued $queued ${queued == 1 ? 'chapter' : 'chapters'} for narration.';
  final counts = <String, int>{};
  for (final r in skipped.values) {
    counts[r] = (counts[r] ?? 0) + 1;
  }
  final parts = <String>[
    for (final (code, text) in _reasons)
      if ((counts[code] ?? 0) > 0) '${counts[code]} $text',
    for (final e in counts.entries)
      if (!_reasons.any((r) => r.$1 == e.key)) '${e.value} were skipped',
  ];
  return parts.isEmpty ? head : '$head Skipped: ${parts.join(', ')}.';
}

/// "Saving the audio of 5 chapters to this device."
String savingToast(int n) => 'Saving the audio of $n ${n == 1 ? 'chapter' : 'chapters'} to this device.';
