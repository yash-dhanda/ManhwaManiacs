/// Short relative and clock labels the status screens print in folio type.
String _two(int n) => n.toString().padLeft(2, '0');

/// `21:04` in local time.
String clockLabel(DateTime t) {
  final l = t.toLocal();
  return '${_two(l.hour)}:${_two(l.minute)}';
}

String _span(Duration d) {
  final m = d.inMinutes;
  if (m < 1) return 'NOW';
  if (m < 60) return '$m MIN';
  if (d.inHours < 48) return '${d.inHours} H';
  return '${d.inDays} D';
}

/// `12 MIN AGO`, `JUST NOW`.
String agoLabel(DateTime at, DateTime now) {
  final d = now.difference(at);
  if (d.inMinutes < 1) return 'JUST NOW';
  return '${_span(d)} AGO';
}

/// `IN 18 MIN`, `DUE NOW` once it has passed.
String inLabel(DateTime at, DateTime now) {
  final d = at.difference(now);
  if (d.inMinutes < 1) return 'DUE NOW';
  return 'IN ${_span(d)}';
}

/// `30 MIN`, `2 H`, `1 D` for a check interval given in minutes.
String intervalLabel(int minutes) {
  if (minutes >= 1440 && minutes % 1440 == 0) return '${minutes ~/ 1440} D';
  if (minutes >= 60 && minutes % 60 == 0) return '${minutes ~/ 60} H';
  return '$minutes MIN';
}

/// `212 SERIES · 3 NEW`.
String runCountsLabel(int series, int fresh) => '$series SERIES · $fresh NEW';
