import 'dart:typed_data';
import 'dart:ui' show Rect;

enum PanelDirection { ltr, rtl }

/// A panel in px at the analysis width, or in page fractions after [toPageFractions].
typedef PanelRect = Rect;

/// L = (0.2126 R + 0.7152 G + 0.0722 B) / 255 on 8-bit values, stored 0-255 (rounded).
Uint8List luminanceOf(Uint8List rgba) {
  final out = Uint8List(rgba.length ~/ 4);
  for (var i = 0; i < out.length; i++) {
    out[i] = (0.2126 * rgba[i * 4] + 0.7152 * rgba[i * 4 + 1] + 0.0722 * rgba[i * 4 + 2]).round();
  }
  return out;
}

const _minGutter = 12;
const _minSide = 48;

// L > 0.92 -> lum > 234.6 ; L < 0.06 -> lum < 15.3 (compared on the 0-255 value).
bool _light(int v) => v / 255 > 0.92;
bool _dark(int v) => v / 255 < 0.06;

bool _isGutter(int count, int lights, int darks) => lights >= count * 0.98 || darks >= count * 0.98;

/// Content runs (start, endExclusive) along an axis, gutters being runs of >= 12 gutter lines.
List<(int, int)> _runs(List<bool> gutterLine) {
  final n = gutterLine.length;
  final isGut = List<bool>.filled(n, false);
  var i = 0;
  while (i < n) {
    if (!gutterLine[i]) {
      i++;
      continue;
    }
    var j = i;
    while (j < n && gutterLine[j]) {
      j++;
    }
    if (j - i >= _minGutter) {
      for (var k = i; k < j; k++) {
        isGut[k] = true;
      }
    }
    i = j;
  }
  final runs = <(int, int)>[];
  i = 0;
  while (i < n) {
    if (isGut[i]) {
      i++;
      continue;
    }
    var j = i;
    while (j < n && !isGut[j]) {
      j++;
    }
    runs.add((i, j));
    i = j;
  }
  return runs;
}

/// Panel detection of cinematic 9.4.3 on a luminance plane.
List<PanelRect> detectPanels(Uint8List lum, int width, int height, PanelDirection direction) {
  final rowG = List<bool>.generate(height, (y) {
    var l = 0, d = 0;
    for (var x = 0; x < width; x++) {
      final v = lum[y * width + x];
      if (_light(v)) l++;
      if (_dark(v)) d++;
    }
    return _isGutter(width, l, d);
  });
  final strip = height / width > 2;
  final out = <PanelRect>[];
  for (final (y0, y1) in _runs(rowG)) {
    final bandH = y1 - y0;
    if (strip) {
      if (width >= _minSide && bandH >= _minSide) out.add(Rect.fromLTWH(0, y0.toDouble(), width.toDouble(), bandH.toDouble()));
      continue;
    }
    final colG = List<bool>.generate(width, (x) {
      var l = 0, d = 0;
      for (var y = y0; y < y1; y++) {
        final v = lum[y * width + x];
        if (_light(v)) l++;
        if (_dark(v)) d++;
      }
      return _isGutter(bandH, l, d);
    });
    final cols = _runs(colG);
    final row = <PanelRect>[];
    for (final (x0, x1) in cols) {
      if (x1 - x0 >= _minSide && bandH >= _minSide) {
        row.add(Rect.fromLTWH(x0.toDouble(), y0.toDouble(), (x1 - x0).toDouble(), bandH.toDouble()));
      }
    }
    if (direction == PanelDirection.rtl) row.sort((a, b) => b.left.compareTo(a.left));
    out.addAll(row);
  }
  return out;
}

/// Panel rects as fractions of the page, the manifest's shape.
List<PanelRect> toPageFractions(List<PanelRect> rects, int width, int height) => [
      for (final r in rects) Rect.fromLTWH(r.left / width, r.top / height, r.width / width, r.height / height),
    ];
