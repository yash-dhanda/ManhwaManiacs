import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/duotone.dart';

// Applies the 4x5 matrix to an sRGB colour, as ColorFilter.matrix does in sRGB value space.
List<double> _apply(List<double> m, Color c) {
  final v = [c.r * 255, c.g * 255, c.b * 255, c.a * 255, 1.0];
  return [for (var r = 0; r < 3; r++) [for (var i = 0; i < 5; i++) m[r * 5 + i] * (i == 4 ? 255 : v[i])].reduce((a, b) => a + b)];
}

void main() {
  const duo = Color(0xFFB8B2A4);
  test('black stays black, white becomes the duo colour, mid grey is half of it', () {
    final m = duotoneMatrix(duo);
    expect(m, hasLength(20));
    expect(_apply(m, const Color(0xFF000000)), everyElement(0));
    final w = _apply(m, const Color(0xFFFFFFFF));
    expect(w[0], closeTo(duo.r * 255, 0.01));
    expect(w[1], closeTo(duo.g * 255, 0.01));
    expect(w[2], closeTo(duo.b * 255, 0.01));
    final g = _apply(m, const Color(0xFF808080));
    expect(g[0] / (duo.r * 255), closeTo(128 / 255, 0.001));
    expect(g[1] / (duo.g * 255), closeTo(128 / 255, 0.001));
    expect(g[2] / (duo.b * 255), closeTo(128 / 255, 0.001));
  });

  test('the alpha row leaves alpha alone and matrices are cached per colour', () {
    final m = duotoneMatrix(duo);
    expect(m.sublist(15), [0, 0, 0, 1, 0]);
    expect(identical(duotoneMatrix(duo), m), isTrue);
  });
}
