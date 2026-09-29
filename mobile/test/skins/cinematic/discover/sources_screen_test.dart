import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/sources/models/source_health.dart';
import 'package:manhwamaniacs/features/sources/models/source_pin.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/sources/sources_screen.dart';

import 'harness.dart';

void main() {
  final sources = [
    src('asura', health: const SourceHealth(status: SourceHealthStatus.ok)),
    src('mangadex', health: const SourceHealth(status: SourceHealthStatus.failing, consecutiveFailures: 3)),
    src('weeb', health: const SourceHealth(status: SourceHealthStatus.dead)),
  ];
  const pins = [
    SourcePin(sourceId: 'asura', sortOrder: 0, name: 'ASURA'),
    SourcePin(sourceId: 'gone', sortOrder: 1, name: 'GONE', available: false),
    SourcePin(sourceId: 'mangadex', sortOrder: 2, name: 'MANGADEX'),
  ];

  testWidgets('directory: deck, pinned first, health text in semantics', (tester) async {
    final h = tester.ensureSemantics();
    await pumpScreen(tester, const SourcesScreen(), sources: FakeSources(sources: sources), pins: pins);
    await settle(tester);
    expect(find.text('Sources'), findsOneWidget);
    expect(find.text('3 sources · 3 healthy · 2 pinned'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('MANGADEX, FAILING · 3 errors')), findsWidgets);
    expect(find.bySemanticsLabel(RegExp(r'WEEB, DEAD')), findsOneWidget);
    expect(find.text('GONE'), findsNothing); // unavailable pin is not rendered
    h.dispose();
  });

  testWidgets('Move down writes the full order, unavailable pins kept in place', (tester) async {
    final repo = FakeSources(sources: sources);
    await pumpScreen(tester, const SourcesScreen(), sources: repo, pins: pins);
    await settle(tester);
    await tester.longPress(find.text('ASURA').first);
    await settle(tester, 300);
    expect(find.text('Move up'), findsOneWidget);
    await tester.tap(find.text('Move down'));
    await settle(tester, 300);
    expect(repo.replaced, [
      ['mangadex', 'gone', 'asura'],
    ]);
  });

  testWidgets('pinned empty and no match states', (tester) async {
    await pumpScreen(tester, const SourcesScreen(), sources: FakeSources(sources: sources));
    await settle(tester);
    expect(
      find.text('No pinned sources. Tap the pin on any source to keep it at the top.'),
      findsOneWidget,
    );
  });

  testWidgets('pins that fail to load disable the toggle with a note', (tester) async {
    await pumpScreen(
      tester,
      const SourcesScreen(),
      sources: FakeSources(sources: sources),
      pinsSynced: false,
    );
    await settle(tester, 5000);
    expect(find.textContaining("Pinned sources couldn't be loaded"), findsWidgets);
  });

  testWidgets('tablet shows the table with KIND and health text, no LANGUAGE', (tester) async {
    await pumpScreen(
      tester,
      const SourcesScreen(),
      sources: FakeSources(sources: sources),
      pins: pins,
      size: const Size(834, 1194),
    );
    await settle(tester);
    expect(find.text('MANGA'), findsWidgets);
    expect(find.textContaining('LANGUAGE'), findsNothing);
    expect(find.textContaining('FAILING · 3 errors'), findsWidgets);
  });

  testWidgets('tap targets on iOS and Android', (tester) async {
    final h = tester.ensureSemantics();
    await pumpScreen(tester, const SourcesScreen(), sources: FakeSources(sources: sources), pins: pins);
    await settle(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    h.dispose();
  });
}
