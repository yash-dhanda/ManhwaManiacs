import 'package:manhwamaniacs/core/time/server_instant.dart';
import 'package:manhwamaniacs/features/library/models/ambient.dart';
import 'package:manhwamaniacs/features/library/models/continue_reading_item.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';

/// `GET /home` (cinematic 9.1.7) as immutable Dart classes. Parsing is tolerant: an unknown section
/// type, an unknown field or one malformed item is dropped, never thrown.

Map<String, dynamic>? _map(Object? v) => v is Map<String, dynamic> ? v : null;

List<Map<String, dynamic>> _maps(Object? v) => [
      if (v is List<dynamic>)
        for (final e in v)
          if (e is Map<String, dynamic>) e,
    ];

String? _str(Object? v) {
  if (v is! String) return null;
  final t = v.trim();
  return t.isEmpty ? null : t;
}

int? _int(Object? v) => v is num ? v.toInt() : null;

/// A local calendar date (`YYYY-MM-DD`) at local midnight.
DateTime? _localDate(Object? v) {
  final s = _str(v);
  if (s == null) return null;
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(s);
  if (m == null) return null;
  return DateTime(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
}

class HomeStreak {
  const HomeStreak({
    this.currentDays = 0,
    this.longestDays = 0,
    this.atRisk = false,
    this.lastActiveDate,
    this.milestonesSeen = const [],
  });

  final int currentDays, longestDays;
  final bool atRisk;

  /// A local calendar date, `DateTime` at midnight.
  final DateTime? lastActiveDate;
  final List<int> milestonesSeen;

  HomeStreak copyWith({bool? atRisk}) => HomeStreak(
        currentDays: currentDays,
        longestDays: longestDays,
        atRisk: atRisk ?? this.atRisk,
        lastActiveDate: lastActiveDate,
        milestonesSeen: milestonesSeen,
      );

  factory HomeStreak.fromJson(Object? json) {
    final j = _map(json);
    if (j == null) return const HomeStreak();
    return HomeStreak(
      currentDays: _int(j['current_days']) ?? 0,
      longestDays: _int(j['longest_days']) ?? 0,
      atRisk: j['at_risk'] as bool? ?? false,
      lastActiveDate: _localDate(j['last_active_date']),
      milestonesSeen: [
        if (j['milestones_seen'] is List<dynamic>)
          for (final e in j['milestones_seen'] as List<dynamic>)
            if (e is num) e.toInt(),
      ],
    );
  }
}

/// The 9.1.5 availability object.
class RecapAvailability {
  const RecapAvailability({required this.available, this.reason, this.fromKey, this.toKey, this.fromNumber, this.toNumber, this.estSeconds, this.cached = false});
  final bool available;
  final String? reason, fromKey, toKey;
  final num? fromNumber, toNumber;
  final int? estSeconds;
  final bool cached;

  static RecapAvailability? tryParse(Object? json) {
    final j = _map(json);
    if (j == null) return null;
    final range = _map(j['range']);
    return RecapAvailability(
      available: j['available'] as bool? ?? false,
      reason: _str(j['reason']),
      fromKey: _str(range?['from_key']),
      toKey: _str(range?['to_key']),
      fromNumber: range?['from_number'] as num?,
      toNumber: range?['to_number'] as num?,
      estSeconds: _int(j['est_seconds']),
      cached: j['cached'] as bool? ?? false,
    );
  }
}

class AiState {
  const AiState({this.available = false, this.reason = 'not_configured'});
  final bool available;
  final String reason;

  factory AiState.fromJson(Object? json) {
    final j = _map(json);
    if (j == null) return const AiState();
    return AiState(available: j['available'] as bool? ?? false, reason: _str(j['reason']) ?? 'not_configured');
  }
}

/// Why the cover story is what it is (the backend's `cover.reason`).
abstract final class HomeCoverReason {
  static const newChapters = 'new_chapters';
  static const inProgress = 'in_progress';
  static const paused = 'paused';
  static const firstPick = 'first_pick';
  static const aiPick = 'ai_pick';
  static const caughtUp = 'caught_up';
  static const popular = 'popular';
}

class HomeCover {
  const HomeCover({
    required this.sourceId,
    required this.seriesKey,
    this.chapterKey,
    this.reason = HomeCoverReason.popular,
    this.ambient,
    this.contentKind = 'manga',
    this.recap,
    this.title = '',
    this.coverUrl,
    this.chapterNumber,
    this.lastPage = 1,
    this.pageCount = 0,
    this.newCount = 0,
    this.pausedDays = 0,
    this.why,
    this.author,
  });

  final String sourceId, seriesKey;
  final String? chapterKey;
  final String reason;
  final Ambient? ambient;
  final String contentKind;
  final RecapAvailability? recap;
  final String title;

  /// The source's absolute URL or the backend's relative cover proxy path.
  final String? coverUrl;
  final double? chapterNumber;
  final int lastPage, pageCount, newCount, pausedDays;
  final String? why, author;

  bool get isNovel => contentKind == 'novel';

  /// Reading the chapter from its start (nothing read yet, or a pick).
  bool get isStart => reason == HomeCoverReason.firstPick ||
      reason == HomeCoverReason.aiPick ||
      reason == HomeCoverReason.caughtUp ||
      reason == HomeCoverReason.popular;

  /// 0..1 of the chapter in progress; null when nothing is in progress.
  double? get progress => reason == HomeCoverReason.inProgress && pageCount > 0 ? (lastPage / pageCount).clamp(0.0, 1.0) : null;

  static HomeCover? tryParse(Object? json) {
    final j = _map(json);
    if (j == null) return null;
    final source = _str(j['source_id']), series = _str(j['series_key']);
    if (source == null || series == null) return null;
    return HomeCover(
      sourceId: source,
      seriesKey: series,
      chapterKey: _str(j['chapter_key']),
      reason: _str(j['reason']) ?? HomeCoverReason.popular,
      ambient: Ambient.tryParse(j['ambient']),
      contentKind: _str(j['content_kind']) ?? 'manga',
      recap: RecapAvailability.tryParse(j['recap']),
      title: _str(j['title']) ?? '',
      coverUrl: _str(j['cover_url']),
      chapterNumber: (j['chapter_number'] as num?)?.toDouble(),
      lastPage: _int(j['last_page']) ?? 1,
      pageCount: _int(j['page_count']) ?? 0,
      newCount: _int(j['new_count']) ?? 0,
      pausedDays: _int(j['paused_days']) ?? 0,
      why: _str(j['why']),
      author: _str(j['author']),
    );
  }
}

enum HomeAlsoKind {
  newChapters,
  because,
  letter,
  almostThere;

  static HomeAlsoKind? parse(Object? v) => switch (_str(v)?.replaceAll('_', '').toLowerCase()) {
        'newchapters' => newChapters,
        'because' => because,
        'letter' => letter,
        'almostthere' => almostThere,
        _ => null,
      };
}

class HomeAlso {
  const HomeAlso({required this.kind, this.sourceId, this.seriesKey, this.title = '', required this.headline, this.deck, this.ambient, this.coverUrl});
  final HomeAlsoKind kind;
  final String? sourceId, seriesKey, deck, coverUrl;
  final String title, headline;
  final Ambient? ambient;

  /// The cover proxy path when the payload names none.
  String? get coverPath => coverUrl ?? (sourceId == null || seriesKey == null ? null : '/sources/$sourceId/series/${Uri.encodeComponent(seriesKey!)}/cover');

  static HomeAlso? tryParse(Object? json) {
    final j = _map(json);
    if (j == null) return null;
    final kind = HomeAlsoKind.parse(j['kind']);
    final headline = _str(j['headline']);
    if (kind == null || headline == null) return null;
    return HomeAlso(
      kind: kind,
      sourceId: _str(j['source_id']),
      seriesKey: _str(j['series_key']),
      title: _str(j['title']) ?? '',
      headline: headline,
      deck: _str(j['deck']),
      ambient: Ambient.tryParse(j['ambient']),
      coverUrl: _str(j['cover_url']),
    );
  }
}

enum HomeSectionType {
  firstPicks('first_picks'),
  continueReading('continue'),
  newThisWeek('new_this_week'),
  almostThere('almost_there'),
  whereWereWe('where_were_we'),
  sentToYou('sent_to_you'),
  picked('picked'),
  because('because'),
  circle('circle'),
  circleTop('circle_top'),
  sources('sources'),
  genres('genres'),
  numbers('numbers'),
  popular('popular'),

  /// Client-only: the offline edition's saved series.
  saved('saved');

  const HomeSectionType(this.wire);
  final String wire;

  static HomeSectionType? parse(Object? v) {
    final s = _str(v);
    for (final t in values) {
      if (t.wire == s) return t;
    }
    return null;
  }
}

enum HomeSectionState {
  ready,
  empty,
  unavailable,
  stale;

  static HomeSectionState parse(Object? v) => switch (_str(v)) {
        'empty' => empty,
        'unavailable' => unavailable,
        'stale' => stale,
        _ => ready,
      };
}

enum ContinueNudge {
  newChapters,
  almostDone,
  paused;

  static ContinueNudge? parse(Object? v) => switch (_str(v)) {
        'new' => newChapters,
        'almost_done' => almostDone,
        'paused' => paused,
        _ => null,
      };
}

/// A `continue` row: the continue-reading row plus the section's extras.
class HomeContinueItem {
  const HomeContinueItem({required this.row, this.nudge, this.newCount = 0, this.pausedDays = 0, this.recap, this.mature = false});
  final ContinueReadingItem row;
  final ContinueNudge? nudge;
  final int newCount, pausedDays;
  final RecapAvailability? recap;

  /// Stamped when the feed is saved for the offline edition (`isMatureLocal`).
  final bool mature;

  Ambient? get ambient => row.ambient;
}

/// A `new_this_week`, `almost_there` or `where_were_we` row: the library row plus the extras.
class HomeSeriesItem {
  const HomeSeriesItem({required this.series, this.chaptersLeft, this.recap, this.mature = false, this.lastReadAt});
  final FollowedSeries series;
  final int? chaptersLeft;
  final RecapAvailability? recap;
  final bool mature;

  /// When this profile last read the series, where the payload says (Where were we?).
  final DateTime? lastReadAt;

  Ambient? get ambient => series.ambient;
}

/// `picked`, `because`, `first_picks`, `popular`: a world title or a source series, with its `why`.
class HomePickItem {
  const HomePickItem({this.world, this.source, this.why, this.mature = false}) : assert(world != null || source != null);
  final WorldItem? world;
  final SourceSeriesSummary? source;
  final String? why;
  final bool mature;

  String get title => world?.title ?? source!.title;
  Ambient? get ambient => world?.ambient ?? source?.ambient;
}

class HomeSourceItem {
  const HomeSourceItem({required this.sourceId, required this.name, this.iconUrl, this.mature = false, this.available = true, this.suggested = false, this.latestCovers = const []});
  final String sourceId, name;
  final String? iconUrl;
  final bool mature, available, suggested;
  final List<String> latestCovers;
}

class HomeGenreItem {
  const HomeGenreItem({required this.genre, this.weight = 0});
  final String genre;
  final double weight;
}

class HomeNumbersItem {
  const HomeNumbersItem({this.streak = const HomeStreak(), this.chaptersWeek = 0, this.secondsWeek = 0});
  final HomeStreak streak;
  final int chaptersWeek, secondsWeek;
}

/// The offline edition's saved series.
class HomeSavedItem {
  const HomeSavedItem({required this.sourceId, required this.seriesKey, required this.title, this.chapters = 0, this.coverUrl, this.lastReadAt});
  final String sourceId, seriesKey, title;
  final int chapters;
  final String? coverUrl;
  final DateTime? lastReadAt;
}

class HomeSeed {
  const HomeSeed({required this.title, this.sourceId, this.seriesKey});
  final String title;
  final String? sourceId, seriesKey;
}

class HomeSection {
  const HomeSection({
    required this.type,
    required this.title,
    this.seed,
    this.note,
    this.fallback,
    this.items = const [],
    this.state = HomeSectionState.ready,
    this.generatedAt,
  });

  final HomeSectionType type;
  final String title;
  final HomeSeed? seed;
  final String? note, fallback;

  /// The typed items of [type] (`HomeContinueItem`, `HomeSeriesItem`, `HomePickItem`, ...).
  final List<Object> items;
  final HomeSectionState state;
  final DateTime? generatedAt;

  bool get hasItems => items.isNotEmpty;

  HomeSection copyWith({List<Object>? items, HomeSectionState? state, String? title}) => HomeSection(
        type: type,
        title: title ?? this.title,
        seed: seed,
        note: note,
        fallback: fallback,
        items: items ?? this.items,
        state: state ?? this.state,
        generatedAt: generatedAt,
      );

  static HomeSection? tryParse(Object? json) {
    final j = _map(json);
    if (j == null) return null;
    final type = HomeSectionType.parse(j['type']);
    if (type == null) return null;
    final items = <Object>[];
    for (final raw in _maps(j['items'])) {
      try {
        final item = _item(type, raw);
        if (item != null) items.add(item);
      } catch (_) {
        // One malformed row never blanks the section.
      }
    }
    final seed = _map(j['seed']);
    return HomeSection(
      type: type,
      title: _str(j['title']) ?? '',
      seed: seed == null || _str(seed['title']) == null
          ? null
          : HomeSeed(title: _str(seed['title'])!, sourceId: _str(seed['source_id']), seriesKey: _str(seed['series_key'])),
      note: _str(j['note']),
      fallback: _str(j['fallback']),
      items: items,
      state: HomeSectionState.parse(j['state']),
      generatedAt: serverInstant(j['generated_at']),
    );
  }

  static Object? _item(HomeSectionType type, Map<String, dynamic> j) => switch (type) {
        HomeSectionType.continueReading => HomeContinueItem(
            row: ContinueReadingItem.fromJson(j),
            nudge: ContinueNudge.parse(j['nudge']),
            newCount: _int(j['new_count']) ?? 0,
            pausedDays: _int(j['paused_days']) ?? 0,
            recap: RecapAvailability.tryParse(j['recap']),
          ),
        HomeSectionType.newThisWeek || HomeSectionType.almostThere || HomeSectionType.whereWereWe => HomeSeriesItem(
            series: FollowedSeries.fromJson(j),
            chaptersLeft: _int(j['chapters_left']),
            recap: RecapAvailability.tryParse(j['recap']),
            lastReadAt: serverInstant(j['last_read_at']),
          ),
        HomeSectionType.picked || HomeSectionType.because || HomeSectionType.firstPicks || HomeSectionType.popular => _pick(j),
        HomeSectionType.sources => HomeSourceItem(
            sourceId: _str(j['source_id']) ?? _str(j['id'])!,
            name: _str(j['name']) ?? _str(j['source_id']) ?? '',
            iconUrl: _str(j['icon_url']),
            mature: j['mature'] as bool? ?? false,
            available: j['available'] as bool? ?? true,
            suggested: j['suggested'] as bool? ?? false,
            latestCovers: [
              if (j['latest_covers'] is List<dynamic>)
                for (final c in j['latest_covers'] as List<dynamic>)
                  if (_str(c) != null) _str(c)!,
            ],
          ),
        HomeSectionType.genres => HomeGenreItem(genre: _str(j['genre'])!, weight: (j['weight'] as num?)?.toDouble() ?? 0),
        HomeSectionType.numbers => HomeNumbersItem(
            streak: HomeStreak.fromJson(j['streak']),
            chaptersWeek: _int(j['chapters_week']) ?? 0,
            secondsWeek: _int(j['seconds_week']) ?? 0,
          ),
        _ => null,
      };

  static HomePickItem? _pick(Map<String, dynamic> j) {
    final item = _map(j['item']);
    if (item == null) return null;
    final why = _str(j['why']);
    if (j['kind'] == 'world') return HomePickItem(world: WorldItem.fromJson(item), why: why);
    return HomePickItem(source: SourceSeriesSummary.fromJson(item, ''), why: why);
  }
}

class HomeFeed {
  const HomeFeed({
    this.issueNo = 1,
    required this.headline,
    required this.deck,
    this.kickerTitle,
    this.streak = const HomeStreak(),
    this.cover,
    this.also = const [],
    this.sections = const [],
    this.ai = const AiState(),
    this.generatedAt,
  });

  final int issueNo;
  final String headline, deck;

  /// The series title when the headline dropped it (over 60 graphemes).
  final String? kickerTitle;
  final HomeStreak streak;
  final HomeCover? cover;
  final List<HomeAlso> also;
  final List<HomeSection> sections;
  final AiState ai;
  final DateTime? generatedAt;

  HomeFeed copyWith({String? headline, String? deck, String? kickerTitle, bool clearKicker = false, HomeStreak? streak, List<HomeSection>? sections, List<HomeAlso>? also, AiState? ai}) => HomeFeed(
        issueNo: issueNo,
        headline: headline ?? this.headline,
        deck: deck ?? this.deck,
        kickerTitle: clearKicker ? null : (kickerTitle ?? this.kickerTitle),
        streak: streak ?? this.streak,
        cover: cover,
        also: also ?? this.also,
        sections: sections ?? this.sections,
        ai: ai ?? this.ai,
        generatedAt: generatedAt,
      );

  HomeSection? section(HomeSectionType t) {
    for (final s in sections) {
      if (s.type == t) return s;
    }
    return null;
  }

  factory HomeFeed.fromJson(Map<String, dynamic> j) => HomeFeed(
        issueNo: _int(j['issue_no']) ?? 1,
        headline: _str(j['headline']) ?? 'Your first issue starts here.',
        deck: _str(j['deck']) ?? '',
        kickerTitle: _str(j['kicker_title']),
        streak: HomeStreak.fromJson(j['streak']),
        cover: HomeCover.tryParse(j['cover']),
        also: [
          for (final a in (j['also'] is List<dynamic> ? j['also'] as List<dynamic> : const <dynamic>[]))
            if (HomeAlso.tryParse(a) case final ok?) ok,
        ],
        sections: [
          for (final s in (j['sections'] is List<dynamic> ? j['sections'] as List<dynamic> : const <dynamic>[]))
            if (HomeSection.tryParse(s) case final ok?) ok,
        ],
        ai: AiState.fromJson(j['ai']),
        generatedAt: serverInstant(j['generated_at']),
      );
}
