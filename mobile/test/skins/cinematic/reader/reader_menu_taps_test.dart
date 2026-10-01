import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_view.dart';

import '../../../screenshots/support/shot_network.dart';
import 'reader_test_support.dart';

// The owner's bug: the reading menu opened while scrolling. Only a deliberate double tap opens it,
// and never a touch that catches a moving strip. Both entry points: the library reader and the
// source reader (each owns its own feed controller).

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
      testWidgets('a single centre tap does not open the menu; a double tap opens and closes it', (tester) async {
        await pumpReader(tester, origin: origin, platform: TargetPlatform.iOS);
        await _hidden(tester);
        await tapSingle(tester);
        expect(chromeVisible(tester), isFalse, reason: 'a single tap');
        await tapDouble(tester);
        expect(chromeVisible(tester), isTrue, reason: 'a double tap opens');
        await tapDouble(tester);
        expect(chromeVisible(tester), isFalse, reason: 'a double tap closes');
        await disposeReader(tester);
      });

      testWidgets('a tap that stops a fling, or a double tap starting on one, does not open the menu', (tester) async {
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

        await flingAndCatch();
        await tester.tapAt(const Offset(195, 422));
        await settleReader(tester, ms: 700);
        expect(chromeVisible(tester), isFalse, reason: 'the catch is not the first tap of a double');

        await tapDouble(tester);
        expect(chromeVisible(tester), isTrue, reason: 'a deliberate double tap on the stopped strip');
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
    });
  }
}
