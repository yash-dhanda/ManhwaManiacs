import 'package:manhwamaniacs/features/sources/models/source_genre.dart';
import 'package:manhwamaniacs/features/sources/models/source_pin.dart';

class GenreEntry {
  const GenreEntry({
    required this.genre,
    required this.label,
    required this.sourceIds,
    this.idsBySource = const {},
  });

  /// Case-folded merge key.
  final String genre;

  /// First spelling seen.
  final String label;
  final List<String> sourceIds;

  /// Each source's own id for this genre (what its browse endpoint takes).
  final Map<String, String> idsBySource;

  /// The genre id to send to [sourceId]; the label when it is unknown.
  String idFor(String sourceId) => idsBySource[sourceId] ?? label;
}

/// Union of the pinned sources' genres, merged case-insensitively, ordered by
/// weight (highest first); ties and unweighted genres alphabetical.
List<GenreEntry> buildGenreIndex(
  List<SourcePin> pinned,
  Map<String, List<SourceGenre>> genresBySource,
  List<GenreWeight> weights,
) {
  final labels = <String, String>{};
  final ids = <String, List<String>>{};
  final genreIds = <String, Map<String, String>>{};
  for (final pin in pinned) {
    for (final g in genresBySource[pin.sourceId] ?? const <SourceGenre>[]) {
      final key = g.label.trim().toLowerCase();
      if (key.isEmpty) continue;
      labels.putIfAbsent(key, g.label.trim);
      final list = ids.putIfAbsent(key, () => []);
      if (!list.contains(pin.sourceId)) list.add(pin.sourceId);
      genreIds.putIfAbsent(key, () => {}).putIfAbsent(pin.sourceId, () => g.id);
    }
  }
  final w = <String, double>{};
  for (final e in weights) {
    final k = e.genre.trim().toLowerCase();
    if (!w.containsKey(k) || e.weight > w[k]!) w[k] = e.weight;
  }
  final keys = labels.keys.toList()
    ..sort((a, b) {
      final c = (w[b] ?? 0).compareTo(w[a] ?? 0);
      return c != 0 ? c : a.compareTo(b);
    });
  return [
    for (final k in keys)
      GenreEntry(
        genre: k,
        label: labels[k]!,
        sourceIds: ids[k]!,
        idsBySource: genreIds[k]!,
      ),
  ];
}
