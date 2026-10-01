import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/repositories/circle_repository.dart';
import 'package:manhwamaniacs/features/library/models/ambient.dart';

const riya = ProfileRef(profileId: 2, name: 'Riya', username: 'riya');
const arjun = ProfileRef(profileId: 3, name: 'Arjun', username: 'arjun');

/// A configurable in-memory [CircleRepository] for provider and widget tests; every call is
/// recorded in [log].
class FakeCircleRepository implements CircleRepository {
  FakeCircleRepository({
    this.membersList = const [],
    this.feedItems = const [],
    this.letterList = const [],
    this.reactionList = const [],
    this.memberPage,
    Sharing? sharingValue,
    this.seriesData,
    ({List<SharedShelf> collections, List<SharedShelf> sharedWithMe})? shared,
    this.detail,
  })  : sharingValue = sharingValue ?? const Sharing(),
        shared = shared ?? (collections: <SharedShelf>[], sharedWithMe: <SharedShelf>[]);

  List<CircleMember> membersList;
  List<FeedItem> feedItems;
  List<Letter> letterList;
  List<ChapterReactions> reactionList;
  MemberPage? memberPage;
  Sharing sharingValue;
  CircleSeriesData? seriesData;
  ({List<SharedShelf> collections, List<SharedShelf> sharedWithMe}) shared;
  SharedShelfDetail? detail;

  /// Set to make the next calls fail.
  AppError? failWith;
  AppError? failReact, failPatchLetter, failSend, failSharing;
  final log = <String>[];
  final patches = <Map<String, Object?>>[];
  final sent = <({List<int> to, String? note})>[];

  Result<T> _r<T>(T v, [AppError? e]) => (e ?? failWith) != null ? Err((e ?? failWith)!) : Ok(v);

  @override
  Future<Result<CircleSeriesData?>> series({required String sourceId, required String seriesKey}) async => _r(seriesData ?? const CircleSeriesData());

  @override
  Future<Result<List<CircleMember>>> members({String? sourceId, String? seriesKey}) async {
    log.add('members');
    return _r(membersList);
  }

  @override
  Future<Result<MemberPage>> member(int profileId) async {
    log.add('member $profileId');
    if (memberPage == null && failWith == null) return const Err(ApiError(statusCode: 404, code: 'circle_member_not_sharing', message: 'x'));
    return _r(memberPage!);
  }

  @override
  Future<Result<FeedPage>> feed({String? cursor, int limit = 50, String? kind, int? profileId}) async {
    log.add('feed ${kind ?? 'all'} ${cursor ?? ''}');
    final items = kind == 'reading' ? feedItems.where((i) => i.kind != FeedKind.reacted).toList() : kind == 'reaction' ? feedItems.where((i) => i.kind == FeedKind.reacted).toList() : feedItems;
    return _r(FeedPage(items: items));
  }

  @override
  Future<Result<List<ChapterReactions>>> reactions({required String sourceId, required String seriesKey}) async => _r(reactionList);

  @override
  Future<Result<ChapterReactions>> react({required String sourceId, required String seriesKey, required String chapterKey, required ReactionKind kind}) async {
    log.add('react $chapterKey ${kind.wire}');
    if (failReact != null) return Err(failReact!);
    return Ok(ChapterReactions(chapterKey: chapterKey, counts: {for (final k in ReactionKind.values) k: k == kind ? 1 : 0}, total: 1, mine: kind, sealed: false));
  }

  @override
  Future<Result<void>> unreact({required String sourceId, required String seriesKey, required String chapterKey}) async {
    log.add('unreact $chapterKey');
    if (failReact != null) return Err(failReact!);
    return const Ok(null);
  }

  @override
  Future<Result<List<Letter>>> letters() async => _r(letterList);

  @override
  Future<Result<void>> sendLetter({required List<int> toProfileIds, required String sourceId, required String seriesKey, String? note, int? asProfileId}) async {
    log.add('send ${toProfileIds.join(',')}');
    if (failSend != null) return Err(failSend!);
    sent.add((to: toProfileIds, note: note));
    return const Ok(null);
  }

  @override
  Future<Result<Letter>> patchLetter(int id, LetterState state) async {
    log.add('patchLetter $id ${state.wire}');
    if (failPatchLetter != null) return Err(failPatchLetter!);
    return Ok(letterList.firstWhere((l) => l.id == id).copyWith(state: state));
  }

  @override
  Future<Result<Sharing>> sharing(int profileId) async => _r(sharingValue);

  @override
  Future<Result<Sharing>> patchSharing(int profileId, Map<String, Object?> partial) async {
    patches.add(partial);
    if (failSharing != null) return Err(failSharing!);
    return Ok(sharingValue = Sharing(
      activity: partial['activity'] as bool? ?? sharingValue.activity,
      reactions: partial['reactions'] as bool? ?? sharingValue.reactions,
      shelves: partial['shelves'] as bool? ?? sharingValue.shelves,
      recommendations: partial['recommendations'] as bool? ?? sharingValue.recommendations,
      includeMature: partial['include_mature'] as bool? ?? sharingValue.includeMature,
      showPresence: sharingValue.showPresence,
      shareStreak: sharingValue.shareStreak,
      excludedSeries: partial.containsKey('excluded_series')
          ? [for (final e in partial['excluded_series']! as List) ExcludedSeries(sourceId: (e as Map)['source_id'] as String, seriesKey: e['series_key'] as String)]
          : sharingValue.excludedSeries,
    ),);
  }

  @override
  Future<Result<void>> clearActivity() async {
    log.add('clearActivity');
    return _r(null);
  }

  @override
  Future<Result<({List<SharedShelf> collections, List<SharedShelf> sharedWithMe})>> collectionsWithShared() async => _r(shared);

  @override
  Future<Result<SharedShelfDetail>> shelfDetail(int id) async => _r(detail!);

  @override
  Future<Result<void>> shareCollection(int id, {required List<int> profileIds, required String mode}) async {
    log.add('share $id ${profileIds.join(',')} $mode');
    return _r(null);
  }

  @override
  Future<Result<void>> unshareMember(int id, String profileRef) async {
    log.add('unshare $id $profileRef');
    return _r(null);
  }
}

CircleMember member(ProfileRef p, {CircleNow? now, bool? canReceive, CircleShares shares = const CircleShares(activity: true, reactions: true, shelves: true, recommendations: true)}) =>
    CircleMember(profileId: p.profileId, name: p.name, username: p.username, shares: shares, now: now, canReceive: canReceive);

CircleNow nowReading({String title = 'Omniscient Reader', Ambient? ambient, double chapter = 212}) =>
    CircleNow(sourceId: 's', seriesKey: 'or', chapterKey: 'c${chapter.toInt()}', chapterNumber: chapter, title: title, ambient: ambient);

FeedItem feedItem(String id, FeedKind kind, {ProfileRef actor = riya, double? n, ReactionKind? reaction, bool? sealed, bool followed = false, DateTime? at, String title = 'Omniscient Reader', String seriesKey = 'or'}) =>
    FeedItem(id: id, kind: kind, actor: actor, sourceId: 's', seriesKey: seriesKey, title: title, chapterKey: n == null ? null : 'c${n.toInt()}', chapterNumber: n, reaction: reaction, sealed: sealed, followedByViewer: followed, createdAt: at ?? DateTime.now().toUtc());

Letter letter(int id, {ProfileRef from = riya, LetterState state = LetterState.newLetter, String? note = "you'll love the tower arc.", String title = 'Tower of God'}) =>
    Letter(id: id, from: from, sourceId: 's', seriesKey: 'tog$id', title: title, note: note, state: state, createdAt: DateTime.now().toUtc());
