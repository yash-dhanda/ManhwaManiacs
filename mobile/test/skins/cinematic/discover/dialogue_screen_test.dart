import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/ocr/models/ocr_search_result.dart';
import 'package:manhwamaniacs/features/ocr/providers/dialogue_jump_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/dialogue/dialogue_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/dialogue/transcript_block.dart';

import 'harness.dart';

class _Novel extends ContentModeController {
  @override
  ContentMode build() => ContentMode.novel;
}

OcrSearchPage page(int n, {int total = 0}) => OcrSearchPage(
      items: [
        for (var i = 0; i < n; i++)
          const OcrSearchResult(
            sourceId: 'asura',
            seriesKey: 'tower-of-god',
            chapterKey: '88',
            snippet: 'I said <mark>hello</mark> there',
            wordCount: 214,
            engine: 'apple_vision',
            highlightedTerms: ['hello'],
            page: 12,
            box: OcrBox(x: 0.4, y: 0.4, w: 0.2, h: 0.1),
          ),
      ],
      total: total == 0 ? n : total,
      offset: 0,
      limit: 20,
      hasMore: total > n,
    );

void main() {
  testWidgets('idle prompt, scanning entry link and typed hint', (tester) async {
    await pumpScreen(tester, const DialogueScreen());
    await settle(tester);
    expect(find.text('NO. 09 — DIALOGUE'), findsOneWidget);
    expect(find.text('Type a line you remember.'), findsOneWidget);
    expect(find.text('Downloads'), findsOneWidget);
    expect(find.textContaining('Scan more chapters'), findsOneWidget);
  });

  testWidgets('results: credit line, transcript, page-missing still, open sets the jump', (tester) async {
    final ocr = FakeOcr(page: page(2, total: 134));
    final h = tester.ensureSemantics();
    await pumpScreen(tester, const DialogueScreen(q: 'hello'), ocr: ocr, size: const Size(390, 4000));
    await settle(tester, 800);
    expect(ocr.queries, ['hello']);
    expect(find.textContaining('TOWER-OF-GOD · CH 88 · PAGE 12 · 214 WORDS · VISION'), findsWidgets);
    expect(find.text('Showing the first 2 of 134 matches. Narrow the search.'), findsOneWidget);
    expect(find.text('Show more'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp("Page didn't load")), findsWidgets);
    final container = ProviderScope.containerOf(tester.element(find.byType(DialogueScreen)));
    await tester.tap(find.byType(TranscriptBlock).first, warnIfMissed: false);
    await tester.pump();
    await settle(tester, 300);
    expect(find.textContaining('/reader/asura/tower-of-god/88'), findsOneWidget);
    final jump = container.read(dialogueJumpProvider);
    expect(jump?.page, 12);
    expect(jump?.box?.x, 0.4);
    h.dispose();
  });

  testWidgets('no matches notice', (tester) async {
    await pumpScreen(tester, const DialogueScreen(q: 'zzz'), ocr: FakeOcr(), reduced: true);
    await settle(tester, 800);
    expect(find.textContaining('Nothing found for "zzz"'), findsOneWidget);
  });

  testWidgets('not available on this device', (tester) async {
    await pumpScreen(tester, const DialogueScreen(q: 'x'), ocrOn: false, reduced: true);
    await settle(tester);
    expect(find.text("Dialogue search isn't available on this device."), findsOneWidget);
  });

  testWidgets('novels mode shows the manga-only notice', (tester) async {
    await pumpScreen(
      tester,
      const DialogueScreen(),
      reduced: true,
      extra: [contentModeControllerProvider.overrideWith(_Novel.new)],
    );
    await settle(tester);
    expect(find.text('Search novels'), findsOneWidget);
    expect(find.textContaining('Dialogue search is for manga'), findsOneWidget);
  });

  testWidgets('tablet lays the still and transcript in two columns', (tester) async {
    await pumpScreen(
      tester,
      const DialogueScreen(q: 'hello'),
      ocr: FakeOcr(page: page(1)),
      size: const Size(834, 1194),
    );
    await settle(tester, 800);
    final still = tester.getTopLeft(find.byType(AspectRatio).first);
    final text = tester.getTopLeft(find.textContaining('TOWER-OF-GOD').first);
    expect(text.dx, greaterThan(still.dx + 300));
  });

  testWidgets('tap targets', (tester) async {
    final h = tester.ensureSemantics();
    await pumpScreen(
      tester,
      const DialogueScreen(q: 'hello'),
      ocr: FakeOcr(page: page(1)),
      platform: TargetPlatform.iOS,
    );
    await settle(tester, 800);
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    h.dispose();
  });
}
