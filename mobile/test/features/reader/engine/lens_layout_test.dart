import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/lens_layout.dart';

void main() {
  final pages = [const Rect.fromLTWH(0, -500, 390, 600), const Rect.fromLTWH(0, 100, 390, 600), const Rect.fromLTWH(0, 700, 390, 600), const Rect.fromLTWH(0, 1300, 390, 600)];
  const clip = LensClip(Rect.fromLTWH(100, 200, 120, 120), 24);
  test('scale 1 lines up relative to clip; outside pages dropped', () {
    final l = lensLayout(pages, clip, const LensTransform(1, Offset(160, 260)));
    expect(l.map((p) => p.index), [1]);
    expect(l.single.rect, pages[1].shift(const Offset(-100, -200)));
  });
  test('1.12 fixes the origin', () {
    const t = LensTransform(1.12, Offset(160, 260));
    expect(lensMap(const Offset(160, 260), t), const Offset(160, 260));
    expect(lensMap(const Offset(260, 260), t).dx, closeTo(160 + 100 * 1.12, 1e-9));
  });
}
