import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_view.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/manga_reader.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../screenshots/support/shot_network.dart';
import 'reader_test_support.dart';

// 'Open menu with' (Settings > Reading): Tap (default) opens and closes the menu with one centre tap,
// Double tap with a centre double tap, Top or bottom edge with a tap in the edge bands. A touch that
// catches a moving strip (or lands within 300 ms of it stopping) only stops it; a scroll the app made
// (tap-to-scroll, auto-scroll) never eats a tap. The chapter end shows the menu. Both entry points: the
// library reader and the source reader (each owns its own feed controller).

ScrollPosition _strip(WidgetTester tester) => tester
    .state<ScrollableState>(find.descendant(of: find.byType(ReaderEngineView), matching: find.byType(Scrollable)).first)
    .position;

Future<void> _hidden(WidgetTester tester) async {
  await settleReader(tester, ms: 5600);
  expect(chromeVisible(tester), isFalse, reason: 'idle-hidden before the taps');
}

void main() {
  setUpAll(setUpShotCoverCache);

  for (final origin in [ReaderRigOrigin.manifest, ReaderRigOrigin.source]) {
    group(origin.name, () {
      testWidgets('Tap (default): a single centre tap opens and closes the menu at once', (tester) async {
        await pumpReader(tester, origin: origin, platform: TargetPlatform.iOS);
        await _hidden(tester);
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 350)));
        await tester.tapAt(const Offset(195, 422));
        await tester.pump();
        expect(chromeVisible(tester), isTrue, reason: 'no double-tap wait');
        await tapSingle(tester);
        expect(chromeVisible(tester), isFalse, reason: 'a second tap closes');
        await disposeReader(tester);
      });

      testWidgets('Double tap: a single centre tap does not open the menu; a double tap opens and closes it', (tester) async {
        await pumpReader(tester, origin: origin, platform: TargetPlatform.iOS);
        await putReaderSettings(tester, {'menuOpen': 'doubleTap'});
        await _hidden(tester);
        await tapSingle(tester);
        expect(chromeVisible(tester), isFalse, reason: 'a single tap');
        await tapDouble(tester);
        expect(chromeVisible(tester), isTrue, reason: 'a double tap opens');
        await tapDouble(tester);
        expect(chromeVisible(tester), isFalse, reason: 'a double tap closes');
        await disposeReader(tester);
      });

      testWidgets('Top or bottom edge: a centre tap does nothing; a tap in the top or bottom band toggles', (tester) async {
        await pumpReader(tester, origin: origin, platform: TargetPlatform.iOS);
        await putReaderSettings(tester, {'menuOpen': 'edge'});
        await _hidden(tester);
        await tapSingle(tester);
        await tapDouble(tester);
        expect(chromeVisible(tester), isFalse, reason: 'the centre, single or double');
        // 12 % of 844 is 101: the bottom band starts at 743.
        await tapSingle(tester, const Offset(195, 800));
        expect(chromeVisible(tester), isTrue, reason: 'the bottom band opens');
        await _hidden(tester);
        await tapSingle(tester, const Offset(195, 60));
        expect(chromeVisible(tester), isTrue, reason: 'the top band opens');
        await disposeReader(tester);
      });

      testWidgets('a tap that stops a fling, or a tap just after it, does not open the menu', (tester) async {
        await pumpReader(tester, origin: origin, platform: TargetPlatform.iOS);
        await _hidden(tester);
        Future<void> flingAndCatch() async {
          await tester.flingFrom(const Offset(195, 650), const Offset(0, -300), 2500);
          await tester.pump(const Duration(milliseconds: 16));
          await tester.pump(const Duration(milliseconds: 16));
          final at = _strip(tester).pixels;
          await tester.pump(const Duration(milliseconds: 16));
          expect(_strip(tester).pixels, isNot(at), reason: 'still coasting');
          // A slow catch, held past the 300 ms post-scroll cooldown.
          final g = await tester.startGesture(const Offset(195, 422));
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 320)));
          await g.up();
          await tester.pump(const Duration(milliseconds: 200));
        }

        await flingAndCatch();
        await settleReader(tester, ms: 700);
        expect(chromeVisible(tester), isFalse, reason: 'the touch that stopped the fling');

        // A quick catch, and a tap right after it: inside the 300 ms the stop starts.
        await tester.flingFrom(const Offset(195, 650), const Offset(0, -300), 2500);
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 16));
        await tester.tapAt(const Offset(195, 422));
        await tester.pump(const Duration(milliseconds: 16));
        await tester.tapAt(const Offset(195, 422));
        await settleReader(tester, ms: 700);
        expect(chromeVisible(tester), isFalse, reason: 'the catch and a tap inside the cooldown');

        await tapSingle(tester);
        expect(chromeVisible(tester), isTrue, reason: 'a deliberate tap on the stopped strip');
        await disposeReader(tester);
      });

      testWidgets('a scroll the app made never eats the next tap', (tester) async {
        await pumpReader(tester, origin: origin, platform: TargetPlatform.iOS);
        await putReaderSettings(tester, {'stripTaps': 'scroll'});
        await _hidden(tester);
        // Tap-to-scroll: the bottom third moves the strip 75 % of a screen.
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 350)));
        final before = _strip(tester).pixels;
        await tester.tapAt(const Offset(195, 700));
        await settleReader(tester, ms: 600);
        expect(_strip(tester).pixels, greaterThan(before), reason: 'tap-to-scroll moved the strip');
        expect(chromeVisible(tester), isFalse);
        // At once on the wall clock (inside 300 ms of that scroll's end): still a tap.
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
        await tester.tapAt(const Offset(195, 422));
        await tester.pump();
        expect(chromeVisible(tester), isTrue, reason: 'the app scroll is not the reader\'s motion');
        await disposeReader(tester);
      });

      testWidgets('scrolling back never opens the menu', (tester) async {
        await pumpReader(tester, origin: origin, platform: TargetPlatform.iOS);
        await _hidden(tester);
        await tester.dragFrom(const Offset(195, 600), const Offset(0, -400));
        await settleReader(tester, ms: 600);
        await tester.dragFrom(const Offset(195, 200), const Offset(0, 300));
        await settleReader(tester, ms: 600);
        expect(chromeVisible(tester), isFalse);
        await disposeReader(tester);
      });

      testWidgets('reaching the chapter end shows the menu, then it idles out; off in settings, it stays hidden', (tester) async {
        await pumpReader(tester, origin: origin, platform: TargetPlatform.iOS, pages: 2);
        await _hidden(tester);
        _strip(tester).jumpTo(_strip(tester).maxScrollExtent);
        await tester.pump();
        expect(chromeVisible(tester), isTrue, reason: 'the chapter end');
        await settleReader(tester, ms: 5200);
        expect(chromeVisible(tester), isFalse, reason: 'the 5 s idle');

        await putReaderSettings(tester, {'menuAtChapterEnd': false});
        _strip(tester).jumpTo(0);
        await tester.pump();
        _strip(tester).jumpTo(_strip(tester).maxScrollExtent);
        await tester.pump();
        expect(chromeVisible(tester), isFalse, reason: 'Show menu at chapter end off');
        await disposeReader(tester);
      });

      testWidgets('a screen reader reaches the menu whatever the mode', (tester) async {
        final handle = tester.ensureSemantics();
        await pumpReader(tester, origin: origin, platform: TargetPlatform.iOS);
        await putReaderSettings(tester, {'menuOpen': 'edge'});
        await tester.pump();
        final reader = find.byType(CineMangaReader);
        final node = tester.getSemantics(find.descendant(of: reader, matching: find.bySemanticsLabel(RegExp(r'^Chapter .*page'))).first);
        final action = node.getSemanticsData().customSemanticsActionIds!;
        expect(action, isNotEmpty);
        final hidden = chromeVisible(tester);
        node.owner!.performAction(node.id, SemanticsAction.customAction, action.first);
        await tester.pump();
        expect(chromeVisible(tester), isNot(hidden));
        handle.dispose();
        await disposeReader(tester);
      });
    });
  }

  testWidgets('Open menu with persists in the profile record', (tester) async {
    await pumpReader(tester);
    await putReaderSettings(tester, {'menuOpen': 'edge', 'menuAtChapterEnd': false});
    final sp = await SharedPreferences.getInstance();
    final stored = sp.getKeys().where((k) => k.startsWith('mm.reader-settings.')).map(sp.getString).join();
    expect(stored, contains('"menuOpen":"edge"'));
    expect(stored, contains('"menuAtChapterEnd":false'));
    await disposeReader(tester);
  });
}
