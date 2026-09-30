import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/page_sample.dart';
import 'package:manhwamaniacs/features/reader/engine/resolve_sample.dart';

PageSample s(Color? tint) => PageSample(tint: tint, top: const Color(0xFF000000), bottom: const Color(0xFF000000), lTop: 0, lMid: 0, lBottom: 0, pTop: 0, pMid: 0, pBottom: 0, source: PageSampleSource.decode);

void main() {
  const red = Color(0xFFE53935), blue = Color(0xFF1E88E5), cover = Color(0xFF43A047);
  test('chromatic replaces', () => expect(resolveSample(s(red), s(blue), 0, null).tint, blue));
  test('grey keeps previous', () => expect(resolveSample(s(red), s(null), 1, [cover]).tint, red));
  test('6 greys fall back to cover', () {
    expect(resolveSample(s(red), s(null), 5, [cover]).tint, red);
    expect(resolveSample(s(red), s(null), 6, [cover]).tint, cover);
    expect(resolveSample(s(red), s(null), 6, null).tint, red);
  });
  test('grey run counter', () {
    expect(nextGreyRun(3, s(null)), 4);
    expect(nextGreyRun(3, s(red)), 0);
  });
  test('manifest sample', () {
    final m = PageSample.manifest(red);
    expect(m.source, PageSampleSource.manifest);
    expect(m.pTop, 1.0);
    expect(m.top, red);
  });
}
