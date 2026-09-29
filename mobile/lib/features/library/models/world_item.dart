import 'package:manhwamaniacs/features/library/models/ambient.dart';

/// A title from the worldwide catalog (AniList + MangaUpdates), not only from
/// the series this server has cached — `GET /library/world/recommendations`
/// and `POST /library/world/suggest` both answer in this shape.
///
/// Every field is parsed leniently: the endpoints stitch together two external
/// catalogs, and a title one of them knows little about arrives with nulls or
/// missing keys. A card with no rating is still a card; a parse error that
/// blanks the whole screen over one odd row is not.
class WorldItem {
  const WorldItem({
    required this.title,
    this.anilistId = 0,
    this.altTitles = const [],
    this.format,
    this.country,
    this.status,
    this.chapters,
    this.rating,
    this.genres = const [],
    this.coverUrl,
    this.isAdult = false,
    this.platforms = const [],
    this.anilistUrl,
    this.available = const [],
    this.why,
    this.ambient,
  });

  final int anilistId;
  final String title;
  final List<String> altTitles;

  /// "Manhwa" · "Manga" · "Manhua" · "Novel" · "One-shot" · "Comic".
  final String? format;
  final String? country;

  /// "Ongoing" · "Completed" · "Hiatus" · "Cancelled" · "Upcoming".
  final String? status;

  /// Latest known chapter number, or null when nobody knows it.
  final int? chapters;

  /// 0–10, one decimal.
  final double? rating;
  final List<String> genres;

  /// An external URL (AniList's CDN), never the backend's cover proxy.
  final String? coverUrl;
  final bool isAdult;

  /// Official places to read it. May be empty.
  final List<WorldPlatform> platforms;
  final String? anilistUrl;

  /// The reader's own sources that carry it. Empty = none known.
  final List<WorldAvailability> available;

  /// One line on why it was picked. Set on AI answers only.
  final String? why;

  /// The cover's issue colours where the payload carried them, else null.
  final Ambient? ambient;

  factory WorldItem.fromJson(Map<String, dynamic> json) => WorldItem(
        anilistId: (json['anilist_id'] as num?)?.toInt() ?? 0,
        title: _text(json['title']) ?? 'Untitled',
        altTitles: _strings(json['alt_titles']),
        format: _text(json['format']),
        country: _text(json['country']),
        status: _text(json['status']),
        chapters: (json['chapters'] as num?)?.toInt(),
        rating: (json['rating'] as num?)?.toDouble(),
        genres: _strings(json['genres']),
        coverUrl: _text(json['cover_url']),
        isAdult: json['is_adult'] as bool? ?? false,
        platforms: [
          for (final raw in _maps(json['platforms']))
            if (WorldPlatform.fromJson(raw) case final platform?) platform,
        ],
        anilistUrl: _text(json['anilist_url']),
        available: [
          for (final raw in _maps(json['available']))
            if (WorldAvailability.fromJson(raw) case final source?) source,
        ],
        why: _text(json['why']),
        ambient: Ambient.tryParse(json['ambient']),
      );

  // ── Card rules (the contract's, shared by every card on the page) ────────

  /// Where tapping the card goes: the FIRST source that carries it. Null means
  /// the card does not open a series at all — it offers a search instead.
  WorldAvailability? get openTarget => available.isEmpty ? null : available.first;

  /// "On: Asura Scans", "+N more" when several sources carry it.
  String? get availabilityLabel {
    final first = openTarget;
    if (first == null) return null;
    final more = available.length - 1;
    return 'On: ${first.sourceName}${more > 0 ? ' (+$more more)' : ''}';
  }

  /// The outbound "Read on …" link — only for a title none of the reader's
  /// sources carries; a title that opens in the app needs no way out of it.
  WorldPlatform? get readElsewhere =>
      available.isEmpty && platforms.isNotEmpty ? platforms.first : null;

  /// "Manhwa · Ongoing", either half alone, or null with neither.
  String? get badgeLine {
    final parts = [format, status].whereType<String>();
    return parts.isEmpty ? null : parts.join(' · ');
  }

  String? get chaptersLabel => chapters == null ? null : '$chapters ch';

  String? get ratingLabel =>
      rating == null ? null : '★ ${rating!.toStringAsFixed(1)}';

  List<String> get cardGenres => genres.take(3).toList();
}

/// A source of the reader's own that carries a [WorldItem].
class WorldAvailability {
  const WorldAvailability({
    required this.sourceId,
    required this.sourceName,
    required this.seriesKey,
  });

  final String sourceId;
  final String sourceName;
  final String seriesKey;

  /// Null for a row that cannot be opened — without both ids there is no
  /// series page to go to, and a card that pretends otherwise 404s on tap.
  static WorldAvailability? fromJson(Map<String, dynamic> json) {
    final sourceId = _text(json['source_id']);
    final seriesKey = _text(json['series_key']);
    if (sourceId == null || seriesKey == null) return null;
    return WorldAvailability(
      sourceId: sourceId,
      sourceName: _text(json['source_name']) ?? sourceId,
      seriesKey: seriesKey,
    );
  }
}

/// An official place to read a [WorldItem] outside the app.
class WorldPlatform {
  const WorldPlatform({required this.site, required this.url});

  final String site;
  final String url;

  static WorldPlatform? fromJson(Map<String, dynamic> json) {
    final url = _text(json['url']);
    if (url == null) return null;
    return WorldPlatform(site: _text(json['site']) ?? 'the web', url: url);
  }
}

/// One "Because you read …" row.
class WorldSection {
  const WorldSection({required this.becauseTitle, this.items = const []});

  final String becauseTitle;
  final List<WorldItem> items;

  factory WorldSection.fromJson(Map<String, dynamic> json) {
    final because = json['because'];
    return WorldSection(
      becauseTitle:
          (because is Map<String, dynamic> ? _text(because['title']) : null) ??
              'your library',
      items: _items(json['items']),
    );
  }
}

/// `GET /library/world/recommendations`.
class WorldRecommendations {
  const WorldRecommendations({
    this.forYou = const [],
    this.sections = const [],
    this.unavailableReason,
  });

  final List<WorldItem> forYou;
  final List<WorldSection> sections;

  /// Set when the external catalog could not be reached. Shown as a quiet
  /// notice, never as an error: whatever did load still renders.
  final String? unavailableReason;

  bool get isEmpty =>
      forYou.isEmpty && sections.every((section) => section.items.isEmpty);

  factory WorldRecommendations.fromJson(Map<String, dynamic> json) =>
      WorldRecommendations(
        forYou: _items(json['for_you']),
        sections: [
          for (final raw in _maps(json['sections']))
            WorldSection.fromJson(raw),
        ],
        unavailableReason: _text(json['unavailable_reason']),
      );
}

/// `POST /library/world/suggest`.
class WorldSuggestResponse {
  const WorldSuggestResponse({
    this.items = const [],
    this.dropped = 0,
    this.model = '',
    this.remainingToday = 0,
  });

  final List<WorldItem> items;

  /// Titles the model named that the catalog could not verify. Never shown.
  final int dropped;
  final String model;

  /// Requests left in today's allowance, after this one.
  final int remainingToday;

  bool get isEmpty => items.isEmpty;

  factory WorldSuggestResponse.fromJson(Map<String, dynamic> json) =>
      WorldSuggestResponse(
        items: _items(json['items']),
        dropped: (json['dropped'] as num?)?.toInt() ?? 0,
        model: _text(json['model']) ?? '',
        remainingToday: (json['remaining_today'] as num?)?.toInt() ?? 0,
      );
}

/// A trimmed non-empty string, or null.
String? _text(Object? raw) {
  if (raw is! String) return null;
  final trimmed = raw.trim();
  return trimmed.isEmpty ? null : trimmed;
}

List<String> _strings(Object? raw) => [
      if (raw is List<dynamic>)
        for (final entry in raw)
          if (_text(entry) case final text?) text,
    ];

List<Map<String, dynamic>> _maps(Object? raw) => [
      if (raw is List<dynamic>)
        for (final entry in raw)
          if (entry is Map<String, dynamic>) entry,
    ];

List<WorldItem> _items(Object? raw) =>
    [for (final json in _maps(raw)) WorldItem.fromJson(json)];
