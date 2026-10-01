/// The highlight band and the sentence lozenge's geometry (glass 8.16.7, B5): a sentence's text boxes merged per line, padded, and
/// morphed between sentences so the band stretches across line breaks instead of cross-fading.
library;

import 'dart:ui' show Rect, TextBox;

const double kBandPadX = 4, kBandPadY = 2, kBandRadius = 6;

/// One rect per line: boxes whose vertical extents overlap are one line. Pads each by [padX] x [padY].
List<Rect> bandRects(List<TextBox> boxes, {double padX = kBandPadX, double padY = kBandPadY}) {
  if (boxes.isEmpty) return const [];
  final sorted = [...boxes]..sort((a, b) {
      final t = a.top.compareTo(b.top);
      return t != 0 ? t : a.left.compareTo(b.left);
    });
  final lines = <Rect>[];
  for (final b in sorted) {
    final r = Rect.fromLTRB(b.left, b.top, b.right, b.bottom);
    if (lines.isNotEmpty) {
      final last = lines.last;
      final overlap = (r.bottom < last.bottom ? r.bottom : last.bottom) - (r.top > last.top ? r.top : last.top);
      final minH = (r.height < last.height ? r.height : last.height);
      if (minH > 0 && overlap > minH * 0.5) {
        lines[lines.length - 1] = last.expandToInclude(r);
        continue;
      }
    }
    lines.add(r);
  }
  return [for (final l in lines) Rect.fromLTRB(l.left - padX, l.top - padY, l.right + padX, l.bottom + padY)];
}

/// The rects at [t] (0 = [prev], 1 = [next]): paired by index; extra rects of [next] grow from the last of [prev], and rects of [prev]
/// with no partner collapse into the last of [next].
List<Rect> morphBands(List<Rect> prev, List<Rect> next, double t) {
  if (next.isEmpty) return const [];
  if (prev.isEmpty) return next;
  final n = next.length > prev.length ? next.length : prev.length;
  final out = <Rect>[];
  for (var i = 0; i < n; i++) {
    final a = i < prev.length ? prev[i] : prev.last;
    final b = i < next.length ? next[i] : next.last;
    out.add(Rect.lerp(a, b, t)!);
  }
  // Rects beyond [next] have collapsed into its last by t = 1: drop them once settled.
  return t >= 1 ? next : out;
}
