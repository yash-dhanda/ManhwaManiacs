/// "2h ago", not "Sep 20, 2026 3:42 PM".
///
/// History answers "where was I", and an absolute timestamp makes the reader
/// do the subtraction. Past a week the date is genuinely more useful than
/// "37 days ago", so it switches.
String relativeReadTime(DateTime when, {DateTime? now}) {
  final gap = (now ?? DateTime.now()).difference(when);
  if (gap.isNegative) return 'just now';
  if (gap.inMinutes < 1) return 'just now';
  if (gap.inMinutes < 60) return '${gap.inMinutes}m ago';
  if (gap.inHours < 24) return '${gap.inHours}h ago';
  if (gap.inDays < 7) return '${gap.inDays}d ago';
  if (gap.inDays < 365) return '${(gap.inDays / 7).floor()}w ago';
  return '${(gap.inDays / 365).floor()}y ago';
}
