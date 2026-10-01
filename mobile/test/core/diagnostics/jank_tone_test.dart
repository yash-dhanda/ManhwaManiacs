import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/diagnostics/jank_tone.dart';

void main() {
  test('jank tone boundaries', () {
    expect(jankTone(4.99), JankTone.good);
    expect(jankTone(5), JankTone.warn);
    expect(jankTone(14.99), JankTone.warn);
    expect(jankTone(15), JankTone.bad);
  });
}
