import 'dart:ui';

/// `sidebarWidth` 280 / 76, `sidebarInset` 12, `sidebarRadius` 26 (glass 2.2).
const double kSidebarExpanded = 280;
const double kSidebarCollapsed = 76;
const double kSidebarInset = 12;
const double kSidebarRadius = 26;

/// The desktop frame starts expanded from 1180 px wide; below that (and on the tablet frame) it starts collapsed.
bool sidebarStartsExpanded(double width) => width >= 1180;

/// What `glassSidebarEdgeProvider` reads: the content column's leading edge (292 / 88, 0 without a sidebar).
double sidebarEdge({required bool hasSidebar, required bool expanded}) => !hasSidebar ? 0 : (expanded ? kSidebarExpanded : kSidebarCollapsed) + kSidebarInset;

/// Where content starts beside the sidebar (304 expanded, 100 collapsed).
double sidebarContentStart({required bool expanded}) => (expanded ? kSidebarExpanded : kSidebarCollapsed) + kSidebarInset * 2;

/// Resting rects for `mobile/30`'s flights.
class GlassSidebarGeometry {
  const GlassSidebarGeometry._({required this.panel, required this.profileCapsule, required this.homeItem});
  final Rect panel;
  final Rect profileCapsule;
  final Rect homeItem;

  factory GlassSidebarGeometry.of(Size window, {required bool expanded}) {
    final w = expanded ? kSidebarExpanded : kSidebarCollapsed;
    final panel = Rect.fromLTWH(kSidebarInset, kSidebarInset, w, window.height - kSidebarInset * 2);
    const pad = 8.0;
    final capsule = expanded
        ? Rect.fromLTWH(panel.left + pad, panel.bottom - pad - 48, w - pad * 2, 48)
        : Rect.fromLTWH(panel.left + (w - 44) / 2, panel.bottom - pad - 44, 44, 44);
    // Wordmark row 44, search 44, gaps 8: Home is the first item.
    final top = panel.top + pad + 44 + 8 + 44 + 8;
    final home = expanded ? Rect.fromLTWH(panel.left + pad, top, w - pad * 2, 48) : Rect.fromLTWH(panel.left + (w - 44) / 2, top, 44, 44);
    return GlassSidebarGeometry._(panel: panel, profileCapsule: capsule, homeItem: home);
  }
}
