import 'package:manhwamaniacs/features/library/models/world_item.dart';

/// `GET /ai/similar`: `{items, available, reason, basis, generated_at}`. `basis` is `ai`, or
/// `genres` when the items come from the same-genre fallback (`why` is then null).
class SimilarResult {
  const SimilarResult({this.items = const [], this.available = true, this.reason = 'ok', this.basis = 'ai', this.generatedAt});
  final List<WorldItem> items;
  final bool available;
  final String reason, basis;
  final DateTime? generatedAt;

  bool get isGenres => basis == 'genres';

  factory SimilarResult.fromJson(Map<String, dynamic> j) => SimilarResult(
        items: [
          for (final e in (j['items'] as List? ?? const []))
            if (e is Map<String, dynamic>) WorldItem.fromJson(e),
        ],
        available: j['available'] as bool? ?? true,
        reason: j['reason'] as String? ?? 'ok',
        basis: j['basis'] as String? ?? 'ai',
        generatedAt: DateTime.tryParse((j['generated_at'] as String?) ?? ''),
      );
}

/// A similar-series query: a series, or an AniList id (onboarding), with the genre fallback.
class SimilarQuery {
  const SimilarQuery.series(String this.source, String this.series, {this.fallbackGenres = false}) : anilistId = null;
  const SimilarQuery.anilist(int this.anilistId) : source = null, series = null, fallbackGenres = false;
  final String? source, series;
  final int? anilistId;
  final bool fallbackGenres;

  Map<String, Object> get params => {
        if (anilistId != null) 'anilist_id': anilistId!,
        if (source != null) 'source': source!,
        if (series != null) 'series': series!,
        if (fallbackGenres) 'fallback': 'genres',
      };

  @override
  bool operator ==(Object other) => other is SimilarQuery && other.source == source && other.series == series && other.anilistId == anilistId && other.fallbackGenres == fallbackGenres;
  @override
  int get hashCode => Object.hash(source, series, anilistId, fallbackGenres);
}
