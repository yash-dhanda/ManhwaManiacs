import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_poll.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/circle/store/reaction_outbox.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

ProviderContainer _c(FakeCircleRepository repo) {
  final c = ProviderContainer(overrides: [
    circleRepositoryProvider.overrideWithValue(repo),
    reactionOutboxProvider.overrideWithValue(null),
  ],);
  addTearDown(c.dispose);
  return c;
}

const key = (sourceId: 's', seriesKey: 'or');

void main() {
  group('poll controller', () {
    test('one 60 s timer while a scope is visible and the app is resumed', () {
      fakeAsync((async) {
        var ticks = 0;
        final c = CirclePollController(onTick: () => ticks++);
        final a = Object(), b = Object();
        expect(c.running, isFalse);
        c.register(a, visible: true);
        c.register(b, visible: true);
        expect(c.running, isTrue);
        async.elapse(const Duration(seconds: 130));
        expect(ticks, 2);
        c.setVisible(a, false); // covered by a route
        expect(c.running, isTrue); // b still visible
        c.setVisible(b, false); // branch offstage
        expect(c.running, isFalse);
        async.elapse(const Duration(seconds: 130));
        expect(ticks, 2);
        c.setVisible(a, true);
        c.setResumed(false); // app paused
        expect(c.running, isFalse);
        async.elapse(const Duration(minutes: 5));
        expect(ticks, 2);
        c.setResumed(true);
        expect(c.running, isTrue);
        c.unregister(a);
        expect(c.running, isFalse);
        c.dispose();
      });
    });
  });

  group('outbox', () {
    OutboxEntry e(String ch, ReactionKind? k, int at) => OutboxEntry(sourceId: 's', seriesKey: 'or', chapterKey: ch, kind: k, at: DateTime.utc(2026, 1, 1, 0, 0, at));

    test('the last write per chapter wins and profiles are isolated', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final a = ReactionOutbox(prefs, 'u1p1'), b = ReactionOutbox(prefs, 'u1p2');
      await a.enqueue(e('c1', ReactionKind.loved, 1));
      await a.enqueue(e('c2', ReactionKind.tears, 2));
      await a.enqueue(e('c1', null, 3));
      expect(a.entries().map((x) => (x.chapterKey, x.kind)), [('c2', ReactionKind.tears), ('c1', null)]);
      expect(b.entries(), isEmpty);
      expect(a.pending('s', 'or', 'c1'), (true, null));
    });

    test('flush sends oldest first, stops at a network error, drops refusals', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final box = ReactionOutbox(prefs, 'u1p1');
      await box.enqueue(e('c2', ReactionKind.tears, 2));
      await box.enqueue(e('c1', ReactionKind.loved, 1));
      final repo = FakeCircleRepository();
      expect(await box.flush(repo), 2);
      expect(repo.log, ['react c1 loved', 'react c2 tears']);
      expect(box.entries(), isEmpty);
      await box.enqueue(e('c3', ReactionKind.hype, 3));
      repo.failReact = const NetworkError(message: 'x');
      expect(await box.flush(repo, isNetwork: (x) => x is NetworkError), 0);
      expect(box.entries(), hasLength(1));
      repo.failReact = const ApiError(statusCode: 422, code: 'validation_error', message: 'x');
      await box.flush(repo, isNetwork: (x) => x is NetworkError);
      expect(box.entries(), isEmpty);
    });
  });

  group('reactions', () {
    test('press draws at once, sets, moves and clears', () async {
      final repo = FakeCircleRepository();
      final c = _c(repo);
      await c.read(chapterReactionsProvider(key).future);
      final n = c.read(chapterReactionsProvider(key).notifier);
      unawaited(n.press('c142', ReactionKind.loved));
      expect(c.read(chapterReactionsProvider(key)).value!.single.mine, ReactionKind.loved);
      await Future<void>.delayed(Duration.zero);
      await n.press('c142', ReactionKind.shook);
      expect(repo.log, containsAllInOrder(['react c142 loved', 'react c142 shook']));
      expect(c.read(chapterReactionsProvider(key)).value!.single.mine, ReactionKind.shook);
      await n.press('c142', ReactionKind.shook);
      expect(repo.log.last, 'unreact c142');
      expect(c.read(chapterReactionsProvider(key)).value!.single.mine, isNull);
    });

    test('a refusal rolls back', () async {
      final repo = FakeCircleRepository()..failReact = const ApiError(statusCode: 422, code: 'validation_error', message: 'x');
      final c = _c(repo);
      await c.read(chapterReactionsProvider(key).future);
      await c.read(chapterReactionsProvider(key).notifier).press('c1', ReactionKind.loved);
      expect(c.read(chapterReactionsProvider(key)).value, isEmpty);
    });

    test('offline keeps the drawn state', () async {
      final repo = FakeCircleRepository()..failReact = const NetworkError(message: 'x');
      final c = _c(repo);
      await c.read(chapterReactionsProvider(key).future);
      await c.read(chapterReactionsProvider(key).notifier).press('c1', ReactionKind.loved);
      expect(c.read(chapterReactionsProvider(key)).value!.single.mine, ReactionKind.loved);
    });
  });

  group('letters and sharing', () {
    test('patch is optimistic and restored on failure', () async {
      final repo = FakeCircleRepository(letterList: [letter(1), letter(2)]);
      final c = _c(repo);
      await c.read(lettersProvider.future);
      expect(c.read(newLetterCountProvider), 2);
      expect(await c.read(lettersProvider.notifier).patch(1, LetterState.kept), isTrue);
      expect(c.read(newLetterCountProvider), 1);
      expect(await c.read(lettersProvider.notifier).patch(2, LetterState.dismissed), isTrue);
      expect(c.read(lettersProvider).value!.map((l) => l.id), [1]);
      repo.failPatchLetter = const NetworkError(message: 'x');
      expect(await c.read(lettersProvider.notifier).patch(1, LetterState.read), isFalse);
      expect(c.read(lettersProvider).value!.single.state, LetterState.kept);
    });

    test('sharing patch sends only the changed key', () async {
      final repo = FakeCircleRepository();
      final c = _c(repo);
      final s = await c.read(sharingProvider(1).future);
      expect(await c.read(sharingProvider(1).notifier).patch(s.copyWith(activity: true)), isTrue);
      expect(repo.patches, [
        {'activity': true},
      ]);
      expect(await c.read(sharingProvider(1).notifier).patch(c.read(sharingProvider(1)).value!), isTrue);
      expect(repo.patches, hasLength(1));
      repo.failSharing = const NetworkError(message: 'x');
      expect(await c.read(sharingProvider(1).notifier).patch(c.read(sharingProvider(1)).value!.copyWith(reactions: false)), isFalse);
      expect(c.read(sharingProvider(1)).value!.reactions, isTrue);
    });
  });

  group('feed and recipients', () {
    test('recipients keep canReceive members only', () async {
      final repo = FakeCircleRepository(membersList: [member(riya, canReceive: true), member(arjun, canReceive: false)]);
      final c = _c(repo);
      expect((await c.read(recipientsProvider(key).future)).map((m) => m.name), ['Riya']);
    });

    test('markFollowed flips every dispatch of the series', () async {
      final repo = FakeCircleRepository(feedItems: [feedItem('1', FeedKind.started), feedItem('2', FeedKind.finishedChapter, n: 3)]);
      final c = _c(repo);
      await c.read(circleFeedProvider(null).future);
      c.read(circleFeedProvider(null).notifier).markFollowed('s', 'or');
      expect(c.read(circleFeedProvider(null)).value!.items.every((i) => i.followedByViewer), isTrue);
    });
  });
}
