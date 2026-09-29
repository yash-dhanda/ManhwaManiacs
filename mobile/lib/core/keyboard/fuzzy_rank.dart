class RankedItem<T> {
  const RankedItem(this.item, this.score, this.matches);
  final T item;
  final int score;

  /// Indices into the label of the matched characters, for highlighting.
  final List<int> matches;
}

bool _wordStart(String s, int i) => i == 0 || !RegExp('[a-z0-9]', caseSensitive: false).hasMatch(s[i - 1]);

/// Case-insensitive subsequence match. +3 per character that directly follows the previous match,
/// +2 per match at a word start, minus the index of the first match. Ties keep input order.
/// An empty query keeps every item in order.
List<RankedItem<T>> rankItems<T>(String query, List<T> items, String Function(T) label, {int limit = 40}) {
  final q = query.trim().toLowerCase();
  final out = <RankedItem<T>>[];
  for (final item in items) {
    final text = label(item);
    if (q.isEmpty) {
      out.add(RankedItem(item, 0, const []));
      continue;
    }
    final lower = text.toLowerCase();
    final at = <int>[];
    var from = 0;
    for (var k = 0; k < q.length; k++) {
      final i = lower.indexOf(q[k], from);
      if (i < 0) {
        at.clear();
        break;
      }
      at.add(i);
      from = i + 1;
    }
    if (at.isEmpty) continue;
    var score = -at.first;
    for (var k = 0; k < at.length; k++) {
      if (k > 0 && at[k] == at[k - 1] + 1) score += 3;
      if (_wordStart(text, at[k])) score += 2;
    }
    out.add(RankedItem(item, score, at));
  }
  // List.sort is not stable: index breaks ties.
  final order = {for (var i = 0; i < out.length; i++) out[i]: i};
  out.sort((a, b) {
    final d = b.score.compareTo(a.score);
    return d != 0 ? d : order[a]!.compareTo(order[b]!);
  });
  return out.length > limit ? out.sublist(0, limit) : out;
}
