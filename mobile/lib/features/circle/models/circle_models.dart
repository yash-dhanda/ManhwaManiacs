import 'package:manhwamaniacs/features/library/models/ambient.dart';

/// `{profile_id, name, avatar_key, username}` (circle-api `ProfileRef`).
class ProfileRef {
  const ProfileRef({required this.profileId, required this.name, this.avatarKey, this.username});

  final int profileId;
  final String name;
  final String? avatarKey, username;

  factory ProfileRef.fromJson(Map<String, dynamic> j) => ProfileRef(
        profileId: (j['profile_id'] as num?)?.toInt() ?? 0,
        name: j['name'] as String? ?? '',
        avatarKey: j['avatar_key'] as String?,
        username: j['username'] as String?,
      );

  @override
  bool operator ==(Object other) => other is ProfileRef && other.profileId == profileId && other.name == name && other.avatarKey == avatarKey && other.username == username;

  @override
  int get hashCode => Object.hash(profileId, name, avatarKey, username);
}

/// mobile/13's name for [ProfileRef].
typedef CircleMemberRef = ProfileRef;

Map<String, dynamic> _map(Object? o) => o is Map ? Map<String, dynamic>.from(o) : const {};
DateTime? _date(Object? o) => o is String ? DateTime.tryParse(o.endsWith('Z') || o.contains('+') ? o : '${o}Z') : null;
double? _num(Object? o) => (o as num?)?.toDouble();

/// The seven reaction kinds in stored order; [wire] is the API value.
enum ReactionKind {
  loved('loved'),
  shook('shook'),
  laughed('laughed'),
  tears('tears'),
  chefsKiss('chefs_kiss'),
  hype('hype'),
  wrecked('wrecked');

  const ReactionKind(this.wire);
  final String wire;

  static ReactionKind? tryParse(Object? wire) {
    for (final k in values) {
      if (k.wire == wire) return k;
    }
    return null;
  }
}

/// `now` of a member (only when their `show_presence` is on).
class CircleNow {
  const CircleNow({required this.sourceId, required this.seriesKey, required this.chapterKey, this.chapterNumber, this.title = '', this.ambient, this.since});

  final String sourceId, seriesKey, chapterKey, title;
  final double? chapterNumber;
  final Ambient? ambient;
  final DateTime? since;

  static CircleNow? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final j = _map(raw);
    return CircleNow(
      sourceId: j['source_id'] as String? ?? '',
      seriesKey: j['series_key'] as String? ?? '',
      chapterKey: j['chapter_key'] as String? ?? '',
      chapterNumber: _num(j['chapter_number']),
      title: j['title'] as String? ?? '',
      ambient: Ambient.tryParse(j['ambient']),
      since: _date(j['since']),
    );
  }
}

/// A member's four sharing flags as `shares`.
class CircleShares {
  const CircleShares({this.activity = false, this.reactions = false, this.shelves = false, this.recommendations = false});

  final bool activity, reactions, shelves, recommendations;

  factory CircleShares.fromJson(Object? raw) {
    final j = _map(raw);
    return CircleShares(
      activity: j['activity'] as bool? ?? false,
      reactions: j['reactions'] as bool? ?? false,
      shelves: j['shelves'] as bool? ?? false,
      recommendations: j['recommendations'] as bool? ?? false,
    );
  }
}

/// `{current_days, alive_today}`.
class CircleStreak {
  const CircleStreak({this.currentDays = 0, this.aliveToday = false});
  final int currentDays;
  final bool aliveToday;

  static CircleStreak? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final j = _map(raw);
    return CircleStreak(currentDays: (j['current_days'] as num?)?.toInt() ?? 0, aliveToday: j['alive_today'] as bool? ?? false);
  }
}

/// One entry of `GET /circle/members`.
class CircleMember extends ProfileRef {
  const CircleMember({
    required super.profileId,
    required super.name,
    super.avatarKey,
    super.username,
    this.shares = const CircleShares(),
    this.now,
    this.lastActiveAt,
    this.streak,
    this.canReceive,
  });

  final CircleShares shares;
  final CircleNow? now;
  final DateTime? lastActiveAt;
  final CircleStreak? streak;

  /// Only present when the call carried a series; null otherwise.
  final bool? canReceive;

  ProfileRef get ref => ProfileRef(profileId: profileId, name: name, avatarKey: avatarKey, username: username);

  factory CircleMember.fromJson(Map<String, dynamic> j) {
    final p = ProfileRef.fromJson(j);
    return CircleMember(
      profileId: p.profileId,
      name: p.name,
      avatarKey: p.avatarKey,
      username: p.username,
      shares: CircleShares.fromJson(j['shares']),
      now: CircleNow.tryParse(j['now']),
      lastActiveAt: _date(j['last_active_at']),
      streak: CircleStreak.tryParse(j['streak']),
      canReceive: j['can_receive'] as bool?,
    );
  }

  @override
  bool operator ==(Object other) => other is CircleMember && super == other && other.canReceive == canReceive && other.now?.chapterKey == now?.chapterKey && other.now?.seriesKey == now?.seriesKey;

  @override
  int get hashCode => Object.hash(super.hashCode, canReceive, now?.seriesKey);
}

enum FeedKind { started, finishedChapter, finishedSeries, reacted }

/// The series fields every Circle shape carries (`CircleSeries`).
class CircleSeries {
  const CircleSeries({required this.sourceId, required this.seriesKey, this.title = '', this.coverUrl, this.ambient, this.contentKind});

  final String sourceId, seriesKey, title;
  final String? coverUrl, contentKind;
  final Ambient? ambient;

  factory CircleSeries.fromJson(Map<String, dynamic> j) => CircleSeries(
        sourceId: j['source_id'] as String? ?? '',
        seriesKey: j['series_key'] as String? ?? '',
        title: j['title'] as String? ?? '',
        coverUrl: j['cover_url'] as String?,
        ambient: Ambient.tryParse(j['ambient']),
        contentKind: j['content_kind'] as String?,
      );
}

/// One dispatch of `GET /circle/feed`.
class FeedItem {
  const FeedItem({
    required this.id,
    required this.kind,
    required this.actor,
    required this.sourceId,
    required this.seriesKey,
    this.title = '',
    this.coverUrl,
    this.ambient,
    this.contentKind,
    this.chapterKey,
    this.chapterNumber,
    this.reaction,
    this.sealed,
    this.followedByViewer = false,
    this.createdAt,
  });

  final String id;
  final FeedKind kind;
  final ProfileRef actor;
  final String sourceId, seriesKey, title;
  final String? coverUrl, contentKind, chapterKey;
  final Ambient? ambient;
  final double? chapterNumber;
  final ReactionKind? reaction;
  final bool? sealed;
  final bool followedByViewer;
  final DateTime? createdAt;

  static FeedKind _kind(Object? s) => switch (s) {
        'started' => FeedKind.started,
        'finished_chapter' => FeedKind.finishedChapter,
        'finished_series' => FeedKind.finishedSeries,
        _ => FeedKind.reacted,
      };

  factory FeedItem.fromJson(Map<String, dynamic> j) {
    final s = CircleSeries.fromJson(j);
    return FeedItem(
      id: '${j['id']}',
      kind: _kind(j['kind']),
      actor: ProfileRef.fromJson(_map(j['actor'])),
      sourceId: s.sourceId,
      seriesKey: s.seriesKey,
      title: s.title,
      coverUrl: s.coverUrl,
      ambient: s.ambient,
      contentKind: s.contentKind,
      chapterKey: j['chapter_key'] as String?,
      chapterNumber: _num(j['chapter_number']),
      reaction: ReactionKind.tryParse(j['reaction']),
      sealed: j['sealed'] as bool?,
      followedByViewer: j['followed_by_viewer'] as bool? ?? false,
      createdAt: _date(j['created_at']),
    );
  }

  FeedItem copyWith({bool? followedByViewer}) => FeedItem(
        id: id,
        kind: kind,
        actor: actor,
        sourceId: sourceId,
        seriesKey: seriesKey,
        title: title,
        coverUrl: coverUrl,
        ambient: ambient,
        contentKind: contentKind,
        chapterKey: chapterKey,
        chapterNumber: chapterNumber,
        reaction: reaction,
        sealed: sealed,
        followedByViewer: followedByViewer ?? this.followedByViewer,
        createdAt: createdAt,
      );
}

/// A page of the feed.
class FeedPage {
  const FeedPage({this.items = const [], this.nextCursor});
  final List<FeedItem> items;
  final String? nextCursor;
}

/// Someone's reaction on a chapter (`by[]`).
class ReactionBy extends ProfileRef {
  const ReactionBy({required super.profileId, required super.name, super.avatarKey, super.username, this.kind, this.createdAt});

  final ReactionKind? kind;
  final DateTime? createdAt;

  ReactionBy.of(ProfileRef p, ReactionKind this.kind, {this.createdAt}) : super(profileId: p.profileId, name: p.name, avatarKey: p.avatarKey, username: p.username);

  ProfileRef get member => ProfileRef(profileId: profileId, name: name, avatarKey: avatarKey, username: username);

  factory ReactionBy.fromJson(Map<String, dynamic> j) {
    final p = ProfileRef.fromJson(j);
    return ReactionBy(
      profileId: p.profileId,
      name: p.name,
      avatarKey: p.avatarKey,
      username: p.username,
      kind: ReactionKind.tryParse(j['kind']),
      createdAt: _date(j['created_at']),
    );
  }
}

/// `ChapterReactions`: the reactions on one chapter. [sealed] is the server half of the spoiler guard.
class ChapterReactions {
  const ChapterReactions({
    required this.chapterKey,
    this.chapterNumber,
    this.counts = const {},
    this.total = 0,
    this.by = const [],
    this.mine,
    this.sealed = true,
  });

  final String chapterKey;
  final double? chapterNumber;
  final Map<ReactionKind, int> counts;
  final int total;
  final List<ReactionBy> by;
  final ReactionKind? mine;
  final bool sealed;

  int countOf(ReactionKind k) => counts[k] ?? 0;

  factory ChapterReactions.fromJson(Map<String, dynamic> j) {
    final by = [for (final r in (j['by'] as List? ?? const [])) if (r is Map) ReactionBy.fromJson(Map<String, dynamic>.from(r))];
    final counts = <ReactionKind, int>{};
    final raw = _map(j['counts']);
    for (final k in ReactionKind.values) {
      counts[k] = (raw[k.wire] as num?)?.toInt() ?? 0;
    }
    return ChapterReactions(
      chapterKey: j['chapter_key'] as String? ?? '',
      chapterNumber: _num(j['chapter_number']),
      counts: counts,
      total: (j['total'] as num?)?.toInt() ?? by.length,
      by: by,
      mine: ReactionKind.tryParse(j['mine']),
      sealed: j['sealed'] as bool? ?? true,
    );
  }

  ChapterReactions copyWith({Map<ReactionKind, int>? counts, int? total, List<ReactionBy>? by, ReactionKind? mine, bool clearMine = false, bool? sealed}) => ChapterReactions(
        chapterKey: chapterKey,
        chapterNumber: chapterNumber,
        counts: counts ?? this.counts,
        total: total ?? this.total,
        by: by ?? this.by,
        mine: clearMine ? null : (mine ?? this.mine),
        sealed: sealed ?? this.sealed,
      );
}

/// mobile/13's name for [ChapterReactions].
typedef CircleChapterReactions = ChapterReactions;

enum LetterState { newLetter, read, kept, dismissed }

extension LetterStateWire on LetterState {
  String get wire => switch (this) { LetterState.newLetter => 'new', LetterState.read => 'read', LetterState.kept => 'kept', LetterState.dismissed => 'dismissed' };

  static LetterState parse(Object? s) => switch (s) {
        'read' => LetterState.read,
        'kept' => LetterState.kept,
        'dismissed' => LetterState.dismissed,
        _ => LetterState.newLetter,
      };
}

/// One inbox letter.
class Letter {
  const Letter({required this.id, required this.from, required this.sourceId, required this.seriesKey, this.title = '', this.coverUrl, this.ambient, this.contentKind, this.note, this.state = LetterState.newLetter, this.createdAt});

  final int id;
  final ProfileRef from;
  final String sourceId, seriesKey, title;
  final String? coverUrl, contentKind, note;
  final Ambient? ambient;
  final LetterState state;
  final DateTime? createdAt;

  factory Letter.fromJson(Map<String, dynamic> j) {
    final s = CircleSeries.fromJson(j);
    return Letter(
      id: (j['id'] as num?)?.toInt() ?? 0,
      from: ProfileRef.fromJson(_map(j['from'])),
      sourceId: s.sourceId,
      seriesKey: s.seriesKey,
      title: s.title,
      coverUrl: s.coverUrl,
      ambient: s.ambient,
      contentKind: s.contentKind,
      note: j['note'] as String?,
      state: LetterStateWire.parse(j['state']),
      createdAt: _date(j['created_at']),
    );
  }

  Letter copyWith({LetterState? state}) => Letter(id: id, from: from, sourceId: sourceId, seriesKey: seriesKey, title: title, coverUrl: coverUrl, ambient: ambient, contentKind: contentKind, note: note, state: state ?? this.state, createdAt: createdAt);
}

/// `{source_id, series_key, title}` of `excluded_series`.
class ExcludedSeries {
  const ExcludedSeries({required this.sourceId, required this.seriesKey, this.title = ''});
  final String sourceId, seriesKey, title;

  factory ExcludedSeries.fromJson(Map<String, dynamic> j) => ExcludedSeries(sourceId: j['source_id'] as String? ?? '', seriesKey: j['series_key'] as String? ?? '', title: j['title'] as String? ?? '');

  Map<String, String> toJson() => {'source_id': sourceId, 'series_key': seriesKey, 'title': title};

  @override
  bool operator ==(Object other) => other is ExcludedSeries && other.sourceId == sourceId && other.seriesKey == seriesKey;

  @override
  int get hashCode => Object.hash(sourceId, seriesKey);
}

/// `GET /profiles/{id}/sharing`.
class Sharing {
  const Sharing({
    this.activity = false,
    this.reactions = true,
    this.shelves = true,
    this.recommendations = true,
    this.includeMature = false,
    this.showPresence = false,
    this.shareStreak = false,
    this.excludedSeries = const [],
  });

  final bool activity, reactions, shelves, recommendations, includeMature, showPresence, shareStreak;
  final List<ExcludedSeries> excludedSeries;

  factory Sharing.fromJson(Map<String, dynamic> j) => Sharing(
        activity: j['activity'] as bool? ?? false,
        reactions: j['reactions'] as bool? ?? true,
        shelves: j['shelves'] as bool? ?? true,
        recommendations: j['recommendations'] as bool? ?? true,
        includeMature: j['include_mature'] as bool? ?? false,
        showPresence: j['show_presence'] as bool? ?? false,
        shareStreak: j['share_streak'] as bool? ?? false,
        excludedSeries: [for (final e in (j['excluded_series'] as List? ?? const [])) if (e is Map) ExcludedSeries.fromJson(Map<String, dynamic>.from(e))],
      );

  Sharing copyWith({bool? activity, bool? reactions, bool? shelves, bool? recommendations, bool? includeMature, bool? showPresence, bool? shareStreak, List<ExcludedSeries>? excludedSeries}) => Sharing(
        activity: activity ?? this.activity,
        reactions: reactions ?? this.reactions,
        shelves: shelves ?? this.shelves,
        recommendations: recommendations ?? this.recommendations,
        includeMature: includeMature ?? this.includeMature,
        showPresence: showPresence ?? this.showPresence,
        shareStreak: shareStreak ?? this.shareStreak,
        excludedSeries: excludedSeries ?? this.excludedSeries,
      );
}

/// A shelf shared with the viewer, or the viewer's own shelf's share block.
class SharedShelfInfo {
  const SharedShelfInfo({this.ownerProfileId, this.mode, this.memberProfileIds = const [], this.members = const []});
  final int? ownerProfileId;
  final String? mode; // can_add | view_only
  final List<int> memberProfileIds;
  final List<ProfileRef> members;

  static SharedShelfInfo? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final j = _map(raw);
    return SharedShelfInfo(
      ownerProfileId: (j['owner_profile_id'] as num?)?.toInt(),
      mode: j['mode'] as String?,
      memberProfileIds: [for (final e in (j['member_profile_ids'] as List? ?? const [])) (e as num).toInt()],
      members: [for (final e in (j['members'] as List? ?? const [])) if (e is Map) ProfileRef.fromJson(Map<String, dynamic>.from(e))],
    );
  }
}

/// `SharedShelf`: a shelf of another profile, shared with the viewer.
class SharedShelf {
  const SharedShelf({required this.id, required this.name, this.description, this.seriesCount = 0, this.previewCovers = const [], this.previewAmbientDuo, this.owner, this.role = 'view_only', this.shared, this.createdAt});

  final int id, seriesCount;
  final String name;
  final String? description, previewAmbientDuo;
  final List<String> previewCovers;
  final ProfileRef? owner;
  final String role; // owner | can_add | view_only
  final SharedShelfInfo? shared;
  final DateTime? createdAt;

  bool get canAdd => role == 'owner' || role == 'can_add';

  factory SharedShelf.fromJson(Map<String, dynamic> j) => SharedShelf(
        id: (j['id'] as num?)?.toInt() ?? 0,
        name: j['name'] as String? ?? '',
        description: j['description'] as String?,
        seriesCount: (j['series_count'] as num?)?.toInt() ?? 0,
        previewCovers: [for (final e in (j['preview_covers'] as List? ?? const [])) if (e is String) e],
        previewAmbientDuo: () {
          final d = j['preview_ambient_duo'];
          return d is String ? d : (d is List && d.isNotEmpty && d.first is String ? d.first as String : null);
        }(),
        owner: j['owner'] is Map ? ProfileRef.fromJson(_map(j['owner'])) : null,
        role: j['role'] as String? ?? 'view_only',
        shared: SharedShelfInfo.tryParse(j['shared']),
        createdAt: _date(j['created_at']),
      );
}

/// A series line of the member page: `CircleSeries` plus what the member did with it.
class MemberSeries extends CircleSeries {
  const MemberSeries({required super.sourceId, required super.seriesKey, super.title, super.coverUrl, super.ambient, super.contentKind, this.chapterKey, this.chapterNumber, this.reaction, this.sealed, this.at});

  final String? chapterKey;
  final double? chapterNumber;
  final ReactionKind? reaction;
  final bool? sealed;

  /// `last_activity_at`, `finished_at` or `created_at`, whichever the rail carries.
  final DateTime? at;

  factory MemberSeries.fromJson(Map<String, dynamic> j) {
    final s = CircleSeries.fromJson(j);
    return MemberSeries(
      sourceId: s.sourceId,
      seriesKey: s.seriesKey,
      title: s.title,
      coverUrl: s.coverUrl,
      ambient: s.ambient,
      contentKind: s.contentKind,
      chapterKey: j['chapter_key'] as String?,
      chapterNumber: _num(j['chapter_number']),
      reaction: ReactionKind.tryParse(j['reaction']),
      sealed: j['sealed'] as bool?,
      at: _date(j['last_activity_at'] ?? j['finished_at'] ?? j['created_at']),
    );
  }
}

/// `GET /circle/members/{profile_id}`.
class MemberPage {
  const MemberPage({required this.profile, this.shares = const CircleShares(), this.now, this.lastActiveAt, this.streak, this.reading = const [], this.finished = const [], this.reactions = const [], this.shelves = const []});

  final ProfileRef profile;
  final CircleShares shares;
  final CircleNow? now;
  final DateTime? lastActiveAt;
  final CircleStreak? streak;
  final List<MemberSeries> reading, finished, reactions;
  final List<SharedShelf> shelves;

  factory MemberPage.fromJson(Map<String, dynamic> j) {
    List<MemberSeries> series(String k) => [for (final e in (j[k] as List? ?? const [])) if (e is Map) MemberSeries.fromJson(Map<String, dynamic>.from(e))];
    return MemberPage(
      profile: ProfileRef.fromJson(_map(j['profile'])),
      shares: CircleShares.fromJson(j['shares']),
      now: CircleNow.tryParse(j['now']),
      lastActiveAt: _date(j['last_active_at']),
      streak: CircleStreak.tryParse(j['streak']),
      reading: series('reading'),
      finished: series('finished'),
      reactions: series('reactions'),
      shelves: [for (final e in (j['shelves'] as List? ?? const [])) if (e is Map) SharedShelf.fromJson(Map<String, dynamic>.from(e))],
    );
  }
}

/// How far a member has read of a series (`readers[]` of `GET /circle/series`).
class CircleReader {
  const CircleReader({required this.member, required this.chapterKey, this.chapterNumber, this.lastReadAt});

  final ProfileRef member;
  final String chapterKey;
  final double? chapterNumber;
  final DateTime? lastReadAt;

  factory CircleReader.fromJson(Map<String, dynamic> j) => CircleReader(
        member: ProfileRef.fromJson(_map(j['profile'])),
        chapterKey: j['chapter_key'] as String? ?? '',
        chapterNumber: _num(j['chapter_number']),
        lastReadAt: _date(j['last_read_at']),
      );
}

/// `GET /circle/series` (followers, readers) with the per-chapter reactions of `GET /circle/reactions`.
class CircleSeriesData {
  const CircleSeriesData({this.readers = const [], this.chapters = const [], this.followers = const []});

  final List<CircleReader> readers;
  final List<ChapterReactions> chapters;
  final List<ProfileRef> followers;
}

/// Alias used by the spec text.
typedef CircleSeriesInfo = CircleSeriesData;

/// One series row of a shelf detail (`GET /library/collections/{id}`), rendered from the shelf's
/// own snapshot (never from the viewer's library).
class ShelfSeriesRow extends CircleSeries {
  const ShelfSeriesRow({required super.sourceId, required super.seriesKey, super.title, super.coverUrl, super.ambient, super.contentKind, this.addedByProfileId, this.addedBy});

  final int? addedByProfileId;
  final ProfileRef? addedBy;

  factory ShelfSeriesRow.fromJson(Map<String, dynamic> j) {
    final s = CircleSeries.fromJson(j);
    return ShelfSeriesRow(
      sourceId: s.sourceId,
      seriesKey: s.seriesKey,
      title: s.title,
      coverUrl: s.coverUrl,
      ambient: s.ambient,
      contentKind: s.contentKind,
      addedByProfileId: (j['added_by_profile_id'] as num?)?.toInt(),
      addedBy: j['added_by'] is Map ? ProfileRef.fromJson(_map(j['added_by'])) : null,
    );
  }
}

/// A shelf detail with its `role`, `shared` block, `owner` and rows.
class SharedShelfDetail {
  const SharedShelfDetail({required this.shelf, this.series = const [], this.isSmart = false});
  final SharedShelf shelf;
  final List<ShelfSeriesRow> series;
  final bool isSmart;

  factory SharedShelfDetail.fromJson(Map<String, dynamic> j) => SharedShelfDetail(
        shelf: SharedShelf.fromJson(j),
        series: [for (final e in (j['series'] as List? ?? const [])) if (e is Map) ShelfSeriesRow.fromJson(Map<String, dynamic>.from(e))],
        isSmart: j['rules'] != null,
      );
}

/// One recipient of a sent letter: "Not opened yet" (`new`) or "Opened" (the server reports nothing finer).
class SentRecipient extends ProfileRef {
  const SentRecipient({required super.profileId, required super.name, super.avatarKey, super.username, this.opened = false});
  final bool opened;

  factory SentRecipient.fromJson(Map<String, dynamic> j) {
    final p = ProfileRef.fromJson(j);
    return SentRecipient(profileId: p.profileId, name: p.name, avatarKey: p.avatarKey, username: p.username, opened: j['state'] != 'new');
  }
}

/// A row of `GET /circle/letters?box=sent` (glass 9.3.1, 15.5): one send to one or more recipients.
class SentLetter {
  const SentLetter({required this.id, required this.to, required this.sourceId, required this.seriesKey, this.title = '', this.coverUrl, this.contentKind, this.note, this.createdAt});
  final String id;
  final List<SentRecipient> to;
  final String sourceId, seriesKey, title;
  final String? coverUrl, contentKind, note;
  final DateTime? createdAt;

  factory SentLetter.fromJson(Map<String, dynamic> j) {
    final s = CircleSeries.fromJson(j);
    return SentLetter(
      id: '${j['id']}',
      to: [for (final e in (j['to'] as List? ?? const [])) if (e is Map) SentRecipient.fromJson(Map<String, dynamic>.from(e))],
      sourceId: s.sourceId,
      seriesKey: s.seriesKey,
      title: s.title,
      coverUrl: s.coverUrl,
      contentKind: s.contentKind,
      note: j['note'] as String?,
      createdAt: _date(j['created_at']),
    );
  }
}
