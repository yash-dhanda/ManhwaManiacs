import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/brightness_band_math.dart';

void main() {
  test('band ranges at 390 px: iOS 24-70.8, Android 0-46.8', () {
    final ios = brightnessBandRange(390, TargetPlatform.iOS);
    expect(ios.start, 24);
    expect(ios.end, closeTo(70.8, 1e-9));
    final android = brightnessBandRange(390, TargetPlatform.android);
    expect(android.start, 0);
    expect(android.end, closeTo(46.8, 1e-9));
    expect(inBrightnessBand(10, 390, TargetPlatform.iOS), isFalse, reason: 'the 20 px back strip stays the system');
    expect(inBrightnessBand(10, 390, TargetPlatform.android), isTrue);
    expect(inBrightnessBand(80, 390, TargetPlatform.iOS), isFalse, reason: 'x 80 scrolls the strip');
    expect(inBrightnessBand(80, 390, TargetPlatform.android), isFalse);
  });

  test('activation after 10 px with |dy| > 2 |dx|', () {
    expect(bandActivates(0, 9), isNull, reason: '9 px is undecided');
    expect(bandActivates(0, 11), isTrue);
    expect(bandActivates(0, -11), isTrue);
    expect(bandActivates(8, 8), isFalse, reason: 'a diagonal belongs to the strip');
    expect(bandActivates(5, 11), isTrue);
    expect(bandActivates(6, 11), isFalse);
  });

  test('20 to 100 % over 60 % of the height', () {
    expect(bandBrightness(0.2, -0.6 * 844, 844), closeTo(1.0, 1e-9));
    expect(bandBrightness(1.0, 0.6 * 844, 844), closeTo(0.2, 1e-9));
    expect(bandBrightness(0.6, -0.3 * 844, 844), closeTo(1.0, 1e-9));
    expect(bandBrightness(0.6, 2000, 844), 0.2);
  });
}
