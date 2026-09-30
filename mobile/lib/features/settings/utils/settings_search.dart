import 'package:manhwamaniacs/core/utils/text_fold.dart';

/// One searchable row of Settings: the section it lives in, its label and the words people type
/// for it.
class SettingsRowRef {
  const SettingsRowRef({required this.id, required this.section, required this.label, this.keywords = const []});

  final String id, section, label;
  final List<String> keywords;
}

String _norm(String s) => foldDiacritics(s).toLowerCase().trim();

/// At most [limit] rows for [query]: label-prefix matches first, then label substrings, then
/// keyword matches; case and diacritics do not matter. An empty query matches nothing.
List<SettingsRowRef> matchSettings(String query, List<SettingsRowRef> rows, {int limit = 12}) {
  final q = _norm(query);
  if (q.isEmpty) return const [];
  final prefix = <SettingsRowRef>[], substring = <SettingsRowRef>[], keyword = <SettingsRowRef>[];
  for (final r in rows) {
    final label = _norm(r.label);
    if (label.startsWith(q)) {
      prefix.add(r);
    } else if (label.contains(q)) {
      substring.add(r);
    } else if (r.keywords.any((k) => _norm(k).contains(q))) {
      keyword.add(r);
    }
  }
  return [...prefix, ...substring, ...keyword].take(limit).toList();
}
