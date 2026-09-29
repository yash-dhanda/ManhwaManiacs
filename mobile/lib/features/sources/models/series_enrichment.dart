/// `GET /series/enrichment`: `{anilist_id, format, score, official}`.
class SeriesEnrichment {
  const SeriesEnrichment({
    required this.anilistId,
    this.format,
    this.score,
    this.official = const [],
  });

  final int anilistId;
  final String? format;

  /// AniList's mean score on a 0-10 scale (the server already divided by 10).
  final double? score;
  final List<({String site, String url})> official;

  factory SeriesEnrichment.fromJson(Map<String, dynamic> json) => SeriesEnrichment(
        anilistId: (json['anilist_id'] as num?)?.toInt() ?? 0,
        format: json['format'] as String?,
        score: (json['score'] as num?)?.toDouble(),
        official: [
          for (final l in (json['official'] as List<dynamic>? ?? const []))
            if (l is Map && l['url'] is String)
              (site: (l['site'] as String?) ?? 'Official', url: l['url'] as String),
        ],
      );
}
