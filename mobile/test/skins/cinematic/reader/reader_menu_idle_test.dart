import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/ruler.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/running_head.dart';

import '../../../screenshots/support/shot_network.dart';
import 'reader_test_support.dart';

// The owner's rule: the reading menu a double tap opens stays 5 s untouched, then hides. Touching it
// (a control, the chapter slider, a sheet from it) starts the 5 s again; a drag or a sheet in
// progress never runs out; scrolling hides it at once; a screen reader or reduce motion keeps it up.
// Both entry points: the library reader and the source reader.

const _centre = Offset(195, 422);

/// Waits out the menu shown at open, then opens it with a double tap; the clock starts on return.
Future<void> _open(WidgetTester tester) async {
  await settleReader(tester, ms: 5600);
  expect(chromeVisible(tester), isFalse, reason: 'idle-hidden after open');
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 350)));
  await tester.tapAt(_centre);
  await tester.pump(const Duration(milliseconds: 60));
  await tester.tapAt(_centre);
  await tester.pump();
  expect(chromeVisible(tester), isTrue, reason: 'a double tap opens');
}

/// Pumps [ms] in 100 ms steps from now.
Future<void> _after(WidgetTester tester, int ms) async {
  for (var t = 0; t < ms; t += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _expectIdlesFromNow(WidgetTester tester, String why) async {
  await _after(tester, 4900);
  expect(chromeVisible(tester), isTrue, reason: '$why: up at 4.9 s');
  await _after(tester, 200);
  expect(chromeVisible(tester), isFalse, reason: '$why: hidden at 5.1 s');
}

void main() {
  setUpAll(setUpShotCoverCache);

  for (final origin in [ReaderRigOrigin.manifest, ReaderRigOrigin.source]) {
    group(origin.name, () {
      testWidgets('opened, it is up at 4.9 s and hidden at 5.1 s', (tester) async {
        await pumpReader(tester, origin: origin, platform: TargetPlatform.iOS);
        await _open(tester);
        await _expectIdlesFromNow(tester, 'untouched');
        await disposeReader(tester);
      });

      testWidgets('tapping a control restarts the 5 s', (tester) async {
        await pumpReader(tester, origin: origin, platform: TargetPlatform.iOS);
        await _open(tester);
        await _after(tester, 4000);
        await tester.tapAt(tester.getCenter(find.byType(ReaderRuler)));
        await tester.pump();
        await _expectIdlesFromNow(tester, 'after the tap');
        await disposeReader(tester);
      });

      testWidgets('scrolling the page hides it at once', (tester) async {
        await pumpReader(tester, origin: origin, platform: TargetPlatform.iOS);
        await _open(tester);
        // The chapter's first 800 ms (wall clock) never hide by scrolling.
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 900)));
        await tester.dragFrom(const Offset(195, 600), const Offset(0, -200));
        await tester.pump(const Duration(milliseconds: 100));
        expect(chromeVisible(tester), isFalse);
        await disposeReader(tester);
      });

      testWidgets('dragging the chapter slider never runs out; letting go restarts the 5 s', (tester) async {
        await pumpReader(tester, origin: origin, platform: TargetPlatform.iOS);
        await _open(tester);
        final g = await tester.startGesture(tester.getCenter(find.byType(ReaderRuler)));
        await tester.pump();
        await g.moveBy(const Offset(30, 0));
        await tester.pump();
        await _after(tester, 8000);
        expect(chromeVisible(tester), isTrue, reason: 'held by the drag');
        await g.up();
        await tester.pump();
        await _expectIdlesFromNow(tester, 'after the drag');
        await disposeReader(tester);
      });

      testWidgets('a sheet opened from it holds it; closing the sheet restarts the 5 s', (tester) async {
        await pumpReader(tester, origin: origin, platform: TargetPlatform.iOS);
        await _open(tester);
        await tester.tap(find.descendant(of: find.byType(ReaderRunningHead), matching: find.text('CH 2')));
        await _after(tester, 900);
        final sheet = find.text('CONTENTS', findRichText: true);
        expect(sheet, findsWidgets);
        await _after(tester, 8000);
        expect(chromeVisible(tester), isTrue, reason: 'held by the sheet');
        Navigator.of(tester.element(sheet.first)).pop();
        await tester.pump();
        await _after(tester, 600);
        expect(sheet, findsNothing);
        // The sheet's close is seen within 250 ms; the full 5 s runs from there.
        await _after(tester, 4300);
        expect(chromeVisible(tester), isTrue, reason: 'within 5 s of the close');
        await _after(tester, 1000);
        expect(chromeVisible(tester), isFalse, reason: 'idle after the close');
        await disposeReader(tester);
      });

      testWidgets('a screen reader keeps it up', (tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(accessibleNavigation: true);
        addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
        await pumpReader(tester, origin: origin, platform: TargetPlatform.iOS);
        await _after(tester, 12000);
        expect(chromeVisible(tester), isTrue);
        await disposeReader(tester);
      });

      testWidgets('reduce motion keeps it up', (tester) async {
        await pumpReader(tester, origin: origin, platform: TargetPlatform.iOS, reduced: true);
        await _after(tester, 12000);
        expect(chromeVisible(tester), isTrue);
        await disposeReader(tester);
      });
    });
  }
}
