// ignore_for_file: require_trailing_commas, avoid_redundant_argument_values, library_private_types_in_public_api, directives_ordering
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/providers/library_read_state.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/core/utils/pagination.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloaded_series_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/home/providers/home_feed_provider.dart';
import 'package:manhwamaniacs/features/home/repositories/home_repository.dart';
import 'package:manhwamaniacs/features/library/models/continue_reading_item.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/library/repositories/library_repository.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/sources/providers/source_pins_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_overrides.dart';
import 'home_fixtures.dart';

class _FakeHome implements HomeRepository {
  _FakeHome(this.answer);
  Result<HomeFeed> Function() answer;
  final calls = <({String? kind, int tz, bool refresh})>[];
  Future<void>? hold;

  @override
  Future<Result<HomeFeed>> fetch({required String? contentKind, required int tzOffsetMinutes, bool refresh = false}) async {
    calls.add((kind: contentKind, tz: tzOffsetMinutes, refresh: refresh));
    if (hold != null) await hold;
    return answer();
  }
}

// ignore_for_file: unused_element_parameter
class _FakeLib implements LibraryRepository {
  @override
  Future<Result<WorldSuggestResponse>> localSuggest(String prompt, {int limit = 6}) => throw UnimplementedError();

  _FakeLib({this.cont, this.recent, this.followed, this.fail = false});
  final List<ContinueReadingItem>? cont;
  final List<FollowedSeries>? recent, followed;
  final bool fail;

  Result<T> _r<T>(T? v) => fail || v == null ? const Err(NetworkError(message: 'down')) : Ok(v);

  @override
  Future<Result<List<ContinueReadingItem>>> continueReading({int limit = 10}) async => _r(cont);

  @override
  Future<Result<List<FollowedSeries>>> recentlyUpdated({int limit = 10}) async => _r(recent);

  @override
  Future<Result<WorldRecommendations>> worldRecommendations({int seeds = 5, int perSeed = 10}) async => _r<WorldRecommendations>(null);

  int lists = 0;

  @override
  Future<Result<PagedResult<FollowedSeries>>> listSeries({int page = 1, int perPage = 40, String? sort, String? search, String? readingStatus, bool? isFavorite, List<int>? tagIds, bool? newOnly,}) async =>
      lists++ < 0 ? throw StateError('') : _r(followed == null ? null : PagedResult(items: followed!, total: followed!.length, page: 1, perPage: perPage, hasNext: false));

  @override
  Future<Result<LibraryStatistics>> statistics() async => _r<LibraryStatistics>(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Pins extends SourcePinsNotifier {
  @override
  Future<SourcePinsState> build() async => const SourcePinsState(synced: true);
}

class _FailingPins extends SourcePinsNotifier {
  @override
  Future<SourcePinsState> build() async => throw const NetworkError(message: 'down');
}

class _Switchable extends ActiveProfileNotifier {
  @override
  ActiveProfile? build() => const ActiveProfile(id: 1, name: 'One', avatarKey: null, mood: Mood.neutral);
  void switchTo(int id) => state = ActiveProfile(id: id, name: 'P$id', avatarKey: null, mood: Mood.neutral);
}

Future<ProviderContainer> container(_FakeHome home, _FakeLib lib, {DateTime? now, bool gate = false, bool pinsFail = false}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [
    sharedPrefsProvider.overrideWithValue(prefs),
    authenticatedAuthOverride(),
    activeProfileProvider.overrideWith(_Switchable.new),
    ...noDownloadsStoreOverrides(),
    ...contentModeOverrides(),
    homeRepositoryProvider.overrideWithValue(home),
    libraryRepositoryProvider.overrideWithValue(lib),
    matureGateOpenProvider.overrideWithValue(gate),
    downloadedSeriesProvider.overrideWith((ref) async => const []),
    sourcePinsProvider.overrideWith(pinsFail ? _FailingPins.new : _Pins.new),
    clockProvider.overrideWithValue(() => now ?? DateTime(2026, 9, 30, 15)),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('refreshFromServer sends refresh and reports changed only when identities or generatedAt differ', () async {
    var name = 'ready';
    final home = _FakeHome(() => Ok(loadHome(name)));
    final c = await container(home, _FakeLib());
    await c.read(homeFeedProvider.future);
    expect(home.calls.single.refresh, isFalse);
    final same = await c.read(homeFeedProvider.notifier).refreshFromServer();
    expect(home.calls.last.refresh, isTrue);
    expect(same.changed, isFalse);
    expect(same.error, isNull);
    name = 'caught-up';
    final other = await c.read(homeFeedProvider.notifier).refreshFromServer();
    expect(other.changed, isTrue);
    expect(c.read(homeFeedProvider).value!.feed, isNotNull);
  });

  test('homeFeedChanged reads generatedAt', () {
    final a = loadHome('ready');
    expect(homeFeedChanged(a, a), isFalse);
    expect(homeFeedChanged(a, null), isTrue);
    expect(homeFeedChanged(null, null), isFalse);
  });

  test('refreshFromServer failure reports the error and keeps the view', () async {
    var fail = false;
    final home = _FakeHome(() => fail ? const Err(NetworkError(message: 'down')) : Ok(loadHome('ready')));
    final c = await container(home, _FakeLib(fail: true));
    await c.read(homeFeedProvider.future);
    fail = true;
    final r = await c.read(homeFeedProvider.notifier).refreshFromServer();
    expect(r.changed, isFalse);
    expect(r.error, isNotNull);
    expect(c.read(homeFeedProvider).value, isNotNull);
  });

  test('a refresh started under one profile never lands on the next', () async {
    final home = _FakeHome(() => Ok(loadHome('ready')));
    final c = await container(home, _FakeLib());
    final sub = c.listen(homeFeedProvider, (_, __) {});
    addTearDown(sub.close);
    await c.read(homeFeedProvider.future);
    final gate = Completer<void>();
    home.hold = gate.future;
    final stale = c.read(homeFeedProvider.notifier).refresh();
    home.hold = null;
    home.answer = () => Ok(loadHome('caught-up'));
    (c.read(activeProfileProvider.notifier) as _Switchable).switchTo(2);
    final b = await c.read(homeFeedProvider.future);
    home.answer = () => Ok(loadHome('ready'));
    gate.complete();
    await stale;
    expect(homeFeedChanged(c.read(homeFeedProvider).value!.feed, b.feed), isFalse);
  });

  test('closing a reader refetches a live home feed', () async {
    final home = _FakeHome(() => Ok(loadHome('ready')));
    final c = await container(home, _FakeLib());
    final sub = c.listen(homeFeedProvider, (_, __) {});
    addTearDown(sub.close);
    await c.read(homeFeedProvider.future);
    c.read(libraryReadStateProvider).refresh();
    await Future<void>.delayed(Duration.zero);
    expect(home.calls, hasLength(2));
  });

  test("Glass Home's followed list re-reads with every new feed", () async {
    var name = 'ready';
    final home = _FakeHome(() => Ok(loadHome(name)));
    final lib = _FakeLib(followed: const []);
    final c = await container(home, lib);
    final sub = c.listen(homeFollowedProvider, (_, __) {});
    addTearDown(sub.close);
    await c.read(homeFollowedProvider.future);
    final before = lib.lists;
    name = 'caught-up';
    await c.read(homeFeedProvider.notifier).refreshFromServer();
    await c.read(homeFollowedProvider.future);
    expect(lib.lists, greaterThan(before));
  });
}
