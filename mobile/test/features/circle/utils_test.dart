import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/utils/dispatch.dart';
import 'package:manhwamaniacs/features/circle/utils/letters.dart';
import 'package:manhwamaniacs/features/circle/utils/presence.dart';
import 'package:manhwamaniacs/features/circle/utils/reaction_kinds.dart';
import 'package:manhwamaniacs/features/circle/utils/sharing_patch.dart';
import 'package:manhwamaniacs/features/circle/utils/spoiler_guard.dart';
import 'package:manhwamaniacs/features/library/models/ambient.dart';

const riya = ProfileRef(profileId: 2, name: 'Riya');

FeedItem item(FeedKind k, {double? n, ReactionKind? r, DateTime? at}) => FeedItem(id: '1', kind: k, actor: riya, sourceId: 's', seriesKey: 'k', title: 'Omniscient Reader', chapterNumber: n, reaction: r, createdAt: at);

void main() {
  group('reaction kinds', () {
    test('seven in stored order, five offered, wire names', () {
      expect(reactionSpecs.map((s) => s.kind), ReactionKind.values);
      expect(reactionSpecs.where((s) => s.offered).length, 5);
      expect(ReactionKind.chefsKiss.wire, 'chefs_kiss');
      expect(ReactionKind.tryParse('chefs_kiss'), ReactionKind.chefsKiss);
      expect(reactionSpec(ReactionKind.hype).stampText, 'HYPE');
    });
    test('press sets, moves and clears', () {
      expect(pressReaction(null, ReactionKind.loved), isA<SetReaction>());
      expect((pressReaction(ReactionKind.loved, ReactionKind.shook) as SetReaction).kind, ReactionKind.shook);
      expect(pressReaction(ReactionKind.loved, ReactionKind.loved), isA<ClearReaction>());
    });
  });

  group('spoiler guard', () {
    bool g({bool own = false, bool? sealed, bool local = false, bool session = false}) => isGuarded(isOwn: own, sealed: sealed, completedLocally: local, completedThisSession: session);
    test('unread and half-read chapters are sealed by the server', () => expect(g(sealed: true), isTrue));
    test('a finished chapter is open', () => expect(g(sealed: false), isFalse));
    test('unknown hides', () => expect(g(), isTrue));
    test('own reactions are never guarded', () => expect(g(own: true, sealed: true), isFalse));
    test('completed locally or this session unseals', () {
      expect(g(sealed: true, local: true), isFalse);
      expect(g(sealed: true, session: true), isFalse);
    });
    test('the session set', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(completedThisSessionProvider.notifier).markCompleted('s', 'k', '142');
      expect(c.read(completedThisSessionProvider), {chapterId('s', 'k', '142')});
    });
  });

  group('dispatch', () {
    String t(FeedItem i, [bool guarded = false]) => dispatchText(i, guarded);
    test('sentences', () {
      expect(t(item(FeedKind.started)), 'Riya started Omniscient Reader.');
      expect(t(item(FeedKind.finishedChapter, n: 142)), 'Riya finished chapter 142 of Omniscient Reader.');
      expect(t(item(FeedKind.finishedChapter, n: 12.5)), 'Riya finished chapter 12.5 of Omniscient Reader.');
      expect(t(item(FeedKind.finishedSeries)), 'Riya finished Omniscient Reader.');
      expect(t(item(FeedKind.reacted, n: 142, r: ReactionKind.loved)), 'Riya reacted Loved to chapter 142 of Omniscient Reader.');
      expect(t(item(FeedKind.reacted, n: 142, r: ReactionKind.loved), true), 'Riya reacted to chapter 142 of Omniscient Reader.');
      expect(t(item(FeedKind.reacted, r: ReactionKind.loved), true), 'Riya reacted to a chapter of Omniscient Reader.');
    });
    test('runs mark names italic and carry the reaction', () {
      final p = dispatchParts(item(FeedKind.reacted, n: 1, r: ReactionKind.tears), false);
      expect(p.first.italic, isTrue);
      expect(p.where((r) => r.reaction == ReactionKind.tears), hasLength(1));
    });
    test('day groups', () {
      final now = DateTime(2026, 9, 30, 10);
      expect(dayLabel(DateTime(2026, 9, 30, 1), now), 'TODAY');
      expect(dayLabel(DateTime(2026, 9, 29, 23), now), 'YESTERDAY');
      expect(dayLabel(DateTime(2026, 9, 21, 9), now), 'MON 21 SEP');
      final g = dayGroups([item(FeedKind.started, at: DateTime(2026, 9, 30, 9)), item(FeedKind.started, at: DateTime(2026, 9, 30, 8)), item(FeedKind.started, at: DateTime(2026, 9, 29, 8))], now);
      expect(g.map((e) => (e.label, e.items.length)), [('TODAY', 2), ('YESTERDAY', 1)]);
    });
  });

  group('letters', () {
    test('newCount and toast', () {
      Letter l(LetterState s) => Letter(id: 1, from: riya, sourceId: 's', seriesKey: 'k', state: s);
      expect(newCount([l(LetterState.newLetter), l(LetterState.read), l(LetterState.newLetter), l(LetterState.kept)]), 2);
      expect(sendToast(['Riya']), 'Sent to Riya.');
      expect(sendToast(['Riya', 'Arjun']), 'Sent to Riya and Arjun.');
      expect(sendToast(['Riya', 'Arjun', 'Mei']), 'Sent to Riya, Arjun and Mei.');
    });
    test('visibleFraction', () {
      const vp = Rect.fromLTWH(0, 0, 100, 100);
      expect(visibleFraction(const Rect.fromLTWH(0, 0, 100, 50), vp), 1);
      expect(visibleFraction(const Rect.fromLTWH(0, 75, 100, 50), vp), 0.5);
      expect(visibleFraction(const Rect.fromLTWH(0, 200, 100, 50), vp), 0);
      expect(letterReadAfter.inMilliseconds, 2000);
    });
  });

  group('sharingPatch', () {
    const base = Sharing();
    test('only changed keys, never presence or streak', () {
      expect(sharingPatch(base, base.copyWith(activity: true)), {'activity': true});
      expect(sharingPatch(base, base.copyWith(showPresence: true)), {'show_presence': true});
      expect(sharingPatch(base, base.copyWith(shareStreak: true)), {'share_streak': true});
      expect(sharingPatch(base.copyWith(showPresence: true, shareStreak: true), base.copyWith(showPresence: true, shareStreak: true)), isEmpty);
      expect(sharingPatch(base, base.copyWith(includeMature: true, reactions: false)), {'include_mature': true, 'reactions': false});
    });
    test('excluded_series is sent whole', () {
      const a = ExcludedSeries(sourceId: 's', seriesKey: 'a', title: 'A');
      const b = ExcludedSeries(sourceId: 's', seriesKey: 'b', title: 'B');
      final one = base.copyWith(excludedSeries: [a]);
      final two = base.copyWith(excludedSeries: [a, b]);
      expect(sharingPatch(one, two)['excluded_series'], [
        {'source_id': 's', 'series_key': 'a'},
        {'source_id': 's', 'series_key': 'b'},
      ]);
      expect(sharingPatch(two, two), isEmpty);
    });
  });

  group('presence', () {
    const amb = Ambient(duo: Color(0xFF112233), tint: Color(0xFF000000), ink: Color(0xFFFFFFFF));
    CircleNow now({Ambient? a}) => CircleNow(sourceId: 's', seriesKey: 'k', chapterKey: 'c212', chapterNumber: 212, title: 'Omniscient Reader', ambient: a);
    test('ring colour falls back', () {
      expect(ringColour(now(a: amb)), const Color(0xFF112233));
      expect(ringColour(now()), const Color(0xFFB8B2A4));
    });
    test('the chapter folio only with stored progress', () {
      expect(nowLabel(now(), {'s:k:c212'}), 'Reading Omniscient Reader · CH 212');
      expect(nowLabel(now(), {}), 'Reading Omniscient Reader');
    });
  });

  test('models parse the circle-api examples', () {
    final p = ChapterReactions.fromJson({'chapter_key': 'c', 'counts': {'hype': 1}, 'by': [{'profile_id': 2, 'name': 'R', 'kind': 'hype'}]});
    expect(p.countOf(ReactionKind.hype), 1);
    expect(p.total, 1);
    final m = CircleMember.fromJson({'profile_id': 2, 'name': 'Riya', 'shares': {'activity': true}, 'now': {'source_id': 's', 'series_key': 'k', 'chapter_key': 'c', 'ambient': {'duo': '#112233', 'tint': '#000000', 'ink': '#ffffff'}}, 'unknown': 1});
    expect(m.now!.ambient!.duo, const Color(0xFF112233));
    expect(m.canReceive, isNull);
    final f = FeedItem.fromJson({'id': 9, 'kind': 'finished_chapter', 'actor': {'profile_id': 2, 'name': 'Riya'}, 'source_id': 's', 'series_key': 'k', 'created_at': '2026-09-30T10:00:00'});
    expect(f.kind, FeedKind.finishedChapter);
    expect(f.createdAt!.isUtc, isTrue);
  });
}
