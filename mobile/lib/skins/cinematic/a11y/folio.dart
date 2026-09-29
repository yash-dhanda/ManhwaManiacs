/// The spoken form of a folio (cinematic 7.29). The visual text goes in
/// `ExcludeSemantics`, this string on `Semantics(label:)`.
String folioLabel(String visual, {int? count}) {
  final v = visual.trim();
  final base = _spoken(v);
  return count == null ? base : '$base, $count';
}

String _plural(int n, String one, [String? many]) => n == 1 ? one : (many ?? '${one}s');

String _spoken(String v) {
  var m = RegExp(r'^CH\s*(\d+)\s*·\s*(\d+)\s*%$', caseSensitive: false).firstMatch(v);
  if (m != null) return 'Chapter ${m[1]}, ${m[2]} percent read';
  m = RegExp(r'^CH\s*(\d+)\s*·\s*p\.?\s*(\d+)$', caseSensitive: false).firstMatch(v);
  if (m != null) return 'Chapter ${m[1]}, page ${m[2]}';
  m = RegExp(r'^CH\s*(\d+)\s*OF\s*(\d+)$', caseSensitive: false).firstMatch(v);
  if (m != null) return 'Chapter ${m[1]} of ${m[2]}';
  m = RegExp(r'^NEXT\s*·\s*CH\s*(\d+)$', caseSensitive: false).firstMatch(v);
  if (m != null) return 'Next, chapter ${m[1]}';
  m = RegExp(r'^(\d+)\s*NEW$', caseSensitive: false).firstMatch(v);
  if (m != null) {
    final n = int.parse(m[1]!);
    return '$n new ${_plural(n, 'chapter')}';
  }
  m = RegExp(r'^PAUSED\s+(\d+)\s*D$', caseSensitive: false).firstMatch(v);
  if (m != null) {
    final n = int.parse(m[1]!);
    return 'Paused $n ${_plural(n, 'day')}';
  }
  m = RegExp(r'^(\d+)\s*([HDM])$', caseSensitive: false).firstMatch(v);
  if (m != null) {
    final n = int.parse(m[1]!);
    final unit = switch (m[2]!.toUpperCase()) { 'H' => 'hour', 'D' => 'day', _ => 'minute' };
    return '$n ${_plural(n, unit)} ago';
  }
  m = RegExp(r'^(\d+)\s*MIN$', caseSensitive: false).firstMatch(v);
  if (m != null) {
    final n = int.parse(m[1]!);
    return '$n ${_plural(n, 'minute')}';
  }
  m = RegExp(r'^p\.?\s*(\d+)$', caseSensitive: false).firstMatch(v);
  if (m != null) return 'page ${m[1]}';
  if (v == '18+' || v == '18') return 'Mature, 18 plus';
  if (v.isEmpty) return v;
  // Plain words: sentence case ("READING" -> "Reading").
  final lower = v.toLowerCase();
  return v == v.toUpperCase() ? '${lower[0].toUpperCase()}${lower.substring(1)}' : v;
}
