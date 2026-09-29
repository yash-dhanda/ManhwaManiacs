import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/lightbox_math.dart';

void main() {
  test('the art never exceeds 1.5x its natural pixels', () {
    expect(lightboxFitSize(const Size(720, 1080), const Size(2000, 3000)), const Size(1080, 1620));
    final f = lightboxFitSize(const Size(720, 1080), const Size(390, 844));
    expect(f.width, closeTo(390, 0.01));
    expect(f.height, closeTo(585, 0.01));
    expect(lightboxFitSize(Size.zero, const Size(390, 844)), Size.zero);
  });
  test('barrier opacity follows 0.96 * (1 - dy / 400)', () {
    expect(lightboxBarrierOpacity(0), 0.96);
    expect(lightboxBarrierOpacity(200), closeTo(0.48, 1e-9));
    expect(lightboxBarrierOpacity(500), 0);
  });
  test('dismiss past 120 px or 800 px/s', () {
    expect(lightboxShouldDismiss(119, 0), isFalse);
    expect(lightboxShouldDismiss(121, 0), isTrue);
    expect(lightboxShouldDismiss(10, 799), isFalse);
    expect(lightboxShouldDismiss(10, 801), isTrue);
  });
  test('the chip reads 250%', () => expect(lightboxZoomLabel(2.5), '250%'));
}
