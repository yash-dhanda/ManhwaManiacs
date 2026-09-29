import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/pagination.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/library/models/global_search_result.dart';
import 'package:manhwamaniacs/features/library/providers/library_list_provider.dart';
import 'package:manhwamaniacs/features/ocr/models/ocr_search_result.dart';
import 'package:manhwamaniacs/features/ocr/providers/dialogue_still_provider.dart';
import 'package:manhwamaniacs/features/ocr/utils/still_crop.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/models/source_genre.dart';
import 'package:manhwamaniacs/features/sources/models/source_health.dart';
import 'package:manhwamaniacs/features/sources/models/source_pin.dart';
import 'package:manhwamaniacs/features/sources/models/source_search_group.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/catalogue/catalogue_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/dialogue/dialogue_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/dialogue/subtitled_still.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/discover_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/sources/source_row.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/sources/sources_screen.dart';

import 'harness.dart';

SourceSearchGroup _group(String id, int n) => SourceSearchGroup(
      source: id,
      sourceName: id.toUpperCase(),
      status: n == 0 ? SourceGroupStatus.empty : SourceGroupStatus.ok,
      items: [
        for (var i = 0; i < n; i++)
          GlobalSearchItem(kind: 'source', source: id, seriesId: '$id$i', title: 'Title $id $i'),
      ],
    );

const _pins = [
  SourcePin(sourceId: 'asura', sortOrder: 0, name: 'ASURA'),
  SourcePin(sourceId: 'mangadex', sortOrder: 1, name: 'MANGADEX'),
];

final _sources = [
  src('asura', health: const SourceHealth(status: SourceHealthStatus.ok)),
  src('mangadex', health: const SourceHealth(status: SourceHealthStatus.failing, consecutiveFailures: 3)),
];

/// Tier 1 answers at once and points at tier 2; tier 2 waits on [tier2].
class _Tiered extends FakeSources {
  _Tiered() : super(sources: [src('asura')]);

  final tier2 = Completer<Result<GroupedSearchResult>>();
  final tiers = <int?>[];

  @override
  Future<Result<GroupedSearchResult>> searchGrouped(String query, {int page = 1, int perPage = 40, int? tier}) {
    tiers.add(tier);
    if (tier == 2) return tier2.future;
    return Future.value(
      Ok(GroupedSearchResult(groups: [_group('asura', 2)], tier: 1, nextTier: 2, sourcesDeferred: 5)),
    );
  }
}

OcrSearchResult _hit(int i, {int? page = 3}) => OcrSearchResult(
      sourceId: 'asura',
      seriesKey: 'tog',
      chapterKey: '$i',
      snippet: 'I said <mark>hello</mark> $i',
      wordCount: 10,
      engine: 'mlkit',
      highlightedTerms: const ['hello'],
      page: page,
      box: const OcrBox(x: 0.4, y: 0.4, w: 0.2, h: 0.1),
    );

OcrSearchPage _page(int n) => OcrSearchPage(
      items: [for (var i = 0; i < n; i++) _hit(i)],
      total: n,
      offset: 0,
      limit: 20,
      hasMore: false,
    );

bool _fieldFocused(WidgetTester tester) => tester.widget<TextField>(find.byType(TextField).first).focusNode!.hasFocus;

void main() {
  stillWiring();
  group('Discover', () {
    testWidgets('/ focuses the field', (tester) async {
      await pumpScreen(tester, const DiscoverScreen(), sources: FakeSources(sources: _sources), pins: _pins);
      await settle(tester);
      expect(_fieldFocused(tester), isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.slash);
      await tester.pump();
      expect(_fieldFocused(tester), isTrue);
    });

    testWidgets('Esc clears the query, and unfocuses an empty field', (tester) async {
      await pumpScreen(tester, const DiscoverScreen());
      await settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.slash);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(_fieldFocused(tester), isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.slash);
      await tester.enterText(find.byType(TextField), 'solo');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '');
    });

    testWidgets('Enter searches at once, before the debounce', (tester) async {
      final sources = FakeSources(sources: _sources);
      await pumpScreen(tester, const DiscoverScreen(), sources: sources);
      await settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.slash);
      await tester.enterText(find.byType(TextField), 'solo');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump(const Duration(milliseconds: 50));
      expect(sources.searched, contains('solo'));
      await settle(tester, 500);
    });

    testWidgets('3 switches to the third scope', (tester) async {
      await pumpScreen(tester, const DiscoverScreen());
      await settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.slash);
      await tester.pump();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
      await settle(tester);
      expect(find.textContaining('scope=sources'), findsOneWidget);
    });

    testWidgets('the field is italic while empty and Roman once it holds a query', (tester) async {
      await pumpScreen(tester, const DiscoverScreen());
      await settle(tester);
      TextStyle style() => tester.widget<TextField>(find.byType(TextField)).style!;
      final empty = style().fontStyle;
      await tester.enterText(find.byType(TextField), 'so');
      await tester.pump();
      expect(style().fontStyle, FontStyle.normal);
      expect(empty, isNot(FontStyle.normal));
      expect(tester.widget<TextField>(find.byType(TextField)).cursorWidth, 3);
    });

    testWidgets('the third tap on the thumb index focuses the field', (tester) async {
      await pumpScreen(tester, const DiscoverScreen());
      await settle(tester);
      final c = ProviderScope.containerOf(tester.element(find.byType(DiscoverScreen)));
      expect(_fieldFocused(tester), isFalse);
      c.read(discoverFocusSignalProvider.notifier).state++;
      await tester.pump();
      expect(_fieldFocused(tester), isTrue);
    });

    testWidgets('tier 1 publishes, tier 2 runs behind the rule, then merges', (tester) async {
      final sources = _Tiered();
      await pumpScreen(tester, const DiscoverScreen(q: 'solo'), sources: sources);
      await settle(tester, 800);
      expect(sources.tiers, [1, 2]);
      expect(find.text('2 results so far · searching 5 more sources…'), findsOneWidget);
      expect(find.byType(IndeterminateRule), findsOneWidget);
      expect(find.text('ASURA'), findsOneWidget);
      sources.tier2.complete(Ok(GroupedSearchResult(groups: [_group('mangadex', 3)], tier: 2, sourcesFailed: 1)));
      await settle(tester, 500);
      expect(find.byType(IndeterminateRule), findsNothing);
      expect(find.text('5 results · 2 sources'), findsOneWidget);
      expect(find.text('MANGADEX'), findsOneWidget);
      expect(find.textContaining("1 source didn't answer."), findsOneWidget);
    });

    testWidgets('the filter slugs bind searchGroupFilterProvider', (tester) async {
      await pumpScreen(
        tester,
        const DiscoverScreen(q: 'solo'),
        sources: FakeSources(groups: [_group('asura', 3), _group('quiet', 0)]),
      );
      await settle(tester, 800);
      final c = ProviderScope.containerOf(tester.element(find.byType(DiscoverScreen)));
      await tester.tap(find.text('PINNED'));
      await tester.pump();
      expect(c.read(searchGroupFilterProvider), SearchGroupFilter.pinned);
      await tester.tap(find.text('WITH RESULTS'));
      await tester.pump();
      expect(c.read(searchGroupFilterProvider), SearchGroupFilter.hasResults);
    });

    testWidgets('genre tiles cap at 12 with All n genres', (tester) async {
      await pumpScreen(
        tester,
        const DiscoverScreen(),
        pins: _pins,
        sources: FakeSources(
          sources: _sources,
          genres: [for (var i = 0; i < 15; i++) SourceGenre(id: 'g$i', label: 'Genre ${i.toString().padLeft(2, '0')}')],
        ),
      );
      await settle(tester, 800);
      expect(find.text('All 15 genres'), findsOneWidget);
      expect(find.textContaining('Genre 0'), findsWidgets);
      expect(find.text('Genre 12'), findsNothing);
      await tester.ensureVisible(find.text('All 15 genres'));
      await tester.pump();
      await tester.tap(find.text('All 15 genres'));
      await tester.pump();
      expect(find.text('Fewer genres'), findsOneWidget);
    });

    testWidgets('trending: two titles per source, capped, from the popular pages', (tester) async {
      await pumpScreen(
        tester,
        const DiscoverScreen(),
        pins: _pins,
        sources: FakeSources(
          sources: _sources,
          modes: const [SourceBrowseMode(id: 'popular', label: 'Popular')],
          series: [for (var i = 0; i < 6; i++) series('s$i', 'Trend $i', 'asura')],
        ),
      );
      await settle(tester, 800);
      expect(find.textContaining('Trending on your sources'), findsOneWidget);
      expect(find.textContaining('Trend 0'), findsWidgets);
      expect(find.textContaining('Trend 5'), findsNothing);
    });

    testWidgets('long-press on a result poster opens Quick look', (tester) async {
      await pumpScreen(
        tester,
        const DiscoverScreen(q: 'solo'),
        sources: FakeSources(groups: [_group('asura', 2)]),
      );
      await settle(tester, 800);
      await tester.longPress(find.text('Title asura 0'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('IN DIALOGUE'), findsNothing);
    });

    testWidgets('a rate limited search shows the live countdown', (tester) async {
      await pumpScreen(
        tester,
        const DiscoverScreen(q: 'solo'),
        extra: [searchListProvider.overrideWith(_RateLimitedSearch.new)],
      );
      await settle(tester, 800);
      expect(find.text('SLOW DOWN'), findsOneWidget);
      expect(find.text('Retrying in 3 s'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Retrying in 2 s'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3)); // zero: retries
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('Sources', () {
    testWidgets('Alt+Down moves the focused pinned row; the full order is written', (tester) async {
      final repo = FakeSources(sources: _sources);
      await pumpScreen(tester, const SourcesScreen(), sources: repo, pins: _pins);
      await settle(tester);
      for (var i = 0; i < 20; i++) {
        final ctx = FocusManager.instance.primaryFocus?.context;
        if (ctx?.findAncestorWidgetOfExactType<SourceRow>()?.source.id == 'asura') break;
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      await simulateKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await simulateKeyUpEvent(LogicalKeyboardKey.altLeft);
      await settle(tester, 300);
      expect(repo.replaced, [
        ['mangadex', 'asura'],
      ]);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('/ focuses the filter; p toggles the focused row and toasts', (tester) async {
      final repo = FakeSources(sources: _sources);
      await pumpScreen(tester, const SourcesScreen(), sources: repo);
      await settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.slash);
      await tester.pump();
      expect(_fieldFocused(tester), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.tap(find.byTooltip('More for ASURA').first);
      await settle(tester, 300);
      await tester.tap(find.text('Pin'));
      await settle(tester, 300);
      expect(find.text('ASURA pinned'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('ASURA pinned'), findsNothing);
    });

    testWidgets('the trailing dots-three opens the same menu', (tester) async {
      await pumpScreen(tester, const SourcesScreen(), sources: FakeSources(sources: _sources), pins: _pins);
      await settle(tester);
      await tester.tap(find.byTooltip('More for ASURA').first);
      await settle(tester, 300);
      expect(find.text('Health details'), findsOneWidget);
      expect(find.text('Move down'), findsOneWidget);
    });

    testWidgets('the tablet table has KIND and HEALTH heads', (tester) async {
      await pumpScreen(
        tester,
        const SourcesScreen(),
        sources: FakeSources(sources: _sources),
        pins: _pins,
        size: const Size(834, 1194),
      );
      await settle(tester);
      expect(find.text('KIND'), findsOneWidget);
      expect(find.text('HEALTH'), findsOneWidget);
    });
  });

  group('Catalogue', () {
    final wall = [for (var i = 0; i < 10; i++) series('s$i', 'Series $i', 'asura')];

    testWidgets('] steps the browse mode and / focuses the search', (tester) async {
      await pumpScreen(
        tester,
        const CatalogueScreen(sourceId: 'asura'),
        sources: FakeSources(
          sources: [src('asura')],
          series: wall,
          modes: const [SourceBrowseMode(id: 'popular', label: 'Popular'), SourceBrowseMode(id: 'latest', label: 'Latest')],
        ),
      );
      await settle(tester, 800);
      await tester.sendKeyEvent(LogicalKeyboardKey.slash);
      await tester.pump();
      expect(_fieldFocused(tester), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.bracketRight);
      await settle(tester, 300);
      expect(find.textContaining('mode=latest'), findsOneWidget);
    });

    testWidgets('three posters per row on phones, five on tablets', (tester) async {
      Future<int> perRow(Size size) async {
        await pumpScreen(
          tester,
          const CatalogueScreen(sourceId: 'asura'),
          sources: FakeSources(sources: [src('asura')], series: wall),
          size: size,
        );
        await settle(tester, 800);
        final tops = [for (var i = 0; i < 10; i++) tester.getTopLeft(find.text('Series $i').first).dy];
        return tops.where((y) => (y - tops.first).abs() < 2).length;
      }

      expect(await perRow(const Size(390, 844)), 3);
      expect(await perRow(const Size(834, 1194)), 5);
    });

    testWidgets('the opening state: dial at 400 ms, deck and tip at 3 s', (tester) async {
      await pumpScreen(tester, const CatalogueScreen(sourceId: 'asura'), sources: _Never());
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(LeaderDial), findsNothing);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(LeaderDial), findsWidgets);
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('This source can take about 10 s.'), findsOneWidget);
    });

    testWidgets('a rate limited deck counts down live', (tester) async {
      await pumpScreen(
        tester,
        const CatalogueScreen(sourceId: 'asura'),
        sources: FakeSources(
          sources: [src('asura')],
          listSeriesError: const ApiError(statusCode: 429, code: 'rate_limited', message: 'slow', details: {'retry_after': 12}),
        ),
      );
      await settle(tester, 800);
      expect(find.text('Rate limited · retrying in 12 s'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Rate limited · retrying in 10 s'), findsOneWidget);
      await tester.pump(const Duration(seconds: 13));
    });

    testWidgets('long-press on a wall poster opens Quick look', (tester) async {
      await pumpScreen(
        tester,
        const CatalogueScreen(sourceId: 'asura'),
        sources: FakeSources(sources: [src('asura')], series: wall),
      );
      await settle(tester, 800);
      await tester.longPress(find.text('Series 1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Open'), findsOneWidget);
    });
  });

  group('Dialogue', () {
    testWidgets('/ focuses the field', (tester) async {
      await pumpScreen(tester, const DialogueScreen());
      await settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.slash);
      await tester.pump();
      expect(_fieldFocused(tester), isTrue);
    });

    testWidgets('rack focus on the first 12 stills; the 13th develops with a plain fade', (tester) async {
      await pumpScreen(tester, const DialogueScreen(q: 'hello'), ocr: FakeOcr(page: _page(13)), size: const Size(390, 12000));
      await settle(tester, 800);
      final stills = tester.widgetList<SubtitledStill>(find.byType(SubtitledStill, skipOffstage: false)).toList();
      expect(stills.length, 13);
      expect(stills.take(12).every((s) => s.rack), isTrue);
      expect(stills.last.rack, isFalse);
    });

    testWidgets('the highlight band sweeps in: partial mid-way, full at the end', (tester) async {
      await pumpScreen(tester, const DialogueScreen(q: 'hello'), ocr: FakeOcr(page: _page(1)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 80));
      final mid = tester.widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox)).map((b) => b.widthFactor!).toList();
      expect(mid, isNotEmpty);
      await tester.pump(const Duration(milliseconds: 500));
      final end = tester.widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox)).map((b) => b.widthFactor!);
      expect(end.every((v) => v == 1), isTrue);
    });

    testWidgets('long-press and the dots-three open Quick look', (tester) async {
      await pumpScreen(tester, const DialogueScreen(q: 'hello'), ocr: FakeOcr(page: _page(1)));
      await settle(tester, 800);
      await tester.tap(find.byTooltip('More for this line'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Open in reader'), findsOneWidget);
    });
  });
}

/// The search fails with a 429 by state, not by throwing out of `build`.
class _RateLimitedSearch extends SearchListNotifier {
  @override
  Future<GroupedSearchResult> build() async {
    unawaited(
      Future<void>.microtask(
        () => state = const AsyncError(
          ApiError(statusCode: 429, code: 'rate_limited', message: 'slow', details: {'retry_after': 3}),
          StackTrace.empty,
        ),
      ),
    );
    return Completer<GroupedSearchResult>().future; // no previous value to show
  }

  @override
  Future<void> refresh() async {}
}

class _Never extends FakeSources {
  _Never() : super(sources: [src('asura')]);

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

// A valid 1 x 1 PNG.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

void stillWiring() {
  testWidgets('the still crops the page in layout by stillCropWindow', (tester) async {
    await pumpScreen(
      tester,
      const DialogueScreen(q: 'hello'),
      ocr: FakeOcr(page: _page(1)),
      extra: [
        dialogueStillProvider.overrideWith((ref, key) async => DialogueStill(bytes: _png, aspect: 0.5)),
      ],
    );
    await settle(tester, 800);
    final w = stillCropWindow(_hit(0).box, 0.5);
    final stillBox = tester.getSize(find.byType(SubtitledStill));
    final pageW = stillBox.width / w.width;
    final shift = tester
        .widgetList<Transform>(find.descendant(of: find.byType(SubtitledStill), matching: find.byType(Transform)))
        .map((t) => t.transform.getTranslation())
        .where((v) => v.x != 0 || v.y != 0)
        .toList();
    expect(shift, isNotEmpty);
    expect(shift.first.x, closeTo(-w.left * pageW, 0.5));
    expect(shift.first.y, closeTo(-w.top * (pageW / 0.5), 0.5));
  });
}
