import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/content_mode_switch.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/status_capsule.dart';
import 'package:manhwamaniacs/skins/glass/shell/bar_icon.dart';
import 'package:manhwamaniacs/skins/glass/shell/glass_back_button.dart';
import 'package:manhwamaniacs/skins/glass/shell/glass_scaffold.dart';
import 'package:manhwamaniacs/skins/glass/shell/large_title.dart';
import 'package:manhwamaniacs/skins/glass/shell/profile_menu.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_common.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

/// The trailing actions with "More" appended for [overflow] entries, capped at [max].
List<GlassBarAction> barActions(List<GlassBarAction> actions,
    List<GlassMenuEntry> overflow, BuildContext context,
    {int max = 3,}) {
  if (overflow.isEmpty) return actions.take(max).toList();
  final more = GlassBarAction(
    id: 'more',
    label: 'More',
    glyph: GlassGlyph.dotsThree,
    onPress: () => unawaited(showGlassMenu(context,
        anchor: globalRectOf(context), title: 'More', entries: overflow,),),
  );
  return [...actions.take(max - 1), more];
}

/// The width a status capsule needs: 12 padding, the 20 px disc or 14 px spinner, 6, the `footnote` text, 12.
double statusCapsuleWidth(BuildContext context, String text) =>
    12 +
    20 +
    6 +
    measureText(context, text,
            roleStyle(context, gt.typeFootnote, onGlass: true, wght: 600),)
        .width +
    12;

/// The phone nav row (glass 7.14): 44 tall at safe-top + 8, one `SkinGlassGroup` with a shape for the leading button, the title
/// capsule (once the large title has scrolled under the row) or a status capsule, and the trailing group.
class GlassNavRow extends ConsumerStatefulWidget {
  const GlassNavRow({
    super.key,
    required this.title,
    required this.leading,
    required this.actions,
    required this.overflow,
    required this.contentModeSwitch,
    required this.showDepth,
    required this.offline,
    required this.offset,
    required this.hasLargeTitle,
    this.currentKey,
  });
  final String title;
  final GlassLeading leading;
  final List<GlassBarAction> actions;
  final List<GlassMenuEntry> overflow;
  final bool contentModeSwitch;
  final bool showDepth;
  final bool offline;
  final ValueListenable<double> offset;
  final bool hasLargeTitle;
  final String? currentKey;

  @override
  ConsumerState<GlassNavRow> createState() => _GlassNavRowState();
}

class _GlassNavRowState extends ConsumerState<GlassNavRow> {
  bool _showTitle = false;

  @override
  void initState() {
    super.initState();
    widget.offset.addListener(_onScroll);
    _showTitle = _shouldShow(widget.offset.value);
  }

  @override
  void dispose() {
    widget.offset.removeListener(_onScroll);
    super.dispose();
  }

  bool _shouldShow(double off) =>
      !widget.hasLargeTitle || off >= GlassLargeTitle.capsuleAt;

  // The row's shape list is rebuilt at rest, never mid-motion: only the threshold crossing rebuilds it.
  void _onScroll() {
    final s = _shouldShow(widget.offset.value);
    if (s != _showTitle) setState(() => _showTitle = s);
  }

  @override
  Widget build(BuildContext context) {
    final w =
        MediaQuery.sizeOf(context).width - 2 * GlassFrame.screenMargin(context);
    final side = math.max(44.0, GlassFrame.hitMin(context));
    final actions = barActions(widget.actions, widget.overflow, context);
    final shapes = <SkinGlassShape>[];
    final aligns = <Alignment>[];

    // Leading.
    switch (widget.leading) {
      case GlassLeading.back:
        shapes.add(SkinGlassShape(
            size: Size(side, side),
            shape: const GlassShape.circle(),
            child: GlassBackButton(
                inGroup: true,
                showDepth: widget.showDepth,
                currentKey: widget.currentKey,),),);
        aligns.add(Alignment.centerLeft);
      case GlassLeading.profile:
        shapes.add(
          SkinGlassShape(
            size: Size(side, side),
            shape: const GlassShape.circle(),
            child: Center(
                child: _ProfileLeading(
                    onLongPressRect: (r) =>
                        showProfileSwitcher(context, ref, r),),),
          ),
        );
        aligns.add(Alignment.centerLeft);
      case GlassLeading.none:
        break;
    }

    // Centre: a status capsule while offline, else the title capsule once the large title is under the row.
    if (widget.offline) {
      const text = 'Offline';
      shapes.add(
        SkinGlassShape(
          size: Size(statusCapsuleWidth(context, text), 36),
          child: const GlassStatusCapsule(
              kind: GlassStatusKind.offline, inGroup: true,),
        ),
      );
      aligns.add(Alignment.center);
    } else if (_showTitle) {
      final style =
          roleStyle(context, gt.typeSubhead, onGlass: true, wght: 600);
      final tw = (measureText(context, widget.title, style).width + 32)
          .clamp(56.0, w * 0.6);
      shapes.add(SkinGlassShape(
          size: Size(tw, 36),
          child: _TitleCapsule(title: widget.title, width: tw),),);
      aligns.add(Alignment.center);
    }

    // Trailing: mode switch and up to three icons.
    if (widget.contentModeSwitch) {
      shapes.add(const SkinGlassShape(
          size: Size(88, 36),
          child:
              GlassContentModeSwitch(variant: GlassContentModeVariant.navRow),),);
      aligns.add(Alignment.centerRight);
    }
    if (actions.isNotEmpty) {
      final n = actions.length;
      shapes.add(
        SkinGlassShape(
          size: Size(n * side + (n - 1) * 8, side),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < n; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                GlassBarIcon(
                    icon: actions[i].icon,
                    label: actions[i].label,
                    onPressed: actions[i].onPress,
                    badge: actions[i].badge,
                    iconBuilder: actions[i].iconBuilder,),
              ],
            ],
          ),
        ),
      );
      aligns.add(Alignment.centerRight);
    }
    if (shapes.isEmpty) return const SizedBox.shrink();
    // A trailing group after a mode switch: keep both at the end with the gap between them.
    return SkinGlassGroup(
        shapes: shapes, aligns: aligns, debugLabel: 'GlassNavRow',);
  }
}

class _ProfileLeading extends ConsumerWidget {
  const _ProfileLeading({required this.onLongPressRect});
  final void Function(Rect) onLongPressRect;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Semantics(
        button: true,
        label: 'Profile and settings',
        excludeSemantics: true,
        onTap: () => context.go(Routes.indexHub()),
        onLongPress: () => onLongPressRect(globalRectOf(context)),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.go(Routes.indexHub()),
          onLongPress: () => onLongPressRect(globalRectOf(context)),
          child: SizedBox.square(dimension: math.max(44.0, GlassFrame.hitMin(context)), child: const Center(child: GlassMyOrb())),
        ),
      );
}

/// The title capsule: scale 0.9 to 1 on `springSnappy` when it materialises (the Title capsule move).
class _TitleCapsule extends ConsumerStatefulWidget {
  const _TitleCapsule({required this.title, required this.width});
  final String title;
  final double width;

  @override
  ConsumerState<_TitleCapsule> createState() => _TitleCapsuleState();
}

class _TitleCapsuleState extends ConsumerState<_TitleCapsule>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, value: 0);

  @override
  void initState() {
    super.initState();
    GlassMotion.play(MotionName.titleCapsule, controller: _c, target: 1);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Opacity(
          opacity: _c.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.9 + 0.1 * _c.value.clamp(0.0, 1.0),
            child: Semantics(
              header: true,
              label: widget.title,
              excludeSemantics: true,
              child: Center(
                  child: Text(widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textScaler: TextScaler.noScaling,
                      style: roleStyle(context, gt.typeSubhead,
                              onGlass: true, wght: 600,)
                          .copyWith(color: gt.colorOnGlass),),),
            ),
          ),
        ),
      );
}
