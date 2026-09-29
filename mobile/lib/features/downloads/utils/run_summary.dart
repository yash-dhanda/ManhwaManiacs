/// How a download run ended, for the summary line.
typedef DownloadRunOutcome = ({
  int requested,
  int saved,
  int alreadySaved,
  int missingPages,
  int failed,
  bool stopped,
  int? freeMb, // set when the run stopped for lack of room
});

String describeRun(DownloadRunOutcome o) {
  if (o.freeMb != null) {
    return 'Out of room: only ${o.freeMb} MB free. Remove some downloads and run it again.';
  }
  if (o.stopped) return 'Stopped: ${o.saved} saved.';
  if (o.saved == 0 && o.failed == 0 && o.missingPages == 0) {
    return 'Nothing to download — those are already saved.';
  }
  if (o.failed == 0 && o.missingPages == 0) {
    return '${o.saved} ${o.saved == 1 ? 'chapter' : 'chapters'} saved.';
  }
  final total = o.saved + o.missingPages + o.failed;
  final parts = [
        '${o.saved} of $total saved',
        if (o.missingPages > 0) '${o.missingPages} with missing pages',
        if (o.failed > 0) '${o.failed} failed',
  ];
  return '${parts.join(', ')}.';
}
