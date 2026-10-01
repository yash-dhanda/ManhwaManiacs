import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/reader/engine/page_sample.dart';

export 'package:manhwamaniacs/features/reader/engine/page_sample.dart' show PageSample, PageSampleSource;

enum PageBand { top, mid, bottom }

/// The `Lb` sources of glass 2.1.7: the relative luminance of what is directly behind a surface.
abstract final class Lb {
  /// A backdrop that is unknown (first frame, palette not loaded): dim 0.64, easing down once a sample lands.
  static const double unknown = 1.0;

  /// The field term: the owning palette's mean `l` times the field opacity, plus 0.02.
  static double field(double l, double opacity) => l * opacity + 0.02;

  /// A surface over a cover reads its brightest part, not its mean.
  static double cover(double lMax) => lMax;

  /// The maximum of the listed bands of a reader page sample.
  static double page(PageSample s, {Set<PageBand> bands = const {PageBand.top, PageBand.mid, PageBand.bottom}}) {
    var v = 0.0;
    if (bands.contains(PageBand.top)) v = math.max(v, s.pTop);
    if (bands.contains(PageBand.mid)) v = math.max(v, s.pMid);
    if (bands.contains(PageBand.bottom)) v = math.max(v, s.pBottom);
    return v;
  }

  /// A novel paper's own luminance.
  static double paper(double luminance) => luminance;

  /// A bar over scrolling content: `max(field term, lItems)`.
  static double bar(double fieldTerm, double lItems) => math.max(fieldTerm, lItems);
}

/// Items report their `lMax` here; bars ask what sits under them. Recomputes at most every 100 ms while
/// scrolling and holds while the scroll velocity exceeds 3000 px/s.
class GlassLbScope extends StatefulWidget {
  const GlassLbScope({super.key, required this.child});
  final Widget child;

  static GlassLbScopeState? maybeOf(BuildContext context) => context.findAncestorStateOfType<GlassLbScopeState>();

  @override
  State<GlassLbScope> createState() => GlassLbScopeState();
}

class GlassLbScopeState extends State<GlassLbScope> {
  static const Duration minInterval = Duration(milliseconds: 100);
  static const double holdVelocity = 3000;

  final Set<_GlassLbItemState> _items = {};
  final ValueNotifier<int> tick = ValueNotifier(0);
  Duration? _lastEvent;
  Duration _lastCompute = Duration.zero;

  /// The largest `lMax` among registered items whose global rects intersect [rect].
  double lItemsUnder(Rect rect) {
    var m = 0.0;
    for (final i in _items) {
      final r = i.globalRect();
      if (r != null && r.overlaps(rect)) m = math.max(m, i.widget.lMax);
    }
    return m;
  }

  bool _onScroll(ScrollNotification n) {
    final now = Duration(microseconds: DateTime.now().microsecondsSinceEpoch);
    if (n is ScrollUpdateNotification) {
      final dt = _lastEvent == null ? 0 : (now - _lastEvent!).inMicroseconds / 1e6;
      final v = dt > 0 ? ((n.scrollDelta ?? 0).abs() / dt) : 0.0;
      _lastEvent = now;
      if (v <= holdVelocity && now - _lastCompute >= minInterval) {
        _lastCompute = now;
        tick.value++;
      }
    } else if (n is ScrollEndNotification) {
      _lastEvent = null;
      _lastCompute = now;
      tick.value++;
    }
    return false;
  }

  @override
  void dispose() {
    tick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => NotificationListener<ScrollNotification>(onNotification: _onScroll, child: widget.child);
}

/// A poster or row: reports its `lMax` to the nearest [GlassLbScope].
class GlassLbItem extends StatefulWidget {
  const GlassLbItem({super.key, required this.lMax, required this.child});
  final double lMax;
  final Widget child;

  @override
  State<GlassLbItem> createState() => _GlassLbItemState();
}

class _GlassLbItemState extends State<GlassLbItem> {
  GlassLbScopeState? _scope;

  Rect? globalRect() {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope?._items.remove(this);
    _scope = GlassLbScope.maybeOf(context);
    _scope?._items.add(this);
  }

  @override
  void dispose() {
    _scope?._items.remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Builds a bar with the live `Lb` under its rect: `Lb.bar(fieldTerm, lItems)`, refreshed on the scope's tick.
class GlassLbBar extends StatefulWidget {
  const GlassLbBar({super.key, required this.fieldTerm, required this.builder});
  final double fieldTerm;
  final Widget Function(BuildContext context, double lb) builder;

  @override
  State<GlassLbBar> createState() => _GlassLbBarState();
}

class _GlassLbBarState extends State<GlassLbBar> {
  GlassLbScopeState? _scope;
  double _lItems = 0;

  void _refresh() {
    final box = context.findRenderObject();
    if (_scope == null || box is! RenderBox || !box.attached || !box.hasSize) return;
    final v = _scope!.lItemsUnder(box.localToGlobal(Offset.zero) & box.size);
    if (v != _lItems) setState(() => _lItems = v);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope?.tick.removeListener(_refresh);
    _scope = GlassLbScope.maybeOf(context);
    _scope?.tick.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refresh();
    });
  }

  @override
  void dispose() {
    _scope?.tick.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, Lb.bar(widget.fieldTerm, _lItems));
}
