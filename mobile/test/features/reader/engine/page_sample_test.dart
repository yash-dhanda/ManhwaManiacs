import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/page_sample.dart';

Uint8List img(int Function(int x, int y) px, {int w = 64, int h = 64}) {
  final b = Uint8List(w * h * 4);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final c = px(x, y);
      final i = (y * w + x) * 4;
      b[i] = (c >> 16) & 255; b[i + 1] = (c >> 8) & 255; b[i + 2] = c & 255; b[i + 3] = 255;
    }
  }
  return b;
}

void main() {
  test('white', () async {
    final s = await samplePageRgba(img((x, y) => 0xFFFFFF), 64, 64);
    expect(s.tint, isNull);
    for (final v in [s.lTop, s.lMid, s.lBottom, s.pTop, s.pMid, s.pBottom]) { expect(v, closeTo(1, 1e-9)); }
  });
  test('black', () async {
    final s = await samplePageRgba(img((x, y) => 0), 64, 64);
    expect(s.tint, isNull);
    for (final v in [s.lTop, s.lMid, s.lBottom, s.pTop, s.pMid, s.pBottom]) { expect(v, 0); }
  });
  test('top quarter white', () async {
    final s = await samplePageRgba(img((x, y) => y < 16 ? 0xFFFFFF : 0), 64, 64);
    expect(s.lTop, closeTo(1, 1e-9));
    expect(s.lMid, 0);
    expect(s.pTop, closeTo(1, 1e-9));
  });
  test('bubble counts for p95, not l', () async {
    final s = await samplePageRgba(img((x, y) => (x < 8 && y < 8) ? 0xFFFFFF : 0), 64, 64);
    expect(s.lTop, lessThanOrEqualTo(0.07));
    expect(s.pTop, 1.0);
  });
  test('flat red', () async {
    final s = await samplePageRgba(img((x, y) => 0xE53935), 64, 64);
    expect(s.tint, isNotNull);
    expect((s.tint!.r * 255).round(), closeTo(0xE5, 1));
    expect((s.tint!.g * 255).round(), closeTo(0x39, 1));
    expect((s.tint!.b * 255).round(), closeTo(0x35, 1));
  });
  test('grey ramp', () async {
    final s = await samplePageRgba(img((x, y) { final v = x * 4; return (v << 16) | (v << 8) | v; }), 64, 64);
    expect(s.tint, isNull);
  });
  test('equality', () async {
    final a = await samplePageRgba(img((x, y) => 0xFFFFFF), 64, 64);
    final b = await samplePageRgba(img((x, y) => 0xFFFFFF), 64, 64);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });
}
