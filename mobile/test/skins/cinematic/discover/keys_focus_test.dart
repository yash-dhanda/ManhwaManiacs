import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/library/models/global_search_result.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/library/providers/intelligence_providers.dart';
import 'package:manhwamaniacs/features/ocr/models/ocr_search_result.dart';
import 'package:manhwamaniacs/features/sources/models/source_pin.dart';
import 'package:manhwamaniacs/features/sources/models/source_search_group.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/ask_scope.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/catalogue/catalogue_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/dialogue/dialogue_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/dialogue/transcript_block.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/discover_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/sources/source_row.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/sources/sources_screen.dart';

import 'harness.dart';

const _pins = [
  SourcePin(sourceId: 'asura', sortOrder: 0, name: 'ASURA'),
  SourcePin(sourceId: 'mangadex', sortOrder: 1, name: 'MANGADEX'),
];

SourceSearchGroup _group(String id, int n) => SourceSearchGroup(
      source: id,
      sourceName: id.toUpperCase(),
      status: SourceGroupStatus.ok,
      items: [
        for (var i = 0; i < n; i++)
          GlobalSearchItem(kind: 'source', source: id, seriesId: '$id$i', title: 'Title $id $i'),
      ],
    );

OcrSearchResult _hit(int i) => OcrSearchResult(
      sourceId: 'asura',
      seriesKey: 'tog',
      chapterKey: '$i',
      snippet: 'I said <mark>hello</mark> $i',
      wordCount: 10,
      engine: 'mlkit',
      highlightedTerms: const ['hello'],
      page: 3,
      box: const OcrBox(x: 0.4, y: 0.4, w: 0.2, h: 0.1),
    );

Future<void> _key(WidgetTester tester, LogicalKeyboardKey k) async {
  await tester.sendKeyEvent(k);
  await tester.pump(const Duration(milliseconds: 50));
}

bool _headingFocused(WidgetTester tester) => tester
    .widgetList<Focus>(find.descendant(of: find.byType(HeadingFocus), matching: find.byType(Focus)))
    .any((f) => f.focusNode?.hasPrimaryFocus ?? false);

/// A 2 px foreground border is CineFocusRing painting.
bool _ringPainted(WidgetTester tester) => tester.widgetList<DecoratedBox>(find.byType(DecoratedBox)).any(
      (d) => d.position == DecorationPosition.foreground && (d.decoration as BoxDecoration).border != null,
    );

Future<void> _tabUntilRing(WidgetTester tester) async {
  for (var i = 0; i < 12 && !_ringPainted(tester); i++) {
    await _key(tester, LogicalKeyboardKey.tab);
  }
}

void main() {
  final wall = [for (var i = 0; i < 40; i++) series('s$i', 'Series $i', 'asura')];

  group('Route focus lands on the level-1 heading', () {
    testWidgets('Discover', (tester) async {
      await pumpScreen(tester, const DiscoverScreen());
      await settle(tester);
      expect(_headingFocused(tester), isTrue);
    });
    testWidgets('Dialogue', (tester) async {
      await pumpScreen(tester, const DialogueScreen());
      await settle(tester);
      expect(_headingFocused(tester), isTrue);
    });
    testWidgets('Sources', (tester) async {
      await pumpScreen(tester, const SourcesScreen(), sources: FakeSources(sources: [src('asura')]));
      await settle(tester, 800);
      expect(_headingFocused(tester), isTrue);
    });
    testWidgets('Catalogue', (tester) async {
      await pumpScreen(tester, const CatalogueScreen(sourceId: 'asura'), sources: FakeSources(sources: [src('asura')], series: wall));
      await settle(tester, 800);
      expect(_headingFocused(tester), isTrue);
    });
  });

  group('Discover keys', () {
    for (final (k, scope) in [
      (LogicalKeyboardKey.digit2, 'scope=library'),
      (LogicalKeyboardKey.digit3, 'scope=sources'),
      (LogicalKeyboardKey.digit4, 'scope=dialogue'),
      (LogicalKeyboardKey.digit5, 'scope=ask'),
    ]) {
      testWidgets('${k.keyLabel} opens $scope', (tester) async {
        await pumpScreen(tester, const DiscoverScreen());
        await settle(tester);
        await _key(tester, k);
        await settle(tester);
        expect(find.textContaining(scope), findsOneWidget);
      });
    }

    testWidgets('1 returns to ALL', (tester) async {
      await pumpScreen(tester, const DiscoverScreen(scope: 'sources'));
      await settle(tester);
      await _key(tester, LogicalKeyboardKey.digit1);
      await settle(tester);
      expect(find.textContaining('at /search'), findsOneWidget);
      expect(find.textContaining('scope='), findsNothing);
    });

    testWidgets('down arrow moves focus along', (tester) async {
      await pumpScreen(tester, const DiscoverScreen());
      await settle(tester);
      expect(_headingFocused(tester), isTrue);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_headingFocused(tester), isFalse);
    });

    testWidgets(']  and [ step through the result groups', (tester) async {
      await pumpScreen(
        tester,
        const DiscoverScreen(q: 'solo'),
        sources: FakeSources(groups: [_group('asura', 6), _group('mangadex', 6), _group('quiet', 6)]),
      );
      await settle(tester, 800);
      final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
      final start = scroll.position.pixels;
      await _key(tester, LogicalKeyboardKey.bracketRight);
      await settle(tester, 800);
      expect(scroll.position.pixels, greaterThan(start));
      await _key(tester, LogicalKeyboardKey.bracketRight);
      await settle(tester, 800);
      final after = scroll.position.pixels;
      await _key(tester, LogicalKeyboardKey.bracketLeft);
      await settle(tester, 800);
      expect(scroll.position.pixels, lessThan(after));
    });

    testWidgets('Tab order paints the focus ring', (tester) async {
      await pumpScreen(tester, const DiscoverScreen());
      await settle(tester);
      await _tabUntilRing(tester);
      expect(_ringPainted(tester), isTrue);
    });
  });

  group('Sources keys', () {
    final rows = FakeSources(sources: [src('asura'), src('mangadex'), src('zed')]);

    String? focusedRow() => FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<SourceRow>()
        ?.source
        .id;

    Future<void> toFirstRow(WidgetTester tester) async {
      for (var i = 0; i < 30 && focusedRow() == null; i++) {
        await _key(tester, LogicalKeyboardKey.tab);
      }
    }

    testWidgets('j and k move between rows, Enter opens the row', (tester) async {
      await pumpScreen(tester, const SourcesScreen(), sources: rows);
      await settle(tester, 800);
      await toFirstRow(tester);
      final first = focusedRow();
      expect(first, isNotNull);
      final node = FocusManager.instance.primaryFocus;
      await _key(tester, LogicalKeyboardKey.keyJ);
      expect(FocusManager.instance.primaryFocus, isNot(node));
      await _key(tester, LogicalKeyboardKey.keyK);
      expect(FocusManager.instance.primaryFocus, node);
      await _key(tester, LogicalKeyboardKey.enter);
      await settle(tester, 300);
      expect(find.textContaining('at /sources/$first'), findsOneWidget);
    });

    testWidgets('dragging a pinned row lifts it without a Material error', (tester) async {
      await pumpScreen(tester, const SourcesScreen(), sources: rows, pins: _pins);
      await settle(tester, 800);
      final g = await tester.startGesture(tester.getCenter(find.byIcon(kDotsSixVertical).first));
      for (var i = 0; i < 4; i++) {
        await g.moveBy(const Offset(0, 14));
        await tester.pump(const Duration(milliseconds: 60));
      }
      expect(tester.takeException(), isNull);
      await g.up();
      await settle(tester, 300);
    });

    testWidgets('Tab order paints the focus ring', (tester) async {
      await pumpScreen(tester, const SourcesScreen(), sources: rows, pins: _pins);
      await settle(tester, 800);
      await _tabUntilRing(tester);
      expect(_ringPainted(tester), isTrue);
    });
  });

  group('Catalogue keys', () {
    Future<void> pumpCatalogue(WidgetTester tester, FakeSources s) async {
      await pumpScreen(tester, const CatalogueScreen(sourceId: 'asura'), sources: s);
      await settle(tester, 800);
    }

    FakeSources fake() => FakeSources(sources: [src('asura')], series: wall);

    testWidgets('Home and End jump to the ends', (tester) async {
      await pumpCatalogue(tester, fake());
      final pos = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
      await _key(tester, LogicalKeyboardKey.end);
      expect(pos.pixels, pos.maxScrollExtent);
      expect(pos.maxScrollExtent, greaterThan(0));
      await _key(tester, LogicalKeyboardKey.home);
      expect(pos.pixels, 0);
    });

    testWidgets('r reloads the first page', (tester) async {
      final s = fake();
      await pumpCatalogue(tester, s);
      final before = s.seriesCalls;
      await _key(tester, LogicalKeyboardKey.keyR);
      await settle(tester, 500);
      expect(s.seriesCalls, greaterThan(before));
    });

    for (final k in [
      LogicalKeyboardKey.keyJ,
      LogicalKeyboardKey.keyL,
      LogicalKeyboardKey.keyK,
      LogicalKeyboardKey.keyH,
    ]) {
      testWidgets('${k.keyLabel} moves focus', (tester) async {
        await pumpCatalogue(tester, fake());
        // Start from a poster so both directions have somewhere to go.
        for (var i = 0; i < 4; i++) {
          await _key(tester, LogicalKeyboardKey.tab);
        }
        final before = FocusManager.instance.primaryFocus;
        await _key(tester, k);
        expect(FocusManager.instance.primaryFocus, isNot(before));
      });
    }

    testWidgets('Tab order paints the focus ring', (tester) async {
      await pumpCatalogue(tester, fake());
      await _tabUntilRing(tester);
      expect(_ringPainted(tester), isTrue);
    });
  });

  group('Dialogue keys', () {
    Future<void> pumpHits(WidgetTester tester) async {
      await pumpScreen(
        tester,
        const DialogueScreen(q: 'hello'),
        ocr: FakeOcr(page: OcrSearchPage(items: [for (var i = 0; i < 4; i++) _hit(i)], total: 4, offset: 0, limit: 20, hasMore: false)),
      );
      await settle(tester, 800);
    }

    String? focusedHit() => FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<TranscriptBlock>()
        ?.hit
        .chapterKey;

    Future<void> toFirstHit(WidgetTester tester) async {
      for (var i = 0; i < 30 && focusedHit() == null; i++) {
        await _key(tester, LogicalKeyboardKey.tab);
      }
    }

    testWidgets('j and k move between hits, Enter opens the reader', (tester) async {
      await pumpHits(tester);
      await toFirstHit(tester);
      expect(focusedHit(), isNotNull);
      final node = FocusManager.instance.primaryFocus;
      await _key(tester, LogicalKeyboardKey.keyJ);
      expect(FocusManager.instance.primaryFocus, isNot(node));
      await _key(tester, LogicalKeyboardKey.keyK);
      expect(FocusManager.instance.primaryFocus, node);
      await _key(tester, LogicalKeyboardKey.enter);
      await settle(tester, 300);
      expect(find.textContaining('page=3'), findsOneWidget);
    });

    testWidgets('Tab order paints the focus ring', (tester) async {
      await pumpHits(tester);
      await _tabUntilRing(tester);
      expect(_ringPainted(tester), isTrue);
    });
  });

  group('Dialogue stills build lazily', () {
    testWidgets('only the stills near the viewport mount', (tester) async {
      await pumpScreen(
        tester,
        const DialogueScreen(q: 'hello'),
        ocr: FakeOcr(page: OcrSearchPage(items: [for (var i = 0; i < 20; i++) _hit(i)], total: 20, offset: 0, limit: 20, hasMore: false)),
      );
      await settle(tester, 800);
      final mounted = tester.widgetList(find.byType(TranscriptBlock, skipOffstage: false)).length;
      expect(mounted, lessThan(20));
      expect(mounted, greaterThan(0));
    });
  });

  group('Dialogue availability', () {
    testWidgets('the server capability off shows the server notice', (tester) async {
      await pumpScreen(tester, const DialogueScreen(), serverOcr: false);
      await settle(tester, 4000);
      expect(find.textContaining('on this server'), findsOneWidget);
    });

    testWidgets('the device off shows the device notice', (tester) async {
      await pumpScreen(tester, const DialogueScreen(), ocrOn: false);
      await settle(tester, 4000);
      expect(find.textContaining('on this device'), findsOneWidget);
    });

    testWidgets('the server capability off removes the DIALOGUE scope', (tester) async {
      await pumpScreen(tester, const DiscoverScreen(), serverOcr: false);
      await settle(tester, 800);
      expect(find.text('DIALOGUE'), findsNothing);
    });
  });

  group('ASK scope', () {
    Future<void> pumpAsk(WidgetTester tester, SuggestionsNotifier Function() n) => pumpScreen(
          tester,
          const Scaffold(body: SingleChildScrollView(child: AskScope(query: 'x', onSearchInstead: _noop))),
          extra: [suggestionsProvider.overrideWith(n)],
        );

    testWidgets('a 429 counts down live from the Retry-After header value', (tester) async {
      await pumpAsk(tester, _Fails.new);
      await settle(tester, 300);
      expect(find.text('SLOW DOWN'), findsOneWidget);
      expect(find.text('Retrying in 7 s'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Retrying in 5 s'), findsOneWidget);
    });

    testWidgets('the dial appears after 1 s, not at once', (tester) async {
      await pumpAsk(tester, _Thinks.new);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(LeaderDial), findsNothing);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(LeaderDial), findsOneWidget);
    });

    testWidgets('World cards fade in staggered', (tester) async {
      await pumpAsk(tester, _Answers.new);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
      double opacity(String title) => tester
          .widget<Opacity>(find.ancestor(of: find.text(title), matching: find.byType(Opacity)).first)
          .opacity;
      expect(opacity('Second'), lessThan(opacity('First')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(opacity('Second'), 1);
    });
  });
}

void _noop() {}

class _Fails extends SuggestionsNotifier {
  @override
  Future<WorldSuggestResponse?> build() async => throw const ApiError(
        statusCode: 429,
        code: 'rate_limited',
        message: 'slow',
        details: {'retry_after': 7},
      );
}

class _Thinks extends SuggestionsNotifier {
  @override
  Future<WorldSuggestResponse?> build() => Completer<WorldSuggestResponse?>().future;
}

class _Answers extends SuggestionsNotifier {
  @override
  Future<WorldSuggestResponse?> build() async => const WorldSuggestResponse(
        items: [WorldItem(title: 'First', why: 'because'), WorldItem(title: 'Second')],
      );
}
