// ignore_for_file: require_trailing_commas, avoid_redundant_argument_values, library_private_types_in_public_api, directives_ordering
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  Future<Result<HomeFeed>> fetch({required String? contentKind, required int tzOffsetMinutes, bool refresh = false}) async {
    calls.add((kind: contentKind, tz: tzOffsetMinutes, refresh: refresh));
    return answer();
  }
}

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

  @override
  Future<Result<PagedResult<FollowedSeries>>> listSeries({int page = 1, int perPage = 40, String? sort, String? search, String? readingStatus, bool? isFavorite, List<int>? tagIds, bool? newOnly,}) async =>
      _r(followed == null ? null : PagedResult(items: followed!, total: followed!.length, page: 1, perPage: perPage, hasNext: false));

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
  test('a server answer is the feed, origin server; tz offset is sent; content_kind omitted with novels off', () async {
    final home = _FakeHome(() => Ok(loadHome('ready')));
    final c = await container(home, _FakeLib());
    final v = await c.read(homeFeedProvider.future);
    expect((v.state, v.origin, v.offline), (HomeFeedState.ready, HomeFeedOrigin.server, false));
    expect(v.feed!.headline, 'Tonight: chapter 143 of The Lantern Courier.');
    expect(home.calls.single.kind, isNull);
    expect(home.calls.single.tz, DateTime(2026, 9, 30, 15).timeZoneOffset.inMinutes);
  });

  test('a 500 falls back to the local composer, which still has a cover story', () async {
    final at = DateTime(2026, 9, 30, 15);
    final home = _FakeHome(() => const Err(ApiError(statusCode: 500, code: 'boom', message: 'x')));
    final c = await container(
      home,
      _FakeLib(
        cont: [contRow('a', at: at.subtract(const Duration(days: 1)), page: 20)],
        recent: const [],
        followed: [followedRow('a')],
      ),
    );
    final v = await c.read(homeFeedProvider.future);
    expect((v.state, v.origin), (HomeFeedState.ready, HomeFeedOrigin.local));
    expect(v.feed!.cover!.seriesKey, 'a');
    expect(v.feed!.ai.available, isFalse);
    expect(v.feed!.section(HomeSectionType.continueReading), isNotNull);
  });

  test('a NetworkError composes the offline edition', () async {
    final home = _FakeHome(() => const Err(NetworkError(message: 'down')));
    final c = await container(home, _FakeLib(fail: true));
    final v = await c.read(homeFeedProvider.future);
    expect((v.origin, v.offline), (HomeFeedOrigin.offline, true));
    expect(v.feed!.headline, 'Offline edition.');
  });

  test('a TimeoutError is offline too', () async {
    final c = await container(_FakeHome(() => const Err(TimeoutError())), _FakeLib(fail: true));
    expect((await c.read(homeFeedProvider.future)).origin, HomeFeedOrigin.offline);
  });

  test('every input failing is unavailable', () async {
    final home = _FakeHome(() => const Err(ApiError(statusCode: 500, code: 'boom', message: 'x')));
    final c = await container(home, _FakeLib(fail: true), pinsFail: true);
    final v = await c.read(homeFeedProvider.future);
    expect((v.state, v.feed), (HomeFeedState.unavailable, null));
    expect(v.retryAfter, isNull);
  });

  test('a new profile with nothing is empty', () async {
    final home = _FakeHome(() => Ok(HomeFeed.fromJson({'headline': 'Your first issue starts here.', 'deck': 'x'})));
    final c = await container(home, _FakeLib());
    expect((await c.read(homeFeedProvider.future)).state, HomeFeedState.empty);
  });

  test('the at-risk override: 20:30 turns it on, 19:59 leaves it off, even when the payload disagrees', () async {
    final home = _FakeHome(() => Ok(loadHome('at-risk'))); // 12 days, last active yesterday, at_risk false
    var c = await container(home, _FakeLib(), now: DateTime(2026, 9, 30, 20, 30));
    var v = await c.read(homeFeedProvider.future);
    expect(v.feed!.streak.atRisk, isTrue);
    expect(v.feed!.headline, 'Twelve days and counting. One chapter keeps it alive.');
    expect(v.feed!.deck, 'Open any chapter before midnight to keep your streak.');
    expect(v.feed!.cover!.title, 'The Lantern Courier', reason: 'the cover series is unchanged');

    c = await container(home, _FakeLib(), now: DateTime(2026, 9, 30, 19, 59));
    v = await c.read(homeFeedProvider.future);
    expect(v.feed!.streak.atRisk, isFalse);
    expect(v.feed!.headline, 'Tonight: chapter 143 of The Lantern Courier.');
  });

  test('a payload that says at risk is corrected when the day was already read', () async {
    final feed = HomeFeed.fromJson({
      'headline': 'Twelve days and counting. One chapter keeps it alive.',
      'deck': 'Open any chapter before midnight to keep your streak.',
      'streak': {'current_days': 12, 'longest_days': 12, 'at_risk': true, 'last_active_date': '2026-09-30'},
      'cover': {'reason': 'new_chapters', 'source_id': 's', 'series_key': 'k', 'chapter_key': 'c9', 'chapter_number': 9, 'title': 'Kite'},
    });
    final c = await container(_FakeHome(() => Ok(feed)), _FakeLib(), now: DateTime(2026, 9, 30, 21));
    final v = await c.read(homeFeedProvider.future);
    expect(v.feed!.streak.atRisk, isFalse);
    expect(v.feed!.headline, 'Tonight: chapter 9 of Kite.');
  });

  test('a profile switch fetches again; refresh asks the server to skip its cache', () async {
    final home = _FakeHome(() => Ok(loadHome('ready')));
    final c = await container(home, _FakeLib());
    c.listen(homeFeedProvider, (_, __) {});
    await c.read(homeFeedProvider.future);
    expect(home.calls, hasLength(1));
    (c.read(activeProfileProvider.notifier) as _Switchable).switchTo(2);
    await c.read(homeFeedProvider.future);
    expect(home.calls, hasLength(2));
    await c.read(homeFeedProvider.notifier).refresh();
    expect(home.calls.last.refresh, isTrue);
  });
}
