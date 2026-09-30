/// The `shareable` block of `GET /library/statistics` and `GET /library/annual`
/// (cinematic 9.2.5): only non-mature series, whatever the 18+ gate says. A
/// share card may draw nothing else.
class SeriesAmbient {
  const SeriesAmbient({required this.duo, required this.tint, required this.ink});

  /// Duotone highlight, `#RRGGBB`.
  final String duo;
  final String tint;
  final String ink;

  static SeriesAmbient? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final duo = raw['duo'];
    final tint = raw['tint'];
    final ink = raw['ink'];
    if (duo is! String || tint is! String) return null;
    return SeriesAmbient(duo: duo, tint: tint, ink: ink is String ? ink : '#F3F0E8');
  }
}

class GenreWeight {
  const GenreWeight({required this.genre, required this.weight});
  final String genre;

  /// Share of reading seconds, 0..1.
  final double weight;

  factory GenreWeight.fromJson(Map<String, dynamic> json) => GenreWeight(
        genre: (json['genre'] as String? ?? '').trim(),
        weight: (json['weight'] as num?)?.toDouble() ?? 0,
      );
}

class ShareSeries {
  const ShareSeries({
    required this.sourceId,
    required this.seriesKey,
    required this.title,
    this.coverUrl,
    this.ambient,
    this.secondsRead = 0,
    this.chaptersRead = 0,
  });

  final String sourceId;
  final String seriesKey;
  final String title;
  final String? coverUrl;
  final SeriesAmbient? ambient;
  final int secondsRead;
  final int chaptersRead;

  factory ShareSeries.fromJson(Map<String, dynamic> json) => ShareSeries(
        sourceId: json['source_id'] as String? ?? '',
        seriesKey: json['series_key'] as String? ?? '',
        title: (json['title'] as String? ?? '').trim(),
        coverUrl: _nonEmpty(json['cover_url']),
        ambient: SeriesAmbient.tryParse(json['ambient']),
        secondsRead: (json['seconds_read'] as num?)?.toInt() ?? 0,
        chaptersRead: (json['chapters_read'] as num?)?.toInt() ?? 0,
      );
}

class ArtSeries {
  const ArtSeries({
    required this.sourceId,
    required this.seriesKey,
    required this.coverUrl,
    this.ambient,
  });

  final String sourceId;
  final String seriesKey;
  final String coverUrl;
  final SeriesAmbient? ambient;

  static ArtSeries? tryParse(Map<String, dynamic> json) {
    final cover = _nonEmpty(json['cover_url']);
    if (cover == null) return null;
    return ArtSeries(
      sourceId: json['source_id'] as String? ?? '',
      seriesKey: json['series_key'] as String? ?? '',
      coverUrl: cover,
      ambient: SeriesAmbient.tryParse(json['ambient']),
    );
  }
}

class Shareable {
  const Shareable({
    this.genreWeights = const [],
    this.topSeries = const [],
    this.artSeries = const [],
  });

  final List<GenreWeight> genreWeights;
  final List<ShareSeries> topSeries;
  final List<ArtSeries> artSeries;

  factory Shareable.fromJson(Map<String, dynamic> json) => Shareable(
        genreWeights: _maps(json['genre_weights']).map(GenreWeight.fromJson).where((g) => g.genre.isNotEmpty).toList(growable: false),
        topSeries: _maps(json['top_series']).map(ShareSeries.fromJson).where((s) => s.title.isNotEmpty).toList(growable: false),
        artSeries: _maps(json['art_series']).map(ArtSeries.tryParse).whereType<ArtSeries>().toList(growable: false),
      );

  static Shareable? tryParse(Object? raw) => raw is Map<String, dynamic> ? Shareable.fromJson(raw) : null;
}

String? _nonEmpty(Object? v) => v is String && v.trim().isNotEmpty ? v.trim() : null;

Iterable<Map<String, dynamic>> _maps(Object? raw) => raw is List ? raw.whereType<Map<String, dynamic>>() : const [];
