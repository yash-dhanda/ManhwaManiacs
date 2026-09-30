import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/ocr/models/ocr_search_result.dart';
import 'package:manhwamaniacs/features/ocr/providers/dialogue_jump_provider.dart';
import 'package:manhwamaniacs/features/ocr/providers/ocr_providers.dart';
import 'package:manhwamaniacs/features/ocr/utils/engine_label.dart';
import 'package:manhwamaniacs/features/sources/providers/discover_providers.dart';
import 'package:manhwamaniacs/skins/glass/screens/dialogue/dialogue_card.dart';
import 'package:manhwamaniacs/skins/glass/screens/dialogue/dialogue_screen.dart';

import '../shell/shell_rig.dart';

OcrSearchResult hit() => const OcrSearchResult(sourceId: 's', seriesKey: 'k', chapterKey: '12', snippet: 'he said <mark>hello</mark> there', wordCount: 212, engine: 'vision', highlightedTerms: ['hello'], page: 3);

List<Override> ov({bool ocr = true}) => [
      ocrFeatureVisibleProvider.overrideWithValue(true),
      serverOcrCapabilityProvider.overrideWith((ref) async => ocr),
      ocrSearchProvider.overrideWith((ref, q) async => OcrSearchPage(items: [hit()], total: 86, offset: 0, limit: 20, hasMore: true)),
    ];

void main() {
  test('engine names', () {
    expect(engineName('apple_vision'), 'Vision');
    expect(engineName('ML_Kit'), 'ML Kit');
    expect(engineName('x'), 'x');
    expect(engineName(null), 'Unknown');
  });

  testWidgets('results: card with highlighted terms, word count and engine, load more', (t) async {
    await pumpGlassShell(t, start: '/ocr?q=hello', extra: ov());
    expect(find.byType(GlassDialogueScreen), findsOneWidget);
    expect(find.byType(GlassDialogueCard), findsOneWidget);
    expect(find.textContaining('<mark>', findRichText: true), findsNothing);
    expect(find.text('212 words · Vision'), findsOneWidget);
    expect(find.text('Showing the first 1 of 86 matches'), findsOneWidget);
    expect(find.text('Load more'), findsOneWidget);
  });

  testWidgets('opening a result hands the jump over', (t) async {
    final rig = await pumpGlassShell(t, start: '/ocr?q=hello', extra: ov());
    await t.tap(find.byType(GlassDialogueCard));
    await t.pump(const Duration(milliseconds: 300));
    final j = rig.container.read(dialogueJumpProvider);
    expect(j?.chapterKey, '12');
    expect(j?.page, 3);
    expect(j?.q, 'hello');
  });

  testWidgets('idle lens without a query', (t) async {
    await pumpGlassShell(t, start: '/ocr', extra: ov());
    expect(find.text('Search the dialogue you remember'), findsOneWidget);
  });

  testWidgets('capabilities lens when the server has no OCR', (t) async {
    await pumpGlassShell(t, start: '/ocr', extra: ov(ocr: false));
    expect(find.text("Dialogue search isn't available on this server."), findsOneWidget);
  });
}
