/// One entry of `GET /sources/{id}/genres`: `{id, label}`.
class SourceGenre {
  const SourceGenre({required this.id, required this.label});

  final String id;
  final String label;

  factory SourceGenre.fromJson(Map<String, dynamic> json) {
    final id = '${json['id'] ?? json['label'] ?? ''}';
    return SourceGenre(id: id, label: (json['label'] as String?) ?? id);
  }
}

/// One `{genre, weight}` of the profile's genre affinity.
class GenreWeight {
  const GenreWeight({required this.genre, required this.weight});

  final String genre;
  final double weight;

  factory GenreWeight.fromJson(Map<String, dynamic> json) => GenreWeight(
        genre: '${json['genre'] ?? ''}',
        weight: (json['weight'] as num?)?.toDouble() ?? 0,
      );
}
