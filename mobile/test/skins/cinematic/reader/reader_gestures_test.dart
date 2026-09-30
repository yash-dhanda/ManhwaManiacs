import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_gestures.dart';

void main() {
  test('edge zones are max(24, the system inset)', () {
    expect(swipeStartAllowed(23, 390), isFalse);
    expect(swipeStartAllowed(24, 390), isTrue);
    expect(swipeStartAllowed(366, 390), isTrue);
    expect(swipeStartAllowed(367, 390), isFalse);
    expect(swipeStartAllowed(30, 390, leftInset: 40), isFalse);
    expect(swipeStartAllowed(41, 390, leftInset: 40), isTrue);
    expect(swipeStartAllowed(360, 390, rightInset: 40), isFalse);
  });

  test('30 degrees from horizontal', () {
    expect(withinHorizontal(const Offset(100, 57)), isTrue);
    expect(withinHorizontal(const Offset(100, 58)), isFalse);
    expect(withinHorizontal(const Offset(-100, -40)), isTrue);
    expect(withinHorizontal(const Offset(0, 100)), isFalse);
  });

  test('commit at 72 px or 600 px/s, only at zoom 1.0 or less', () {
    SwipeVerdict v(double dx, double vx, {double zoom = 1, bool rtl = false}) => classifySwipe(dx: dx, vx: vx, zoom: zoom, rtl: rtl);
    expect(v(-71, -100), SwipeVerdict.none);
    expect(v(-72, 0), SwipeVerdict.toward);
    expect(v(-20, -600), SwipeVerdict.toward);
    expect(v(80, 0), SwipeVerdict.away);
    expect(v(-100, -900, zoom: 1.1), SwipeVerdict.none);
    expect(v(-100, -900, zoom: 0.5), SwipeVerdict.toward);
    expect(v(-100, 0, rtl: true), SwipeVerdict.away);
    expect(classifySwipe(dx: -100, vx: 0, zoom: 1, rtl: false, enabled: false), SwipeVerdict.none);
  });

  testWidgets('the recognizer rejects edge starts and steep drags, accepts a horizontal one', (tester) async {
    var swipes = 0;
    var vertical = 0.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            ListView(children: [for (var i = 0; i < 40; i++) SizedBox(height: 80, child: Text('row $i'))]),
            Positioned.fill(
              child: RawGestureDetector(
                behavior: HitTestBehavior.translucent,
                gestures: {
                  ChapterSwipeRecognizer: GestureRecognizerFactoryWithHandlers<ChapterSwipeRecognizer>(
                    () => ChapterSwipeRecognizer(screenWidth: 800),
                    (r) => r.onEnd = (d) => swipes++,
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
    await tester.dragFrom(const Offset(400, 300), const Offset(-150, 0));
    await tester.pump();
    expect(swipes, 1);
    await tester.dragFrom(const Offset(10, 300), const Offset(-150, 0));
    await tester.pump();
    expect(swipes, 1, reason: 'started inside the edge zone');
    await tester.dragFrom(const Offset(400, 500), const Offset(40, -200));
    await tester.pump();
    expect(swipes, 1, reason: 'a steep drag stays with the scroll');
    vertical = tester.state<ScrollableState>(find.byType(Scrollable).first).position.pixels;
    expect(vertical, greaterThan(50));
  });
}
