import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/circle/store/reaction_outbox.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_overrides.dart';
import 'fakes.dart';

const key = (sourceId: 's', seriesKey: 'or');
const me = ProfileRef(profileId: 1, name: 'Me');

/// Pages on a cursor; a page request waits on [gate] when set.
class _Paging extends FakeCircleRepository {
  _Paging(List<FeedItem> first) : super(feedItems: first);
  Completer<void>? gate;
  @override
  Future<Result<FeedPage>> feed({String? cursor, int limit = 50, String? kind, int? profileId}) async {
    log.add('feed ${cursor ?? ''}');
    if (cursor == null) return Ok(FeedPage(items: feedItems, nextCursor: 'p2'));
    await gate?.future;
    return Ok(FeedPage(items: [feedItem('old', FeedKind.started)], nextCursor: 'p3'));
  }
}

Future<(ProviderContainer, ReactionOutbox)> _withOutbox(FakeCircleRepository repo, {bool online = false}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final box = ReactionOutbox(prefs, 'u1p1');
  final c = ProviderContainer(overrides: [
    sharedPrefsProvider.overrideWithValue(prefs),
    activeProfileOverride(),
    circleRepositoryProvider.overrideWithValue(repo),
    reactionOutboxProvider.overrideWithValue(box),
    deviceOnlineProvider.overrideWith((ref) => online ? Stream.value(true) : const Stream<bool>.empty()),
  ],);
  addTearDown(c.dispose);
  return (c, box);
}

OutboxEntry _q(String ch, ReactionKind? k) => OutboxEntry(sourceId: 's', seriesKey: 'or', chapterKey: ch, kind: k, at: DateTime.utc(2026));

void main() {
  test('a loadMore landing after a refresh does not overwrite the fresh feed', () async {
    final repo = _Paging([feedItem('a', FeedKind.started)])..gate = Completer<void>();
    final c = ProviderContainer(overrides: [circleRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(c.dispose);
    final sub = c.listen(circleFeedProvider(null), (_, __) {});
    addTearDown(sub.close);
    await c.read(circleFeedProvider(null).future);
    final more = c.read(circleFeedProvider(null).notifier).loadMore();
    repo.feedItems = [feedItem('new', FeedKind.started), feedItem('a', FeedKind.started)];
    c.invalidate(circleFeedProvider(null));
    await c.read(circleFeedProvider(null).future);
    repo.gate!.complete();
    await more;
    expect(c.read(circleFeedProvider(null)).value!.items.map((i) => i.id), ['new', 'a']);
  });

  test("a member's feed marks a followed series", () async {
    final repo = FakeCircleRepository(feedItems: [feedItem('1', FeedKind.started)]);
    final c = ProviderContainer(overrides: [circleRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(c.dispose);
    await c.read(memberFeedProvider(2).future);
    c.read(memberFeedProvider(2).notifier).markFollowed('s', 'or');
    expect(c.read(memberFeedProvider(2)).value!.items.single.followedByViewer, isTrue);
  });

  test('queued reactions are drawn over the server answer', () async {
    final (c, box) = await _withOutbox(FakeCircleRepository());
    await box.enqueue(_q('c1', ReactionKind.loved));
    final list = await c.read(chapterReactionsProvider(key).future);
    expect(list.single.mine, ReactionKind.loved);
  });

  test('a cold start online flushes the outbox', () async {
    final repo = FakeCircleRepository();
    final (c, box) = await _withOutbox(repo, online: true);
    await box.enqueue(_q('c1', ReactionKind.loved));
    c.read(circleOutboxFlusherProvider);
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(repo.log, contains('react c1 loved'));
    expect(box.entries(), isEmpty);
  });

  test('a press sent online drops an older queued one for that chapter', () async {
    final repo = FakeCircleRepository();
    final (c, box) = await _withOutbox(repo);
    await box.enqueue(_q('c1', ReactionKind.loved));
    await c.read(chapterReactionsProvider(key).future);
    await c.read(chapterReactionsProvider(key).notifier).press('c1', ReactionKind.hype);
    expect(box.entries(), isEmpty);
  });

  test('clearing a reaction takes the viewer off the stamp', () async {
    final repo = FakeCircleRepository(reactionList: [
      ChapterReactions(chapterKey: 'c1', counts: const {ReactionKind.loved: 1}, total: 1, by: [ReactionBy.of(me, ReactionKind.loved)], mine: ReactionKind.loved),
    ],);
    final (c, _) = await _withOutbox(repo);
    await c.read(chapterReactionsProvider(key).future);
    await c.read(chapterReactionsProvider(key).notifier).press('c1', ReactionKind.loved);
    expect(c.read(chapterReactionsProvider(key)).value!.single.by, isEmpty);
  });

  test('sending a letter refreshes the sent box', () async {
    var builds = 0;
    final c = ProviderContainer(overrides: [
      circleRepositoryProvider.overrideWithValue(FakeCircleRepository()),
      sentLettersProvider.overrideWith((ref) async {
        builds++;
        return const <SentLetter>[];
      }),
    ],);
    addTearDown(c.dispose);
    final sub = c.listen(sentLettersProvider, (_, __) {});
    addTearDown(sub.close);
    await c.read(sentLettersProvider.future);
    await c.read(circleActionsProvider).sendLetter(toProfileIds: [2], sourceId: 's', seriesKey: 'or');
    await c.read(sentLettersProvider.future);
    expect(builds, 2);
  });
}
