import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/skins/cinematic/a11y/folio.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_tooltip.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// One tab of [CineContentsTabs]: a folio (`01`) and a label (`CHAPTERS`), with an optional raised
/// count. [loading] shows the count as `–`, [error] as `!` in `proof`; [disabledReason] is the
/// tooltip when it is disabled.
class CineTab {
  const CineTab({required this.folio, required this.label, this.count, this.disabled = false, this.disabledReason, this.loading = false, this.error = false});
  final String folio, label;
  final int? count;
  final bool disabled, loading, error;
  final String? disabledReason;
}

/// The contents tabs (cinematic 7.12): a tab row over a [TabController] with the folio + label in
/// `typeNav` at its tablet size, a 2 px `spot` underline whose x and width follow the pager during
/// a swipe (Rule slide, 320 ms `settle`, on a tap), a 1 px `rule.1` under the whole row and
/// horizontal scroll on phones. Arrow keys move between tabs while the row has focus.
class CineContentsTabs extends StatefulWidget {
  const CineContentsTabs({super.key, required this.controller, required this.tabs});

  final TabController controller;
  final List<CineTab> tabs;

  /// `[` and `]` for the screens to bind in the key registry.
  static void previous(TabController c) => _step(c, -1);
  static void next(TabController c) => _step(c, 1);

  static void _step(TabController c, int d) {
    final i = (c.index + d).clamp(0, c.length - 1);
    if (i != c.index) c.animateTo(i, duration: CineDur.column, curve: CineCurves.settle);
  }

  @override
  State<CineContentsTabs> createState() => _CineContentsTabsState();
}

class _CineContentsTabsState extends State<CineContentsTabs> {
  late List<GlobalKey> _keys = [for (final _ in widget.tabs) GlobalKey()];
  late List<FocusNode> _nodes = [for (final _ in widget.tabs) FocusNode()];
  final _rowKey = GlobalKey();
  List<Rect> _rects = const [];

  @override
  void didUpdateWidget(CineContentsTabs old) {
    super.didUpdateWidget(old);
    if (old.tabs.length != widget.tabs.length) {
      for (final n in _nodes) {
        n.dispose();
      }
      _keys = [for (final _ in widget.tabs) GlobalKey()];
      _nodes = [for (final _ in widget.tabs) FocusNode()];
    }
  }

  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _measure() {
    final row = _rowKey.currentContext?.findRenderObject() as RenderBox?;
    if (row == null || !row.hasSize) return;
    final r = <Rect>[];
    for (final k in _keys) {
      final b = k.currentContext?.findRenderObject() as RenderBox?;
      if (b == null || !b.hasSize) return;
      r.add(b.localToGlobal(Offset.zero, ancestor: row) & b.size);
    }
    if (r.length != _rects.length || [for (var i = 0; i < r.length; i++) r[i] != _rects[i]].contains(true)) {
      setState(() => _rects = r);
    }
  }

  void _select(int i) {
    if (widget.tabs[i].disabled) return;
    if (i != widget.controller.index) cineFeedback(context, HapticEvent.select, sound: SoundEvent.select);
    final reduced = CineMotion.reduced(context);
    widget.controller.animateTo(i, duration: reduced ? CineDur.reduced : CineDur.column, curve: CineCurves.settle);
    CineMotion.track(MotionName.ruleSlide, reduced ? 150 : 320).end();
  }

  void _arrow(int dir) {
    var i = widget.controller.index;
    do {
      i += dir;
    } while (i >= 0 && i < widget.tabs.length && widget.tabs[i].disabled);
    if (i < 0 || i >= widget.tabs.length) return;
    _select(i);
    _nodes[i].requestFocus();
  }

  CineTextRole _role(CineTextRole r) => CineTextRole(
        family: r.family,
        italic: r.italic,
        wght: r.wght,
        axes: r.axes,
        sizes: List.filled(r.sizes.length, r.sizes[1]),
        lines: List.filled(r.lines.length, r.lines[1]),
        trackingEm: r.trackingEm,
        cap: r.cap,
        upper: r.upper,
      );

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final reduced = CineMotion.reduced(context);
    final nav = _role(c.typeNav);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _measure();
    });
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _arrow(-1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => _arrow(1),
      },
      child: Container(
        decoration: BoxDecoration(border: Border(bottom: c.ruleHair)),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: AnimatedBuilder(
            animation: Listenable.merge([widget.controller, widget.controller.animation]),
            builder: (context, _) {
              final v = widget.controller.animation?.value ?? widget.controller.index.toDouble();
              return Stack(key: _rowKey, children: [
                Row(children: [
                  for (var i = 0; i < widget.tabs.length; i++) _tab(context, i, nav, reduced, v),
                ],),
                if (!reduced && _rects.length == widget.tabs.length) _indicator(c, v),
              ],);
            },
          ),
        ),
      ),
    );
  }

  Widget _indicator(CineTokens c, double v) {
    final lo = v.floor().clamp(0, _rects.length - 1), hi = v.ceil().clamp(0, _rects.length - 1);
    final t = v - v.floor();
    final a = _rects[lo], b = _rects[hi];
    final left = a.left + (b.left - a.left) * t;
    final width = a.width + (b.width - a.width) * t;
    return Positioned(left: left, bottom: 0, width: width, height: 2, child: ColoredBox(key: const Key('cine-tab-indicator'), color: c.colorSpot));
  }

  Widget _tab(BuildContext context, int i, CineTextRole nav, bool reduced, double v) {
    final c = context.cine;
    final t = widget.tabs[i];
    final selected = widget.controller.index == i;
    final fg = t.disabled ? c.colorInk30 : null;
    final spoken = folioLabel(t.label, count: t.count);
    Widget tab = CinePressable(
      focusNode: _nodes[i],
      enabled: !t.disabled,
      hit: false,
      onTap: () => _select(i),
      builder: (context, st) {
        final ink = fg ?? (selected || st.hovered ? c.colorInk100 : c.colorInk45);
        return Container(
          key: _keys[i],
          constraints: const BoxConstraints(minHeight: 48),
          padding: EdgeInsets.symmetric(horizontal: c.space4),
          transform: st.pressed ? Matrix4.translationValues(0, 1, 0) : null,
          child: Stack(alignment: Alignment.bottomCenter, children: [
            Center(
              widthFactor: 1,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                CineLit(t.folio, CineFace.plexMono, 12, 16, color: t.disabled ? c.colorInk30 : c.colorInk45),
                SizedBox(width: c.space2),
                CineRoleText(t.label, nav, color: ink),
                if (t.count != null || t.loading || t.error) ...[
                  SizedBox(width: c.space2),
                  CineRoleText(t.error ? '!' : (t.loading ? '–' : '${t.count}'), c.typeFolio, color: t.error ? c.colorProof : c.colorInk45),
                ],
              ],),
            ),
            if (reduced)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 2,
                child: AnimatedOpacity(duration: CineDur.reduced, opacity: selected ? 1 : 0, child: ColoredBox(color: c.colorSpot)),
              ),
          ],),
        );
      },
    );
    if (t.disabled && t.disabledReason != null) tab = CineTooltip(message: t.disabledReason!, child: tab);
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      enabled: !t.disabled,
      label: spoken.isEmpty ? t.label : '${t.folio}, $spoken',
      excludeSemantics: true,
      onTap: t.disabled ? null : () => _select(i),
      child: tab,
    );
  }
}

/// The panels under [CineContentsTabs]: swipeable by default; `pager: false` blocks horizontal
/// drags so nested tabs switch by tap only and the hub pager owns them (cinematic 11).
class CineTabPanels extends StatelessWidget {
  const CineTabPanels({super.key, required this.controller, required this.children, this.pager = true});
  final TabController controller;
  final List<Widget> children;
  final bool pager;

  @override
  Widget build(BuildContext context) => TabBarView(
        controller: controller,
        physics: pager ? null : const NeverScrollableScrollPhysics(),
        children: children,
      );
}

/// A pinned sliver header for [CineContentsTabs] (the `sticky` variant), `paper.0` behind it so
/// the content scrolls under.
SliverPersistentHeader cineStickyContentsTabs({required TabController controller, required List<CineTab> tabs}) =>
    SliverPersistentHeader(pinned: true, delegate: _StickyTabs(controller, tabs));

class _StickyTabs extends SliverPersistentHeaderDelegate {
  _StickyTabs(this.controller, this.tabs);
  final TabController controller;
  final List<CineTab> tabs;

  @override
  double get minExtent => 49;
  @override
  double get maxExtent => 49;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      ColoredBox(color: context.cine.colorPaper0, child: CineContentsTabs(controller: controller, tabs: tabs));

  @override
  bool shouldRebuild(_StickyTabs o) => o.controller != controller || o.tabs != tabs;
}
