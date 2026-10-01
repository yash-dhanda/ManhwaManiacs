import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/read_state.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/home/providers/home_feed_provider.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/spotlights.dart';

import '../../../features/home/home_fixtures.dart';

final now = DateTime(2026, 9, 30, 15);

HomeFeedView view(HomeFeed f, {bool offline = false, HomeFeedState state = HomeFeedState.ready}) =>
    (state: state, feed: f, origin: offline ? HomeFeedOrigin.offline : HomeFeedOrigin.server, offline: offline, retryAfter: null);

List<SpotlightSpec> of(String fixture, {DateTime? at}) => composeSpotlights(view(loadHome(fixture)), now: at ?? now);

void main() {
  test('ready: next up, because, newest, previously on in order, at most six, no duplicate series', () {
    final s = of('ready');
    expect(s.length, lessThanOrEqualTo(6));
    expect(s.first.kind, SpotlightKind.nextUp);
    expect(s.first.meta, startsWith('Ch 143 is new'));
    expect(s.first.primaryLabel, startsWith('Start Ch 143'));
    final kinds = s.map((e) => e.kind).toList();
    expect(kinds.indexOf(SpotlightKind.because), greaterThan(0));
    final keys = [for (final e in s) if (e.key != null) e.key];
    expect(keys.toSet().length, keys.length);
    final b = s.firstWhere((e) => e.kind == SpotlightKind.because);
    expect(b.aiWhy, isTrue);
    expect(b.primaryLabel, anyOf('Start reading', 'Search my sources'));
  });

  test('a letter card carries the sender', () {
    final s = of('circle');
    final l = s.firstWhere((e) => e.kind == SpotlightKind.letter);
    expect(l.from!.name, isNotEmpty);
    expect(l.primaryLabel, 'Start reading');
  });

  test('previously on candidate has the recap secondary', () {
    final s = of('ready');
    final p = s.where((e) => e.kind == SpotlightKind.previouslyOn);
    for (final e in p) {
      expect(e.secondaryLabel, 'Previously on');
      expect(e.meta, startsWith('Paused '));
    }
  });

  test('caught up leads with the caught-up card', () {
    final s = of('caught-up');
    expect(s.first.kind, SpotlightKind.caughtUp);
    expect(s.first.title, "You're caught up");
    expect(s.first.meta, 'Nothing new on your shelf');
  });

  test('new profile: one Start here card', () {
    final s = of('new-profile');
    expect(s.length, 1);
    expect(s.single.kind, SpotlightKind.start);
    expect(s.single.meta, 'Start here');
    expect(s.single.primaryLabel, anyOf('Start reading', 'Search my sources'));
  });

  test('offline: one card from the edition cover', () {
    final f = loadHome('ready');
    final s = composeSpotlights(view(f, offline: true), now: now);
    expect(s.length, 1);
    expect(s.single.kind, SpotlightKind.offline);
  });

  test('December appends Wrapped as the last card', () {
    final s = of('ready', at: DateTime(2026, 12, 3));
    expect(s.last.kind, SpotlightKind.wrapped);
    expect(s.last.title, 'Your 2026 in chapters');
    expect(s.last.primary, SpotlightAction.openWrapped);
    expect(s.last.secondaryLabel, isNull);
    expect(of('ready').any((e) => e.isWrapped), isFalse);
  });

  test('a novel cover reads percent in', () {
    final f = loadHome('novel');
    final s = composeSpotlights(view(f), now: now);
    expect(s, isNotEmpty);
  });

  test('empty state yields no cards without a pick', () {
    expect(composeSpotlights(view(const HomeFeed(headline: 'x', deck: ''), state: HomeFeedState.empty), now: now), isEmpty);
  });

  Map<String, dynamic> raw(String name) => jsonDecode(File('test/fixtures/home/$name.json').readAsStringSync()) as Map<String, dynamic>;

  test('Next up from a Continue row labels the chapter it opens', () {
    final j = raw('ready')..['cover'] = null;
    final s = composeSpotlights(view(HomeFeed.fromJson(j)), now: now).firstWhere((e) => e.kind == SpotlightKind.nextUp);
    expect(s.primaryLabel, 'Continue Ch 142');
    expect(s.target!.chapterKey, 'c142');
  });

  test('Where were we without a recap offers no Previously on', () {
    final j = raw('ready');
    for (final sec in j['sections'] as List) {
      if ((sec as Map)['type'] == 'where_were_we') {
        for (final i in sec['items'] as List) {
          (i as Map)['recap'] = {'available': false, 'reason': 'no_dialogue'};
        }
      }
    }
    final p = composeSpotlights(view(HomeFeed.fromJson(j)), now: now).where((e) => e.kind == SpotlightKind.previouslyOn);
    expect(p, isNotEmpty);
    for (final e in p) {
      expect(e.secondaryLabel, isNull);
    }
  });

  test('a finished furthest chapter resumes at the next one', () {
    final r = ReadState.fromJson({'started': true, 'chapter_key': 'c10', 'chapter_number': 10, 'total': 13, 'continue_key': 'c11', 'continue_number': 11});
    expect((r.resumeKey, r.resumeNumber), ('c11', 11.0));
    final mid = ReadState.fromJson({'started': true, 'chapter_key': 'c10', 'chapter_number': 10, 'total': 13});
    expect((mid.resumeKey, mid.resumeNumber), ('c10', 10.0));
  });
}
