// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/providers/listen_settings_provider.dart';
import 'package:manhwamaniacs/features/novels/utils/sleep_timer.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/post_play_card.dart';

import '../feature/feature_test_support.dart';
import 'listen_test_support.dart';

Widget host(Widget child, {bool reduced = false, bool screenReader = false}) => MaterialApp(
      theme: featureTheme(TargetPlatform.android),
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced, accessibleNavigation: screenReader),
        child: c!,
      ),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('PostPlayCard', () {
    testWidgets('types the next chapter, sweeps a dial for 5000 ms, then plays on', (tester) async {
      var played = 0;
      await tester.pumpWidget(host(PostPlayCard(nextLabel: 'Chapter 13', onPlayNow: () => played++, onCancel: () {})));
      expect(find.text('NEXT'), findsOneWidget);
      expect(find.byKey(const Key('post-play-dial')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 4700));
      expect(played, 0);
      await tester.pump(const Duration(milliseconds: 400));
      expect(played, 1);
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('Play now goes at once, Cancel stops the countdown', (tester) async {
      var played = 0, cancelled = 0;
      await tester.pumpWidget(host(PostPlayCard(nextLabel: 'Chapter 13', onPlayNow: () => played++, onCancel: () => cancelled++)));
      await tester.tap(find.text('Play now'));
      await tester.pump();
      expect(played, 1);

      await tester.pumpWidget(host(PostPlayCard(key: UniqueKey(), nextLabel: 'Chapter 13', onPlayNow: () => played++, onCancel: () => cancelled++)));
      await tester.tap(find.text('Cancel'));
      await tester.pump(const Duration(seconds: 6));
      expect(cancelled, 1);
      expect(played, 1);
    });

    testWidgets('the countdown waits while focus is inside the card', (tester) async {
      var played = 0;
      await tester.pumpWidget(host(PostPlayCard(nextLabel: 'Chapter 13', onPlayNow: () => played++, onCancel: () {})));
      await tester.pump(const Duration(milliseconds: 100));
      Focus.of(tester.element(find.text('Play now'))).requestFocus();
      final scope = FocusScope.of(tester.element(find.text('Play now')));
      scope.focusedChild?.requestFocus();
      final firstButton = find.text('Play now');
      FocusManager.instance.primaryFocus?.unfocus();
      // Move focus into the card with the keyboard.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 8));
      expect(firstButton, findsOneWidget);
      expect(played, 0, reason: 'focus inside the card holds the countdown');
    });

    testWidgets('with auto-play off there is no dial and it waits for Play now', (tester) async {
      var played = 0;
      await tester.pumpWidget(host(PostPlayCard(nextLabel: 'Chapter 13', countdown: false, onPlayNow: () => played++, onCancel: () {})));
      expect(find.byKey(const Key('post-play-dial')), findsNothing);
      await tester.pump(const Duration(seconds: 10));
      expect(played, 0);
    });

    testWidgets('it does not start while a screen reader runs', (tester) async {
      var played = 0;
      await tester.pumpWidget(host(PostPlayCard(nextLabel: 'Chapter 13', onPlayNow: () => played++, onCancel: () {}), screenReader: true));
      expect(find.byKey(const Key('post-play-dial')), findsNothing);
      await tester.pump(const Duration(seconds: 10));
      expect(played, 0);
    });

    testWidgets('reduced motion: no sweep, a folio counting 5 S to 1 S, the title whole', (tester) async {
      var played = 0;
      await tester.pumpWidget(host(PostPlayCard(nextLabel: 'Chapter 13', onPlayNow: () => played++, onCancel: () {}), reduced: true));
      expect(find.byKey(const Key('post-play-dial')), findsNothing);
      expect(find.text('Chapter 13'), findsOneWidget);
      expect(find.text('5 S'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('4 S'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      expect(played, 1);
    });
  });

  group('the boundary in the reader', () {
    testWidgets('the end of a chapter shows the card; the countdown swaps the next chapter in place and keeps listening', (tester) async {
      final l = await pumpListen(tester);
      await settleNovel(tester, ms: 800);
      await tester.tap(find.byKey(const Key('opener-listen')));
      await l.settle();
      l.player.finish();
      await l.settle();
      expect(find.byKey(const Key('post-play-card')), findsOneWidget);
      expect(find.text('NEXT'), findsOneWidget);
      await settleNovel(tester, ms: 5600);
      await settleNovel(tester, ms: 800);
      await l.settle();
      expect(l.players.length, 2, reason: 'the next chapter got its own player');
      expect(l.state.key!.chapterKey, '2');
      expect(l.state.status, NarrationStatus.playing);
      expect(find.byKey(const Key('post-play-card')), findsNothing);
      await leaveListen(l);
    });

    testWidgets('Play now advances at once', (tester) async {
      final l = await pumpListen(tester);
      await settleNovel(tester, ms: 800);
      await tester.tap(find.byKey(const Key('opener-listen')));
      await l.settle();
      l.player.finish();
      await l.settle();
      await tester.tap(find.text('Play now'));
      await settleNovel(tester, ms: 800);
      await l.settle();
      expect(l.state.key!.chapterKey, '2');
      await leaveListen(l);
    });

    testWidgets('End of chapter stops here with no card', (tester) async {
      final l = await pumpListen(tester);
      await settleNovel(tester, ms: 800);
      await tester.tap(find.byKey(const Key('opener-listen')));
      await l.settle();
      l.narration.setSleep(SleepChoice.endOfChapter);
      l.player.finish();
      await l.settle();
      expect(find.byKey(const Key('post-play-card')), findsNothing);
      await settleNovel(tester, ms: 6000);
      expect(l.state.key!.chapterKey, '1');
      expect(l.players, hasLength(1));
      await leaveListen(l);
    });

    testWidgets('with auto-play off the card shows without the dial and waits', (tester) async {
      final l = await pumpListen(tester, prefsValues: const {'mm.listen-settings.u1p1': '{"autoPlayNext":false}'});
      await settleNovel(tester, ms: 800);
      await tester.tap(find.byKey(const Key('opener-listen')));
      await l.settle();
      expect(l.container.read(listenSettingsValueProvider).autoPlayNext, isFalse);
      l.player.finish();
      await l.settle();
      expect(find.byKey(const Key('post-play-card')), findsOneWidget);
      expect(find.byKey(const Key('post-play-dial')), findsNothing);
      await settleNovel(tester, ms: 6000);
      expect(l.state.key!.chapterKey, '1');
      await leaveListen(l);
    });

    testWidgets('Cancel keeps the reader on this chapter', (tester) async {
      final l = await pumpListen(tester);
      await settleNovel(tester, ms: 800);
      await tester.tap(find.byKey(const Key('opener-listen')));
      await l.settle();
      l.player.finish();
      await l.settle();
      await tester.tap(find.text('Cancel'));
      await settleNovel(tester, ms: 6000);
      expect(find.byKey(const Key('post-play-card')), findsNothing);
      expect(l.state.key!.chapterKey, '1');
      await leaveListen(l);
    });
  });
}
