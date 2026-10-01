import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/repositories/library_repository.dart';
import 'package:manhwamaniacs/skins/glass/screens/circle/circle_screen.dart';

import '../../../features/circle/fakes.dart';
import '../shell/shell_rig.dart';

/// mobile/43's fixtures, built from the backend/08 and 09 response shapes: four members (reading, today, away with a streak,
/// and one whose `now` is null though they read 5 minutes ago), a feed with a collapsible run, an open and a guarded reaction
/// and an unfollowed start, two letters (new, kept), one sent letter, a shared shelf and a friend page.

final DateTime circleNow = DateTime(2026, 10, 1, 21);

const aarav = ProfileRef(profileId: 2, name: 'Aarav', avatarKey: 'violet', username: 'aarav');
const mira = ProfileRef(profileId: 3, name: 'Mira', avatarKey: 'cyan', username: 'mira');
const kai = ProfileRef(profileId: 4, name: 'Kai', avatarKey: 'rose', username: 'kai');
const noor = ProfileRef(profileId: 5, name: 'Noor', avatarKey: 'amber', username: 'noor');

const _all = CircleShares(activity: true, reactions: true, shelves: true, recommendations: true);

List<CircleMember> circleMembers() => [
      CircleMember(profileId: 4, name: 'Kai', avatarKey: 'rose', username: 'kai', shares: _all, lastActiveAt: circleNow.subtract(const Duration(days: 3)), streak: const CircleStreak(currentDays: 12)),
      CircleMember(profileId: 3, name: 'Mira', avatarKey: 'cyan', username: 'mira', shares: _all, lastActiveAt: circleNow.subtract(const Duration(hours: 2))),
      CircleMember(profileId: 5, name: 'Noor', avatarKey: 'amber', username: 'noor', shares: _all, lastActiveAt: circleNow.subtract(const Duration(minutes: 5))),
      CircleMember(
        profileId: 2,
        name: 'Aarav',
        avatarKey: 'violet',
        username: 'aarav',
        shares: _all,
        now: CircleNow(sourceId: 's', seriesKey: 'or', chapterKey: 'c212', title: 'Omniscient Reader', since: circleNow.subtract(const Duration(minutes: 5))),
        lastActiveAt: circleNow.subtract(const Duration(minutes: 5)),
      ),
    ];

FeedItem _f(String id, FeedKind k, ProfileRef who, {String series = 'solo', String title = 'Solo Leveling', double? n, ReactionKind? r, bool? sealed, bool followed = true, required Duration ago}) => FeedItem(
      id: id,
      kind: k,
      actor: who,
      sourceId: 's',
      seriesKey: series,
      title: title,
      chapterKey: n == null ? null : 'c${n.toInt()}',
      chapterNumber: n,
      reaction: r,
      sealed: sealed,
      followedByViewer: followed,
      createdAt: circleNow.subtract(ago).toUtc(),
    );

List<FeedItem> circleFeed() => [
      _f('a3', FeedKind.finishedChapter, aarav, n: 152, ago: const Duration(minutes: 40)),
      _f('a2', FeedKind.finishedChapter, aarav, n: 141, ago: const Duration(minutes: 50)),
      _f('a1', FeedKind.finishedChapter, aarav, n: 140, ago: const Duration(minutes: 60)),
      _f('m1', FeedKind.reacted, mira, series: 'or', title: 'Omniscient Reader', n: 88, r: ReactionKind.hype, sealed: false, ago: const Duration(hours: 2)),
      _f('k1', FeedKind.reacted, kai, series: 'or', title: 'Omniscient Reader', n: 212, r: ReactionKind.wrecked, sealed: true, ago: const Duration(hours: 3)),
      _f('m0', FeedKind.started, mira, series: 'ob', title: 'Omniscient Reader', followed: false, ago: const Duration(days: 1)),
    ];

List<Letter> circleLetters() => [
      Letter(id: 1, from: aarav, sourceId: 's', seriesKey: 'tog', title: 'Tower of God', note: "You'll love the tower arc.", createdAt: circleNow.toUtc()),
      Letter(id: 2, from: mira, sourceId: 's', seriesKey: 'bh', title: 'Blue Hour', state: LetterState.kept, createdAt: circleNow.toUtc()),
    ];

List<SentLetter> circleSent() => [
      const SentLetter(id: 'g1', sourceId: 's', seriesKey: 'solo', title: 'Solo Leveling', to: [
        SentRecipient(profileId: 2, name: 'Aarav', avatarKey: 'violet'),
        SentRecipient(profileId: 3, name: 'Mira', avatarKey: 'cyan', opened: true),
      ],),
    ];

MemberPage aaravPage() => const MemberPage(
      profile: aarav,
      shares: _all,
      now: CircleNow(sourceId: 's', seriesKey: 'or', chapterKey: 'c212', title: 'Omniscient Reader'),
      reading: [MemberSeries(sourceId: 's', seriesKey: 'or', title: 'Omniscient Reader'), MemberSeries(sourceId: 's', seriesKey: 'solo', title: 'Solo Leveling')],
      reactions: [MemberSeries(sourceId: 's', seriesKey: 'or', title: 'Omniscient Reader', chapterKey: 'c212', chapterNumber: 212, reaction: ReactionKind.hype, sealed: true)],
    );

/// The fake repository with the friend filter on the feed.
class CircleFake extends FakeCircleRepository {
  CircleFake({super.membersList, super.feedItems, super.letterList, super.memberPage, super.sharingValue, super.shared, super.reactionList});

  @override
  Future<Result<FeedPage>> feed({String? cursor, int limit = 50, String? kind, int? profileId}) async {
    log.add('feed ${profileId ?? 'all'}');
    if (failWith != null) return Err(failWith!);
    return Ok(FeedPage(items: [for (final i in feedItems) if (profileId == null || i.actor.profileId == profileId) i]));
  }
}

CircleFake circleFake({bool sharing = true, List<CircleMember>? members, List<FeedItem>? feed, MemberPage? page, AppError? fail}) {
  final f = CircleFake(
    membersList: members ?? circleMembers(),
    feedItems: feed ?? circleFeed(),
    letterList: circleLetters(),
    memberPage: page ?? aaravPage(),
    sharingValue: Sharing(activity: sharing),
    shared: (
      collections: <SharedShelf>[],
      sharedWithMe: const [SharedShelf(id: 7, name: 'Weekend reads', seriesCount: 4, owner: aarav)],
    ),
  );
  f.failWith = fail;
  return f;
}

/// Records follow calls; answers with an error so no `FollowedSeries` fixture is needed.
class FollowRecorder implements LibraryRepository {
  final followed = <String>[];

  @override
  Future<Result<FollowedSeries>> follow({required String sourceId, required String seriesKey}) async {
    followed.add('$sourceId:$seriesKey');
    return const Err(NetworkError(message: 'test'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Letters extends LettersNotifier {
  @override
  Future<List<Letter>> build() async => (await ref.watch(circleRepositoryProvider).letters()).value;
}

/// The network-free Circle overrides around [repo] (letters through the repo, Sent letters, the fixed clock).
List<Override> circleOverrides(CircleFake repo) => [
      circleRepositoryProvider.overrideWithValue(repo),
      lettersProvider.overrideWith(_Letters.new),
      sentLettersProvider.overrideWith((ref) async => circleSent()),
      circleClockProvider.overrideWithValue(() => circleNow),
    ];

/// Pumps `/circle…` in the Glass shell with [repo].
Future<ShellRig> pumpCircle(WidgetTester t, CircleFake repo, {String start = '/circle', Size size = const Size(390, 844), List<Override> extra = const []}) async {
  final rig = await pumpGlassShell(
    t,
    start: start,
    size: size,
    extra: [...circleOverrides(repo), ...extra],
  );
  for (var i = 0; i < 20; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
  return rig;
}

Future<void> settle(WidgetTester t, [int ms = 1200]) async {
  for (var e = 0; e < ms; e += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Future<void> unmount(WidgetTester t) async {
  await t.pumpWidget(const SizedBox.shrink());
  await t.pump(const Duration(milliseconds: 100));
}

/// Every visible text, flattened.
String visibleText() => [
      for (final e in find.byType(Text, skipOffstage: false).evaluate()) ((e.widget as Text).data ?? (e.widget as Text).textSpan?.toPlainText() ?? '').replaceAll('\uFFFC', ''),
    ].join('\n');

/// Puts focus on an activity row (the screen's keys need focus inside it).
void focusRow(WidgetTester t, String id) {
  final f = find.byWidgetPredicate((w) => w is Focus && w.focusNode?.debugLabel == 'activity $id', skipOffstage: false);
  (t.widget(f.first) as Focus).focusNode!.requestFocus();
}
