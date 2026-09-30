import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/home/repositories/home_repository.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/repositories/library_repository.dart';
import 'package:manhwamaniacs/features/updates/providers/unread_count_provider.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/library/models/continue_reading_item.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/core/utils/pagination.dart';

import '../../../features/home/home_fixtures.dart';
import '../shell/shell_rig.dart';

/// A `GET /home` that answers with [answer] and records every call.
class FakeHomeRepo implements HomeRepository {
  FakeHomeRepo(this.answer);
  Future<Result<HomeFeed>> Function() answer;
  final calls = <({String? kind, bool refresh})>[];

  @override
  Future<Result<HomeFeed>> fetch({required String? contentKind, required int tzOffsetMinutes, bool refresh = false}) {
    calls.add((kind: contentKind, refresh: refresh));
    return answer();
  }
}

FakeHomeRepo homeRepoOf(String fixture) => FakeHomeRepo(() async => Ok(loadHome(fixture)));

/// The library answers nothing (the local composer is not under test); followed is empty.
class _QuietLib implements LibraryRepository {
  @override
  Future<Result<PagedResult<FollowedSeries>>> listSeries({int page = 1, int perPage = 40, String? sort, String? search, String? readingStatus, bool? isFavorite, List<int>? tagIds, bool? newOnly}) async =>
      Ok(PagedResult(items: const [], total: 0, page: 1, perPage: perPage, hasNext: false));

  @override
  Future<Result<List<ContinueReadingItem>>> continueReading({int limit = 10}) async => const Err(NetworkError(message: 'down'));

  @override
  Future<Result<List<FollowedSeries>>> recentlyUpdated({int limit = 10}) async => const Err(NetworkError(message: 'down'));

  @override
  Future<Result<WorldRecommendations>> worldRecommendations({int seeds = 5, int perSeed = 10}) async => const Err(NetworkError(message: 'down'));

  @override
  Future<Result<LibraryStatistics>> statistics() async => const Err(NetworkError(message: 'down'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The overrides a Home screen test needs on top of the shell's: the home repository and a quiet library.
List<Override> homeOverrides(FakeHomeRepo repo, {DateTime? now, int unread = 0}) => [
      homeRepositoryProvider.overrideWithValue(repo),
      libraryRepositoryProvider.overrideWithValue(_QuietLib()),
      clockProvider.overrideWithValue(() => now ?? DateTime(2026, 9, 30, 15)),
      matureGateOpenProvider.overrideWithValue(false),
      if (unread > 0) unreadNotificationCountProvider.overrideWith(() => _Unread(unread)),
    ];

class _Unread extends UnreadCountNotifier {
  _Unread(this.n);
  final int n;
  @override
  int build() => n;
}

Future<ShellRig> pumpHome(WidgetTester t, FakeHomeRepo repo, {Size size = const Size(390, 844), DateTime? now, int unread = 0, List<Override> extra = const [], bool settle = true}) async {
  final rig = await pumpGlassShell(t, size: size, settle: false, extra: [...homeOverrides(repo, now: now, unread: unread), ...extra]);
  if (settle) {
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 300));
    }
  }
  return rig;
}

Completer<Result<HomeFeed>> pendingFeed(FakeHomeRepo repo) {
  final c = Completer<Result<HomeFeed>>();
  repo.answer = () => c.future;
  return c;
}

/// A Home test: runs [body], then lets the feed's ten-minute keep-alive timer fire so no timer outlives the widget tree.
void homeTest(String name, Future<void> Function(WidgetTester t) body, {bool skip = false}) => testWidgets(name, (t) async {
      await body(t);
      await t.pump(const Duration(minutes: 11));
    }, skip: skip,);

/// An unread count the test can move.
class MutableUnread extends UnreadCountNotifier {
  int initial = 0;
  @override
  int build() => initial;
  void set(int n) => state = n;
}
