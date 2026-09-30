import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/primitives/badge.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart' show GlassSpinner;
import 'package:manhwamaniacs/skins/glass/primitives/tooltip.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The sidebar item that is active for [path] (exactly one). Nested Library items light only themselves; a pinned source's page lights
/// its pinned entry; a sheet route is passed as the path beneath it, so activity follows the route under a sheet (glass 7.16).
String sidebarActiveId(String location, {List<String> pinnedSources = const []}) {
  final u = Uri.tryParse(location);
  var p = u?.path ?? location;
  if (p.length > 1 && p.endsWith('/')) p = p.substring(0, p.length - 1);
  switch (p) {
    case '/':
      return 'home';
    case '/library/recommendations':
      return 'forYou';
    case '/updates':
      return 'updates';
    case '/library':
    case '/library/browse':
      return 'shelf';
    case '/library/collections':
      return 'collections';
    case '/library/history':
      return 'history';
    case '/library/bookmarks':
      return 'bookmarks';
    case '/downloads':
      return 'downloads';
    case '/sources':
      return 'sources';
    case '/library/statistics':
      return 'stats';
    case '/ocr':
      return 'dialogue';
    case '/admin/status':
      return 'status';
    case '/more':
      return 'settings';
  }
  if (p.startsWith('/library/collections/')) return 'collections';
  if (p.startsWith('/library/statistics/')) return 'stats';
  if (p.startsWith('/circle')) return 'circle';
  if (p.startsWith('/settings')) return 'settings';
  if (p.startsWith('/sources/')) {
    final id = Uri.decodeComponent(p.split('/')[2]);
    return pinnedSources.contains(id) ? 'pin:$id' : 'sources';
  }
  return 'home';
}

/// One sidebar row: 48 tall on Flutter, radius 12, icon 20 and `sidebarItem` 14/20 at `wght` 520; hover `fill4`, pressed sinks to
/// 0.98. The active droplet is drawn by the sidebar behind the row; the row only recolours (glyph `iris400`, label `wght` 700).
class GlassSidebarItem extends ConsumerWidget {
  const GlassSidebarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.expanded,
    required this.onTap,
    this.badge,
    this.dot = false,
    this.loading = false,
    this.warn = false,
    this.indent = 0,
    this.trailing,
    this.onDisc = false,
  });
  final Widget Function(Color color) icon;
  final String label;
  final bool active;
  final bool expanded;
  final VoidCallback onTap;
  final int? badge;
  final bool dot;
  final bool loading;
  final bool warn;
  final double indent;
  final Widget? trailing;
  final bool onDisc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = active ? gt.colorIris400 : gt.colorOnGlass;
    final core = GlassPressable(
      material: GlassMaterial.content,
      sink: 0.98,
      shape: const GlassShape.superellipse(12),
      minHit: false,
      onTap: onTap,
      semanticsLabel: [label, if (badge != null && badge! > 0) '$badge new', if (dot) 'new'].join(', '),
      semanticsSelected: active,
      builder: (context, info) {
        Widget glyph = SizedBox(width: 20, height: 20, child: Center(child: icon(color)));
        glyph = onDisc && active ? GlassBacking(size: 28, child: glyph) : glyph;
        Widget badgeW = const SizedBox.shrink();
        if (badge != null && badge! > 0) badgeW = GlassBadge.count(badge!);
        if (dot) badgeW = const GlassBadge.dot();
        if (warn) badgeW = Container(width: 8, height: 8, decoration: BoxDecoration(color: gt.colorWarning, shape: BoxShape.circle));
        if (expanded) {
          return Container(
            height: 48,
            padding: EdgeInsets.only(left: 12 + indent, right: 12),
            decoration: BoxDecoration(color: info.states.hovered && !active ? gt.colorFill4 : const Color(0x00000000), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                glyph,
                const SizedBox(width: 12),
                Expanded(child: GlassText(label, role: gt.typeSidebarItem, wght: active ? 700 : 520, onGlass: true, maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (loading) const SizedBox(width: 10, height: 10, child: GlassSpinner(size: 10)) else badgeW,
                if (trailing != null) trailing!,
              ],
            ),
          );
        }
        return Center(
          child: SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                glyph,
                if (badge != null && badge! > 0 || dot || warn) Positioned(top: -4, right: -4, child: badgeW),
              ],
            ),
          ),
        );
      },
    );
    return expanded
        ? SizedBox(height: 48, child: core)
        : GlassTooltip(message: label, level: GlassTooltipLevel.bar, above: false, child: SizedBox(height: 48, child: core));
  }
}
