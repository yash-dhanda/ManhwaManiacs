import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/utils/progress_streak.dart';
import 'package:manhwamaniacs/features/reader/models/reading_progress.dart';
import 'package:manhwamaniacs/features/reader/repositories/reader_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Mem implements StreakDayStore {
  final m = <int, StreakDay>{};
  @override
  StreakDay? read(int p) => m[p];
  @override
  void write(int p, StreakDay d) => m[p] = d;
}

ProgressAnswer a({bool? ext, int days = 13, int? secs}) =>
    ProgressAnswer(streak: ext == null ? null : StreakSnapshot(currentDays: days, extendedToday: ext), todaySeconds: secs);

List<StreakEvent> note(Mem s, ProgressAnswer ans, {DateTime? now, int? goal}) =>
    noteProgressResponse(profileId: 1, answer: ans, nowLocal: now ?? DateTime(2026, 9, 29, 10), goalMinutes: goal, store: s);

void main() {
  test('false then true flares once', () {
    final s = Mem();
    expect(note(s, a(ext: false)), isEmpty);
    final e = note(s, a(ext: true));
    expect(e.whereType<StreakFlare>(), hasLength(1));
    expect(e.whereType<StreakFlare>().single.currentDays, 13);
    expect(note(s, a(ext: true)), isEmpty);
  });

  test('true first stays quiet', () {
    final s = Mem();
    expect(note(s, a(ext: true)), isEmpty);
    expect(note(s, a(ext: true)), isEmpty);
  });

  test('a new local day resets', () {
    final s = Mem();
    note(s, a(ext: true));
    final next = DateTime(2026, 9, 30, 9);
    expect(note(s, a(ext: false), now: next), isEmpty);
    expect(note(s, a(ext: true), now: next).whereType<StreakFlare>(), hasLength(1));
  });

  test('the goal crossing fires once', () {
    final s = Mem();
    expect(note(s, a(secs: 500), goal: 10).whereType<GoalMet>(), isEmpty);
    expect(note(s, a(secs: 650), goal: 10).whereType<GoalMet>(), hasLength(1));
    expect(note(s, a(secs: 700), goal: 10).whereType<GoalMet>(), isEmpty);
  });

  test('a missing streak field emits only StreakToday', () {
    final s = Mem();
    final e = note(s, a(secs: 90), goal: 10);
    expect(e, hasLength(1));
    expect((e.single as StreakToday).seconds, 90);
  });

  test('the prefs store round-trips', () async {
    SharedPreferences.setMockInitialValues({});
    final st = PrefsStreakDayStore(await SharedPreferences.getInstance(), userId: 3);
    expect(st.read(7), isNull);
    st.write(7, const StreakDay(day: '2026-09-29', extended: true, todaySeconds: 42, goalMet: false));
    expect(st.read(7)!.todaySeconds, 42);
  });

  group('repository', () {
    test('sends tz_offset_minutes and calls the hook only after an answer', () async {
      final seen = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: 'http://x'))
        ..httpClientAdapter = _Adapter((o) {
          seen.add(o);
          if (o.path == '/reader/progress') {
            return ResponseBody.fromString(
              jsonEncode({
                'id': 1, 'source_id': 's', 'series_key': 'k', 'chapter_key': 'c', 'chapter_number': 1, 'last_page': 1, 'page_count': 2,
                'scroll_offset_px': 0, 'is_completed': false, 'time_spent_seconds': 0,
                'streak': {'current_days': 4, 'extended_today': true}, 'today_seconds': 120,
              }),
              200,
              headers: {Headers.contentTypeHeader: ['application/json']},
            );
          }
          return ResponseBody.fromString(jsonEncode({'detail': 'no'}), 500, headers: {Headers.contentTypeHeader: ['application/json']});
        });
      final answers = <ProgressAnswer>[];
      final repo = ReaderRepositoryImpl(dio, onAnswer: answers.add);
      const push = ProgressPush(sourceId: 's', seriesKey: 'k', chapterKey: 'c', lastPage: 1);
      expect((await repo.saveProgress(push)).isOk, isTrue);
      expect(seen.single.queryParameters['tz_offset_minutes'], DateTime.now().timeZoneOffset.inMinutes.clamp(-720, 840));
      expect(answers.single.streak!.extendedToday, isTrue);
      expect(answers.single.todaySeconds, 120);
      expect((await repo.saveProgressBatch([push])).isErr, isTrue);
      expect(answers, hasLength(1));
      expect(seen.last.queryParameters.containsKey('tz_offset_minutes'), isTrue);
    });
  });
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);
  final ResponseBody Function(RequestOptions) respond;
  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<List<int>>? r, Future<void>? c) async => respond(o);
  @override
  void close({bool force = false}) {}
}
