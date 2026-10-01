// ignore_for_file: require_trailing_commas
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/listen/glass_narration_host.dart';
import 'package:manhwamaniacs/skins/glass/listen/listen_common.dart';
import 'package:manhwamaniacs/skins/glass/listen/listen_row.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/novel_keys.dart';
import 'package:manhwamaniacs/skins/glass/shell/accessory.dart';
import 'package:manhwamaniacs/skins/glass/shell/accessory_controller.dart';
import 'package:manhwamaniacs/skins/glass/shell/desktop_accessory.dart';

import '../primitives/support.dart';

GlassNarrationAccessory _narrating({bool playing = true, int phase = 0, void Function()? onStop, void Function()? onNext, void Function()? onPrev, void Function(Rect)? open}) => GlassNarrationAccessory(
      title: 'Chapter 12 · Aurora',
      playing: playing,
      progress: 0.4,
      onPlayPause: () {},
      openPlayer: open ?? (_) {},
      onNextChapter: onNext,
      onPreviousChapter: onPrev,
      voiceHue: const Color(0xFF8FD6B7),
      voiceInitial: 'A',
      onStop: onStop,
      phase: phase,
    );

void main() {
  testWidgets('the bottom accessory narrates: orb, title, play, a sideways flick changes chapter, a downward flick stops', (t) async {
    final handle = t.ensureSemantics();
    var next = 0, stop = 0;
    Rect? opened;
    final state = GlassAccessoryState(narration: _narrating(onNext: () => next++, onStop: () => stop++, open: (r) => opened = r));
    await t.pumpWidget(primHost(SizedBox(width: 390, height: 56, child: Consumer(builder: (c, ref, _) => GlassAccessoryBody(state: state, minimised: false)))));
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('Chapter 12 · Aurora'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.bySemanticsLabel('Pause'), findsOneWidget);
    await t.tap(find.text('Chapter 12 · Aurora'));
    await t.pump();
    expect(opened, isNotNull);
    await t.fling(find.text('Chapter 12 · Aurora'), const Offset(-300, 0), 2000);
    await t.pump(const Duration(seconds: 1));
    expect(next, 1);
    await t.fling(find.text('Chapter 12 · Aurora'), const Offset(0, 120), 2000);
    await t.pump(const Duration(seconds: 1));
    expect(stop, 1);
    handle.dispose();
  });

  testWidgets('the accessory states: preparing shows the ring, failed shows the retry', (t) async {
    final handle = t.ensureSemantics();
    await t.pumpWidget(primHost(SizedBox(width: 390, height: 56, child: Consumer(builder: (c, ref, _) => GlassAccessoryBody(state: GlassAccessoryState(narration: _narrating(phase: 1)), minimised: false)))));
    await t.pump(const Duration(milliseconds: 100));
    expect(find.bySemanticsLabel('Preparing audio'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(primHost(SizedBox(width: 390, height: 56, child: Consumer(builder: (c, ref, _) => GlassAccessoryBody(state: GlassAccessoryState(narration: _narrating(phase: 2)), minimised: false)))));
    await t.pump(const Duration(milliseconds: 100));
    expect(find.bySemanticsLabel("Audio couldn't load, retry"), findsOneWidget);
    handle.dispose();
  });

  testWidgets('the desktop accessory: orb, title, play and the 2 px progress; collapsed it is a 56 px orb with a play overlay', (t) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(glassAccessoryProvider.notifier).setNarration(_narrating());
    Future<void> pump({required bool expanded}) async {
      await t.pumpWidget(const SizedBox());
      await t.pumpWidget(UncontrolledProviderScope(container: container, child: primHost(SizedBox(width: expanded ? 252 : 56, child: GlassDesktopAccessory(expanded: expanded)))));
      await t.pump(const Duration(milliseconds: 100));
    }

    await pump(expanded: true);
    expect(find.text('Chapter 12 · Aurora'), findsOneWidget);
    expect(find.byType(ListenProgressLine), findsOneWidget);
    await pump(expanded: false);
    expect(find.text('Chapter 12 · Aurora'), findsNothing);
    expect(t.getSize(find.byType(GlassDesktopAccessory)).width, 56);
  });

  testWidgets('hit areas: the row\'s controls meet 44 x 44', (t) async {
    final handle = t.ensureSemantics();
    await t.pumpWidget(primHost(SizedBox(width: 390, height: 56, child: Consumer(builder: (c, ref, _) => GlassAccessoryBody(state: GlassAccessoryState(narration: _narrating()), minimised: false)))));
    await t.pump(const Duration(milliseconds: 100));
    await expectLater(t, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  test('the Listen key group: [ ] sentence, Shift+[ ] 15 s, < > speed, v voices, p play', () {
    final b = novelKeyBindings(desktopFrame: false, singleKeys: true);
    NovelKeyAction? of(LogicalKeyboardKey k, {bool shift = false}) {
      for (final x in b) {
        if (x.activator.trigger == k && x.activator.shift == shift) return x.action;
      }
      return null;
    }

    expect(of(LogicalKeyboardKey.bracketLeft), NovelKeyAction.previousSentence);
    expect(of(LogicalKeyboardKey.bracketRight), NovelKeyAction.nextSentence);
    expect(of(LogicalKeyboardKey.bracketLeft, shift: true), NovelKeyAction.back15);
    expect(of(LogicalKeyboardKey.bracketRight, shift: true), NovelKeyAction.forward15);
    expect(of(LogicalKeyboardKey.comma, shift: true), NovelKeyAction.slower);
    expect(of(LogicalKeyboardKey.period, shift: true), NovelKeyAction.faster);
    expect(of(LogicalKeyboardKey.keyV), NovelKeyAction.voices);
    expect(of(LogicalKeyboardKey.keyP), NovelKeyAction.playPause);
  });

  test('chapter lines and the row geometry', () {
    expect(listenRowWidth(358, landscapePhone: true), 320);
    expect(listenRowWidth(358, landscapePhone: false), 358);
    expect(kListenRowLinger, const Duration(milliseconds: 5000));
    expect(listenClock(312000), '5:12');
    expect(listenClock(1120000, remaining: true), '−18:40');
    expect(listenSpokenClock(312000, 1432000), '5 minutes 12 of 23 minutes 52');
    expect(glassListenScopeFor(['novels', 's', 'k', 'c1'], null), (sourceId: 's', seriesKey: 'k', chapterKey: 'c1'));
    expect(glassListenScopeFor(['sources', 's', 'series', 'k'], null), (sourceId: 's', seriesKey: 'k', chapterKey: null));
    expect(glassListenScopeFor(['library'], (sourceId: 'a', seriesKey: 'b', chapterKey: 'c')), (sourceId: 'a', seriesKey: 'b', chapterKey: 'c'));
    expect(glassListenScopeFor(['library'], null), isNull);
  });
}
