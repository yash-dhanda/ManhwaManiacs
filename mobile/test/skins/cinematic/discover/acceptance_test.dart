import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/global_search_result.dart';
import 'package:manhwamaniacs/features/ocr/models/ocr_search_result.dart';
import 'package:manhwamaniacs/features/sources/models/source_health.dart';
import 'package:manhwamaniacs/features/sources/models/source_pin.dart';
import 'package:manhwamaniacs/features/sources/models/source_search_group.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/catalogue/catalogue_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_extras.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_kit.dart'
    show TypedText;
import 'package:manhwamaniacs/skins/cinematic/screens/discover/dialogue/dialogue_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/discover_keys.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/discover_results.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/discover_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/sources/sources_screen.dart';

import 'harness.dart';

SourceSearchGroup _group(String id, int n) => SourceSearchGroup(
      source: id,
      sourceName: id.toUpperCase(),
      status: n == 0 ? SourceGroupStatus.empty : SourceGroupStatus.ok,
      items: [
        for (var i = 0; i < n; i++)
          GlobalSearchItem(
              kind: 'source',
              source: id,
              seriesId: '$id$i',
              title: 'Title $id $i',),
      ],
    );

const _pins = [
  SourcePin(sourceId: 'asura', sortOrder: 0, name: 'ASURA'),
  SourcePin(sourceId: 'mangadex', sortOrder: 1, name: 'MANGADEX'),
];

final _sources = [
  src('asura', health: const SourceHealth(status: SourceHealthStatus.ok)),
  src('mangadex',
      health: const SourceHealth(
          status: SourceHealthStatus.failing, consecutiveFailures: 3,),),
];

const _hit = OcrSearchResult(
  sourceId: 'asura',
  seriesKey: 'tower-of-god',
  chapterKey: '88',
  snippet: 'I said <mark>hello</mark> there',
  wordCount: 214,
  engine: 'apple_vision',
  highlightedTerms: ['hello'],
  page: 12,
  box: OcrBox(x: 0.4, y: 0.4, w: 0.2, h: 0.1),
);

typedef _Case = ({
  String name,
  Widget Function() screen,
  Future<void> Function(WidgetTester, TargetPlatform) pump
});

Future<void> _settle(WidgetTester t) => settle(t, 900);

final _cases = <_Case>[
  (
    name: 'discover',
    screen: () => const DiscoverScreen(),
    pump: (t, p) => pumpScreen(
          t,
          const DiscoverScreen(),
          pins: _pins,
          sources: FakeSources(sources: _sources),
          platform: p,
        ),
  ),
  (
    name: 'discover results',
    screen: () => const DiscoverScreen(q: 'solo'),
    pump: (t, p) => pumpScreen(
          t,
          const DiscoverScreen(q: 'solo'),
          pins: _pins,
          sources: FakeSources(sources: _sources, groups: [_group('asura', 3)]),
          platform: p,
        ),
  ),
  (
    name: 'sources',
    screen: () => const SourcesScreen(),
    pump: (t, p) => pumpScreen(
          t,
          const SourcesScreen(),
          pins: _pins,
          sources: FakeSources(sources: _sources),
          platform: p,
        ),
  ),
  (
    name: 'catalogue',
    screen: () => const CatalogueScreen(sourceId: 'asura'),
    pump: (t, p) => pumpScreen(
          t,
          const CatalogueScreen(sourceId: 'asura'),
          sources: FakeSources(
            sources: _sources,
            series: [
              for (var i = 0; i < 6; i++) series('s$i', 'Series $i', 'asura'),
            ],
          ),
          platform: p,
        ),
  ),
  (
    name: 'dialogue',
    screen: () => const DialogueScreen(q: 'hello'),
    pump: (t, p) => pumpScreen(
          t,
          const DialogueScreen(q: 'hello'),
          ocr: FakeOcr(
              page: const OcrSearchPage(
                  items: [_hit],
                  total: 1,
                  offset: 0,
                  limit: 20,
                  hasMore: false,),),
          platform: p,
        ),
  ),
];

void main() {
  for (final c in _cases) {
    testWidgets('${c.name}: iOS tap targets, labels and contrast',
        (tester) async {
      final h = tester.ensureSemantics();
      await c.pump(tester, TargetPlatform.iOS);
      await _settle(tester);
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      h.dispose();
    });

    testWidgets('${c.name}: Android tap targets, labels and contrast',
        (tester) async {
      final h = tester.ensureSemantics();
      await c.pump(tester, TargetPlatform.android);
      await _settle(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      h.dispose();
    });
  }

  group('key groups register under the masthead title', () {
    for (final (name, screen) in <(String, Widget)>[
      ('Discover', const DiscoverScreen()),
      ('Sources', const SourcesScreen()),
      ('Catalogue', const CatalogueScreen(sourceId: 'asura')),
      ('Dialogue', const DialogueScreen()),
    ]) {
      testWidgets(name, (tester) async {
        await pumpScreen(tester, screen,
            sources: FakeSources(sources: _sources),);
        await tester.pump();
        expect(CineKeyRegistry.groups.value.keys, contains(name));
        expect(CineKeyRegistry.groups.value[name], isNotEmpty);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 12));
        expect(CineKeyRegistry.groups.value.keys, isNot(contains(name)));
      });
    }
  });

  group('reduced motion', () {
    testWidgets('the letter reveal is complete after 250 ms and stops',
        (tester) async {
      await pumpScreen(
        tester,
        const SourcesScreen(),
        sources: FakeSources(sources: _sources),
        pins: _pins,
        reduced: true,
      );
      await tester.pump(); // the first tick starts the 200 ms fade
      await tester.pump(const Duration(milliseconds: 250));
      final h = find.byType(SetHeading).first;
      final fade = find.descendant(of: h, matching: find.byType(FadeTransition));
      expect(fade, findsWidgets);
      expect(tester.widget<FadeTransition>(fade.first).opacity.value, 1);
    });

    testWidgets('the letter reveal runs when motion is on', (tester) async {
      await pumpScreen(tester, const SourcesScreen(),
          sources: FakeSources(sources: _sources), pins: _pins,);
      await tester.pump(const Duration(milliseconds: 100));
      double least() => tester
          .widgetList<Opacity>(find.descendant(of: find.byType(SetHeading).first, matching: find.byType(Opacity)))
          .fold(1.0, (m, o) => o.opacity < m ? o.opacity : m);
      expect(least(), lessThan(1));
      await settle(tester, 1500);
      expect(least(), 1);
    });

    String typed(WidgetTester tester) => tester
        .widget<Text>(find.descendant(
            of: find.byType(TypedText).first, matching: find.byType(Text),),)
        .data!;

    testWidgets('the typed hint is complete at once', (tester) async {
      await pumpScreen(tester, const DiscoverScreen(), reduced: true);
      await tester.pump(const Duration(milliseconds: 250));
      expect(typed(tester), 'Search every source');
    });

    testWidgets('the typed hint is still typing with motion on',
        (tester) async {
      await pumpScreen(tester, const DiscoverScreen());
      await tester.pump(const Duration(milliseconds: 250));
      expect(typed(tester).length, lessThan('Search every source'.length));
      await tester.pump(const Duration(seconds: 2));
      expect(typed(tester), 'Search every source');
    });

    testWidgets('the group jump is instant', (tester) async {
      await pumpScreen(
        tester,
        const DiscoverScreen(q: 'solo'),
        sources:
            FakeSources(groups: [_group('asura', 3), _group('mangadex', 3)]),
        size: const Size(390, 500),
        reduced: true,
      );
      await settle(tester, 800);
      final state =
          tester.state<DiscoverResultsState>(find.byType(DiscoverResults));
      final scroll =
          Scrollable.of(tester.element(find.byType(DiscoverResults))).position;
      expect(scroll.pixels, 0);
      final done = state.jumpTo('mangadex');
      await tester.pump();
      final first = scroll.pixels;
      expect(first, greaterThan(0));
      await tester.pump(const Duration(milliseconds: 500));
      expect(scroll.pixels, first);
      await done;
    });

    testWidgets('the group jump glides when motion is on', (tester) async {
      await pumpScreen(
        tester,
        const DiscoverScreen(q: 'solo'),
        sources:
            FakeSources(groups: [_group('asura', 3), _group('mangadex', 3)]),
        size: const Size(390, 500),
      );
      await settle(tester, 800);
      final state =
          tester.state<DiscoverResultsState>(find.byType(DiscoverResults));
      final scroll =
          Scrollable.of(tester.element(find.byType(DiscoverResults))).position;
      final done = state.jumpTo('mangadex');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final early = scroll.pixels;
      await tester.pump(const Duration(milliseconds: 500));
      expect(scroll.pixels, greaterThan(early));
      await done;
    });

    testWidgets('the highlight sweep shows its end state at once',
        (tester) async {
      await pumpScreen(tester, const DialogueScreen(q: 'hello'),
          reduced: true, ocr: FakeOcr(page: _page),);
      await tester.pump(const Duration(milliseconds: 50));
      final bands = tester
          .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox));
      expect(bands, isNotEmpty);
      expect(bands.every((b) => b.widthFactor == 1), isTrue);
    });
  });
}

const _page = OcrSearchPage(
    items: [_hit], total: 1, offset: 0, limit: 20, hasMore: false,);
