import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/ocr/models/ocr_search_result.dart';
import 'package:manhwamaniacs/features/ocr/models/page_text.dart';
import 'package:manhwamaniacs/features/ocr/providers/dialogue_jump_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/bubble_pulse.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// A fake reader engine: a PageView of 5 pages, each with an overlay slot.
class _FakeReader extends StatefulWidget {
  const _FakeReader({required this.loadPages, required this.pageLog});

  final Future<List<PageText>?> Function() loadPages;
  final List<int> pageLog;

  @override
  State<_FakeReader> createState() => _FakeReaderState();
}

class _FakeReaderState extends State<_FakeReader> {
  final _c = PageController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DialogueLandingHost(
        sourceId: 'asura',
        seriesKey: 'tog',
        chapterKey: '88',
        loadPages: widget.loadPages,
        jumpToPage: (p) {
          widget.pageLog.add(p);
          _c.jumpToPage(p - 1);
        },
        builder: (context, overlay) => PageView(
          controller: _c,
          children: [
            for (var p = 1; p <= 5; p++)
              Stack(fit: StackFit.expand, children: [Center(child: Text('page $p')), overlay(p)]),
          ],
        ),
      );
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required DialogueJump? jump,
  required Future<List<PageText>?> Function() loadPages,
  required List<int> log,
  bool reduced = false,
}) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  if (jump != null) container.read(dialogueJumpProvider.notifier).set(jump);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: ThemeData(extensions: const [cinematicTokens]),
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: Scaffold(body: _FakeReader(loadPages: loadPages, pageLog: log)),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return container;
}

const _box = OcrBox(x: 0.2, y: 0.3, w: 0.4, h: 0.1);

void main() {
  testWidgets('a known page: jumps there, pulses the frame, toasts, and the jump is spent', (tester) async {
    final log = <int>[];
    final c = await _pump(
      tester,
      jump: const DialogueJump(sourceId: 'asura', seriesKey: 'tog', chapterKey: '88', q: 'hi', page: 3, box: _box),
      loadPages: () async => fail('pages must not be fetched'),
      log: log,
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(log, [3]);
    expect(find.text('page 3'), findsOneWidget);
    expect(find.byType(BubblePulse), findsOneWidget);
    expect(find.text('Found on page 3.'), findsOneWidget);
    expect(c.read(dialogueJumpProvider), isNull);
    await tester.pump(const Duration(milliseconds: 1100)); // two 480 ms passes, then gone
    expect(find.byType(BubblePulse), findsNothing);
    await tester.pump(const Duration(seconds: 4)); // toast hold
    expect(find.text('Found on page 3.'), findsNothing);
  });

  testWidgets('no page: the OCR text finds it, then the pulse runs on that page', (tester) async {
    final log = <int>[];
    await _pump(
      tester,
      jump: const DialogueJump(sourceId: 'asura', seriesKey: 'tog', chapterKey: '88', q: 'ñandú', box: _box),
      loadPages: () async => const [PageText(page: 1, text: 'x'), PageText(page: 4, text: 'un nandu')],
      log: log,
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(log, [4]);
    expect(find.text('Found on page 4.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('no match: opens at the chapter start with the toast and no pulse', (tester) async {
    final log = <int>[];
    await _pump(
      tester,
      jump: const DialogueJump(sourceId: 'asura', seriesKey: 'tog', chapterKey: '88', q: 'zzz'),
      loadPages: () async => const [PageText(page: 1, text: 'x')],
      log: log,
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(log, isEmpty);
    expect(find.text('page 1'), findsOneWidget);
    expect(find.byType(BubblePulse), findsNothing);
    expect(find.text('Opened at the chapter start. The line is in this chapter.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('a jump for another chapter is left alone', (tester) async {
    final log = <int>[];
    final c = await _pump(
      tester,
      jump: const DialogueJump(sourceId: 'asura', seriesKey: 'tog', chapterKey: '99', q: 'hi', page: 2, box: _box),
      loadPages: () async => null,
      log: log,
    );
    expect(log, isEmpty);
    expect(c.read(dialogueJumpProvider), isNotNull);
  });

  testWidgets('reduced motion: one static frame instead of two pulses', (tester) async {
    await _pump(
      tester,
      jump: const DialogueJump(sourceId: 'asura', seriesKey: 'tog', chapterKey: '88', q: 'hi', page: 2, box: _box),
      loadPages: () async => null,
      log: <int>[],
      reduced: true,
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(BubblePulse), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(BubblePulse), findsNothing);
    await tester.pump(const Duration(seconds: 4));
  });
}
