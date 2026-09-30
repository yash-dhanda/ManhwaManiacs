import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/shell/sidebar_geometry.dart';

void main() {
  test('expanded by default from 1180 px wide only', () {
    expect(sidebarStartsExpanded(1366), isTrue);
    expect(sidebarStartsExpanded(1180), isTrue);
    expect(sidebarStartsExpanded(1179), isFalse);
    expect(sidebarStartsExpanded(834), isFalse);
  });

  test('edge and content start', () {
    expect(sidebarEdge(hasSidebar: true, expanded: true), 292);
    expect(sidebarEdge(hasSidebar: true, expanded: false), 88);
    expect(sidebarEdge(hasSidebar: false, expanded: true), 0);
    expect(sidebarContentStart(expanded: true), 304);
    expect(sidebarContentStart(expanded: false), 100);
  });

  test('panel is inset 12 and spans the height', () {
    final g = GlassSidebarGeometry.of(const Size(1366, 1024), expanded: true);
    expect(g.panel, const Rect.fromLTWH(12, 12, 280, 1000));
    expect(g.profileCapsule.bottom, g.panel.bottom - 8);
    final c = GlassSidebarGeometry.of(const Size(1366, 1024), expanded: false);
    expect(c.panel.width, 76);
    expect(c.profileCapsule.width, 44);
    expect(c.homeItem.height, 44);
  });
}
