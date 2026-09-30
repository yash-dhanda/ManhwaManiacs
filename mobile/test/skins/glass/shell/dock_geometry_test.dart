import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/shell/dock_geometry.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';

void main() {
  const size = Size(390, 844);
  const pad = EdgeInsets.only(bottom: 34);
  final g = GlassDockGeometry.of(size, pad);

  test('dock is 64 tall, 21 from the left and bottom plus safe-bottom', () {
    expect(g.dock.height, 64);
    expect(g.dock.left, 21);
    expect(g.dock.bottom, 844 - 21 - 34);
  });

  test('orb is 50, 21 from the right edge, 8 from the dock', () {
    expect(g.orb.size, const Size(50, 50));
    expect(g.orb.right, 390 - 21);
    expect(g.orb.left - g.dock.right, 8);
    expect(g.orb.bottom, g.dock.bottom);
  });

  test('accessory is 48 tall, 8 above the dock, spanning dock plus orb', () {
    expect(g.accessory.height, 48);
    expect(g.dock.top - g.accessory.bottom, 8);
    expect(g.accessory.left, 21);
    expect(g.accessory.right, g.orb.right);
  });

  test('minimised capsule is 50 tall on the same bottom line', () {
    expect(g.minimised.height, 50);
    expect(g.minimised.bottom, g.dock.bottom);
  });

  test('tabs are four equal cells in order', () {
    final r = [for (final t in GlassTab.values) g.tabRect(t)];
    for (final c in r) {
      expect(c.width, closeTo(g.dock.width / 4, 1e-9));
    }
    expect(r[0].left, g.dock.left);
    expect(r[3].right, closeTo(g.dock.right, 1e-9));
    expect(g.dropletRect(GlassTab.library).size, const Size(56, 52));
  });
}
