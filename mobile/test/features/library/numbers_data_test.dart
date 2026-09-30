import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/features/library/providers/numbers_providers.dart';
import 'package:manhwamaniacs/features/library/repositories/numbers_repository.dart';
import 'package:manhwamaniacs/features/library/store/numbers_snapshot.dart';
import 'package:manhwamaniacs/features/library/utils/milestones.dart';
import 'package:manhwamaniacs/features/library/utils/numbers_rules.dart';
import 'package:manhwamaniacs/features/library/utils/streak.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/numbers_fixtures.dart';
import '../../support/test_overrides.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);
  final ResponseBody Function(RequestOptions) respond;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, [int status = 200]) => ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: ['application/json'],
    },);

void main() {
  group('models', () {
    test('statistics parses the streak flags, shareable and range', () {
      final s = statisticsFixture(atRisk: true, milestonesSeen: [7, 30]);
      expect(s.streak.atRisk, isTrue);
      expect(s.streak.milestonesSeen, [7, 30]);
      expect(s.timezoneOffsetMinutes, 330);
      expect(s.sessionCapSeconds, 1800);
      expect(s.shareable!.genreWeights.first.genre, 'Fantasy');
      expect(s.shareable!.topSeries.first.ambient!.duo, '#7FA6D6');
      expect(s.shareable!.artSeries, hasLength(9));
      expect(s.bySeries.first.coverUrl, contains('/cover'));
    });

    test('statistics without the new fields keeps the defaults', () {
      final s = LibraryStatistics.fromJson({'followed_total': 1});
      expect(s.streak.atRisk, isFalse);
      expect(s.streak.milestonesSeen, isEmpty);
      expect(s.shareable, isNull);
    });

    test('annual parses every 9.2.7 field by name', () {
      final a = annualFixture(circle: true);
      expect(a.year, 2026);
      expect(a.partial, isTrue);
      expect(a.recordedDays, 120);
      expect(a.chaptersByMonth, hasLength(12));
      expect(a.byHour, hasLength(24));
      expect(a.byHour[23], 7000);
      expect(a.topSeries, hasLength(5));
      expect(a.longestStreak.days, 31);
      expect(a.longestStreak.month, 3);
      expect(a.topSources.first.share, 0.41);
      expect(a.circle!.single.finishedTogether, ['Solo Leveling']);
      expect(a.topVoices.first.name, 'Marlowe');
      expect(a.availableYears, [2026, 2025]);
      expect(a.shareable!.artSeries, hasLength(9));
    });

    test('annual circle is null when absent and voices may be empty', () {
      final a = annualFixture(voices: false);
      expect(a.circle, isNull);
      expect(a.topVoices, isEmpty);
    });
  });

  group('repository', () {
    test('statistics sends days and the clamped offset', () async {
      final adapter = _Adapter((_) => _json(statisticsJson(days: 365)));
      final dio = Dio(BaseOptions(baseUrl: 'http://t'))..httpClientAdapter = adapter;
      final r = await NumbersRepositoryImpl(dio).statistics(days: 365);
      expect(r.isOk, isTrue);
      final q = adapter.requests.single.queryParameters;
      expect(q['days'], 365);
      expect(q['tz_offset_minutes'], inInclusiveRange(-720, 840));
      expect(adapter.requests.single.path, '/library/statistics');
    });

    test('annual always sends year and tz offset', () async {
      final adapter = _Adapter((_) => _json(annualJson()));
      final dio = Dio(BaseOptions(baseUrl: 'http://t'))..httpClientAdapter = adapter;
      final r = await NumbersRepositoryImpl(dio).annual(2026);
      expect(r.isOk, isTrue);
      expect(adapter.requests.single.path, '/library/annual');
      expect(adapter.requests.single.queryParameters['year'], 2026);
      expect(adapter.requests.single.queryParameters, contains('tz_offset_minutes'));
    });

    test('markMilestoneSeen posts to the seen endpoint', () async {
      final adapter = _Adapter((_) => ResponseBody.fromString('', 204));
      final dio = Dio(BaseOptions(baseUrl: 'http://t'))..httpClientAdapter = adapter;
      final r = await NumbersRepositoryImpl(dio).markMilestoneSeen(30);
      expect(r.isOk, isTrue);
      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.path, '/library/statistics/milestones/30/seen');
    });

    test('a connection error is a NetworkError', () async {
      final adapter = _Adapter((o) => throw DioException.connectionError(requestOptions: o, reason: 'down'));
      final dio = Dio(BaseOptions(baseUrl: 'http://t'))..httpClientAdapter = adapter;
      final r = await NumbersRepositoryImpl(dio).statistics(days: 30);
      expect(r.isErr, isTrue);
      expect(r.error, isA<NetworkError>());
    });

    test('the offset clamp holds at both ends', () {
      expect(clampedTzOffsetMinutes(const Duration(hours: -15)), -720);
      expect(clampedTzOffsetMinutes(const Duration(hours: 20)), 840);
      expect(clampedTzOffsetMinutes(const Duration(hours: 5, minutes: 30)), 330);
    });
  });

  group('rules', () {
    test('ranges and labels', () {
      expect(kNumbersRanges, [7, 30, 90, 365]);
      expect(kNumbersRangeLabels[365], 'YEAR');
    });

    test('bestChapterDay: most chapters, ties to the latest date', () {
      final d = [
        DailyActivity(date: DateTime(2026, 9), chaptersRead: 5),
        DailyActivity(date: DateTime(2026, 9, 2), chaptersRead: 9),
        DailyActivity(date: DateTime(2026, 9, 3), chaptersRead: 9),
        DailyActivity(date: DateTime(2026, 9, 4)),
      ];
      expect(bestChapterDay(d)!.date, DateTime(2026, 9, 3));
      expect(bestChapterDay([DailyActivity(date: DateTime(2026, 9, 4))]), isNull);
    });

    test('annualAvailable: December or 30 recorded days', () {
      final thin = annualFixture(recordedDays: 29);
      final thick = annualFixture(recordedDays: 30);
      expect(annualAvailable(DateTime(2026, 11, 30), thin), isFalse);
      expect(annualAvailable(DateTime(2026, 12), thin), isTrue);
      expect(annualAvailable(DateTime(2026, 9), thick), isTrue);
      expect(annualAvailable(DateTime(2026, 9), null), isFalse);
    });

    test('issueNumber counts earlier available years', () {
      expect(issueNumber(2026, [2026, 2025, 2024]), 3);
      expect(issueNumber(2024, [2026, 2025, 2024]), 1);
      expect(issueNumber(2026, [2026]), 1);
    });
  });

  group('milestones', () {
    ReadingStreak s(int d, [List<int> seen = const []]) => ReadingStreak(currentDays: d, milestonesSeen: seen);

    test('pendingMilestone', () {
      expect(pendingMilestone(s(0)), isNull);
      expect(pendingMilestone(s(6)), isNull);
      expect(pendingMilestone(s(7)), 7);
      expect(pendingMilestone(s(29, [7])), isNull);
      expect(pendingMilestone(s(30, [7])), 30);
      expect(pendingMilestone(s(45)), 30);
      expect(pendingMilestone(s(365, [7, 30, 100])), 365);
    });

    test('milestonesToMark marks every unseen one up to the shown card', () {
      expect(milestonesToMark(s(45), 30), [7, 30]);
      expect(milestonesToMark(s(30, [7]), 30), [30]);
      expect(milestonesToMark(s(7), 7), [7]);
    });
  });

  group('streak state', () {
    final today = DateTime(2026, 9, 29, 10);
    HomeStreak h(int d, DateTime? last, {bool risk = false}) => HomeStreak(currentDays: d, longestDays: 31, lastActiveDate: last, atRisk: risk);

    test('tiers at 0, 3, 12, 45 and 120 days', () {
      expect([0, 3, 12, 45, 120].map(streakTier), [StreakTier.none, StreakTier.one, StreakTier.three, StreakTier.ring, StreakTier.sparks]);
    });

    test('read today, not yet before 20:00, at risk after 20:00', () {
      expect(streakState(h(12, DateTime(2026, 9, 29)), today), StreakLiveState.aliveToday);
      expect(streakState(h(12, DateTime(2026, 9, 28)), today), StreakLiveState.aliveNotToday);
      expect(streakState(h(12, DateTime(2026, 9, 28)), DateTime(2026, 9, 29, 20, 1)), StreakLiveState.atRisk);
      expect(streakState(h(0, null), today), StreakLiveState.none);
    });

    test('HomeStreak.fromReadingStreak copies the shared fields', () {
      final r = ReadingStreak(currentDays: 5, longestDays: 9, lastActiveDate: DateTime(2026, 9, 29), atRisk: true, milestonesSeen: const [7]);
      final hs = HomeStreak.fromReadingStreak(r);
      expect([hs.currentDays, hs.longestDays, hs.atRisk, hs.milestonesSeen], [5, 9, true, [7]]);
    });
  });

  group('snapshot and range persistence', () {
    test('snapshot round trip and profile isolation', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final a = NumbersSnapshot(prefs, userId: 1, profileId: 1);
      final b = NumbersSnapshot(prefs, userId: 1, profileId: 2);
      await a.writeNumbers(30, statisticsJson());
      await a.writeAnnual(2026, annualJson());
      expect(a.numbersKey(30), 'mm.numbers.last.30.u1p1');
      expect(a.annualKey(2026), 'mm.annual.last.2026.u1p1');
      expect(a.readNumbers(30)!['followed_total'], 212);
      expect(a.readAnnual(2026)!['year'], 2026);
      expect(b.readNumbers(30), isNull);
      expect(a.readNumbers(7), isNull);
    });

    test('range defaults to 30, round trips and is per profile', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      ProviderContainer make(int profile) => ProviderContainer(overrides: [
            sharedPrefsProvider.overrideWithValue(prefs),
            authenticatedAuthOverride(),
            activeProfileOverride(),
          ],);
      final c = make(1);
      addTearDown(c.dispose);
      expect(c.read(statsRangeProvider), 30);
      await c.read(statsRangeProvider.notifier).set(365);
      expect(c.read(statsRangeProvider), 365);
      await c.read(statsRangeProvider.notifier).set(14);
      expect(c.read(statsRangeProvider), 365);
      final key = prefs.getKeys().singleWhere((k) => k.startsWith('mm.stats.range.'));
      expect(key, matches(RegExp(r'^mm\.stats\.range\.u\d+p\d+$')));
      // A fresh container (an app restart) reads it back.
      final again = make(1);
      addTearDown(again.dispose);
      expect(again.read(statsRangeProvider), 365);
      // Another profile's key is untouched.
      await prefs.setInt('mm.stats.range.u1p999', 7);
      expect(prefs.getInt(key), 365);
    });
  });
}
