import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/ocr/controllers/ocr_run_controller.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/dialogue/scan/dialogue_scan_block.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/dialogue/scan/scan_dialogue_button.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

import 'harness.dart';

Widget _host(Widget child) => ProviderScope(
      child: MaterialApp(
        theme: ThemeData(extensions: const [cinematicTokens]),
        home: Scaffold(body: child),
      ),
    );

void main() {
  const id = (sourceId: 's', seriesKey: 'k', chapterKey: '1');

  testWidgets('every run phase renders', (tester) async {
    Future<void> show(OcrRunState s) async {
      await tester.pumpWidget(_host(DialogueScanBlock(preview: s)));
      await tester.pump(const Duration(milliseconds: 50));
    }

    await show(const OcrRunState());
    expect(find.text('READING THE DIALOGUE'), findsNothing);
    await show(const OcrRunState(
        phase: OcrRunPhase.recognizing,
        chapter: id,
        completedPages: 2,
        totalPages: 40,),);
    expect(find.text('READING THE DIALOGUE'), findsOneWidget);
    expect(find.text('Page 3 of 40'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    await show(const OcrRunState(
        phase: OcrRunPhase.paused, chapter: id, totalPages: 40,),);
    expect(find.textContaining('Text extraction pauses in the background'),
        findsOneWidget,);
    await show(const OcrRunState(phase: OcrRunPhase.uploading, chapter: id));
    expect(find.text('Saving the transcript…'), findsOneWidget);
    await show(const OcrRunState(phase: OcrRunPhase.done, wordCount: 214));
    expect(find.text('214 words are now searchable.'), findsOneWidget);
    expect(find.text('Search dialogue'), findsOneWidget);
    await show(const OcrRunState(phase: OcrRunPhase.cancelled));
    expect(find.text('Scan cancelled.'), findsOneWidget);
    await show(const OcrRunState(
        phase: OcrRunPhase.failed, chapter: id, message: 'Engine died',),);
    expect(find.textContaining('Engine died'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
  });

  testWidgets(
      'scan button: hidden without OCR, badge and re-scan confirm when indexed',
      (tester) async {
    await pumpScreen(
        tester, const Scaffold(body: ScanDialogueButton(chapter: id)),
        ocrOn: false,);
    expect(find.byType(IconButton), findsNothing);
    await pumpScreen(
        tester, const Scaffold(body: ScanDialogueButton(chapter: id)),);
    await tester.pump();
    expect(find.byType(IconButton), findsOneWidget);
    expect(find.text('TEXT'), findsNothing);
  });
}
