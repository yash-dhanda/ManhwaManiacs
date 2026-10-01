import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/annual.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/features/library/store/numbers_snapshot.dart';
import 'package:manhwamaniacs/features/library/utils/reading_stats.dart';
import 'package:manhwamaniacs/features/library/utils/wrapped_cards.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/numbers_fixtures.dart';

DailyActivity d(int day, int pages, {int ch = 1}) => DailyActivity(date: DateTime(2026, 9, day), pagesRead: pages, chaptersRead: ch, secondsRead: pages * 20);
HourActivity h(int hour, int pages) => HourActivity(hour: hour, pagesRead: pages);

void main() {
  test('bestPagesDay: most pages, ties to the latest', () {
    expect(bestPagesDay([d(1, 10), d(2, 40), d(3, 40), d(4, 0)])!.date.day, 3);
    expect(bestPagesDay([d(1, 0)]), isNull);
  });

  test('daysRead and heat levels', () {
    expect(daysRead([d(1, 0), d(2, 5), d(3, 1)]), 2);
    expect([0, 1, 19, 20, 59, 60, 149, 150, 900].map(heatLevel), [0, 1, 1, 2, 2, 3, 3, 4, 4]);
  });

  test('weeklyTotals is Monday first', () {
    // 2026-09-06 is a Sunday, 07 a Monday.
    final w = weeklyTotals([d(6, 10), d(7, 20), d(13, 5), d(14, 1)]);
    expect(w.map((x) => x.start.day), [31, 7, 14].map((x) => x == 31 ? 31 : x));
    expect(w[1].pages, 25);
    expect(w[1].days, 2);
  });

  test('clockBand at every edge', () {
    ClockBand of(int hour) => clockBand([h(hour, 5)])!.band;
    expect([of(22), of(4), of(5), of(8), of(9), of(16), of(17), of(21), of(0)], [
      ClockBand.night, ClockBand.night, ClockBand.early, ClockBand.early, ClockBand.day, ClockBand.day, ClockBand.evening, ClockBand.evening, ClockBand.night,
    ]);
    expect(clockBand([h(3, 0)]), isNull);
    // band with the most pages wins, peak is the busiest single hour (ties: earlier).
    final r = clockBand([h(23, 10), h(1, 10), h(12, 15), h(13, 5)])!;
    expect(r.band, ClockBand.night);
    expect(r.peakHour, 12);
  });

  group('snapshots', () {
    test('both shapes read, age words', () async {
      SharedPreferences.setMockInitialValues({'mm.numbers.last.7.u1p1': '{"followed_total": 5}'});
      final snap = NumbersSnapshot(await SharedPreferences.getInstance(), userId: 1, profileId: 1);
      expect(snap.readNumbers(7)!['followed_total'], 5);
      expect(snap.numbersSavedAt(7), isNull);
      final t = DateTime(2026, 9, 29, 10);
      await snap.writeNumbers(30, {'followed_total': 9}, now: t);
      expect(snap.readNumbers(30)!['followed_total'], 9);
      expect(snap.numbersSavedAt(30), isNotNull);
      expect(snapshotAge(t, t.add(const Duration(seconds: 20))), 'just now');
      expect(snapshotAge(t, t.add(const Duration(minutes: 12))), '12 min ago');
      expect(snapshotAge(t, t.add(const Duration(hours: 2))), '2 h ago');
      expect(snapshotAge(t, t.add(const Duration(days: 3))), '3 d ago');
      await snap.purge();
      expect(snap.readNumbers(30), isNull);
      expect(snap.readNumbers(7), isNull);
    });
  });

  group('wrapped cards', () {
    test('the omissions and renumbering', () {
      final full = annualFixture();
      expect(wrappedCards(full, profileShares: false).map((c) => c.number), [1, 2, 3, 4, 5, 6, 7, 10, 12]);
      final j = annualJson(circle: true)..['busiest_day'] = {'date': '2026-03-14', 'chapters': 42, 'series': <Object?>[]};
      final withCircle = Annual.fromJson(j);
      expect(wrappedCards(withCircle, profileShares: true).map((c) => c.number), [1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12]);
      expect(wrappedCards(withCircle, profileShares: false).contains(WrappedCard.together), isFalse);
      final thin = Annual.fromJson({...annualJson(), 'top_series': <Object?>[], 'genres': <Object?>[], 'by_hour': <Object?>[], 'top_sources': <Object?>[], 'longest_streak': {'days': 0}});
      expect(wrappedCards(thin, profileShares: false), [WrappedCard.cover, WrappedCard.time, WrappedCard.volume, WrappedCard.summary]);
    });

    test('not enough data and titles', () {
      expect(notEnoughData(annualFixture(recordedDays: 6)), isTrue);
      expect(notEnoughData(annualFixture(recordedDays: 7)), isFalse);
      expect(wrappedTitle(annualFixture()), WrappedTitle.soFar);
      expect(wrappedTitle(annualFixture(partial: false)), WrappedTitle.inChapters);
    });

    test('share eligibility drops mature material', () {
      final j = annualJson();
      (j['shareable'] as Map)['genre_weights'] = [
        {'genre': 'Mature', 'weight': 0.6},
        {'genre': 'Fantasy', 'weight': 0.4},
      ];
      (j['shareable'] as Map)['top_series'] = [
        {'source_id': 'hot', 'series_key': 'k', 'title': 'Hot Series', 'cover_url': '/c'},
      ];
      final a = Annual.fromJson(j);
      const mature = {'hot', 'shelf'};
      expect(shareEligible(WrappedCard.summary, a, matureSources: mature)!.series, isEmpty);
      expect(shareEligible(WrappedCard.cover, a, matureSources: mature), isNull);
      expect(shareEligible(WrappedCard.genres, a)!.genres.map((g) => g.genre), ['Fantasy']);
      // The mature top source is skipped for the next.
      expect(shareEligible(WrappedCard.topSource, a, matureSources: const {'shelf'})!.source!.sourceId, 'asura');
      expect(shareEligible(WrappedCard.together, a), isNull);
      expect(shareEligible(WrappedCard.time, a), isNotNull);
    });
  });
}
