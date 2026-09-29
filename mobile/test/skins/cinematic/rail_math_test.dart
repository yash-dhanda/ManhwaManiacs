import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rail_math.dart';

void main() {
  test('visible posters', () {
    expect(railVisible(width: 390), 3.2);
    expect(railVisible(width: 390, textScale: 1.3), 2.3);
    expect(railVisible(width: 390, textScale: 2.0), 2.3);
    expect(railVisible(width: 820), 5.2);
    expect(railVisible(width: 1180, textScale: 2.0), 5.2);
  });

  test('gap', () {
    expect(railGap(390), 8);
    expect(railGap(599), 8);
    expect(railGap(600), 12);
  });

  test('poster width for 390, 820 and 1180 px content, and the 2.3 case', () {
    expect(railPosterWidth(contentWidth: 390, visible: 3.2, gap: 8), closeTo((390 - 3 * 8) / 3.2, 1e-9));
    expect(railPosterWidth(contentWidth: 820, visible: 5.2, gap: 12), closeTo((820 - 5 * 12) / 5.2, 1e-9));
    expect(railPosterWidth(contentWidth: 1180, visible: 5.2, gap: 12), closeTo((1180 - 5 * 12) / 5.2, 1e-9));
    expect(railPosterWidth(contentWidth: 358, visible: 2.3, gap: 8), closeTo((358 - 2 * 8) / 2.3, 1e-9));
    // The last visible poster is the partial one: the row is full width.
    final w = railPosterWidth(contentWidth: 358, visible: 3.2, gap: 8);
    expect(3.2 * w + 3 * 8, closeTo(358, 1e-9));
  });

  test('snap and reveal offsets', () {
    expect(railSnapOffset(offset: 130, posterWidth: 100, gap: 8, maxExtent: 1000), 108);
    expect(railSnapOffset(offset: 40, posterWidth: 100, gap: 8, maxExtent: 1000), 0);
    expect(railSnapOffset(offset: 990, posterWidth: 100, gap: 8, maxExtent: 300), 300);
    expect(railRevealOffset(index: 5, offset: 0, viewport: 358, posterWidth: 100, gap: 8, maxExtent: 2000), 5 * 108 + 100 - 358);
    expect(railRevealOffset(index: 1, offset: 300, viewport: 358, posterWidth: 100, gap: 8, maxExtent: 2000), 108);
    expect(railRevealOffset(index: 2, offset: 100, viewport: 358, posterWidth: 100, gap: 8, maxExtent: 2000), 100);
  });
}
