import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart' show SelectableRegionState, Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/reactions/glass_reactions.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// What the menu offers (F1). Null callbacks drop their row; [recommendDisabled] keeps the row disabled with its reason (glass 9.3.4).
class NovelSelectionActions {
  const NovelSelectionActions({
    required this.onCopy,
    required this.onBookmark,
    required this.onReact,
    this.onPlayFrom,
    this.onRecommend,
    this.recommendDisabled = false,
  });
  final VoidCallback onCopy, onBookmark;
  final void Function(ReactionKind kind, Offset from) onReact;

  /// Present only when the chapter's audio exists.
  final VoidCallback? onPlayFrom;

  /// Present only when `mobile/43`'s `recommend` sheet is registered.
  final VoidCallback? onRecommend;
  final bool recommendDisabled;
}

/// Menu geometry (F1): at least 220 wide, rows 44, radius 20 inside 26.
const double kSelectionMenuMinWidth = 220, kSelectionMenuRow = 44, kSelectionMenuRadius = 26, kSelectionRowRadius = 20;

/// The Glass selection menu, returned by the reader's `SelectionArea.contextMenuBuilder`: `glassThick` (T4), blooming above
/// `contextMenuAnchors` on `springMorph`; it rebuilds with the new anchors while the handles move. "React to this chapter" morphs the
/// menu into the six reaction bubbles at the same anchor.
class GlassSelectionMenu extends ConsumerStatefulWidget {
  const GlassSelectionMenu({super.key, required this.region, required this.actions, required this.lb, this.onDismiss});
  final SelectableRegionState region;
  final NovelSelectionActions actions;
  final double lb;

  /// The keyboard path (`Shift+F10`) shows the menu in its own overlay entry; this removes it.
  final VoidCallback? onDismiss;

  @override
  ConsumerState<GlassSelectionMenu> createState() => _GlassSelectionMenuState();
}

class _GlassSelectionMenuState extends ConsumerState<GlassSelectionMenu> with SingleTickerProviderStateMixin {
  late final AnimationController _bloom;
  bool _reacting = false;
  final List<GlobalKey> _bubbleKeys = [for (var i = 0; i < 6; i++) GlobalKey()];

  @override
  void initState() {
    super.initState();
    _bloom = AnimationController(vsync: this);
    glassFire(ref, HapticEvent.longpressOpen);
    unawaited(GlassMotion.play(MotionName.bloom, controller: _bloom, target: 1));
  }

  @override
  void dispose() {
    _bloom.dispose();
    super.dispose();
  }

  void _done(VoidCallback f) {
    f();
    widget.region.hideToolbar();
    widget.onDismiss?.call();
  }

  void _openReactions() {
    glassFire(ref, HapticEvent.reactionBloom);
    setState(() => _reacting = true);
    _bloom.value = 0.6;
    unawaited(GlassMotion.play(MotionName.reactionBloomAndArc, controller: _bloom, target: 1));
  }

  Offset _centreOf(int i) {
    final ro = _bubbleKeys[i].currentContext?.findRenderObject();
    return ro is RenderBox && ro.hasSize ? ro.localToGlobal(ro.size.center(Offset.zero)) : Offset.zero;
  }

  Widget _row(String label, VoidCallback? onTap, {String? reason}) {
    final enabled = onTap != null;
    return GlassPressable(
      material: GlassMaterial.content,
      sink: 0.99,
      shape: const GlassShape.superellipse(kSelectionRowRadius),
      onTap: onTap,
      enabled: enabled,
      disabledReason: reason,
      semanticsLabel: label,
      builder: (context, info) => SizedBox(
        height: kSelectionMenuRow,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Opacity(opacity: enabled ? 1 : 0.4, child: GlassText(label, role: gt.typeBody, onGlass: true, maxScale: 1.3, maxLines: 2)),
          ),
        ),
      ),
    );
  }

  Widget _rows() {
    final a = widget.actions;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _row('Copy', () => _done(a.onCopy)),
        _row('Bookmark this paragraph', () => _done(a.onBookmark)),
        if (a.onPlayFrom != null) _row('Play from here', () => _done(a.onPlayFrom!)),
        _row('React to this chapter', _openReactions),
        if (a.onRecommend != null || a.recommendDisabled)
          _row(
            a.recommendDisabled ? 'Recommend to… (no one is taking recommendations yet)' : 'Recommend to…',
            a.recommendDisabled ? null : () => _done(a.onRecommend!),
            reason: a.recommendDisabled ? 'No one is taking recommendations yet' : null,
          ),
      ],
    );
  }

  Widget _bubbles() => Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < kGlassReactions.length; i++)
              Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                child: GlassPressable(
                  key: _bubbleKeys[i],
                  material: GlassMaterial.content,
                  shape: const GlassShape.circle(),
                  sink: 0.92,
                  semanticsLabel: kGlassReactions[i].action,
                  onPressChanged: (down) => down ? glassFire(ref, HapticEvent.reactionCross) : null,
                  onTap: () {
                    final from = _centreOf(i);
                    widget.actions.onReact(kGlassReactions[i].kind, from);
                    widget.region.hideToolbar();
                    widget.onDismiss?.call();
                  },
                  builder: (context, info) => SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(child: Icon(kGlassReactions[i].fill, size: 28, color: info.states.pressed ? gt.colorBloom : gt.colorOnGlass)),
                  ),
                ),
              ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final anchors = widget.region.contextMenuAnchors;
    return CustomSingleChildLayout(
      delegate: _AboveAnchor(anchors.primaryAnchor, MediaQuery.paddingOf(context)),
      child: AnimatedBuilder(
        animation: _bloom,
        builder: (context, child) => Opacity(
          opacity: _bloom.value.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.9 + 0.1 * _bloom.value.clamp(0.0, 1.2), alignment: Alignment.bottomCenter, child: child),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: kSelectionMenuMinWidth),
            child: IntrinsicWidth(
              child: SkinGlass(
                tier: GlassTierId.t4,
                lb: widget.lb,
                layer: GlassLayerKind.overlays,
                shape: const GlassShape.superellipse(kSelectionMenuRadius),
                debugLabel: 'novel selection menu',
                child: GlassHost(child: Padding(padding: const EdgeInsets.all(3), child: _reacting ? _bubbles() : _rows())),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Puts the menu 8 px above [anchor], inside the safe area, flipping below when there is no room.
class _AboveAnchor extends SingleChildLayoutDelegate {
  _AboveAnchor(this.anchor, this.pad);
  final Offset anchor;
  final EdgeInsets pad;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints c) => BoxConstraints.loose(Size(math.max(0, c.maxWidth - 16), c.maxHeight));

  @override
  Offset getPositionForChild(Size size, Size child) {
    final x = (anchor.dx - child.width / 2).clamp(8.0, math.max(8.0, size.width - child.width - 8)).toDouble();
    var y = anchor.dy - child.height - 8;
    if (y < pad.top + 8) y = anchor.dy + 32;
    return Offset(x, y.clamp(pad.top + 8, math.max(pad.top + 8, size.height - child.height - 8)).toDouble());
  }

  @override
  bool shouldRelayout(_AboveAnchor old) => old.anchor != anchor || old.pad != pad;
}
