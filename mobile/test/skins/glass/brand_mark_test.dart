import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/brand_mark.g.dart';

Rect _extent(List<Offset> pts, double w) {
  final r = Rect.fromPoints(pts.first, pts.first);
  var box = r;
  for (final p in pts) {
    box = box.expandToInclude(Rect.fromPoints(p, p));
  }
  return box.inflate(w / 2);
}

void main() {
  const c = GlassMarkGeometry.column;
  bool inside(Rect r) =>
      r.left >= c.left - 1 && r.right <= c.right + 1 && r.top >= c.top - 1 && r.bottom <= c.bottom + 1;

  test('stroked M extents lie inside the column box', () {
    expect(inside(_extent(GlassMarkGeometry.topM, GlassMarkGeometry.stroke)), isTrue);
    expect(inside(_extent(GlassMarkGeometry.bottomM, GlassMarkGeometry.stroke)), isTrue);
    final u = _extent(GlassMarkGeometry.topM, GlassMarkGeometry.stroke)
        .expandToInclude(_extent(GlassMarkGeometry.bottomM, GlassMarkGeometry.stroke));
    expect(u, c);
  });

  test('gutter bar spans the column width and bows 9 units', () {
    final m = GlassMarkGeometry.bar().computeMetrics().first;
    final b = GlassMarkGeometry.bar().getBounds();
    expect(b.left - GlassMarkGeometry.barStroke / 2, closeTo(c.left, 1));
    expect(b.right + GlassMarkGeometry.barStroke / 2, closeTo(c.right, 1));
    final mid = m.getTangentForOffset(m.length / 2)!.position;
    expect(mid.dy - 512, closeTo(9, 0.6));
  });
}
