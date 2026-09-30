
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/recap/models/recap_models.dart';
import 'package:manhwamaniacs/features/recap/models/recap_origin.dart';

import '../discover/harness.dart';
import 'recap_test_support.dart';

Future<FakeRecapRepository> pumpRecap(
  WidgetTester tester, {
  FakeRecapRepository? repo,
  RecapEntry entry = RecapEntry.wipe,
  bool reduced = false,
  bool screenReader = false,
  Size size = const Size(390, 844),
}) async {
  stubCovers();
  final r = repo ?? FakeRecapRepository();
  await pumpScreen(tester, recapScreen(entry: entry, screenReader: screenReader), extra: recapOverrides(r), reduced: reduced, size: size);
  return r;
}

int? secs(WidgetTester tester) {
  for (final w in tester.widgetList<Text>(find.byType(Text))) {
    final m = RegExp(r'^CH 143 · (\d+) S$').firstMatch(w.data ?? '');
    if (m != null) return int.parse(m[1]!);
  }
  return null;
}

Future<void> advance(WidgetTester tester, int ms) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('loading: the title card is set, Skip recap and Continue are usable at t = 0', (tester) async {
    await pumpRecap(tester);
    await advance(tester, 300);
    expect(find.bySemanticsLabel('Omniscient Reader'), findsWidgets);
    expect(find.byKey(const Key('recap-skip')), findsOneWidget);
    expect(find.byKey(const Key('recap-continue')), findsOneWidget);
    expect(find.text('Writing the recap…'), findsNothing, reason: 'typing has started, not finished');
    await advance(tester, 1200);
    expect(find.text('Writing the recap…'), findsOneWidget);
  });

  testWidgets('streams word by word, deck, cast and footnote', (tester) async {
    final repo = await pumpRecap(tester);
    repo.script();
    await advance(tester, 300);
    final partial = find.byType(RichText).evaluate().length;
    expect(partial, greaterThan(0));
    await advance(tester, 2500);
    expect(find.text('Chapters 131–142, as a recap.'), findsOneWidget);
    expect(find.text('CHARACTERS IN THIS STORY'), findsOneWidget);
    expect(find.textContaining('Recap written from the dialogue of chapters 131–142. AI-written; it can be wrong.'), findsOneWidget);
    expect(find.text('the reader'), findsOneWidget);
  });

  testWidgets('countdown runs 12 s after done: folio counts, rule drains, then the reader opens by the wipe', (tester) async {
    final repo = await pumpRecap(tester);
    expect(secs(tester), isNull, reason: 'never before the stream is done');
    repo.script();
    await advance(tester, 500);
    expect(secs(tester), isNull, reason: 'still streaming');
    await advance(tester, 1500);
    final s0 = secs(tester)!;
    expect(s0, inInclusiveRange(10, 12));
    expect(find.byKey(const Key('recap-drain')), findsOneWidget);
    await advance(tester, 5000);
    expect(secs(tester), inInclusiveRange(s0 - 6, s0 - 4));
    await advance(tester, 8000);
    await tester.pumpAndSettle();
    expect(find.textContaining('at /reader/s/k/c143'), findsOneWidget);
  });

  testWidgets('a finger down pauses the countdown', (tester) async {
    final repo = await pumpRecap(tester);
    repo.script();
    await advance(tester, 2000);
    final g = await tester.startGesture(const Offset(200, 300));
    final s0 = secs(tester)!;
    await advance(tester, 4000);
    expect(secs(tester), s0);
    await g.up();
    await advance(tester, 3000);
    expect(secs(tester), inInclusiveRange(s0 - 4, s0 - 2));
  });

  testWidgets('a pointer over the text pauses; leaving resumes', (tester) async {
    final repo = await pumpRecap(tester);
    repo.script();
    await advance(tester, 2000);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(1, 1));
    await mouse.moveTo(tester.getCenter(find.textContaining('The world ended')));
    await tester.pump();
    final s0 = secs(tester)!;
    await advance(tester, 3000);
    expect(secs(tester), s0);
    await mouse.moveTo(const Offset(1, 1));
    await advance(tester, 2000);
    expect(secs(tester), inInclusiveRange(s0 - 3, s0 - 1));
  });

  testWidgets('the app leaving the foreground pauses it', (tester) async {
    final repo = await pumpRecap(tester);
    repo.script();
    await advance(tester, 2000);
    for (final st in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
      tester.binding.handleAppLifecycleStateChanged(st);
    }
    await tester.pump();
    final s0 = secs(tester)!;
    await advance(tester, 4000);
    expect(secs(tester), s0);
    for (final st in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
      tester.binding.handleAppLifecycleStateChanged(st);
    }
    await advance(tester, 2000);
    expect(secs(tester), inInclusiveRange(s0 - 3, s0 - 1));
  });

  testWidgets('a non-reserved key pauses until Space; Space toggles', (tester) async {
    final repo = await pumpRecap(tester);
    repo.script();
    await advance(tester, 2000);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
    await tester.pump();
    final s0 = secs(tester)!;
    await advance(tester, 3000);
    expect(secs(tester), s0);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await advance(tester, 2000);
    final s1 = secs(tester)!;
    expect(s1, inInclusiveRange(s0 - 3, s0 - 1));
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await advance(tester, 3000);
    expect(secs(tester), s1);
  });

  testWidgets('a screen reader running: the countdown never starts', (tester) async {
    final repo = await pumpRecap(tester, screenReader: true);
    repo.script();
    await advance(tester, 20000);
    expect(secs(tester), isNull);
    expect(find.byKey(const Key('recap-drain')), findsNothing);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.textContaining('AI-written'), findsOneWidget, reason: 'the recap itself finished');
  });

  testWidgets('reduced motion: no draining rule, the folio still counts, no per-word fade', (tester) async {
    final repo = await pumpRecap(tester, reduced: true);
    repo.script();
    await advance(tester, 2000);
    expect(find.byKey(const Key('recap-drain')), findsNothing);
    final s0 = secs(tester)!;
    await advance(tester, 3000);
    expect(secs(tester), inInclusiveRange(s0 - 4, s0 - 2));
  });

  testWidgets('Space completes the streaming at once', (tester) async {
    final repo = await pumpRecap(tester);
    repo.script(text: List.generate(60, (i) => 'w$i').join(' '));
    await advance(tester, 300);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await advance(tester, 300);
    expect(find.textContaining('AI-written; it can be wrong.'), findsOneWidget);
  });

  testWidgets('Enter continues by the wipe; s skips; Esc closes', (tester) async {
    var repo = await pumpRecap(tester);
    repo.script(done: false);
    await advance(tester, 500);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.textContaining('at /reader/s/k/c143'), findsOneWidget);
    repo = await pumpRecap(tester, entry: RecapEntry.dip);
    await advance(tester, 300);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
    await tester.pumpAndSettle();
    expect(find.textContaining('at /reader/s/k/c143'), findsOneWidget);
  });

  testWidgets('a JSON no_dialogue answer reads like the stream error', (tester) async {
    await pumpRecap(tester, repo: FakeRecapRepository(none: const RecapNone('no_dialogue')));
    await advance(tester, 5000);
    expect(find.text('NO RECAP FOR THIS ONE'), findsOneWidget);
    expect(find.textContaining("dialogue in these chapters hasn't been read yet"), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('CH 143'), findsOneWidget);
    expect(find.byKey(const Key('recap-scan')), findsNothing, reason: 'nothing saved to scan');
  });

  testWidgets('a stream error event maps to the same slate', (tester) async {
    final repo = await pumpRecap(tester);
    repo.events.add(const RecapError('no_dialogue', 'x'));
    await advance(tester, 500);
    expect(find.text('NO RECAP FOR THIS ONE'), findsOneWidget);
  });

  testWidgets('unavailable: RECAP UNAVAILABLE and the way onward; never proof', (tester) async {
    for (final reason in ['not_configured', 'budget_exhausted']) {
      await pumpRecap(tester, repo: FakeRecapRepository(none: RecapNone(reason)));
      await advance(tester, 5000);
      expect(find.text('RECAP UNAVAILABLE'), findsOneWidget, reason: reason);
      expect(find.text('Pick up where you left off: chapter 143.'), findsOneWidget);
    }
  });

  testWidgets('rate limited shows SLOW DOWN with the live Retry-After', (tester) async {
    await pumpRecap(tester, repo: FakeRecapRepository(none: const RecapNone('rate_limited', retryAfter: 12)));
    await advance(tester, 500);
    expect(find.text('SLOW DOWN'), findsOneWidget);
    expect(find.textContaining('Try again in 12 s'), findsOneWidget);
    await advance(tester, 3000);
    expect(find.textContaining('Try again in 9 s'), findsOneWidget);
  });

  testWidgets('first chapter: no slate, straight to the reader', (tester) async {
    await pumpRecap(tester, repo: FakeRecapRepository(none: const RecapNone('first_chapter')));
    await tester.pumpAndSettle();
    expect(find.textContaining('at /reader/s/k/c143'), findsOneWidget);
  });

  testWidgets('a broken stream reads as CORRECTION with Try again and Continue', (tester) async {
    final repo = await pumpRecap(tester, repo: FakeRecapRepository(none: const RecapNone('error')));
    await advance(tester, 500);
    expect(find.text('CORRECTION'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await advance(tester, 300);
    expect(repo.opens, 2);
  });

  testWidgets('Skip recaps for this series writes skipSeries and offers Undo', (tester) async {
    final repo = await pumpRecap(tester);
    repo.script();
    await advance(tester, 2500);
    await tester.tap(find.text('Skip recaps for this series'));
    await advance(tester, 500);
    expect(find.text('Recaps are off for Omniscient Reader.'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
  });

  testWidgets('tablet: the cast sits beside the recap from 900 dp', (tester) async {
    final repo = await pumpRecap(tester, size: const Size(1024, 1366));
    repo.script();
    await advance(tester, 2500);
    final cast = tester.getTopLeft(find.text('CHARACTERS IN THIS STORY'));
    final text = tester.getTopLeft(find.byType(RichText).first);
    expect(cast.dx, greaterThan(text.dx + 300));
  });

  testWidgets('scrolling back up resets the countdown to 12 s', (tester) async {
    final repo = await pumpRecap(tester, size: const Size(390, 500));
    repo.script(text: List.generate(120, (i) => 'word$i').join(' '));
    await advance(tester, 4500);
    final list = find.byType(CustomScrollView);
    await tester.drag(list, const Offset(0, -300));
    await advance(tester, 2500);
    final before = secs(tester)!;
    await tester.drag(list, const Offset(0, 120));
    await tester.pump();
    expect(secs(tester), greaterThan(before));
    expect(secs(tester), inInclusiveRange(11, 12));
  });

  testWidgets('reduced motion: words appear at full ink, no per-word fade', (tester) async {
    final repo = await pumpRecap(tester, reduced: true);
    repo.script();
    await advance(tester, 300);
    double alpha(InlineSpan s) => s is TextSpan ? (s.style?.color?.a ?? 1) : 1;
    var min = 1.0;
    void walk(InlineSpan s) {
      if (s is TextSpan) {
        if ((s.text ?? '').trim().isNotEmpty) min = alpha(s) < min ? alpha(s) : min;
        s.children?.forEach(walk);
      }
    }

    for (final r in tester.widgetList<RichText>(find.byType(RichText))) {
      if (r.text.toPlainText().contains('Dokja') || r.text.toPlainText().contains('train')) walk(r.text);
    }
    expect(min, 1.0);
  });

  testWidgets('Scan saved chapters shows only with saved manga chapters and OCR available', (tester) async {
    final saved = <String, ChapterDownloadStatus>{'c142': (state: DownloadChapterState.complete, error: null)};
    for (final c in [(true, saved, true), (false, saved, false), (true, <String, ChapterDownloadStatus>{}, false)]) {
      await tester.pumpWidget(const SizedBox());
      stubCovers();
      final repo = FakeRecapRepository(none: const RecapNone('no_dialogue'));
      await pumpScreen(
        tester,
        recapScreen(),
        ocrOn: c.$1,
        extra: [...recapOverrides(repo), seriesChapterDownloadStatusProvider.overrideWith((ref, k) async => c.$2)],
      );
      await advance(tester, 6000);
      expect(find.byKey(const Key('recap-scan')).evaluate().isNotEmpty, c.$3, reason: '$c');
    }
  });
}
