import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/pagination.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_identity.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/models/suggestion.dart';
import 'package:manhwamaniacs/features/library/repositories/library_repository.dart';
import 'package:manhwamaniacs/features/novels/providers/novels_gate_provider.dart';
import 'package:manhwamaniacs/features/ocr/models/ocr_search_result.dart';
import 'package:manhwamaniacs/features/ocr/models/page_text.dart';
import 'package:manhwamaniacs/features/ocr/providers/ocr_providers.dart';
import 'package:manhwamaniacs/features/ocr/repositories/ocr_repository.dart';
import 'package:manhwamaniacs/features/reader/models/reader_page.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/models/source_genre.dart';
import 'package:manhwamaniacs/features/sources/models/source_health.dart';
import 'package:manhwamaniacs/features/sources/models/source_pin.dart';
import 'package:manhwamaniacs/features/sources/models/source_search_group.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/providers/source_pins_provider.dart';
import 'package:manhwamaniacs/features/sources/repositories/sources_repository.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/skin_haptics.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

SourceSummary src(
  String id, {
  bool mature = false,
  bool browsable = true,
  SourceHealth? health,
  String kind = 'manga',
}) =>
    SourceSummary(
      id: id,
      name: id.toUpperCase(),
      description: 'About $id',
      browsable: browsable,
      supportsImport: false,
      mature: mature,
      contentKind: kind,
      health: health,
    );

SourceSeriesSummary series(String id, String title, String source) => SourceSeriesSummary(
      id: id,
      sourceId: source,
      title: title,
      chapterCount: 12,
      genres: const [],
      coverUrl: '',
    );

class FakeSources implements SourcesRepository {
  FakeSources({
    this.sources = const [],
    this.groups = const [],
    this.series = const [],
    this.listSeriesError,
    this.modes = const [],
    this.genres = const [],
    this.pages = const [],
    this.next = false,
  });

  final List<SourceSummary> sources;
  final List<SourceSearchGroup> groups;
  final List<SourceSeriesSummary> series;
  final AppError? listSeriesError;
  final List<SourceBrowseMode> modes;
  final List<SourceGenre> genres;
  final List<ReaderPage> pages;
  final bool next;
  final replaced = <List<String>>[];
  final searched = <String>[];
  int seriesCalls = 0;

  @override
  Future<Result<List<SourceSummary>>> listSources() async => Ok(sources);

  @override
  Future<Result<GroupedSearchResult>> searchGrouped(
    String query, {
    int page = 1,
    int perPage = 40,
    int? tier,
  }) async {
    searched.add(query);
    return Ok(GroupedSearchResult(groups: groups, sourcesQueried: groups.length));
  }

  @override
  Future<Result<List<SourcePin>>> replacePins(List<String> ids) async {
    replaced.add(ids);
    return Ok([
      for (var i = 0; i < ids.length; i++) SourcePin(sourceId: ids[i], sortOrder: i, name: ids[i].toUpperCase()),
    ]);
  }

  @override
  Future<Result<List<SourcePin>>> listPins() async => const Ok([]);

  @override
  Future<Result<PagedResult<SourceSeriesSummary>>> listSeries(
    String sourceId, {
    int page = 1,
    String? query,
    String? sort,
    String? genre,
    bool refresh = false,
  }) async {
    seriesCalls++;
    if (listSeriesError != null) {
      return Err(listSeriesError!);
    }
    return Ok(PagedResult(items: series, total: series.length, page: page, perPage: 20, hasNext: next));
  }

  @override
  Future<Result<List<SourceBrowseMode>>> listBrowseModes(String sourceId) async => Ok(modes);

  @override
  Future<Result<List<SourceGenre>>> listGenres(String sourceId) async => Ok(genres);

  @override
  Future<Result<List<SourceSummary>>> listHealth() async => Ok(sources);

  @override
  Future<Result<SourceHealthSummary>> healthSummary() async =>
      Ok(SourceHealthSummary(total: sources.length, ok: sources.length));

  @override
  Future<Result<List<ReaderPage>>> getChapterPages(String sourceId, String chapterKey) async => Ok(pages);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeLibrary implements LibraryRepository {
  FakeLibrary({this.ai = true});

  final bool ai;

  @override
  Future<Result<SuggestionAvailability>> suggestAvailability() async =>
      Ok(SuggestionAvailability(available: ai, reason: ai ? 'ok' : 'not_configured', remainingToday: 3));

  @override
  Future<Result<PagedResult<FollowedSeries>>> listSeries({
    int page = 1,
    int perPage = 40,
    String? sort,
    String? search,
    String? readingStatus,
    bool? isFavorite,
  }) async =>
      const Ok(PagedResult(items: [], total: 0, page: 1, perPage: 40, hasNext: false));

  @override
  Future<Result<List<GenreWeight>>> genreWeights({int limit = 40}) async => const Ok([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeOcr implements OcrRepository {
  FakeOcr({this.page = OcrSearchPage.empty});

  final OcrSearchPage page;
  final queries = <String>[];

  @override
  Future<Result<OcrSearchPage>> search(String query, {int limit = 20, int offset = 0}) async {
    queries.add(query);
    return Ok(page);
  }

  @override
  Future<Result<List<PageText>?>> fetchChapterText(ChapterIdentity id) async => const Ok(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePins extends SourcePinsNotifier {
  FakePins(this.pins, {this.synced = true});

  final List<SourcePin> pins;
  final bool synced;

  @override
  Future<SourcePinsState> build() async => SourcePinsState(pins: pins, synced: synced);
}

/// Pumps [screen] inside the providers every discover screen needs.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  FakeSources? sources,
  FakeLibrary? library,
  FakeOcr? ocr,
  bool ocrOn = true,
  List<SourcePin> pins = const [],
  bool pinsSynced = true,
  Size size = const Size(390, 844),
  bool reduced = false,
  TargetPlatform platform = TargetPlatform.android,
  List<Override> extra = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => screen),
      GoRoute(path: '/:rest(.*)', builder: (context, s) => Scaffold(body: Text('at ${s.uri}'))),
    ],
    initialLocation: '/',
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        novelsEnabledProvider.overrideWithValue(false),
        skinIdProvider.overrideWithValue(SkinId.cinematic),
        skinHapticsProvider.overrideWithValue(
          SkinHaptics(skin: SkinId.cinematic, map: const {}, enabled: false),
        ),
        sourcesRepositoryProvider.overrideWithValue(sources ?? FakeSources()),
        libraryRepositoryProvider.overrideWithValue(library ?? FakeLibrary()),
        ocrRepositoryProvider.overrideWithValue(ocr ?? FakeOcr()),
        ocrFeatureVisibleProvider.overrideWithValue(ocrOn),
        downloadsStoreProvider.overrideWithValue(null),
        sourcePinsProvider.overrideWith(() => FakePins(pins, synced: pinsSynced)),
        ...extra,
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: ThemeData(
          brightness: Brightness.dark,
          platform: platform,
          extensions: const [cinematicTokens],
        ),
        builder: (c, child) => MediaQuery(
          data: MediaQuery.of(c).copyWith(disableAnimations: reduced),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> settle(WidgetTester tester, [int ms = 600]) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
