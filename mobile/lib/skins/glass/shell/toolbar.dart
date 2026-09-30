import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/status_capsule.dart';
import 'package:manhwamaniacs/skins/glass/shell/bar_icon.dart';
import 'package:manhwamaniacs/skins/glass/shell/glass_back_button.dart';
import 'package:manhwamaniacs/skins/glass/shell/glass_scaffold.dart';
import 'package:manhwamaniacs/skins/glass/shell/large_title.dart';
import 'package:manhwamaniacs/skins/glass/shell/nav_row.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The toolbar row of tablet and desktop frames (glass 7.32): 48 tall, 12 px from the top inside the content column. Leading: a plain
/// `caret-left` on pushed screens, then the page title in `title2` once the large title has scrolled away, and the status capsule
/// 12 px after it. Trailing: one glass group of the screen's actions that always ends with the keyboard-shortcuts button.
class GlassToolbar extends ConsumerStatefulWidget {
  const GlassToolbar({
    super.key,
    required this.title,
    required this.leading,
    required this.actions,
    required this.overflow,
    required this.offline,
    required this.offset,
    required this.hasLargeTitle,
    this.currentKey,
  });
  final String title;
  final GlassLeading leading;
  final List<GlassBarAction> actions;
  final List<GlassMenuEntry> overflow;
  final bool offline;
  final ValueListenable<double> offset;
  final bool hasLargeTitle;
  final String? currentKey;

  @override
  ConsumerState<GlassToolbar> createState() => _GlassToolbarState();
}

class _GlassToolbarState extends ConsumerState<GlassToolbar> {
  bool _showTitle = false;

  @override
  void initState() {
    super.initState();
    widget.offset.addListener(_onScroll);
    _showTitle = !widget.hasLargeTitle ||
        widget.offset.value >= GlassLargeTitle.capsuleAt;
  }

  @override
  void dispose() {
    widget.offset.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final s = !widget.hasLargeTitle ||
        widget.offset.value >= GlassLargeTitle.capsuleAt;
    if (s != _showTitle) setState(() => _showTitle = s);
  }

  @override
  Widget build(BuildContext context) {
    final shortcuts = GlassBarAction(
      id: 'shortcuts',
      label: 'Keyboard shortcuts',
      glyph: ShellGlyph.keyboard,
      onPress: () => context.go(_withSheet(context, 'shortcuts')),
    );
    // Foldable actions fold into "More" so the group plus the title never overflows.
    final width = MediaQuery.sizeOf(context).width;
    final room = ((width - 2 * 24) * 0.45 / 52).floor().clamp(2, 6);
    final all = [...widget.actions, shortcuts];
    var shown = all;
    final folded = <GlassBarAction>[];
    if (all.length > room) {
      for (final a in all.reversed.toList()) {
        if (shown.length <= room - 1) break;
        if (a.foldable && a != shortcuts) {
          folded.add(a);
          shown = [
            for (final s in shown)
              if (s != a) s,
          ];
        }
      }
    }
    final entries = [
      ...widget.overflow,
      for (final a in folded.reversed)
        GlassMenuEntry(label: a.label, onSelected: a.onPress),
    ];
    final actions = entries.isEmpty
        ? shown
        : [
            ...shown.take(shown.length - 1),
            GlassBarAction(
                id: 'more',
                label: 'More',
                glyph: GlassGlyph.dotsThree,
                onPress: () => unawaited(showGlassMenu(context,
                    anchor: globalRect(context),
                    title: 'More',
                    entries: entries,),),),
            shown.last,
          ];

    final children = <SkinGlassShape>[];
    final aligns = <double>[];
    // The chevron is plain (no glass), so the group holds only the trailing actions and the status capsule.
    final n = actions.length;
    if (widget.offline) {
      children.add(SkinGlassShape(
          size: Size(statusCapsuleWidth(context, 'Offline'), 36),
          child: const GlassStatusCapsule(
              kind: GlassStatusKind.offline, inGroup: true,),),);
      aligns.add(-0.2);
    }
    children.add(
      SkinGlassShape(
        size: Size(n * 48.0 + (n - 1) * 8, 48),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < n; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              GlassBarIcon(
                  icon: actions[i].icon,
                  label: actions[i].label,
                  onPressed: actions[i].onPress,
                  badge: actions[i].badge,),
            ],
          ],
        ),
      ),
    );
    aligns.add(1);

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
            child: SkinGlassGroup(
                shapes: children,
                aligns: aligns,
                debugLabel: 'GlassToolbar',
                tier: GlassTierId.t2,),),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          right: 400,
          child: Row(
            children: [
              if (widget.leading == GlassLeading.back)
                _PlainBack(currentKey: widget.currentKey),
              if (_showTitle)
                Flexible(
                    child: GlassText(widget.title,
                        role: gt.typeTitle2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,),),
            ],
          ),
        ),
      ],
    );
  }

  static Rect globalRect(BuildContext context) {
    final ro = context.findRenderObject();
    if (ro is! RenderBox || !ro.attached) return Rect.zero;
    return ro.localToGlobal(Offset.zero) & ro.size;
  }

  static String _withSheet(BuildContext context, String id) {
    final uri = GoRouterState.of(context).uri;
    return uri.replace(
        queryParameters: {...uri.queryParameters, 'sheet': id},).toString();
  }
}

class _PlainBack extends StatelessWidget {
  const _PlainBack({this.currentKey});
  final String? currentKey;

  @override
  Widget build(BuildContext context) => GlassBackButton(currentKey: currentKey);
}
