import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/swipe_math.dart';

void main() {
  test('pill scale grows from 0.6 to 1.0 over one slot', () {
    expect(pillScale(0), 0.6);
    expect(pillScale(44), closeTo(0.8, 1e-9));
    expect(pillScale(88), 1);
    expect(pillScale(200), 1);
  });

  test('the tray opens past half its width, projected', () {
    expect(opensTray(-100, 0, 2), isTrue); // tray 176, half 88
    expect(opensTray(-80, 0, 2), isFalse);
    expect(opensTray(-40, -800, 2), isTrue); // a fling projects past it
    expect(opensTray(-100, 900, 2), isFalse); // thrown back closed
    expect(trayWidth(3), 264);
  });

  test('the full swipe line is 60 % of the row width, projected', () {
    expect(fullSwipeCrossed(-240, 0, 390), isTrue);
    expect(fullSwipeCrossed(-230, 0, 390), isFalse);
    expect(fullSwipeCrossed(-100, -200, 390), isFalse);
    expect(fullSwipeCrossed(-200, -1000, 390), isTrue);
    expect(fullSwipeCrossed(240, 0, 390), isTrue);
  });

  test('the leading 24 px belongs to the back swipe', () {
    expect(startsInBackStrip(10), isTrue);
    expect(startsInBackStrip(23.9), isTrue);
    expect(startsInBackStrip(24), isFalse);
    expect(startsInBackStrip(130, screenLeft: 120), isTrue);
  });
}
