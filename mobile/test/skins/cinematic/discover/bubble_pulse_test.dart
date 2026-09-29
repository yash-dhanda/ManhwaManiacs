import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/ocr/models/ocr_search_result.dart';
import 'package:manhwamaniacs/features/ocr/models/page_text.dart';
import 'package:manhwamaniacs/features/ocr/providers/dialogue_jump_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/bubble_pulse.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

const _box = OcrBox(x: 0.2, y: 0.3, w: 0.4, h: 0.1);

Widget _host(Widget child, {bool reduced = false}) => MaterialApp(
      theme: ThemeData(extensions: const [cinematicTokens]),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 200, height: 400, child: child),
        ),
      ),
    );

double _opacity(WidgetTester t) => t
    .widget<Opacity>(find.descendant(of: find.byType(BubblePulse), matching: find.byType(Opacity)))
    .opacity;

void main() {
  group('landing (reader hook, fake engine)', () {
    test('a known page jumps straight to it with the box', () async {
      final jumps = <int>[];
      final l = await resolveDialogueLanding(
        const DialogueJump(sourceId: 's', seriesKey: 'k', chapterKey: 'c', q: 'hi', page: 12, box: _box),
        () async => fail('pages must not be fetched'),
      );
      if (l.found) jumps.add(l.page!);
      expect(jumps, [12]);
      expect(l.toast, 'Found on page 12.');
      expect(l.box, _box);
    });

    test('an unknown page is found from the OCR text', () async {
      final l = await resolveDialogueLanding(
        const DialogueJump(sourceId: 's', seriesKey: 'k', chapterKey: 'c', q: 'niño'),
        () async => const [PageText(page: 1, text: 'x'), PageText(page: 7, text: 'el nino aqui')],
      );
      expect(l.page, 7);
      expect(l.toast, 'Found on page 7.');
    });

    test('no match opens at the chapter start with the toast', () async {
      final l = await resolveDialogueLanding(
        const DialogueJump(sourceId: 's', seriesKey: 'k', chapterKey: 'c', q: 'zzz'),
        () async => const [PageText(page: 1, text: 'x')],
      );
      expect(l.found, isFalse);
      expect(l.toast, 'Opened at the chapter start. The line is in this chapter.');
    });
  });

  testWidgets('pulses twice for 480 ms each then reports done', (tester) async {
    var done = 0;
    await tester.pumpWidget(_host(BubblePulse(box: _box, onDone: () => done++)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));
    expect(_opacity(tester), greaterThan(0.9)); // first peak
    await tester.pump(const Duration(milliseconds: 240));
    expect(_opacity(tester), lessThan(0.1));
    await tester.pump(const Duration(milliseconds: 240));
    expect(_opacity(tester), greaterThan(0.9)); // second peak
    expect(done, 0);
    await tester.pump(const Duration(milliseconds: 300));
    expect(done, 1);
    final r = tester.getRect(
      find.descendant(of: find.byType(BubblePulse), matching: find.byType(DecoratedBox)),
    );
    expect(r.width, closeTo(80, 0.5));
    expect(r.left, closeTo(40, 0.5));
  });

  testWidgets('reduced motion shows one static frame for 960 ms', (tester) async {
    var done = 0;
    await tester.pumpWidget(_host(BubblePulse(box: _box, onDone: () => done++), reduced: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(_opacity(tester), 1);
    expect(done, 0);
    await tester.pump(const Duration(milliseconds: 500));
    expect(done, 1);
  });
}
