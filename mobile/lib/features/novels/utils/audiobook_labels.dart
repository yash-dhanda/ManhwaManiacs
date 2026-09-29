/// The audiobook button's words.
///
/// "In progress" only for a job a render box is actually working on. A job
/// that is merely queued is WAITING — with no worker free it can sit there a
/// long time — and with no worker configured at all there is no job to talk
/// about, because nothing will ever move, nor any "make" to offer.
String audiobookButtonLabel({
  required bool canRender,
  required int running,
  required int waiting,
  required int rendered,
}) {
  if (!canRender) {
    return rendered == 0
        ? 'Make audiobook'
        : 'Audiobook · $rendered narrated';
  }
  if (running > 0) {
    return waiting > 0
        ? 'Making audiobook · $running in progress, $waiting waiting'
        : 'Making audiobook · $running in progress';
  }
  if (waiting > 0) {
    return 'Make audiobook · $waiting waiting for the narration PC';
  }
  return rendered == 0 ? 'Make audiobook' : 'Make audiobook · $rendered done';
}

/// "Skipped: 2 already asked for, 1 not downloaded to the server yet." — the
/// reasons, because "N skipped." with none left a reader re-asking for the
/// same chapters to find out why.
String skippedNarrationLine(Map<String, String> skipped) {
  final counts = <String, int>{};
  for (final reason in skipped.values) {
    final text = _skipReasons[reason] ?? 'could not be narrated';
    counts[text] = (counts[text] ?? 0) + 1;
  }
  final parts = [
    for (final entry in counts.entries) '${entry.value} ${entry.key}',
  ];
  return 'Skipped: ${parts.join(', ')}.';
}

/// The server's reason codes (`novel_render_queue.enqueue`), as a reader
/// would say them.
const Map<String, String> _skipReasons = {
  'already_queued': 'already asked for',
  'already_rendered': 'already narrated',
  'chapter_not_cached': 'not downloaded to the server yet',
  'chapter_unreadable': 'could not be read',
};
