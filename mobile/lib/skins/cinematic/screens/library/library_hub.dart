import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/updates/providers/unread_count_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/a11y/folio.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_pull_to_reprint.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/library/hub_slide_sliver.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/hub_shell_scope.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The five roots of the Library hub, in branch order (cinematic 8.0.3).
enum HubTab {
  shelf('SHELF'),
  updates('UPDATES'),
  collections('COLLECTIONS'),
  history('HISTORY'),
  bookmarks('BOOKMARKS');

  const HubTab(this.label);
  final String label;
  String get folio => '0${index + 1}';
}

/// The masthead's words: `No. 02 — YOUR SHELF`, `Library`, one line of live facts.
typedef HubMasthead = ({String kicker, String title, String deck});

/// A drag commits to the neighbour tab at this distance or this fling speed (cinematic 11).
const double kHubCommitDistance = 72;
const double kHubCommitVelocity = 600;

/// Whether a release with [dx] travelled and [velocity] px/s commits to a neighbour, and which one
/// (-1 previous, 1 next), or 0 to spring back.
int hubReleaseTarget(double dx, double velocity, {required bool hasPrevious, required bool hasNext}) {
  var dir = 0;
  if (dx <= -kHubCommitDistance || velocity <= -kHubCommitVelocity) dir = 1;
  if (dx >= kHubCommitDistance || velocity >= kHubCommitVelocity) dir = -1;
  if (dx.abs() >= kHubCommitDistance) dir = dx < 0 ? 1 : -1;
  if (dir == 1 && !hasNext) return 0;
  if (dir == -1 && !hasPrevious) return 0;
  return dir;
}

/// The Library hub frame (cinematic 8.9, 7.12, 7.27, 11): masthead, the pinned tab row, the page's
/// content slivers and a finger-tracked swipe between the five tabs. Every tab page builds its own
/// hub; the tabs are branch roots of the nested shell (`HubShellScope`), each with its own route
/// and no back arrow.
class LibraryHub extends ConsumerStatefulWidget {
  const LibraryHub({
    super.key,
    required this.tab,
    required this.masthead,
    required this.slivers,
    this.onRefresh,
    this.scrollController,
    this.mastheadFocus,
    this.overlay,
    this.onSwitch,
  });

  final HubTab tab;
  final HubMasthead masthead;

  /// Everything below the tab row.
  final List<Widget> slivers;

  /// Pull to reprint; null for none.
  final Future<void> Function()? onRefresh;
  final ScrollController? scrollController;
  final FocusNode? mastheadFocus;

  /// A bottom overlay (the select-mode bar).
  final Widget? overlay;

  /// Switches to another tab; defaults to the nested shell's `goBranch`.
  final ValueChanged<HubTab>? onSwitch;

  @override
  ConsumerState<LibraryHub> createState() => _LibraryHubState();
}

class _LibraryHubState extends ConsumerState<LibraryHub> with TickerProviderStateMixin {
  final ValueNotifier<double> _dx = ValueNotifier(0);
  late final AnimationController _spring = AnimationController.unbounded(vsync: this)..addListener(() => _dx.value = _spring.value);
  late final AnimationController _fade = AnimationController(vsync: this, duration: CineDur.reduced, value: 1);
  double _raw = 0;
  bool _dragging = false;

  bool get _hasPrevious => widget.tab.index > 0;
  bool get _hasNext => widget.tab.index < HubTab.values.length - 1;

  @override
  void dispose() {
    _spring.dispose();
    _fade.dispose();
    _dx.dispose();
    super.dispose();
  }

  double _rubber(double raw) {
    final blocked = (raw < 0 && !_hasNext) || (raw > 0 && !_hasPrevious);
    return blocked ? raw * 0.35 : raw;
  }

  void _start(DragStartDetails d) {
    _spring.stop();
    _raw = _dx.value;
    _dragging = true;
  }

  void _update(DragUpdateDetails d) {
    if (!_dragging) return;
    _raw += d.delta.dx;
    _dx.value = _rubber(_raw);
  }

  void _end(DragEndDetails d) {
    if (!_dragging) return;
    _dragging = false;
    final v = d.velocity.pixelsPerSecond.dx;
    final dir = hubReleaseTarget(_raw, v, hasPrevious: _hasPrevious, hasNext: _hasNext);
    if (dir != 0) {
      cineFeedback(context, HapticEvent.select, sound: SoundEvent.select);
      final target = HubTab.values[widget.tab.index + dir];
      _dx.value = 0;
      _raw = 0;
      if (widget.onSwitch != null) {
        widget.onSwitch!(target);
      } else {
        HubShellScope.maybeOf(context)?.shell.goBranch(target.index);
      }
      return;
    }
    if (CineMotion.reduced(context)) {
      _dx.value = 0;
      _raw = 0;
      _fade.forward(from: 0);
      return;
    }
    _spring.value = _dx.value;
    _spring.animateWith(SpringSimulation(context.cine.springRelease.description, _dx.value, 0, v * 0.35));
    _raw = 0;
  }

  void _cancel() {
    _dragging = false;
    _dx.value = 0;
    _raw = 0;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final mq = MediaQuery.of(context);
    final wide = mq.size.width >= 600;
    final grid = CineGrid.of(context);
    final lineH = CineText.style(context, c.typeTitle).height! * (CineText.style(context, c.typeTitle).fontSize ?? 16);
    Widget scroll = CustomScrollView(
      controller: widget.scrollController,
      scrollBehavior: const _HubScrollBehavior(),
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(grid.left, c.space4, grid.right, 0),
            child: _Masthead(masthead: widget.masthead, tab: widget.tab, focus: widget.mastheadFocus, wide: wide),
          ),
        ),
        SliverPersistentHeader(pinned: true, delegate: _TabsDelegate(tab: widget.tab, dx: _dx, extent: hubTabsExtent(context), onSelect: _select)),
        SliverFadeTransition(
          opacity: _fade,
          sliver: HubSlideSliver(
            dx: _dx,
            barColor: c.colorGalley,
            barHeight: lineH * 0.5,
            margin: EdgeInsets.only(left: grid.left, right: grid.right),
            hasPrevious: _hasPrevious,
            hasNext: _hasNext,
            child: SliverMainAxisGroup(slivers: widget.slivers),
          ),
        ),
      ],
    );
    if (widget.onRefresh != null) scroll = CinePullToReprint(onRefresh: widget.onRefresh!, child: scroll);
    scroll = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _start,
      onHorizontalDragUpdate: _update,
      onHorizontalDragEnd: _end,
      onHorizontalDragCancel: _cancel,
      child: scroll,
    );
    return Padding(
      padding: EdgeInsets.only(top: mq.padding.top),
      child: Stack(children: [
        Positioned.fill(child: scroll),
        if (widget.overlay != null) Positioned(left: 0, right: 0, bottom: 0, child: widget.overlay!),
      ],),
    );
  }

  void _select(HubTab t) {
    if (t == widget.tab) return;
    cineFeedback(context, HapticEvent.select, sound: SoundEvent.select);
    if (widget.onSwitch != null) {
      widget.onSwitch!(t);
    } else {
      HubShellScope.maybeOf(context)?.shell.goBranch(t.index);
    }
  }
}

class _HubScrollBehavior extends MaterialScrollBehavior {
  const _HubScrollBehavior();
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;
  @override
  Set<PointerDeviceKind> get dragDevices => {PointerDeviceKind.touch, PointerDeviceKind.stylus, PointerDeviceKind.trackpad};
}

/// The masthead (cinematic 7.27): kicker, level-1 heading revealed on mount, deck and the rule
/// drawn after the letters land. Kicker and deck sit in raised stock over the mood grade.
class _Masthead extends StatelessWidget {
  const _Masthead({required this.masthead, required this.tab, required this.focus, required this.wide});
  final HubMasthead masthead;
  final HubTab tab;
  final FocusNode? focus;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final letters = masthead.title.characters.where((ch) => ch != ' ').length;
    final landed = 120 + (letters < 2 ? 0 : (letters - 1) * math.min(24.0, 560 / (letters - 1))) + 640;
    return Padding(
      padding: EdgeInsets.only(bottom: wide ? 48 : 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        CineStock.raised(Builder(builder: (b) => CineRoleText(masthead.kicker, b.cine.typeKicker, color: b.cine.colorInk45))),
        SizedBox(height: c.space2),
        SetHeading(
          masthead.title,
          id: 'library.${tab.name}.masthead',
          style: CineText.style(context, c.typeMasthead).copyWith(color: c.colorInk100),
          cap: c.typeMasthead.cap,
          level: 1,
          trigger: SetTrigger.mount,
          focusNode: focus,
        ),
        if (masthead.deck.isNotEmpty) ...[
          SizedBox(height: c.space2),
          CineStock.raised(Builder(builder: (b) => CineRoleText(masthead.deck, b.cine.typeDeck, color: b.cine.colorInk60, maxLines: 1, overflow: TextOverflow.ellipsis))),
        ],
        SizedBox(height: c.space4),
        CineRuleDraw(kind: CineRuleKind.heavy, oxford: wide, delay: Duration(milliseconds: landed.round())),
      ],),
    );
  }
}

/// The tab row's pinned height: 48 minimum, growing with text scale, plus the 1 px rule.
double hubTabsExtent(BuildContext context) => math.max(48.0, 16 * cineScale(context) + 24) + 1;

class _TabsDelegate extends SliverPersistentHeaderDelegate {
  _TabsDelegate({required this.tab, required this.dx, required this.extent, required this.onSelect});
  final HubTab tab;
  final ValueListenable<double> dx;
  final double extent;
  final ValueChanged<HubTab> onSelect;

  @override
  double get minExtent => extent;
  @override
  double get maxExtent => extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      ColoredBox(color: context.cine.colorPaper0, child: HubTabRow(tab: tab, dx: dx, onSelect: onSelect));

  @override
  bool shouldRebuild(_TabsDelegate o) => o.tab != tab || o.extent != extent || o.dx != dx;
}

/// `01 SHELF · 02 UPDATES ³ · 03 COLLECTIONS · 04 HISTORY · 05 BOOKMARKS` (cinematic 7.12): the
/// active tab `ink.100` with a 2 px `spot` rule that slides to it over 320 ms (a fade under
/// reduced motion) and follows a hub swipe. Scrolls sideways when it does not fit.
class HubTabRow extends ConsumerStatefulWidget {
  const HubTabRow({super.key, required this.tab, required this.dx, required this.onSelect, this.updatesLoading = false, this.updatesError = false});
  final HubTab tab;
  final ValueListenable<double> dx;
  final ValueChanged<HubTab> onSelect;
  final bool updatesLoading, updatesError;

  @override
  ConsumerState<HubTabRow> createState() => _HubTabRowState();
}

class _HubTabRowState extends ConsumerState<HubTabRow> with SingleTickerProviderStateMixin {
  final _stack = GlobalKey();
  final _keys = [for (final _ in HubTab.values) GlobalKey()];
  List<Rect> _rects = const [];
  late final AnimationController _slide = AnimationController(vsync: this, duration: CineDur.column, value: 1);
  int _from = 0;
  int? _seenIndex;

  @override
  void initState() {
    super.initState();
    _from = widget.tab.index;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = HubShellScope.maybeOf(context)?.currentIndex;
    if (current != null) {
      // A tab that becomes the visible one slides its rule from where the last one stood.
      if (_seenIndex != null && _seenIndex != current && current == widget.tab.index) {
        _from = _seenIndex!;
        final reduced = CineMotion.reduced(context);
        _slide.duration = reduced ? CineDur.reduced : CineDur.column;
        CineMotion.track(MotionName.ruleSlide, reduced ? 150 : 320).end();
        _slide.forward(from: 0);
      }
      _seenIndex = current;
    }
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  void _measure() {
    final row = _stack.currentContext?.findRenderObject() as RenderBox?;
    if (row == null || !row.hasSize) return;
    final r = <Rect>[];
    for (final k in _keys) {
      final b = k.currentContext?.findRenderObject() as RenderBox?;
      if (b == null || !b.hasSize) return;
      r.add(b.localToGlobal(Offset.zero, ancestor: row) & b.size);
    }
    var changed = r.length != _rects.length;
    for (var i = 0; !changed && i < r.length; i++) {
      changed = r[i] != _rects[i];
    }
    if (changed) setState(() => _rects = r);
  }

  CineTextRole _tablet(CineTextRole r) => CineTextRole(
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
    final unread = ref.watch(unreadNotificationCountProvider);
    final reduced = CineMotion.reduced(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _measure();
    });
    final nav = _tablet(c.typeNav);
    final width = MediaQuery.sizeOf(context).width;
    return Container(
      decoration: BoxDecoration(border: Border(bottom: c.ruleHair)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: AnimatedBuilder(
          animation: Listenable.merge([widget.dx, _slide]),
          builder: (context, _) => Stack(key: _stack, children: [
            Row(children: [for (final t in HubTab.values) _tabCell(context, t, nav, unread, reduced)]),
            if (_rects.length == HubTab.values.length) _rule(c, width, reduced),
          ],),
        ),
      ),
    );
  }

  Widget _rule(CineTokens c, double viewport, bool reduced) {
    final active = _rects[widget.tab.index];
    final from = _rects[_from.clamp(0, _rects.length - 1)];
    var rect = reduced ? active : Rect.lerp(from, active, CineCurves.settle.transform(_slide.value))!;
    final dx = widget.dx.value;
    final n = widget.tab.index + (dx < 0 ? 1 : (dx > 0 ? -1 : 0));
    if (dx != 0 && n >= 0 && n < _rects.length) {
      rect = Rect.lerp(rect, _rects[n], (dx.abs() / viewport).clamp(0.0, 1.0))!;
    }
    final fade = reduced ? _slide.value : 1.0;
    return Positioned(
      left: rect.left,
      width: rect.width,
      bottom: 0,
      height: 2,
      child: Opacity(opacity: fade, child: ColoredBox(key: const Key('hub-tab-rule'), color: c.colorSpot)),
    );
  }

  Widget _tabCell(BuildContext context, HubTab t, CineTextRole nav, int unread, bool reduced) {
    final c = context.cine;
    final selected = t == widget.tab;
    final showCount = t == HubTab.updates;
    final count = widget.updatesError ? '!' : (widget.updatesLoading ? '–' : (unread > 0 ? '$unread' : null));
    final size = nav.sizes[1];
    final spoken = folioLabel(t.label, count: showCount && count != null && !widget.updatesError && !widget.updatesLoading ? unread : null);
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: '${t.folio}, $spoken',
      excludeSemantics: true,
      onTap: () => widget.onSelect(t),
      child: CinePressable(
        hit: false,
        onTap: () => widget.onSelect(t),
        builder: (context, st) {
          final ink = selected || st.hovered ? c.colorInk100 : c.colorInk45;
          return Container(
            key: _keys[t.index],
            constraints: const BoxConstraints(minHeight: 48),
            padding: EdgeInsets.symmetric(horizontal: c.space4),
            transform: st.pressed ? Matrix4.translationValues(0, 1, 0) : null,
            child: Center(
              widthFactor: 1,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                CineLit(t.folio, CineFace.plexMono, 12, 16, color: c.colorInk45),
                SizedBox(width: c.space2),
                CineRoleText(t.label, nav, color: ink),
                if (showCount && count != null)
                  Transform.translate(
                    offset: Offset(0, -0.35 * size),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: CineLit(count, CineFace.plexMono, size * 0.72, 12, color: widget.updatesError ? c.colorProof : c.colorInk45),
                    ),
                  ),
              ],),
            ),
          );
        },
      ),
    );
  }
}
