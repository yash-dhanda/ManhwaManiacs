import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/pagination.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/library/models/global_search_result.dart';
import 'package:manhwamaniacs/features/library/providers/library_list_provider.dart';
import 'package:manhwamaniacs/features/ocr/models/ocr_search_result.dart';
import 'package:manhwamaniacs/features/ocr/providers/dialogue_still_provider.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/models/source_genre.dart';
import 'package:manhwamaniacs/features/sources/models/source_health.dart';
import 'package:manhwamaniacs/features/sources/models/source_pin.dart';
import 'package:manhwamaniacs/features/sources/models/source_search_group.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/catalogue/catalogue_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/dialogue/dialogue_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/discover_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/sources/sources_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../skins/cinematic/discover/harness.dart';
import '../support/shot_covers.dart';
import '../support/shot_harness.dart';
import '../support/shot_network.dart';
import '../support/skin_shots.dart';

/// mobile/16 proof: every Discover, Sources, Catalogue and Dialogue state, on
/// phone and tablet, with a `-reduced` copy on the phone.
///
///   MM_PROOF_DIR=../docs/redesign/proof/mobile-16 flutter test \
///     test/screenshots/cinematic/mobile_16_discover_shots_test.dart
///
/// Without MM_PROOF_DIR the shots are rasterised and discarded, so the suite
/// still proves every state renders. Titles and covers are invented.

const _phone = SkinShotSize('phone', Size(390, 844), 2.0, EdgeInsets.only(top: 47, bottom: 34));
const _tablet = SkinShotSize('tablet', Size(834, 1194), 1.5, EdgeInsets.only(top: 24, bottom: 20));

const _titles = [
  'The Lantern Courier',
  'Sword of the Ninth Spring',
  'Skyward Gardeners',
  'Salt and Ember',
  'A Quiet Kingdom',
  'Harbour of Small Gods',
  'The Cartographer Twins',
  'Winter at Halcyon Row',
];

String _slug(String t) => t.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
String _cover(String t) => '/covers/${_slug(t)}.png';

SourceSeriesSummary _series(int i, String source) => SourceSeriesSummary(
      id: _slug(_titles[i % _titles.length]),
      sourceId: source,
      title: _titles[i % _titles.length],
      chapterCount: 40 + i * 13,
      genres: const [],
      coverUrl: _cover(_titles[i % _titles.length]),
    );

SourceSearchGroup _group(String id, int n, {bool error = false}) => SourceSearchGroup(
      source: id,
      sourceName: id.toUpperCase(),
      status: error ? SourceGroupStatus.error : (n == 0 ? SourceGroupStatus.empty : SourceGroupStatus.ok),
      items: [
        for (var i = 0; i < n; i++)
          GlobalSearchItem(
            kind: 'source',
            source: id,
            seriesId: _slug(_titles[i % _titles.length]),
            title: _titles[i % _titles.length],
            coverUrl: _cover(_titles[i % _titles.length]),
            extra: {'chapter_count': 40 + i * 13},
          ),
      ],
    );

const _pins = [
  SourcePin(sourceId: 'lantern', sortOrder: 0, name: 'LANTERN'),
  SourcePin(sourceId: 'harbour', sortOrder: 1, name: 'HARBOUR'),
];

final _sources = [
  src('lantern', health: const SourceHealth(status: SourceHealthStatus.ok)),
  src('harbour', health: const SourceHealth(status: SourceHealthStatus.failing, consecutiveFailures: 3)),
  src('ember', health: const SourceHealth(status: SourceHealthStatus.dead)),
  src('quiet', mature: true, health: const SourceHealth(status: SourceHealthStatus.ok)),
];

const _hit = OcrSearchResult(
  sourceId: 'lantern',
  seriesKey: 'the-lantern-courier',
  chapterKey: '88',
  snippet: 'I told you the lantern would <mark>never</mark> go out',
  wordCount: 214,
  engine: 'apple_vision',
  highlightedTerms: ['never'],
  page: 12,
  box: OcrBox(x: 0.4, y: 0.4, w: 0.2, h: 0.1),
);

OcrSearchPage _ocrPage(int n) => OcrSearchPage(
      items: [for (var i = 0; i < n; i++) _hit],
      total: n,
      offset: 0,
      limit: 20,
      hasMore: false,
    );

class _Tiered extends FakeSources {
  _Tiered() : super(sources: _sources);

  @override
  Future<Result<GroupedSearchResult>> searchGrouped(String query, {int page = 1, int perPage = 40, int? tier}) {
    if (tier == 2) return Completer<Result<GroupedSearchResult>>().future;
    return Future.value(
      Ok(GroupedSearchResult(groups: [_group('lantern', 6)], tier: 1, nextTier: 2, sourcesDeferred: 71)),
    );
  }
}

class _Failing extends FakeSources {
  _Failing(this.error) : super(sources: _sources);

  final AppError error;

  @override
  Future<Result<GroupedSearchResult>> searchGrouped(String query, {int page = 1, int perPage = 40, int? tier}) async =>
      Err(error);
}

class _Never extends FakeSources {
  _Never() : super(sources: _sources);

  @override
  Future<Result<PagedResult<SourceSeriesSummary>>> listSeries(
    String sourceId, {
    int page = 1,
    String? query,
    String? sort,
    String? genre,
    bool refresh = false,
  }) =>
      Completer<Result<PagedResult<SourceSeriesSummary>>>().future;
}

class _NeverSources extends FakeSources {
  @override
  Future<Result<List<SourceSummary>>> listSources() => Completer<Result<List<SourceSummary>>>().future;
}

class _RateLimitedSearch extends SearchListNotifier {
  @override
  Future<GroupedSearchResult> build() async {
    unawaited(
      Future<void>.microtask(
        () => state = const AsyncError(
          ApiError(statusCode: 429, code: 'rate_limited', message: 'slow', details: {'retry_after': 90}),
          StackTrace.empty,
        ),
      ),
    );
    return Completer<GroupedSearchResult>().future;
  }
}

class _Novel extends ContentModeController {
  @override
  ContentMode build() => ContentMode.novel;
}

late Uint8List _stillPng;

class _Shot {
  const _Shot(this.name, this.screen, this.build);

  final String name;
  final Widget screen;
  final List<Override> Function(SharedPreferences prefs) build;
}

const _netErr = NetworkError(message: 'offline');

List<_Shot> _shots() {
  final library = FakeLibrary();
  FakeSources s({
    List<SourceSearchGroup> groups = const [],
    List<SourceSummary>? sources,
    List<SourceSeriesSummary> series = const [],
    AppError? error,
  }) =>
      FakeSources(
        sources: sources ?? _sources,
        groups: groups,
        series: series,
        listSeriesError: error,
        modes: const [
          SourceBrowseMode(id: 'popular', label: 'Popular'),
          SourceBrowseMode(id: 'latest', label: 'Latest'),
          SourceBrowseMode(id: 'top', label: 'Top rated'),
        ],
        genres: const [
          SourceGenre(id: 'r', label: 'Romance'),
          SourceGenre(id: 'a', label: 'Action'),
          SourceGenre(id: 'f', label: 'Fantasy'),
          SourceGenre(id: 'd', label: 'Drama'),
        ],
      );
  final wall = [for (var i = 0; i < 12; i++) _series(i, 'lantern')];
  List<Override> base(
    SharedPreferences p, {
    FakeSources? sources,
    FakeOcr? ocr,
    bool ocrOn = true,
    List<SourcePin> pins = _pins,
    bool synced = true,
    List<Override> extra = const [],
  }) =>
      [
        ...discoverOverrides(p, sources: sources ?? s(), library: library, ocr: ocr, ocrOn: ocrOn, pins: pins, pinsSynced: synced),
        ...extra,
      ];

  return [
    _Shot('discover-idle', const DiscoverScreen(), (p) => base(p, sources: s(series: wall))),
    _Shot('discover-searching', const DiscoverScreen(q: 'lantern'), (p) => base(p, sources: _Never2())),
    _Shot('discover-partial', const DiscoverScreen(q: 'lantern'), (p) => base(p, sources: _Tiered())),
    _Shot(
      'discover-results',
      const DiscoverScreen(q: 'lantern'),
      (p) => base(p, sources: s(groups: [_group('lantern', 6), _group('harbour', 4), _group('bad', 0, error: true), _group('quiet', 0)])),
    ),
    _Shot('discover-no-results', const DiscoverScreen(q: 'zzzz'), base),
    _Shot(
      'discover-offline',
      const DiscoverScreen(q: 'lantern'),
      (p) => base(p, sources: _Failing(_netErr)),
    ),
    _Shot(
      'discover-error',
      const DiscoverScreen(q: 'lantern'),
      (p) => base(p, sources: _Failing(const ApiError(statusCode: 500, code: 'boom', message: 'The sources are having a bad day.'))),
    ),
    _Shot(
      'discover-rate-limited',
      const DiscoverScreen(q: 'lantern'),
      (p) => base(p, extra: [searchListProvider.overrideWith(_RateLimitedSearch.new)]),
    ),
    _Shot('discover-ask', const DiscoverScreen(q: 'a quiet kingdom', scope: 'ask'), base),
    _Shot('sources-directory', const SourcesScreen(), base),
    _Shot('sources-loading', const SourcesScreen(), (p) => base(p, sources: _NeverSources())),
    _Shot('sources-none', const SourcesScreen(), (p) => base(p, sources: s(sources: const []))),
    _Shot('sources-pinned-empty', const SourcesScreen(), (p) => base(p, pins: const [])),
    _Shot('sources-pins-failed', const SourcesScreen(), (p) => base(p, synced: false)),
    _Shot('catalogue-loaded', const CatalogueScreen(sourceId: 'lantern'), (p) => base(p, sources: s(series: wall))),
    _Shot('catalogue-opening', const CatalogueScreen(sourceId: 'lantern'), (p) => base(p, sources: _Never())),
    _Shot(
      'catalogue-not-browsable',
      const CatalogueScreen(sourceId: 'lantern'),
      (p) => base(p, sources: s(sources: [src('lantern', browsable: false)])),
    ),
    _Shot(
      'catalogue-not-found',
      const CatalogueScreen(sourceId: 'gone'),
      (p) => base(p, sources: s(error: const ApiError(statusCode: 404, code: 'source_not_found', message: 'gone'))),
    ),
    _Shot(
      'catalogue-error',
      const CatalogueScreen(sourceId: 'lantern'),
      (p) => base(p, sources: s(error: const ApiError(statusCode: 500, code: 'boom', message: 'Upstream exploded'))),
    ),
    _Shot(
      'catalogue-rate-limited',
      const CatalogueScreen(sourceId: 'lantern'),
      (p) => base(p, sources: s(error: const ApiError(statusCode: 429, code: 'rate_limited', message: 'slow', details: {'retry_after': 90}))),
    ),
    _Shot('dialogue-idle', const DialogueScreen(), base),
    _Shot('dialogue-results', const DialogueScreen(q: 'never'), (p) => base(p, ocr: FakeOcr(page: _ocrPage(3)))),
    _Shot('dialogue-none', const DialogueScreen(q: 'zzz'), (p) => base(p, ocr: FakeOcr())),
    _Shot('dialogue-unavailable', const DialogueScreen(q: 'x'), (p) => base(p, ocrOn: false)),
    _Shot(
      'dialogue-novels',
      const DialogueScreen(),
      (p) => base(p, extra: [contentModeControllerProvider.overrideWith(_Novel.new)]),
    ),
    _Shot('dialogue-offline', const DialogueScreen(q: 'never'), (p) => base(p, ocr: _OfflineOcr())),
  ];
}

class _Never2 extends FakeSources {
  _Never2() : super(sources: _sources);

  @override
  Future<Result<GroupedSearchResult>> searchGrouped(String query, {int page = 1, int perPage = 40, int? tier}) =>
      Completer<Result<GroupedSearchResult>>().future;
}

class _OfflineOcr extends FakeOcr {
  @override
  Future<Result<OcrSearchPage>> search(String query, {int limit = 20, int offset = 0}) async => const Err(_netErr);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);
  setUpAll(setUpShotCoverCache);

  Future<void> shoot(WidgetTester tester, _Shot shot, SkinShotSize size, {required bool reduced}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final covers = <String, Uint8List>{};
    await tester.runAsync(() async {
      for (var i = 0; i < _titles.length; i++) {
        covers[_cover(_titles[i])] = await ShotCoverArt(title: _titles[i], seed: i).toPng(width: 300, height: 450);
      }
    });
    addShotCovers(covers);
    _stillPng = covers[_cover(_titles[1])]!;
    await captureSkinWidget(
      tester,
      name: '${shot.name}${reduced ? '-reduced' : ''}',
      size: size,
      disableAnimations: reduced,
      afterSettle: (t) => pumpUntilCoversLoad(t, rounds: 30),
      overrides: [
        ...shot.build(prefs),
        dialogueStillProvider.overrideWith((ref, key) async => DialogueStill(bytes: _stillPng, aspect: 2 / 3)),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: discoverRouter(shot.screen),
        theme: discoverTheme(),
      ),
    );
  }

  for (final shot in _shots()) {
    testWidgets('${shot.name} phone', (tester) => shoot(tester, shot, _phone, reduced: false));
    testWidgets('${shot.name} tablet', (tester) => shoot(tester, shot, _tablet, reduced: false));
    testWidgets('${shot.name} phone reduced', (tester) => shoot(tester, shot, _phone, reduced: true));
  }
}
