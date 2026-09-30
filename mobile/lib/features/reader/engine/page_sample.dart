import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:manhwamaniacs/core/color/oklch.dart';
import 'package:material_color_utilities/material_color_utilities.dart' show QuantizerCelebi;

enum PageSampleSource { manifest, decode }

/// What the Glass chrome reads off the page under the reading line (glass 2.1.8 step 3).
@immutable
class PageSample {
  const PageSample({
    required this.tint,
    required this.top,
    required this.bottom,
    required this.lTop,
    required this.lMid,
    required this.lBottom,
    required this.pTop,
    required this.pMid,
    required this.pBottom,
    required this.source,
  });

  /// A manifest `pages[].tint` painted before the decode lands: luminance unknown (1.0).
  PageSample.manifest(Color t)
      : tint = t,
        top = t,
        bottom = t,
        lTop = 1,
        lMid = 1,
        lBottom = 1,
        pTop = 1,
        pMid = 1,
        pBottom = 1,
        source = PageSampleSource.manifest;

  final Color? tint;
  final Color top, bottom;
  final double lTop, lMid, lBottom;
  final double pTop, pMid, pBottom;
  final PageSampleSource source;

  PageSample withTint(Color? t) => PageSample(
        tint: t, top: top, bottom: bottom, lTop: lTop, lMid: lMid, lBottom: lBottom,
        pTop: pTop, pMid: pMid, pBottom: pBottom, source: source,);

  @override
  bool operator ==(Object o) =>
      o is PageSample &&
      o.tint == tint && o.top == top && o.bottom == bottom &&
      o.lTop == lTop && o.lMid == lMid && o.lBottom == lBottom &&
      o.pTop == pTop && o.pMid == pMid && o.pBottom == pBottom && o.source == source;

  @override
  int get hashCode => Object.hash(tint, top, bottom, lTop, lMid, lBottom, pTop, pMid, pBottom, source);

  @override
  String toString() => 'PageSample(tint=$tint pTop=$pTop lTop=$lTop ${source.name})';
}

final List<double> _lin = List<double>.generate(256, (i) {
  final c = i / 255;
  return c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
});

double _lum(int r, int g, int b) => 0.2126 * _lin[r] + 0.7152 * _lin[g] + 0.0722 * _lin[b];

/// Mean and nearest-rank 95th percentile of the luminances in [v].
(double, double) _stats(List<double> v) {
  if (v.isEmpty) return (0, 0);
  final s = v.fold<double>(0, (a, b) => a + b) / v.length;
  final sorted = List<double>.of(v)..sort();
  return (s, sorted[(0.95 * v.length).ceil() - 1]);
}

Color? _pickTint(Map<int, int> colorToCount) {
  final entries = colorToCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  for (final e in entries) {
    final c = Color(e.key | 0xFF000000);
    final o = oklchFromColor(c);
    if (o.l >= 0.18 && o.c >= 0.035) return c;
  }
  return null;
}

/// The sample of a decoded page (RGBA, row-major). Pure: runs inside `compute()`.
Future<PageSample> samplePageRgba(Uint8List rgba, int width, int height) async {
  final q = height ~/ 4;
  final bands = [<double>[], <double>[], <double>[]];
  final mean = List<List<double>>.generate(2, (_) => [0, 0, 0]);
  final counts = [0, 0];
  final argb = <int>[];
  for (var y = 0; y < height; y++) {
    final band = y < q ? 0 : (y < height - q ? 1 : 2);
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      final r = rgba[i], g = rgba[i + 1], b = rgba[i + 2];
      bands[band].add(_lum(r, g, b));
      argb.add(0xFF000000 | (r << 16) | (g << 8) | b);
      if (band != 1) {
        final k = band == 0 ? 0 : 1;
        mean[k][0] += r;
        mean[k][1] += g;
        mean[k][2] += b;
        counts[k]++;
      }
    }
  }
  Color avg(int k) => counts[k] == 0
      ? const Color(0xFF000000)
      : Color.fromARGB(255, (mean[k][0] / counts[k]).round(), (mean[k][1] / counts[k]).round(), (mean[k][2] / counts[k]).round());
  final t = _stats(bands[0]), m = _stats(bands[1]), b = _stats(bands[2]);
  final res = await QuantizerCelebi().quantize(argb, 16);
  return PageSample(
    tint: _pickTint(res.colorToCount),
    top: avg(0),
    bottom: avg(1),
    lTop: t.$1, lMid: m.$1, lBottom: b.$1,
    pTop: t.$2, pMid: m.$2, pBottom: b.$2,
    source: PageSampleSource.decode,
  );
}

Future<PageSample> _run((Uint8List, int, int) a) => samplePageRgba(a.$1, a.$2, a.$3);

/// [samplePageRgba] off the main isolate.
Future<PageSample> samplePageInIsolate(Uint8List rgba, int width, int height) =>
    compute(_run, (rgba, width, height));
