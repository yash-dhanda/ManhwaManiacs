// The chapter-row meta strings (glass 7.17). Pure, so the calendar rules are unit tests.

/// "Today", "Yesterday", "3 d ago" (2 to 6 days), "12 Sep" (older), "12 Sep 2025" (another year).
/// Days are calendar days in the reader's own zone, never elapsed hours.
String chapterDateLabel(DateTime date, DateTime now) {
  final a = date.toLocal();
  final b = now.toLocal();
  final days = DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
  if (days <= 0) return 'Today';
  if (days == 1) return 'Yesterday';
  if (days < 7) return '$days d ago';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final base = '${a.day} ${months[a.month - 1]}';
  return a.year == b.year ? base : '$base ${a.year}';
}

/// "12", "12.5", and a middle dot when the source gives no number.
String chapterNumberLabel(double? n) {
  if (n == null) return '·';
  return n == n.roundToDouble() ? n.round().toString() : n.toString();
}
