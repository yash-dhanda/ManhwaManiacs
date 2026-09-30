import 'package:manhwamaniacs/core/utils/text_fold.dart';

final RegExp _wordRun = RegExp(r'[\p{L}\p{N}]+', unicode: true);

/// The query words: runs of letters and digits of at least 2 characters, lower-cased and diacritics-folded.
List<String> novelTextWords(String q) => [
      for (final m in _wordRun.allMatches(q))
        if (m.group(0)!.length >= 2) foldDiacritics(m.group(0)!).toLowerCase(),
    ];

/// The FTS4 `MATCH` string: every word as a quoted term, joined by spaces (every word must match, in any order). Words hold only
/// letters and digits, so user input can never inject an FTS operator. Null when the query has no usable word.
String? novelTextMatchQuery(String q) {
  final words = novelTextWords(q);
  if (words.isEmpty) return null;
  return [for (final w in words) '"$w"'].join(' ');
}
