// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/models/novel_audio.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/novel_paragraph.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

import 'listen_test_support.dart';

Future<ListenRig> started(WidgetTester tester, {bool stale = false, bool owner = true, Size? size, bool wide = false, EdgeInsets padding = EdgeInsets.zero, bool reduced = false, String query = '', Set<String> narrated = const {'1', '2', '3'}}) async {
  final l = await pumpListen(tester, stale: stale, owner: owner, size: size, wide: wide, padding: padding, reduced: reduced, query: query, narrated: narrated);
  await settleNovel(tester, ms: 800);
  await tester.tap(find.byKey(const Key('opener-listen')));
  await l.settle();
  return l;
}

/// The built [NovelParagraph] showing paragraph [p] of the fixture chapter.
NovelParagraph paragraph(WidgetTester tester, int p) {
  final text = fixtureParagraphs()[p];
  return tester.widget<NovelParagraph>(find.byWidgetPredicate((w) => w is NovelParagraph && w.text == text).first);
}

void main() {
  testWidgets('the opener offers Listen for a narrated chapter; a tap starts the narrator and shows the mini player', (tester) async {
    final l = await pumpListen(tester);
    await settleNovel(tester, ms: 800);
    expect(find.byKey(const Key('opener-listen')), findsOneWidget);
    expect(find.text('1 MIN'), findsOneWidget);
    await tester.tap(find.byKey(const Key('opener-listen')));
    await l.settle();
    expect(l.players, hasLength(1));
    expect(l.player.calls, containsAllInOrder(['setUrl', 'play']));
    expect(l.state.status, NarrationStatus.playing);
    expect(l.sessions, contains(isNotNull));
    expect(find.byKey(const Key('mini-player')), findsOneWidget);
    expect(find.text('CHAPTER 1 · READ BY VOICE 20'), findsOneWidget);
    await leaveListen(l);
  });

  testWidgets('a chapter with no audio has no Listen button; the owner sees NOT NARRATED and can ask for it at priority 9', (tester) async {
    final l = await pumpListen(tester, narrated: const {});
    await settleNovel(tester, ms: 800);
    expect(find.byKey(const Key('opener-listen')), findsNothing);
    expect(find.text('NOT NARRATED'), findsOneWidget);
    await tester.tap(find.text('Narrate this chapter'));
    await l.settle();
    expect(l.repo.renderCalls.single.keys, ['1']);
    expect(l.repo.renderCalls.single.priority, 9);
    expect(l.repo.renderCalls.single.force, isFalse);
    await leaveListen(l);
  });

  testWidgets('a reader who is not the owner sees neither NOT NARRATED nor a way to narrate', (tester) async {
    final l = await pumpListen(tester, narrated: const {}, owner: false);
    await settleNovel(tester, ms: 800);
    expect(find.text('NOT NARRATED'), findsNothing);
    expect(find.text('Narrate this chapter'), findsNothing);
    await leaveListen(l);
  });

  testWidgets('hardware key p plays, pauses and resumes', (tester) async {
    final l = await pumpListen(tester);
    await settleNovel(tester, ms: 800);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await l.settle();
    expect(l.state.status, NarrationStatus.playing);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await l.settle();
    expect(l.state.status, NarrationStatus.paused);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await l.settle();
    expect(l.state.isPlaying, isTrue);
    await leaveListen(l);
  });

  testWidgets('hardware keys [ and ] step by sentence', (tester) async {
    final l = await started(tester);
    await l.tick(20000);
    final audio = NovelAudio.fromJson(fixtureJson('audio'));
    final now = l.narration.segment.value;
    await tester.sendKeyEvent(LogicalKeyboardKey.bracketRight);
    await l.settle();
    expect(l.player.seeks.last, Duration(milliseconds: audio.segments[now + 1].startMs));
    await tester.sendKeyEvent(LogicalKeyboardKey.bracketLeft);
    await l.settle();
    expect(l.player.seeks.last.inMilliseconds, lessThan(20000));
    await leaveListen(l);
  });

  testWidgets('hardware keys Shift+[ and Shift+] go back and forward 15 seconds', (tester) async {
    final l = await started(tester);
    await l.tick(30000);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.bracketRight);
    await l.settle();
    expect(l.player.seeks.last, const Duration(seconds: 45));
    await l.tick(45000);
    await tester.sendKeyEvent(LogicalKeyboardKey.bracketLeft);
    await l.settle();
    expect(l.player.seeks.last, const Duration(seconds: 30));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await leaveListen(l);
  });

  testWidgets('hardware keys < and > move the Listen speed by 0.05', (tester) async {
    final l = await started(tester);
    final before = l.state.speed;
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.period);
    await l.settle();
    expect(l.state.speed, closeTo(before + 0.05, 1e-9));
    await tester.sendKeyEvent(LogicalKeyboardKey.comma);
    await tester.sendKeyEvent(LogicalKeyboardKey.comma);
    await l.settle();
    expect(l.state.speed, closeTo(before - 0.05, 1e-9));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await leaveListen(l);
  });

  testWidgets('following along: the band and the word go on the active sentence; tints lose their fill under it', (tester) async {
    final l = await started(tester);
    await l.tick(500);
    await settleNovel(tester, ms: 200);
    final audio = NovelAudio.fromJson(fixtureJson('audio'));
    final seg = audio.segments[l.narration.segment.value];
    final para = paragraph(tester, seg.paragraph);
    final band = para.decorations.where((d) => d.fill == cinematicTokens.colorSpotWash).toList();
    expect(band, hasLength(1));
    expect((band.single.start, band.single.end), (seg.start, seg.end));
    expect(band.single.sweep, greaterThan(0));
    expect(para.decorations.where((d) => d.fill == null && d.underline != null && d.speaker == null), isNotEmpty, reason: 'the spoken word underline');
    // Speaker tints inside the sentence keep their underline but not their 12 % background.
    for (final d in para.decorations.where((d) => d.speaker != null && d.start < seg.end && d.end > seg.start)) {
      expect(d.fill, isNull);
      expect(d.underline, isNotNull);
    }
    // No other paragraph is lit.
    for (final w in tester.widgetList<NovelParagraph>(find.byType(NovelParagraph))) {
      if (w.text != fixtureParagraphs()[seg.paragraph]) expect(w.decorations.where((d) => d.fill == cinematicTokens.colorSpotWash), isEmpty);
    }
    // After the sweep the band is complete.
    await settleNovel(tester, ms: 400);
    expect(paragraph(tester, seg.paragraph).decorations.singleWhere((d) => d.fill == cinematicTokens.colorSpotWash).sweep, 1.0);
    await leaveListen(l);
  });

  testWidgets('stale timings: audio plays, nothing is lit', (tester) async {
    final l = await started(tester, stale: true);
    await l.tick(12000);
    expect(l.state.status, NarrationStatus.playing);
    expect(l.state.highlightSafe, isFalse);
    for (final p in tester.widgetList<NovelParagraph>(find.byType(NovelParagraph))) {
      expect(p.decorations.where((d) => d.fill == cinematicTokens.colorSpotWash), isEmpty);
    }
    await leaveListen(l);
  });

  testWidgets('leaving the reader stops the narrator and releases the player', (tester) async {
    final l = await started(tester);
    final p = l.player;
    await leaveListen(l);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    expect(p.disposed, isTrue);
    expect(l.handler.mediaItem.value, isNull);
  });
}
