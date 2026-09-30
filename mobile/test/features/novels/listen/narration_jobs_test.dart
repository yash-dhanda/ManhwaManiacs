import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';
import 'package:manhwamaniacs/features/novels/providers/narration_jobs_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/series_audio_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_novels_repository.dart';

NovelAudioJob job(String status, {double progress = 0}) =>
    NovelAudioJob(jobId: status, chapterKey: 'c', status: status, progress: progress, errorCode: null);

void main() {
  group('nextJobsPoll cadence', () {
    const base = Duration(seconds: 5);
    test('5 s while a job renders', () {
      expect(nextJobsPoll(base: base, jobs: [job('rendering'), job('queued')], failures: 0), base);
    });
    test('15 s while every job only waits', () {
      expect(nextJobsPoll(base: base, jobs: [job('queued')], failures: 0), const Duration(seconds: 15));
    });
    test('back-off doubles after failures and stops at 60 s', () {
      Duration at(int f) => nextJobsPoll(base: base, jobs: const [], failures: f);
      expect(at(1), const Duration(seconds: 10));
      expect(at(2), const Duration(seconds: 20));
      expect(at(3), const Duration(seconds: 40));
      expect(at(4), const Duration(seconds: 60));
      expect(at(9), const Duration(seconds: 60));
    });
  });

  group('activeAudioJobsProvider', () {
    late FakeNovelsRepository repo;
    late ProviderContainer c;

    Future<ProviderContainer> make() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      return ProviderContainer(overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        novelsRepositoryProvider.overrideWithValue(repo),
        novelAudioJobsPollIntervalProvider.overrideWithValue(const Duration(milliseconds: 20)),
      ],);
    }

    setUp(() => repo = FakeNovelsRepository());
    tearDown(() => c.dispose());

    test('stops polling once nothing is active and no sheet is open', () async {
      repo.activeJobsResult = const Ok(<NovelAudioJob>[]);
      c = await make();
      final sub = c.listen(activeAudioJobsProvider, (_, __) {});
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(repo.activeJobsCalls, 1);
      sub.close();
    });

    test('keeps polling while a job is active, and reports it as one NarrationJob', () async {
      repo.activeJobsResult = Ok([job('rendering', progress: 0.5), job('queued')]);
      c = await make();
      final sub = c.listen(activeAudioJobsProvider, (_, __) {});
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(repo.activeJobsCalls, greaterThan(3));
      final jobs = c.read(activeNarrationJobsProvider);
      expect(jobs, hasLength(1));
      expect(jobs.single.total, 2);
      expect(jobs.single.progress, closeTo(0.25, 1e-9));
      expect(jobs.single.hasBook, isFalse);
      sub.close();
    });

    test('a book remembered from this device names the job', () async {
      repo.activeJobsResult = Ok([job('rendering')]);
      c = await make();
      c.read(narratingBookProvider.notifier).state = (sourceId: 's', seriesKey: 'b', title: 'Omniscient Reader');
      final sub = c.listen(activeAudioJobsProvider, (_, __) {});
      await Future<void>.delayed(const Duration(milliseconds: 60));
      final j = c.read(activeNarrationJobsProvider).single;
      expect(j.hasBook, isTrue);
      expect(j.title, 'Omniscient Reader');
      sub.close();
    });

    test('an open Audiobook sheet keeps an idle poll alive; a failure keeps the last answer', () async {
      repo.activeJobsResult = const Ok(<NovelAudioJob>[]);
      c = await make();
      c.read(audiobookSheetOpenProvider.notifier).state = true;
      final sub = c.listen(activeAudioJobsProvider, (_, __) {});
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(repo.activeJobsCalls, greaterThan(2));
      repo.activeJobsResult = const Err(NetworkError(message: 'offline'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(c.read(activeAudioJobsProvider).valueOrNull, isEmpty);
      sub.close();
    });
  });
}
