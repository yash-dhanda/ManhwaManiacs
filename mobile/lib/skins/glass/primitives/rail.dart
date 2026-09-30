import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/drag_owner.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/letter_reveal.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/rail_columns.dart';
import 'package:manhwamaniacs/skins/glass/primitives/rail_focus.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';

/// glass 7.9 states.
enum GlassRailState { ready, loading, empty, error, partial }

/// The rails of one screen: `↑` and `↓` move between them keeping the column ([railColumn]).
class GlassRailGroup extends StatefulWidget {
  const GlassRailGroup({super.key, required this.child});
  final Widget child;

  static _GroupState? _of(BuildContext context) => context.findAncestorStateOfType<_GroupState>();

  @override
  State<GlassRailGroup> createState() => _GroupState();
}

class _GroupState extends State<GlassRailGroup> {
  final List<_GlassRailState> rails = [];

  void _neighbour(_GlassRailState from, int dir) {
    final sorted = rails.where((r) => r.mounted && r.canFocus).toList()..sort((a, b) => a.top.compareTo(b.top));
    final i = sorted.indexOf(from);
    final j = i + dir;
    if (i < 0 || j < 0 || j >= sorted.length) return;
    final to = sorted[j];
    final col = railColumn(from.focusedIndex, from.offset, to.offset, from.stride);
    to.focusIndex(math.min(col, to.count - 1));
  }

  @override
  Widget build(BuildContext context) => FocusTraversalGroup(child: widget.child);
}

/// One rail (glass 7.9): a `title2` header played by [LetterReveal], an optional subtitle, "See all", and a
/// horizontal scroller on [SnapPhysics] (`springSettle`): free momentum, the ballistic end rounded to the
/// stride, a rubber band at both ends, no snapping while a finger is down. Posters peek at the trailing
/// edge (2.8 visible at 390 px; 1.6 at `f >= 1.9`). Each rail is one tab stop; `←` `→` move inside it.
/// Page arrows show on hover-pointer frames and page by (visible - 1) items on `springPage`.
class GlassRail extends ConsumerStatefulWidget {
  const GlassRail({
    super.key,
    required this.title,
    required this.itemCount,
    required this.itemBuilder,
    required this.itemHeight,
    this.subtitle,
    this.revealKey,
    this.screenId = '',
    this.onSeeAll,
    this.itemWidth,
    this.state = GlassRailState.ready,
    this.onRetry,
    this.unavailable,
    this.skeletonCount = 6,
    this.controller,
    this.forceArrows = false,
  });

  final String title;
  final String? subtitle;

  /// The `LetterReveal` key; defaults to the title.
  final String? revealKey;
  final String screenId;
  final VoidCallback? onSeeAll;
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// The height of one item, poster and text.
  final double itemHeight;

  /// The width of one item; default: the frame's poster width (phones fit the peek).
  final double? itemWidth;
  final GlassRailState state;
  final VoidCallback? onRetry;

  /// An AI rail's slot when it has nothing to show (`AiNotice`, `mobile/28`).
  final Widget? unavailable;
  final int skeletonCount;
  final ScrollController? controller;

  /// For captures: show the page arrows.
  final bool forceArrows;

  @override
  ConsumerState<GlassRail> createState() => _GlassRailState();
}

class _GlassRailState extends ConsumerState<GlassRail> {
  late final ScrollController _c = widget.controller ?? ScrollController();
  final Map<int, FocusNode> _nodes = {};
  final FocusNode _railFocus = FocusNode(debugLabel: 'GlassRail', canRequestFocus: false, skipTraversal: true);
  _GroupState? _group;
  int _remembered = 0;
  int _focused = 0;
  bool _showArrows = false;
  final ValueNotifier<bool> _atStart = ValueNotifier(true);
  Timer? _arrowTimer;
  double _itemW = 124;
  double _gap = 12;
  double _margin = 16;
  double _viewport = 390;

  bool get canFocus => widget.state == GlassRailState.ready || widget.state == GlassRailState.partial;
  int get count => widget.itemCount;
  int get focusedIndex => _focused;
  double get stride => _itemW + _gap;
  double get offset => _c.hasClients ? _c.offset : 0;
  double get top {
    final ro = context.findRenderObject();
    return ro is RenderBox && ro.attached ? ro.localToGlobal(Offset.zero).dy : 0;
  }

  void _syncStart() {
    final at = !_c.hasClients || _c.offset <= 0.5;
    if (at != _atStart.value) _atStart.value = at;
  }

  @override
  void initState() {
    super.initState();
    _c.addListener(_syncStart);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final g = GlassRailGroup._of(context);
    if (g != _group) {
      _group?.rails.remove(this);
      _group = g;
      g?.rails.add(this);
    }
  }

  @override
  void dispose() {
    _group?.rails.remove(this);
    _arrowTimer?.cancel();
    _c.removeListener(_syncStart);
    _atStart.dispose();
    if (widget.controller == null) _c.dispose();
    for (final n in _nodes.values) {
      n.dispose();
    }
    _railFocus.dispose();
    super.dispose();
  }

  FocusNode _node(int i) {
    final n = _nodes.putIfAbsent(i, () => FocusNode(debugLabel: 'GlassRail item $i'));
    n.skipTraversal = i != _remembered;
    return n;
  }

  /// Scrolls item [i] into view with 8 px of padding, then moves focus to it.
  void focusIndex(int i, {int attempt = 0}) {
    if (!mounted || widget.itemCount == 0) return;
    i = i.clamp(0, widget.itemCount - 1);
    if (_c.hasClients) {
      final left = _margin + i * stride;
      final right = left + _itemW;
      final o = _c.offset;
      double? target;
      if (left - 8 < o) {
        target = math.max(0, left - 8 - _margin);
      } else if (right + 8 > o + _viewport) {
        target = right + 8 - _viewport;
      }
      if (target != null) _c.jumpTo(target.clamp(_c.position.minScrollExtent, _c.position.maxScrollExtent));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final n = _nodes[i];
      if (n != null && n.context != null) {
        n.requestFocus();
      } else if (attempt < 4) {
        focusIndex(i, attempt: attempt + 1);
      }
    });
  }

  KeyEventResult _key(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.arrowRight) {
      focusIndex(_focused + 1);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowLeft) {
      focusIndex(_focused - 1);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowDown) {
      _group?._neighbour(this, 1);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowUp) {
      _group?._neighbour(this, -1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _page(int dir) {
    if (!_c.hasClients) return;
    final visible = math.max(1, ((_viewport - _margin) / stride).floor());
    final target = (_c.offset + dir * (visible - 1) * stride).clamp(_c.position.minScrollExtent, _c.position.maxScrollExtent);
    unawaited(_c.animateTo(target, duration: Duration(milliseconds: gt.springPage.ms), curve: Curves.easeOutCubic));
  }

  void _hoverChanged(bool h) {
    _arrowTimer?.cancel();
    if (h) {
      setState(() => _showArrows = true);
    } else {
      _arrowTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _showArrows = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final frame = GlassFrame.of(context);
    final size = MediaQuery.sizeOf(context);
    _margin = GlassFrame.screenMargin(context);
    _gap = frame == GlassFrameKind.phone ? 12 : 16;
    _viewport = size.width;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    if (widget.itemWidth != null) {
      _itemW = widget.itemWidth!;
    } else if (frame == GlassFrameKind.phone) {
      final visible = scale >= 1.9 ? 1.6 : 2.8;
      _itemW = ((size.width - _margin + _gap) / visible - _gap).floorToDouble();
    } else {
      _itemW = posterWidthFor(frame);
    }
    if (widget.state == GlassRailState.empty) {
      return widget.unavailable ?? const SizedBox.shrink();
    }
    final header = Padding(
      padding: EdgeInsets.symmetric(horizontal: _margin),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                LetterReveal(widget.title, role: gt.typeTitle2, revealKey: widget.revealKey ?? widget.title, screenId: widget.screenId, headingLevel: 2),
                if (widget.subtitle != null) Padding(padding: const EdgeInsets.only(top: 2), child: GlassLabel(widget.subtitle!, role: gt.typeFootnote, color: gt.colorLabel2)),
              ],
            ),
          ),
          if (widget.onSeeAll != null)
            GlassButton(label: 'See all', semanticsLabel: 'See all, ${widget.title}', variant: GlassButtonVariant.plain, size: GlassButtonSize.small, onPressed: widget.onSeeAll),
        ],
      ),
    );

    Widget scroller;
    final h = widget.itemHeight + 16;
    switch (widget.state) {
      case GlassRailState.loading:
        scroller = SizedBox(
          height: h,
          child: GlassSkeletonGroup(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: _margin, vertical: 8),
              itemCount: widget.skeletonCount,
              separatorBuilder: (_, __) => SizedBox(width: _gap),
              itemBuilder: (context, i) => _skeletonItem(i),
            ),
          ),
        );
      case GlassRailState.error:
        scroller = Padding(
          padding: EdgeInsets.symmetric(horizontal: _margin, vertical: 8),
          child: Container(
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: gt.colorSurface1, borderRadius: BorderRadius.circular(gt.radiusXl), border: Border.all(color: const Color(0x0FFFFFFF))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GlassLabel("Couldn't load this row", role: gt.typeHeadline, color: gt.colorLabel1),
                GlassButton(label: 'Retry', variant: GlassButtonVariant.plain, size: GlassButtonSize.small, onPressed: widget.onRetry),
              ],
            ),
          ),
        );
      case GlassRailState.ready:
      case GlassRailState.partial:
      case GlassRailState.empty:
        final extra = widget.state == GlassRailState.partial ? 1 : 0;
        scroller = SizedBox(
          height: h,
          child: Focus(
            focusNode: _railFocus,
            onKeyEvent: _key,
            child: FocusTraversalGroup(
              child: ListView.builder(
                controller: _c,
                scrollDirection: Axis.horizontal,
                physics: SnapPhysics(stride: stride),
                padding: EdgeInsets.symmetric(horizontal: _margin, vertical: 8),
                clipBehavior: Clip.none,
                itemCount: widget.itemCount + extra,
                itemBuilder: (context, i) {
                  if (i >= widget.itemCount) {
                    return Padding(padding: EdgeInsets.only(right: _gap), child: GlassSkeletonGroup(child: _skeletonItem(i)));
                  }
                  return Padding(
                    padding: EdgeInsets.only(right: i == widget.itemCount - 1 && extra == 0 ? 0 : _gap),
                    child: SizedBox(
                      width: _itemW,
                      child: Focus(
                        canRequestFocus: false,
                        skipTraversal: true,
                        onFocusChange: (f) {
                          if (!f) return;
                          _focused = i;
                          if (_remembered != i) setState(() => _remembered = i);
                        },
                        child: GlassRailItemScope(node: _node(i), child: widget.itemBuilder(context, i)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
    }

    final canArrow = frame != GlassFrameKind.phone || widget.forceArrows;
    Widget body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [header, const SizedBox(height: 12), scroller],
    );
    if (canArrow && (widget.state == GlassRailState.ready || widget.state == GlassRailState.partial)) {
      body = MouseRegion(
        onEnter: (_) => _hoverChanged(true),
        onExit: (_) => _hoverChanged(false),
        child: Stack(
          children: [
            body,
            Positioned(left: 8, top: 0, bottom: 0, child: Align(alignment: Alignment.centerLeft, child: _Arrow(left: true, visible: _showArrows || widget.forceArrows, controller: _c, onTap: () => _page(-1)))),
            Positioned(right: 8, top: 0, bottom: 0, child: Align(alignment: Alignment.centerRight, child: _Arrow(left: false, visible: _showArrows || widget.forceArrows, controller: _c, onTap: () => _page(1)))),
          ],
        ),
      );
    }
    return GlassDragOwner(kind: GlassDragOwnerKind.rail, atLeadingEdge: _atStart, child: body);
  }

  Widget _skeletonItem(int i) => SizedBox(
        width: _itemW,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassSkeleton(width: _itemW, height: _itemW * 1.5, index: i, delayed: false),
            const SizedBox(height: 8),
            GlassSkeleton(width: _itemW * 0.85, height: 12, radius: 6, index: i, delayed: false),
            const SizedBox(height: 6),
            GlassSkeleton(width: _itemW * 0.5, height: 10, radius: 5, index: i, delayed: false),
          ],
        ),
      );
}

/// A page arrow: a content-twin circle (no backdrop read, so it does not count toward the glass budget).
class _Arrow extends StatelessWidget {
  const _Arrow({required this.left, required this.visible, required this.controller, required this.onTap});
  final bool left;
  final bool visible;
  final ScrollController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          var can = true;
          if (controller.hasClients && controller.position.hasContentDimensions) {
            can = left ? controller.offset > 1 : controller.offset < controller.position.maxScrollExtent - 1;
          }
          final show = visible && can;
          return AnimatedOpacity(
            opacity: show ? 1 : 0,
            duration: gt.curveFadeIn.duration,
            curve: gt.curveFadeIn.curve,
            child: IgnorePointer(
              ignoring: !show,
              child: ExcludeFocus(
                excluding: !show,
                child: GlassPressable(
                  material: GlassMaterial.content,
                  sink: 0.92,
                  shape: const GlassShape.circle(),
                  onTap: onTap,
                  semanticsLabel: left ? 'Previous items' : 'Next items',
                  tooltip: left ? 'Previous' : 'Next',
                  builder: (context, info) => Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: info.states.hovered ? const Color(0xB8282830) : const Color(0x9E131317),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0x38FFFFFF), width: 0.5),
                    ),
                    child: Transform.rotate(angle: left ? math.pi : 0, child: GlyphIcon(GlassGlyph.caretRight, color: gt.colorOnGlass)),
                  ),
                ),
              ),
            ),
          );
        },
      );
}
