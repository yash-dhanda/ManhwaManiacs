import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/library/models/annual.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/features/library/providers/genre_weights_provider.dart';
import 'package:manhwamaniacs/features/library/providers/numbers_providers.dart';
import 'package:manhwamaniacs/features/library/repositories/numbers_repository.dart';
import 'package:manhwamaniacs/features/sources/models/source_genre.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';

import '../../../support/numbers_fixtures.dart';
import '../shell/shell_rig.dart';

/// The Numbers repository the Glass tests drive: payloads by range, one Annual per year, and a record of every request.
class FakeNumbers implements NumbersRepository {
  FakeNumbers({Map<int, LibraryStatistics>? stats, Map<int, Annual>? annuals, this.failWith})
      : stats = stats ?? {for (final d in [7, 30, 90, 365]) d: statisticsFixture(days: d)},
        annuals = annuals ?? {2026: annualFixture(), 2025: annualFixture(year: 2025, partial: false)};

  final Map<int, LibraryStatistics> stats;
  final Map<int, Annual> annuals;
  final List<int> statisticsDays = [];
  final List<int> annualYears = [];
  final List<int> marked = [];
  AppError? failWith;
  Completer<void>? gate;

  @override
  Future<Result<LibraryStatistics>> statistics({required int days}) async {
    statisticsDays.add(days);
    await gate?.future;
    if (failWith != null) return Err(failWith!);
    return Ok(stats[days] ?? statisticsFixture(days: days));
  }

  @override
  Future<Result<Annual>> annual(int year) async {
    annualYears.add(year);
    await gate?.future;
    if (failWith != null) return Err(failWith!);
    final a = annuals[year];
    return a == null ? const Err(UnknownError(message: 'no fixture')) : Ok(a);
  }

  @override
  Future<Result<void>> markMilestoneSeen(int days) async {
    marked.add(days);
    return const Ok(null);
  }
}

final kStatsNow = DateTime(2026, 9, 29, 15);

List<Override> statsOverrides(FakeNumbers repo, {DateTime? now}) => [
      numbersRepositoryProvider.overrideWithValue(repo),
      sourcesListProvider.overrideWith((ref) async => const []),
      clockProvider.overrideWithValue(() => now ?? kStatsNow),
      genreWeightsProvider.overrideWith((ref, limit) async => const [GenreWeight(genre: 'Fantasy', weight: 0.41), GenreWeight(genre: 'Romance', weight: 0.22), GenreWeight(genre: 'Action', weight: 0.15), GenreWeight(genre: 'Drama', weight: 0.1)]),
    ];

Future<ShellRig> pumpStats(WidgetTester t, FakeNumbers repo, {Size size = const Size(390, 844), DateTime? now, String start = '/library/statistics', List<Override> extra = const [], Map<String, Object> prefs = const {}, bool settle = true}) async {
  final rig = await pumpGlassShell(t, size: size, start: start, settle: false, prefsExtra: prefs, extra: [...statsOverrides(repo, now: now), ...extra]);
  if (settle) {
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 300));
    }
  }
  return rig;
}
