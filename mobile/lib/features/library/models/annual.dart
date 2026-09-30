import 'package:manhwamaniacs/features/library/models/shareable.dart';

/// `GET /library/annual` (cinematic 9.2.7), by field name. Glass's additive
/// fields (`pagesRead`, `longestStreak.start/end`, `busiestDay`, `firstsLasts`)
/// are parsed and left unused by Cinematic.
class Annual {
  const Annual({
    required this.year,
    this.partial = false,
    this.since,
    this.until,
    this.recordedDays = 0,
    this.secondsRead = 0,
    this.chaptersRead = 0,
    this.pagesRead = 0,
    this.chaptersByMonth = const [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    this.topSeries = const [],
    this.genres = const [],
    this.byHour = const [],
    this.longestStreak = const AnnualStreak(),
    this.topSources = const [],
    this.circle,
    this.topVoices = const [],
    this.availableYears = const [],
    this.busiestDay,
    this.firstsLasts,
    this.shareable,
    this.raw,
  });

  /// The payload as parsed, kept for the offline snapshot (A6).
  final Map<String, dynamic>? raw;

  final int year;
  final bool partial;
  final DateTime? since;
  final DateTime? until;
  final int recordedDays;
  final int secondsRead;
  final int chaptersRead;
  final int pagesRead;

  /// Always 12 entries, January first.
  final List<int> chaptersByMonth;
  final List<ShareSeries> topSeries;
  final List<GenreWeight> genres;

  /// Always 24 entries once the server answered: seconds per hour.
  final List<int> byHour;
  final AnnualStreak longestStreak;
  final List<AnnualSource> topSources;
  final List<CircleMember>? circle;
  final List<AnnualVoice> topVoices;
  final List<int> availableYears;
  final Map<String, dynamic>? busiestDay;
  final Map<String, dynamic>? firstsLasts;
  final Shareable? shareable;

  factory Annual.fromJson(Map<String, dynamic> json) {
    final months = _ints(json['chapters_by_month']);
    final byHour = List<int>.filled(24, 0);
    for (final h in _maps(json['by_hour'])) {
      final i = (h['hour'] as num?)?.toInt() ?? -1;
      if (i >= 0 && i < 24) byHour[i] = (h['seconds_read'] as num?)?.toInt() ?? 0;
    }
    final circleRaw = json['circle'];
    return Annual(
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      partial: json['partial'] == true,
      since: DateTime.tryParse(json['since'] as String? ?? ''),
      until: DateTime.tryParse(json['until'] as String? ?? ''),
      recordedDays: (json['recorded_days'] as num?)?.toInt() ?? 0,
      secondsRead: (json['seconds_read'] as num?)?.toInt() ?? 0,
      chaptersRead: (json['chapters_read'] as num?)?.toInt() ?? 0,
      pagesRead: (json['pages_read'] as num?)?.toInt() ?? 0,
      chaptersByMonth: [for (var i = 0; i < 12; i++) i < months.length ? months[i] : 0],
      topSeries: _maps(json['top_series']).map(ShareSeries.fromJson).where((s) => s.title.isNotEmpty).toList(growable: false),
      genres: _maps(json['genres']).map(GenreWeight.fromJson).where((g) => g.genre.isNotEmpty).toList(growable: false),
      byHour: byHour,
      longestStreak: AnnualStreak.fromJson(json['longest_streak'] is Map<String, dynamic> ? json['longest_streak'] as Map<String, dynamic> : const {}),
      topSources: _maps(json['top_sources']).map(AnnualSource.fromJson).toList(growable: false),
      circle: circleRaw is List ? _maps(circleRaw).map(CircleMember.fromJson).toList(growable: false) : null,
      topVoices: _maps(json['top_voices']).map(AnnualVoice.fromJson).where((v) => v.name.isNotEmpty).toList(growable: false),
      availableYears: _ints(json['available_years']),
      busiestDay: json['busiest_day'] is Map<String, dynamic> ? json['busiest_day'] as Map<String, dynamic> : null,
      firstsLasts: json['firsts_lasts'] is Map<String, dynamic> ? json['firsts_lasts'] as Map<String, dynamic> : null,
      shareable: Shareable.tryParse(json['shareable']),
      raw: json,
    );
  }
}

class AnnualStreak {
  const AnnualStreak({this.days = 0, this.month, this.start, this.end});
  final int days;

  /// 1..12, the month the longest run started in.
  final int? month;
  final DateTime? start;
  final DateTime? end;

  factory AnnualStreak.fromJson(Map<String, dynamic> json) => AnnualStreak(
        days: (json['days'] as num?)?.toInt() ?? 0,
        month: (json['month'] as num?)?.toInt(),
        start: DateTime.tryParse(json['start'] as String? ?? ''),
        end: DateTime.tryParse(json['end'] as String? ?? ''),
      );
}

class AnnualSource {
  const AnnualSource({required this.sourceId, required this.name, required this.share});
  final String sourceId;
  final String name;

  /// 0..1 of reading seconds.
  final double share;

  factory AnnualSource.fromJson(Map<String, dynamic> json) => AnnualSource(
        sourceId: json['source_id'] as String? ?? '',
        name: json['name'] as String? ?? json['source_id'] as String? ?? '',
        share: (json['share'] as num?)?.toDouble() ?? 0,
      );
}

class CircleMember {
  const CircleMember({required this.profileId, required this.name, this.avatarKey, this.finishedTogether = const []});
  final int profileId;
  final String name;
  final String? avatarKey;

  /// Series titles both finished.
  final List<String> finishedTogether;

  factory CircleMember.fromJson(Map<String, dynamic> json) => CircleMember(
        profileId: (json['profile_id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        avatarKey: json['avatar_key'] as String?,
        finishedTogether: [
          for (final t in (json['finished_together'] as List? ?? const []))
            if (t is String && t.trim().isNotEmpty) t.trim() else if (t is Map && (t['title'] as String? ?? '').trim().isNotEmpty) (t['title'] as String).trim(),
        ],
      );
}

class AnnualVoice {
  const AnnualVoice({required this.voiceId, required this.name, required this.seconds});
  final String voiceId;
  final String name;
  final int seconds;

  factory AnnualVoice.fromJson(Map<String, dynamic> json) => AnnualVoice(
        voiceId: json['voice_id'] as String? ?? '',
        name: (json['name'] as String? ?? '').trim(),
        seconds: (json['seconds'] as num?)?.toInt() ?? 0,
      );
}

Iterable<Map<String, dynamic>> _maps(Object? raw) => raw is List ? raw.whereType<Map<String, dynamic>>() : const [];

List<int> _ints(Object? raw) => raw is List ? [for (final v in raw) if (v is num) v.toInt()] : const [];
