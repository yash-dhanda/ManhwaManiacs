// ignore_for_file: require_trailing_commas, directives_ordering
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/core/utils/pagination.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/models/downloaded_series_group.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloaded_series_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart' show downloadQueueControllerProvider;
import 'package:manhwamaniacs/features/library/models/collection.dart';
import 'package:manhwamaniacs/features/library/models/continue_reading_item.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/models/series_detail.dart';
import 'package:manhwamaniacs/features/library/models/tag.dart';
import 'package:manhwamaniacs/features/library/providers/series_detail_provider.dart';
import 'package:manhwamaniacs/features/library/repositories/library_repository.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/features/updates/providers/unread_count_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/app_frame.dart';
import 'package:manhwamaniacs/skins/cinematic/cinematic_skin.dart';
import 'package:manhwamaniacs/skins/cinematic/navigation.dart';
import 'package:manhwamaniacs/skins/skin_haptics.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../features/library/shelf_fixtures.dart';
import '../../../support/test_overrides.dart';
import '../feature/feature_test_support.dart' show FakeReader, Recorder, RecordingHaptics, RecordingQueue;

export '../../../features/library/shelf_fixtures.dart';
export '../feature/feature_test_support.dart' show Recorder;

/// A server-shaped fake of `GET /library/series`: it filters, sorts and pages what it holds and
/// records every call, so the tests can assert the parameters the shelf sends.
class ShelfLibrary implements LibraryRepository {
  @override
  Future<Result<WorldSuggestResponse>> localSuggest(String prompt, {int limit = 6}) => throw UnimplementedError();

  ShelfLibrary({
    required this.all,
    this.failList = false,
    this.continueRows = const [],
    this.details = const {},
    this.tags = const [],
    this.shelves = const [],
    this.patchDelay = Duration.zero,
    this.failPatchIds = const {},
    this.listError,
    this.listDelay = Duration.zero,
    this.listGate,
  });

  List<FollowedSeries> all;
  bool failList;
  List<ContinueReadingItem> continueRows;
  Map<int, SeriesDetail> details;
  List<Tag> tags;
  List<Collection> shelves;
  Duration patchDelay;
  Set<int> failPatchIds;

  /// A non-network failure of the list (the `CORRECTION` state), or null.
  AppError? listError;
  Duration listDelay;

  /// A list that never answers until this completes (the loading state).
  Completer<void>? listGate;

  final List<Map<String, Object?>> listCalls = [];
  final List<Map<String, Object?>> patches = [];
  final List<int> unfollowed = [];
  final List<String> followedAgain = [];
  final List<String> tagCalls = [];
  final List<String> shelfAdds = [];
  int inflight = 0, peak = 0;

  /// The shelf's own page fetches (they carry a sort); the counts read has none.
  List<Map<String, Object?>> get shelfCalls => [for (final c in listCalls) if (c['sort'] != null) c];

  Map<String, Object?> get lastList => shelfCalls.last;

  @override
  Future<Result<PagedResult<FollowedSeries>>> listSeries({
    int page = 1,
    int perPage = 40,
    String? sort,
    String? search,
    String? readingStatus,
    bool? isFavorite,
    List<int>? tagIds,
    bool? newOnly,
  }) async {
    listCalls.add({'page': page, 'per_page': perPage, 'sort': sort, 'search': search, 'reading_status': readingStatus, 'is_favorite': isFavorite, 'tag_ids': tagIds, 'new_only': newOnly});
    if (listGate != null) await listGate!.future;
    if (listDelay > Duration.zero) await Future<void>.delayed(listDelay);
    if (listError != null) return Err(listError!);
    if (failList) return const Err(NetworkError(message: 'offline in test'));
    var r = [...all];
    if (readingStatus != null) r = [for (final s in r) if (s.readingStatus == readingStatus) s];
    if (isFavorite ?? false) r = [for (final s in r) if (s.isFavorite) s];
    if (newOnly ?? false) r = [for (final s in r) if ((s.readState?.newCount ?? 0) > 0) s];
    if (tagIds != null && tagIds.isNotEmpty) r = [for (final s in r) if (s.tags.any((t) => tagIds.contains(t.id))) s];
    if (search != null && search.isNotEmpty) r = [for (final s in r) if (s.title.toLowerCase().contains(search.toLowerCase())) s];
    switch (sort) {
      case 'title':
        r.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case 'sort_order':
        r.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      case '-new_count':
        r.sort((a, b) => (b.readState?.newCount ?? 0).compareTo(a.readState?.newCount ?? 0));
    }
    final start = (page - 1) * perPage;
    final window = r.skip(start).take(perPage).toList();
    return Ok(PagedResult(items: window, total: r.length, page: page, perPage: perPage, hasNext: start + perPage < r.length));
  }

  @override
  Future<Result<FollowedSeries>> patchSeries(
    int followedId, {
    bool? isFavorite,
    String? readingStatus,
    bool? notify,
    bool? matureOverride,
    bool clearMatureOverride = false,
    int? sortOrder,
  }) async {
    patches.add({'id': followedId, if (isFavorite != null) 'is_favorite': isFavorite, if (readingStatus != null) 'reading_status': readingStatus, if (notify != null) 'notify': notify, if (sortOrder != null) 'sort_order': sortOrder});
    inflight++;
    if (inflight > peak) peak = inflight;
    if (patchDelay > Duration.zero) await Future<void>.delayed(patchDelay);
    inflight--;
    if (failPatchIds.contains(followedId)) return const Err(NetworkError(message: 'nope'));
    final i = all.indexWhere((s) => s.id == followedId);
    if (i < 0) return const Err(UnknownError(message: 'missing'));
    final next = all[i].copyWith(isFavorite: isFavorite, readingStatus: readingStatus, notify: notify, sortOrder: sortOrder);
    all = [...all]..[i] = next;
    return Ok(next);
  }

  @override
  Future<Result<void>> unfollow(int followedId) async {
    unfollowed.add(followedId);
    inflight++;
    if (inflight > peak) peak = inflight;
    if (patchDelay > Duration.zero) await Future<void>.delayed(patchDelay);
    inflight--;
    all = [for (final s in all) if (s.id != followedId) s];
    return const Ok(null);
  }

  @override
  Future<Result<FollowedSeries>> follow({required String sourceId, required String seriesKey}) async {
    followedAgain.add('$sourceId/$seriesKey');
    final row = shelfSeries(900 + followedAgain.length, source: sourceId);
    return Ok(row);
  }

  @override
  Future<Result<SeriesDetail>> getSeries(int followedId) async {
    final d = details[followedId];
    return d == null ? const Err(ApiError(statusCode: 404, message: 'not found', code: 'series_not_found')) : Ok(d);
  }

  @override
  Future<Result<List<ContinueReadingItem>>> continueReading({int limit = 10}) async => Ok(continueRows);

  @override
  Future<Result<List<Tag>>> listTags({String? category}) async => Ok(tags);

  @override
  Future<Result<Tag>> createTag({required String name, String category = 'custom', String? color}) async {
    tagCalls.add('create:$name');
    final t = Tag(id: 100 + tags.length, name: name, category: category);
    tags = [...tags, t];
    return Ok(t);
  }

  @override
  Future<Result<Tag>> renameTag(int tagId, String name) async {
    tagCalls.add('rename:$tagId:$name');
    tags = [for (final t in tags) t.id == tagId ? Tag(id: t.id, name: name, category: t.category) : t];
    return Ok(tags.firstWhere((t) => t.id == tagId));
  }

  @override
  Future<Result<void>> deleteTag(int tagId) async {
    tagCalls.add('delete:$tagId');
    tags = [for (final t in tags) if (t.id != tagId) t];
    return const Ok(null);
  }

  @override
  Future<Result<List<Collection>>> listCollections() async => Ok(shelves);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Unread extends UnreadCountNotifier {
  _Unread(this.n);
  final int n;
  @override
  int build() => n;
}

class LibRig {
  LibRig(this.router, this.container, this.lib, this.rec);
  final GoRouter router;
  final ProviderContainer container;
  final ShelfLibrary lib;
  final Recorder rec;
  String get at => cineLocationOf(router);
}

/// A fixed "now" so ages in captions do not depend on the machine.
final DateTime kShelfNow = DateTime.utc(2026, 9, 30, 21, 4);

/// The real Cinematic router and app frame with the Library's data layer faked, started at [start].
Future<LibRig> pumpShelf(
  WidgetTester t, {
  List<FollowedSeries>? rows,
  ShelfLibrary? lib,
  String start = '/library',
  Size size = const Size(390, 844),
  TargetPlatform platform = TargetPlatform.android,
  double textScale = 1,
  bool reduced = false,
  ContentMode mode = ContentMode.manga,
  bool novelsEnabled = false,
  bool gateOpen = false,
  int unread = 3,
  List<DownloadedSeriesGroup> saved = const [],
  Map<String, Object> prefs = const {},
  List<Override> extra = const [],
  bool settle = true,
}) async {
  SharedPreferences.setMockInitialValues(testPrefsDefaults(prefs));
  final p = await SharedPreferences.getInstance();
  final fake = lib ?? ShelfLibrary(all: rows ?? [for (var i = 1; i <= 12; i++) shelfSeries(i)]);
  final rec = Recorder();
  final c = ProviderContainer(overrides: [
    sharedPrefsProvider.overrideWithValue(p),
    skinIdProvider.overrideWithValue(SkinId.cinematic),
    authenticatedAuthOverride(),
    activeProfileOverride(),
    profileSessionReadyOverride(),
    apiBaseUrlOverride('http://example.test'),
    ...noDownloadsStoreOverrides(),
    ...contentModeOverrides(mode: mode, novelsEnabled: novelsEnabled),
    unreadNotificationCountProvider.overrideWith(() => _Unread(unread)),
    newChaptersBannerProvider.overrideWith((ref) async => null),
    setupCompletedProvider.overrideWithValue(true),
    tonightIdleOverride(),
    libraryRepositoryProvider.overrideWithValue(fake),
    readerRepositoryProvider.overrideWithValue(FakeReader(rec)),
    skinHapticsProvider.overrideWithValue(RecordingHaptics(rec)),
    downloadQueueControllerProvider.overrideWith(() => RecordingQueue(rec)),
    matureGateOpenProvider.overrideWithValue(gateOpen),
    downloadedSeriesProvider.overrideWith((ref) async => saved),
    clockProvider.overrideWithValue(() => kShelfNow),
    sourcesListProvider.overrideWith((ref) async => const [
          SourceSummary(id: 'shelf', name: 'Shelf Scans', description: '', browsable: true, supportsImport: false),
        ]),
    ...extra,
  ],);
  addTearDown(c.dispose);
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final router = c.read(skinRouterProvider);
  if (start != '/') router.go(start);
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp.router(
      theme: CinematicSkin.baseTheme.copyWith(platform: platform),
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale), disableAnimations: reduced),
        child: CineAppFrame(splash: false, child: child!),
      ),
    ),
  ),);
  if (settle) await settleShelf(t);
  addTearDown(() async => t.pumpWidget(const SizedBox()));
  return LibRig(router, c, fake, rec);
}

/// Lets fetches, entrance animations and rules run: 100 ms steps.
Future<void> settleShelf(WidgetTester t, {Duration by = const Duration(milliseconds: 1600)}) async {
  for (var ms = 0; ms < by.inMilliseconds; ms += 100) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

/// A device-saved chapter group for `shelfSeries(id)`.
DownloadedSeriesGroup savedGroup(int id, {String source = 'shelf'}) => DownloadedSeriesGroup(
      sourceId: source,
      seriesKey: 'series-$id',
      seriesTitle: 'Series $id',
      chapters: [
        SavedChapter(
          rowId: id,
          scopeId: 'u1p1',
          sourceId: source,
          seriesKey: 'series-$id',
          chapterKey: 'c1',
          chapterNumber: 1,
          title: null,
          seriesTitle: 'Series $id',
          pageCount: 3,
          bytes: 10,
          state: DownloadChapterState.complete,
          pinned: false,
          readAt: null,
          createdAt: DateTime(2026),
          retryCount: 0,
          error: null,
        ),
      ],
    );

/// `GET /library/series/{id}` answers 500 (a `CORRECTION`, not a missing series).
final libraryDetailFails = seriesDetailProvider.overrideWith((ref, id) async => throw const ApiError(statusCode: 500, code: 'boom', message: 'boom'));
