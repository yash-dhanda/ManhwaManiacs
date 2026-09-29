/// The sentence the Move-to-another-source sheet shows once a candidate is
/// picked: reading position moves by chapter NUMBER, never by key.
String mappingSentence({
  required double? currentNumber,
  required ({double from, double to})? candidateRange,
  required String sourceName,
}) {
  String n(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  final r = candidateRange;
  final c = currentNumber;
  if (c == null || r == null || c < r.from || c > r.to) {
    return "Chapter numbers don't line up, so you'll start at chapter 1 on $sourceName.";
  }
  return "Your place moves by chapter number. You're on chapter ${n(c)}; "
      '$sourceName has chapters ${n(r.from)}–${n(r.to)}, so chapter ${n(c)} '
      'there becomes your place.';
}
