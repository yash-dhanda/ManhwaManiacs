import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/annual.dart';
import 'package:manhwamaniacs/features/library/models/shareable.dart';
import 'package:manhwamaniacs/features/sources/models/source_genre.dart' show GenreWeight;
import 'package:manhwamaniacs/skins/cinematic/screens/annual/annual_copy.dart';

import '../../../support/numbers_fixtures.dart';

void main() {
  test('eleven pages with every section; ten without the circle page', () {
    final full = annualPages(annualFixture(circle: true));
    expect(full, hasLength(11));
    expect(annualPages(annualFixture()), hasLength(10));
    expect(full.map((p) => p.kind), [
      AnnualPageKind.cover,
      AnnualPageKind.time,
      AnnualPageKind.chapters,
      AnnualPageKind.no1,
      AnnualPageKind.genres,
      AnnualPageKind.clock,
      AnnualPageKind.streak,
      AnnualPageKind.sources,
      AnnualPageKind.circle,
      AnnualPageKind.colophon,
      AnnualPageKind.pressRun,
    ]);
  });

  test('holds: 6 s pages, 8 s lists, 12 s colophon, none for the press run', () {
    final by = {for (final p in annualPages(annualFixture(circle: true))) p.kind: p.hold};
    expect(by[AnnualPageKind.cover], const Duration(seconds: 6));
    expect(by[AnnualPageKind.no1], const Duration(seconds: 8));
    expect(by[AnnualPageKind.sources], const Duration(seconds: 8));
    expect(by[AnnualPageKind.colophon], const Duration(seconds: 12));
    expect(by[AnnualPageKind.pressRun], isNull);
  });

  test('empty data skips pages and the segments renumber', () {
    final j = annualJson();
    j['genres'] = <Object?>[];
    j['top_sources'] = <Object?>[];
    j['longest_streak'] = {'days': 0};
    j['circle'] = [
      {'profile_id': 2, 'name': 'Riya', 'finished_together': <Object?>[]},
    ];
    final pages = annualPages(annualFromJson(j)).map((p) => p.kind).toList();
    expect(pages, isNot(contains(AnnualPageKind.genres)));
    expect(pages, isNot(contains(AnnualPageKind.sources)));
    expect(pages, isNot(contains(AnnualPageKind.streak)));
    expect(pages, isNot(contains(AnnualPageKind.circle)));
    expect(pages, hasLength(7));
  });

  test('time headline and deck', () {
    expect(timeHeadline(212 * 3600), 'You read for 212 hours.');
    expect(timeHeadline(3600), 'You read for 1 hour.');
    expect(timeHeadline(1500), 'You read for 25 minutes.');
    expect(timeFigureRange(212 * 3600), (start: 13, end: 16));
    expect(timeDeck(9 * 86400), "That's nine days, cover to cover.");
    expect(timeDeck(86400), "That's one day, cover to cover.");
    expect(timeDeck(12 * 86400), "That's 12 days, cover to cover.");
    expect(timeDeck(20 * 3600), "That's most of a day, cover to cover.");
    expect(timeDeck(5 * 3600), isNull);
    expect(spellSmall(0), 'zero');
    expect(spellSmall(10), '10');
  });

  test('chapters, No. 1 and ranked folios', () {
    expect(chaptersHeadline(4812), '4,812 chapters.');
    expect(chaptersHeadline(1), '1 chapter.');
    expect(no1Headline('Solo Leveling'), 'Your most-read: Solo Leveling.');
    const s = ShareSeries(sourceId: 's', seriesKey: 'k', title: 'T', secondsRead: 12 * 3600, chaptersRead: 38);
    expect(no1Credit(s), '38 CHAPTERS · 12 H');
    expect(rankFolio(s), '38 CH · 12 H');
  });

  test('genres line: two genres, one genre, a vowel', () {
    const f = GenreWeight(genre: 'Fantasy', weight: 0.5);
    const r = GenreWeight(genre: 'Romance', weight: 0.3);
    const a = GenreWeight(genre: 'Action', weight: 0.6);
    expect(genresLine([f, r]), 'A fantasy reader, with a streak of romance.');
    expect(genresLine([f]), 'A fantasy reader through and through.');
    expect(genresLine([a, f]), 'An action reader, with a streak of fantasy.');
  });

  test('streak, sources, circle and thin-data lines', () {
    expect(streakLine(const AnnualStreak(days: 31, month: 3)), 'Longest streak: 31 days, in March.');
    expect(streakLine(const AnnualStreak(days: 1, month: 12)), 'Longest streak: 1 day, in December.');
    expect(sourcesHeadline('MangaDex'), 'MangaDex did the heavy lifting.');
    expect(circleLine(annualFixture(circle: true)), 'You and Riya both finished Solo Leveling.');
    expect(circleLine(annualFixture()), isNull);
    expect(notEnoughLine(5), 'Your Annual needs a few more weeks of reading. 5 days recorded so far.');
    expect(notEnoughLine(1), 'Your Annual needs a few more weeks of reading. 1 day recorded so far.');
  });

  test('cover lines', () {
    expect(coverDeck('Yash'), "An issue about Yash's year in reading");
    expect(issueLine(1, DateTime(2026, 9, 29)), 'No. 1 · 29 SEPTEMBER 2026');
  });

  test('colophon lines: NARRATED BY and WITH are conditional', () {
    final full = colophonLines(annualFixture(circle: true));
    expect(full.map((l) => l.$1), ['STARRING', 'SHOT ON', 'NARRATED BY', 'WITH', 'SET IN', 'PRINTED ON']);
    expect(full.firstWhere((l) => l.$1 == 'NARRATED BY').$2, 'Marlowe, Isolde');
    expect(full.firstWhere((l) => l.$1 == 'SHOT ON').$2, 'MangaDex, Asura, Flame');
    expect(full.firstWhere((l) => l.$1 == 'STARRING').$2.split('\n'), hasLength(5));
    final thin = colophonLines(annualFixture(voices: false));
    expect(thin.map((l) => l.$1), ['STARRING', 'SHOT ON', 'SET IN', 'PRINTED ON']);
    expect(colophonLines(annualFixture()).last.$2, 'ManhwaManiacs');
  });

  test('closing line names the next year', () {
    expect(closingLine(2026), 'See you in 2027.');
  });
}
