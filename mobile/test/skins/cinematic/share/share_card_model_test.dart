import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/utils/streak_state.dart';
import 'package:manhwamaniacs/skins/cinematic/share/share_card_model.dart';

import '../../../support/numbers_fixtures.dart';

void main() {
  test('annual: six templates in order with the spec captions', () {
    final ts = shareTemplates(ShareInput.annual(annualFixture(), 'Yash'));
    expect(ts.map((t) => t.id), [ShareId.time, ShareId.chapters, ShareId.no1, ShareId.genres, ShareId.streak, ShareId.clock]);
    expect(ts[0].figure, '212');
    expect(ts[0].caption, 'hours of reading in 2026.');
    expect(ts[1].figure, '4,812');
    expect(ts[1].caption, 'chapters in 2026.');
    expect(ts[2].figure, 'No. 1');
    expect(ts[2].caption, 'Solo Leveling: 38 chapters, 12 hours.');
    expect(ts[3].figure, 'Fantasy');
    expect(ts[3].caption, '50 % of my reading, then Romance and Action.');
    expect(ts[4].figure, '31');
    expect(ts[4].caption, 'days in a row, my longest in 2026.');
    expect(ts[4].tier, StreakTier.ring);
    expect(ts[5].figure, '76 %');
    expect(ts[5].caption, 'of my reading after 22:00.');
    expect(ts.every((t) => t.kicker == 'THE ANNUAL 2026' && t.profileName == 'Yash'), isTrue);
  });

  test('range: kicker and phrases; YEAR says "the last year"', () {
    final ts = shareTemplates(ShareInput.range(statisticsFixture(), 30, 'Yash'));
    expect(ts.first.kicker, 'THE NUMBERS · 30 DAYS');
    expect(ts.first.caption, 'hours of reading in the last 30 days.');
    expect(ts.firstWhere((t) => t.id == ShareId.streak).caption, 'days in a row, and counting.');
    final year = shareTemplates(ShareInput.range(statisticsFixture(days: 365), 365, 'Yash'));
    expect(year.first.kicker, 'THE NUMBERS · YEAR');
    expect(year.first.caption, 'hours of reading in the last year.');
  });

  test('a streak of zero falls back to the longest streak', () {
    final ts = shareTemplates(ShareInput.range(statisticsFixture(currentDays: 0), 30, 'Yash'));
    final streak = ts.firstWhere((t) => t.id == ShareId.streak);
    expect(streak.figure, '31');
    expect(streak.caption, 'days in a row, my longest.');
  });

  test('templates without shareable data are omitted', () {
    final a = annualFixture(withShareable: false);
    final ts = shareTemplates(ShareInput.annual(a, 'Y'));
    expect(ts.map((t) => t.id), isNot(contains(ShareId.no1)));
    expect(ts.map((t) => t.id), isNot(contains(ShareId.genres)));
    expect(ts.map((t) => t.id), contains(ShareId.time));
    final empty = shareTemplates(ShareInput.range(statisticsFixture(neverRead: true), 30, 'Y'));
    expect(empty, isEmpty);
  });

  test('genres: one and two genre captions', () {
    final one = annualJson();
    (one['shareable'] as Map)['genre_weights'] = [
      {'genre': 'Fantasy', 'weight': 1.0},
    ];
    final two = annualJson();
    (two['shareable'] as Map)['genre_weights'] = [
      {'genre': 'Fantasy', 'weight': 0.7},
      {'genre': 'Drama', 'weight': 0.3},
    ];
    String cap(Map<String, dynamic> j) => shareTemplates(ShareInput.annual(annualFromJson(j), 'Y')).firstWhere((t) => t.id == ShareId.genres).caption;
    expect(cap(one), '100 % of my reading.');
    expect(cap(two), '70 % of my reading, then Drama.');
  });

  test('under one hour the figure is minutes', () {
    final j = annualJson();
    j['seconds_read'] = 1500;
    final t = shareTemplates(ShareInput.annual(annualFromJson(j), 'Y')).first;
    expect(t.figure, '25');
    expect(t.caption, 'minutes of reading in 2026.');
  });

  test('milestone offers the Streak template only', () {
    final ts = shareTemplates(ShareInput.milestone(30, StreakTier.ring, 'Yash', year: 2026));
    expect(ts.single.id, ShareId.streak);
    expect(ts.single.caption, 'days in a row.');
    expect(ts.single.kicker, 'THE ANNUAL 2026');
  });

  test('a non-shareable mature title never reaches a template', () {
    final j = annualJson();
    (j['top_series'] as List).insert(0, {'source_id': 'x', 'series_key': 'm', 'title': 'MATURE SECRET', 'cover_url': '/c', 'seconds_read': 99999, 'chapters_read': 999});
    final ts = shareTemplates(ShareInput.annual(annualFromJson(j), 'Y'));
    expect(ts.expand((t) => [t.figure, t.caption]).join(' '), isNot(contains('MATURE SECRET')));
  });

  test('file names and sizes', () {
    expect(shareFileName(ShareId.no1, ShareFormat.story), 'manhwamaniacs-no1-story.png');
    expect(shareFileName(ShareId.clock, ShareFormat.post), 'manhwamaniacs-clock-post.png');
    expect(shareSize(ShareFormat.story).height, 1920);
    expect(shareSize(ShareFormat.post).height, 1350);
  });
}
