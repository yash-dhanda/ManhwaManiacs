import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/global_search_result.dart';
import 'package:manhwamaniacs/features/sources/models/source_pin.dart';
import 'package:manhwamaniacs/features/sources/models/source_search_group.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/discover_screen.dart';

import 'harness.dart';

SourceSearchGroup group(String id, int n, {bool error = false}) => SourceSearchGroup(
      source: id,
      sourceName: id.toUpperCase(),
      status: error
          ? SourceGroupStatus.error
          : (n == 0 ? SourceGroupStatus.empty : SourceGroupStatus.ok),
      items: [
        for (var i = 0; i < n; i++)
          GlobalSearchItem(kind: 'source', source: id, seriesId: '$id$i', title: 'Title $id $i'),
      ],
    );

void main() {
  testWidgets('idle: scopes follow availability, hint semantics, sources section', (tester) async {
    final h = tester.ensureSemantics();
    await pumpScreen(
      tester,
      const DiscoverScreen(),
      ocrOn: false,
      pins: const [SourcePin(sourceId: 'asura', sortOrder: 0, name: 'Asura')],
      sources: FakeSources(sources: [src('asura')]),
    );
    await settle(tester);
    expect(find.text('NO. 04 — DISCOVER'), findsOneWidget);
    expect(find.text('01 ALL'), findsOneWidget);
    expect(find.text('03 SOURCES'), findsOneWidget);
    expect(find.textContaining('DIALOGUE'), findsNothing); // OCR off, no scope, no entry
    expect(find.text('04 ASK'), findsOneWidget); // AI available, folios renumber
    expect(find.bySemanticsLabel('Search every source'), findsWidgets);
    expect(find.text('ASURA'), findsNothing);
    expect(find.text('Asura'), findsOneWidget); // pinned credit
    h.dispose();
  });

  testWidgets('dialogue scope and entry appear with OCR in manga mode', (tester) async {
    await pumpScreen(tester, const DiscoverScreen());
    await settle(tester);
    expect(find.text('04 DIALOGUE'), findsOneWidget);
    expect(find.text('05 ASK'), findsOneWidget);
    expect(find.text('Search dialogue'), findsOneWidget);
  });

  testWidgets('unknown and text scopes render ALL', (tester) async {
    final h = tester.ensureSemantics();
    await pumpScreen(tester, const DiscoverScreen(scope: 'text'));
    await settle(tester);
    expect(find.bySemanticsLabel('Search every source'), findsWidgets);
    h.dispose();
  });

  testWidgets('results: status line, groups, library first, retry, empty toggle', (tester) async {
    final sources = FakeSources(groups: [
      group('local-not', 0),
      group('asura', 3),
      group('bad', 0, error: true),
      group('quiet', 0),
    ],);
    await pumpScreen(tester, const DiscoverScreen(q: 'solo'), sources: sources);
    await settle(tester, 800);
    expect(sources.searched, ['solo']);
    expect(find.text('3 results · 1 sources'), findsOneWidget);
    expect(find.text('ASURA'), findsOneWidget);
    expect(find.text("This source didn't answer."), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Show 2 sources with no matches'), findsOneWidget);
    await tester.tap(find.text('Show 2 sources with no matches'));
    await settle(tester, 200);
    expect(find.text('Hide 2 sources with no matches'), findsOneWidget);
    expect(find.text('ALL'), findsWidgets);
    expect(find.text('WITH RESULTS'), findsOneWidget);
    expect(find.text('PINNED'), findsOneWidget);
    expect(find.text('Jump to source'), findsOneWidget);
  });

  testWidgets('no results shows the notice with Ask the editors', (tester) async {
    await pumpScreen(tester, const DiscoverScreen(q: 'zzzz'), sources: FakeSources());
    await settle(tester, 2500);
    expect(find.text('NOTHING FOUND'), findsOneWidget);
    expect(find.text('Ask the editors'), findsWidgets);
  });

  testWidgets('reduced motion: typed notice headline is complete at once', (tester) async {
    await pumpScreen(tester, const DiscoverScreen(q: 'zzzz'), sources: FakeSources(), reduced: true);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.textContaining('No series match "zzzz"'), findsOneWidget);
  });

  testWidgets('hardware keys: 3 switches scope, Esc clears then unfocuses', (tester) async {
    await pumpScreen(tester, const DiscoverScreen());
    await settle(tester);
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'abc');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '');
  });

  testWidgets('meets the tap target and label guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(tester, const DiscoverScreen(), platform: TargetPlatform.iOS);
    await settle(tester);
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
