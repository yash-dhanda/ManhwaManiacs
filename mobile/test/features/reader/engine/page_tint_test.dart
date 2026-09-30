import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/page_tint.dart';

void main() {
  test('hls matches colorsys on primaries and greys', () {
    expect(hls(128, 128, 128).s, 0);
    final r = hls(255, 0, 0);
    expect(r.l, 0.5);
    expect(r.s, 1.0);
  });

  test('TintTracker: 5 greys keep, the 6th goes to cover, chromatic returns', () {
    final t = TintTracker();
    expect(t.feed('#FF0000'), const PageTintSource.page('#FF0000'));
    for (var i = 0; i < 5; i++) {
      expect(t.feed(null), const PageTintSource.page('#FF0000'));
    }
    expect(t.feed(null), PageTintSource.cover);
    expect(t.feed(null), PageTintSource.cover);
    expect(t.feed('#00FF00'), const PageTintSource.page('#00FF00'));
  });
}
