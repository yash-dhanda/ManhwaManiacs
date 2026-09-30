import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs_more.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/stack/route_snapshot.dart';

/// The flat back menu (glass 7.37): under Reduce Motion or a screen reader the levels open as a menu from the back button, one
/// row per level newest first (a 24 px leading visual, the title, the depth in `mono`), the tab root last as "{Tab} home". With
/// one level nothing opens. [levels] is the tab's stack oldest first, the root first and the current screen last.
Future<void> showGlassBackMenu(
  BuildContext context, {
  required Rect anchor,
  required List<GlassRouteSnapshot> levels,
  required String tabName,
  required void Function(GlassRouteSnapshot level) onPick,
  Widget Function(GlassRouteSnapshot level)? leadingFor,
}) {
  if (levels.length <= 1) return Future.value();
  final rows = levels.sublist(0, levels.length - 1).reversed.toList();
  Widget leading(GlassRouteSnapshot s) => leadingFor?.call(s) ?? Icon(GlassGlyph28.stack.regular, size: 20);
  return showGlassMenu(
    context,
    anchor: anchor,
    title: 'Back',
    entries: [
      for (var i = 0; i < rows.length; i++)
        GlassMenuEntry(
          label: i == rows.length - 1 ? '$tabName home' : rows[i].title,
          leading: leading(rows[i]),
          trailingMono: i == rows.length - 1 ? null : '${rows[i].depth}',
          onSelected: () => onPick(rows[i]),
        ),
    ],
  );
}

/// The rows [showGlassBackMenu] shows, for tests: newest first, the root last as "{Tab} home".
List<String> backMenuLabels(List<GlassRouteSnapshot> levels, String tabName) {
  if (levels.length <= 1) return const [];
  final rows = levels.sublist(0, levels.length - 1).reversed.toList();
  return [for (var i = 0; i < rows.length; i++) i == rows.length - 1 ? '$tabName home' : rows[i].title];
}
