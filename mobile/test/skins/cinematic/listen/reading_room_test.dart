// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/novels/models/novel_audio.dart';
import 'package:manhwamaniacs/features/novels/utils/sleep_timer.dart';

import 'listen_test_support.dart';

Future<ListenRig> started(WidgetTester tester, {bool stale = false, bool reduced = false, Size? size, bool wide = false, EdgeInsets padding = EdgeInsets.zero, bool owner = true, Set<String> narrated = const {'1', '2', '3'}}) async {
  final l = await pumpListen(tester, stale: stale, reduced: reduced, size: size, wide: wide, padding: padding, owner: owner, narrated: narrated);
  await settleNovel(tester, ms: 800);
  await tester.tap(find.byKey(const Key('opener-listen')));
  await l.settle();
  return l;
}

Future<void> openRoom(ListenRig l) async {
  await l.tester.tap(find.bySemanticsLabel(RegExp('Open the reading room')));
  await settleNovel(l.tester, ms: 700);
}

void main() {
  testWidgets('tapping the mini player opens the reading room; focus goes to Done; Done collapses and focus returns to the player', (tester) async {
    final l = await started(tester);
    await openRoom(l);
    expect(find.text('NOW READING ALOUD'), findsOneWidget);
    expect(find.byKey(const Key('room-play')), findsOneWidget);
    expect(find.byKey(const Key('tile-speed')), findsOneWidget);
    expect(find.byKey(const Key('tile-voices')), findsOneWidget);
    expect(find.byKey(const Key('tile-sleep')), findsOneWidget);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'reading-room-done');
    await tester.tap(find.text('Done'));
    await settleNovel(tester, ms: 700);
    expect(find.text('NOW READING ALOUD'), findsNothing);
    expect(find.byKey(const Key('mini-player')), findsOneWidget);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'mini-play');
    await leaveListen(l);
  });

  testWidgets('Escape collapses the room first and then leaves it to the book', (tester) async {
    final l = await started(tester);
    await openRoom(l);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settleNovel(tester, ms: 700);
    expect(find.text('NOW READING ALOUD'), findsNothing);
    expect(find.byKey(const Key('mini-player')), findsOneWidget);
    await leaveListen(l);
  });

  testWidgets('Android back collapses the room before it leaves the reader', (tester) async {
    final l = await started(tester);
    await openRoom(l);
    await tester.binding.handlePopRoute();
    await settleNovel(tester, ms: 700);
    expect(find.text('NOW READING ALOUD'), findsNothing);
    expect(find.byKey(const Key('mini-player')), findsOneWidget);
    expect(find.text('book page'), findsNothing);
    await leaveListen(l);
  });

  testWidgets('a swipe down collapses the room, finger-tracked', (tester) async {
    final l = await started(tester);
    await openRoom(l);
    await tester.fling(find.text('NOW READING ALOUD'), const Offset(0, 500), 1500);
    await settleNovel(tester, ms: 1200);
    expect(find.text('NOW READING ALOUD'), findsNothing);
    expect(find.byKey(const Key('mini-player')), findsOneWidget);
    await leaveListen(l);
  });

  testWidgets('the transcript shows the sentences; a tap on one plays from it; dialogue carries the speaker', (tester) async {
    final l = await started(tester, size: const Size(390, 1600));
    await openRoom(l);
    final audio = NovelAudio.fromJson(fixtureJson('audio'));
    expect(find.byKey(const Key('transcript')), findsOneWidget);
    expect(find.text('ALICE'), findsWidgets);
    final first = audio.segments[1];
    final text = fixtureParagraphs()[first.paragraph].substring(first.start, first.end).trim();
    await tester.tap(find.text(text).first);
    await l.settle();
    expect(l.player.seeks.last, Duration(milliseconds: first.startMs));
    await leaveListen(l);
  });

  testWidgets('the active sentence carries the band in the transcript', (tester) async {
    final l = await started(tester);
    await openRoom(l);
    await l.tick(500);
    await settleNovel(tester, ms: 300);
    expect(find.byKey(const Key('transcript-band')), findsOneWidget);
    await leaveListen(l);
  });

  testWidgets('stale timings: the room says the highlight is paused and lights nothing', (tester) async {
    final l = await started(tester, stale: true);
    await openRoom(l);
    await l.tick(500);
    expect(find.byKey(const Key('highlight-paused')), findsOneWidget);
    expect(find.text('Highlight paused: the text changed.'), findsOneWidget);
    expect(find.byKey(const Key('transcript-band')), findsNothing);
    await leaveListen(l);
  });

  testWidgets('the tiles open the speed, voices and sleep sheets', (tester) async {
    final l = await started(tester);
    await openRoom(l);
    expect(find.text('1.00×'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tile-speed')));
    await settleNovel(tester, ms: 700);
    expect(find.text('SPEED'), findsWidgets);
    expect(find.text('Pitch stays the same at every speed.'), findsOneWidget);
    await tester.tap(find.text('Done').last);
    await settleNovel(tester, ms: 700);

    await tester.tap(find.byKey(const Key('tile-voices')));
    await settleNovel(tester, ms: 700);
    expect(find.text('THE CAST'), findsOneWidget);
    expect(find.text('Narrator'), findsOneWidget);
    await tester.tap(find.text('Done').last);
    await settleNovel(tester, ms: 700);

    await tester.tap(find.byKey(const Key('tile-sleep')));
    await settleNovel(tester, ms: 700);
    expect(find.text('End of next chapter'), findsOneWidget);
    await tester.tap(find.text('15 min'));
    await settleNovel(tester, ms: 700);
    expect(l.narration.sleepState.value.choice, SleepChoice.minutes(15));
    await settleNovel(tester, ms: 300);
    expect(find.byKey(const Key('tile-sleep')), findsOneWidget);
    await leaveListen(l);
  });

  testWidgets('the speed sheet writes the speed to the player and the profile', (tester) async {
    final l = await started(tester);
    await openRoom(l);
    await tester.tap(find.byKey(const Key('tile-speed')));
    await settleNovel(tester, ms: 700);
    final track = find.byKey(const ValueKey('speed-ruler-track'));
    final rect = tester.getRect(track);
    // 40 % along the 0.50-3.00 track is 1.50x.
    await tester.tapAt(rect.topLeft + Offset(rect.width * 0.4, 20));
    await settleNovel(tester, ms: 400);
    expect(l.state.speed, 1.5);
    expect(l.player.speeds.last, 1.5);
    // Touch and hold anywhere on the ruler resets to 1.00x.
    await tester.longPress(track);
    await settleNovel(tester, ms: 400);
    expect(l.state.speed, 1.0);
    await leaveListen(l);
  });

  testWidgets('the room reads its chapter ruler as "12 minutes 5 seconds of 30 minutes"-style semantics', (tester) async {
    final handle = tester.ensureSemantics();
    final l = await started(tester);
    await openRoom(l);
    await l.tick(20000);
    await settleNovel(tester, ms: 200);
    final node = tester.getSemantics(find.byKey(const Key('listen-ruler')));
    expect(node.label, contains('Position in the chapter'));
    expect(node.value, contains('20 seconds of 1 minute'));
    expect(node.getSemanticsData().hasAction(SemanticsAction.increase), isTrue);
    expect(node.getSemanticsData().hasAction(SemanticsAction.decrease), isTrue);
    handle.dispose();
    await leaveListen(l);
  });
}
