import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/drag_owner.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// One tab of a [GlassTabPager]: its label and the state of its panel (glass 7.13 states).
class GlassTabSpec {
  const GlassTabSpec(this.label, {this.disabled = false, this.loading = false, this.errorText, this.onRetry});
  final String label;
  final bool disabled;

  /// The panel shows its skeleton; the tab still works.
  final bool loading;

  /// The panel shows its error block.
  final String? errorText;
  final VoidCallback? onRetry;
}

/// Exposed so `mobile/29`'s full-width iOS back swipe loses to the pager until it is on its first panel.
class GlassTabPagerController {
  GlassTabPagerController({int initialIndex = 0}) : pages = PageController(initialPage: initialIndex) {
    isAtFirstPanel = ValueNotifier(initialIndex == 0);
    pages.addListener(_onPage);
  }

  final PageController pages;
  late final ValueNotifier<bool> isAtFirstPanel;

  void _onPage() {
    if (!pages.hasClients) return;
    final first = (pages.page ?? 0) < 0.01;
    if (first != isAtFirstPanel.value) isAtFirstPanel.value = first;
  }

  void dispose() {
    pages.removeListener(_onPage);
    pages.dispose();
    isAtFirstPanel.dispose();
  }
}

/// In-page tabs over a pager (glass 7.13): a scrollable strip with a `glassFilm` clear capsule that slides and
/// stretches between the labels while a finger drags a panel, over a `PageView` with `BouncingScrollPhysics`.
class GlassTabPager extends ConsumerStatefulWidget {
  const GlassTabPager({super.key, required this.tabs, required this.panels, this.controller, this.onChanged, this.initialIndex = 0, this.locked = false})
      : assert(tabs.length == panels.length && tabs.length >= 2);

  final List<GlassTabSpec> tabs;
  final List<Widget> panels;
  final GlassTabPagerController? controller;
  final ValueChanged<int>? onChanged;
  final int initialIndex;

  /// The panel owns horizontal drags (select-mode range paint, a pinch): the pager stops swiping; the strip still switches.
  final bool locked;

  @override
  ConsumerState<GlassTabPager> createState() => _GlassTabPagerState();
}

class _GlassTabPagerState extends ConsumerState<GlassTabPager> {
  late final GlassTabPagerController _c = widget.controller ?? GlassTabPagerController(initialIndex: widget.initialIndex);
  late final bool _owns = widget.controller == null;
  final ScrollController _strip = ScrollController();
  final List<FocusNode> _focus = [];
  late int _index = widget.initialIndex;
  double _lastPage = 0;
  Duration _lastT = Duration.zero;
  double _velocity = 0;

  PageController get _pages => _c.pages;

  @override
  void initState() {
    super.initState();
    _focus.addAll(List.generate(widget.tabs.length, (i) => FocusNode(debugLabel: 'GlassTab$i')));
    _pages.addListener(_onPage);
    _lastPage = widget.initialIndex.toDouble();
  }

  @override
  void dispose() {
    _pages.removeListener(_onPage);
    if (_owns) _c.dispose();
    for (final f in _focus) {
      f.dispose();
    }
    _strip.dispose();
    super.dispose();
  }

  void _onPage() {
    if (!_pages.hasClients) return;
    final p = _pages.page ?? 0;
    final now = WidgetsBinding.instance.currentSystemFrameTimeStamp;
    final dt = (now - _lastT).inMicroseconds / 1e6;
    if (dt > 0) _velocity = (p - _lastPage) / dt;
    _lastPage = p;
    _lastT = now;
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0) return false;
    if (n is ScrollEndNotification && _pages.hasClients) {
      final i = (_pages.page ?? 0).round();
      _velocity = 0;
      if (i != _index) {
        setState(() => _index = i);
        glassFire(ref, HapticEvent.select);
        widget.onChanged?.call(i);
        _reveal(i);
      }
    }
    return false;
  }

  void _select(int i) {
    if (i < 0 || i >= widget.tabs.length || widget.tabs[i].disabled) return;
    final reduced = ref.read(glassMotionPrefsProvider).reduced;
    if (i != _index) {
      setState(() => _index = i);
      glassFire(ref, HapticEvent.select);
      widget.onChanged?.call(i);
      _reveal(i);
    }
    if (reduced) {
      _pages.jumpToPage(i);
    } else {
      _pages.animateToPage(i, duration: const Duration(milliseconds: 414), curve: SpringCurve(gt.springSettle));
    }
  }

  void _step(int dir) {
    var i = _index + dir;
    while (i >= 0 && i < widget.tabs.length && widget.tabs[i].disabled) {
      i += dir;
    }
    _select(i);
    if (i >= 0 && i < _focus.length) _focus[i].requestFocus();
  }

  void _reveal(int i) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_strip.hasClients) return;
      final l = _layout(context);
      final x = l.lefts[i];
      final w = l.widths[i];
      final view = _strip.position.viewportDimension;
      final target = (x + w / 2 - view / 2).clamp(0.0, _strip.position.maxScrollExtent);
      _strip.animateTo(target, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  ({List<double> lefts, List<double> widths}) _layout(BuildContext context) {
    final lefts = <double>[];
    final widths = <double>[];
    var x = 8.0;
    for (final t in widget.tabs) {
      final w = measureText(context, t.label, roleStyle(context, gt.typeSubhead, onGlass: true, wght: 620, maxScale: 1.5)).width + 32;
      lefts.add(x);
      widths.add(math.max(w, GlassFrame.hitMin(context)));
      x += widths.last + 4;
    }
    return (lefts: lefts, widths: widths);
  }

  @override
  Widget build(BuildContext context) {
    final reduced = ref.watch(glassMotionPrefsProvider.select((m) => m.reduced));
    final l = _layout(context);
    final total = l.lefts.last + l.widths.last + 8;
    final hit = GlassFrame.hitMin(context);
    final stripHeight = math.max(hit, 44.0);

    Widget indicator() => AnimatedBuilder(
          animation: _pages,
          builder: (context, _) {
            final p = _pages.hasClients ? (_pages.page ?? _index.toDouble()) : _index.toDouble();
            final i0 = p.floor().clamp(0, widget.tabs.length - 1);
            final i1 = math.min(i0 + 1, widget.tabs.length - 1);
            final f = (p - i0).clamp(0.0, 1.0);
            var left = l.lefts[i0] + (l.lefts[i1] - l.lefts[i0]) * f;
            var width = l.widths[i0] + (l.widths[i1] - l.widths[i0]) * f;
            final stretch = 1 + math.min(_velocity.abs() / 2000, 0.25);
            if (f > 0 && f < 1) {
              final c = left + width / 2;
              width *= stretch;
              left = c - width / 2;
            }
            if (reduced) {
              left = l.lefts[_index];
              width = l.widths[_index];
            }
            return Positioned(
              left: left,
              width: width,
              top: (stripHeight - 32) / 2,
              height: 32,
              child: IgnorePointer(
                child: KeyedSubtree(
                  key: ValueKey('glass-tab-indicator-${reduced ? _index : 'live'}'),
                  child: const SkinGlass(
                    key: ValueKey('glass-tab-capsule'),
                    twin: GlassTwin.content,
                    finish: GlassFinishKind.clear,
                    tier: GlassTierId.t1,
                    debugLabel: 'GlassTabIndicator',
                    child: SizedBox.expand(),
                  ),
                ),
              ),
            );
          },
        );

    final strip = SizedBox(
      height: stripHeight,
      child: SingleChildScrollView(
        controller: _strip,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: SizedBox(
          width: math.max(total, MediaQuery.sizeOf(context).width),
          height: stripHeight,
          child: Stack(
            children: [
              indicator(),
              for (var i = 0; i < widget.tabs.length; i++)
                Positioned(
                  left: l.lefts[i],
                  width: l.widths[i],
                  top: 0,
                  height: stripHeight,
                  child: _TabButton(
                    spec: widget.tabs[i],
                    index: i,
                    count: widget.tabs.length,
                    selected: i == _index,
                    focusNode: _focus[i],
                    onTap: () => _select(i),
                    onArrow: _step,
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return GlassDragOwner(
      kind: GlassDragOwnerKind.pager,
      atLeadingEdge: _c.isAtFirstPanel,
      child: CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.bracketLeft): () => _step(-1),
        const SingleActivator(LogicalKeyboardKey.bracketRight): () => _step(1),
      },
      child: Focus(
        canRequestFocus: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            strip,
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScroll,
                child: PageView(
                  controller: _pages,
                  physics: widget.locked ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
                  onPageChanged: (_) {},
                  children: [
                    for (var i = 0; i < widget.panels.length; i++) Semantics(container: true, explicitChildNodes: true, child: _panel(i)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _panel(int i) {
    final t = widget.tabs[i];
    if (t.errorText != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            GlassBacking(size: 28, child: GlyphIcon(GlassGlyph.warningCircle, color: gt.colorDanger)),
            const SizedBox(height: 8),
            GlassText(t.errorText!, role: gt.typeCallout, onGlass: true, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            GlassButton(label: 'Retry', onPressed: t.onRetry, size: GlassButtonSize.small),
          ],),
        ),
      );
    }
    if (t.loading) {
      return GlassSkeletonGroup(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [for (var k = 0; k < 4; k++) Padding(padding: const EdgeInsets.only(bottom: 12), child: GlassSkeleton(height: 44, radius: 20, index: k))]),
        ),
      );
    }
    return widget.panels[i];
  }
}

class _TabButton extends ConsumerWidget {
  const _TabButton({required this.spec, required this.index, required this.count, required this.selected, required this.focusNode, required this.onTap, required this.onArrow});
  final GlassTabSpec spec;
  final int index;
  final int count;
  final bool selected;
  final FocusNode focusNode;
  final VoidCallback onTap;
  final ValueChanged<int> onArrow;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Focus(
        onKeyEvent: (n, e) {
          if (e is! KeyDownEvent) return KeyEventResult.ignored;
          if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
            onArrow(1);
            return KeyEventResult.handled;
          }
          if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
            onArrow(-1);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        skipTraversal: true,
        child: GlassPressable(
          focusNode: focusNode,
          material: GlassMaterial.content,
          growth: GlassGrowth.light,
          sink: 0.96,
          shape: const GlassShape.superellipse(16),
          enabled: !spec.disabled,
          onTap: onTap,
          semanticsLabel: '${spec.label}, tab ${index + 1} of $count',
          semanticsSelected: selected,
          disabledReason: spec.disabled ? '${spec.label} is not available' : null,
          builder: (context, info) => DecoratedBox(
            decoration: BoxDecoration(
              color: info.states.hovered && !selected && !spec.disabled ? gt.colorFill4 : const Color(0x00000000),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: GlassText(
                spec.label,
                role: gt.typeSubhead,
                wght: 620,
                maxScale: 1.5,
                onGlass: true,
                color: spec.disabled ? gt.colorLabel4 : (selected ? gt.colorLabel1 : gt.colorLabel2),
              ),
            ),
          ),
        ),
      );
}
