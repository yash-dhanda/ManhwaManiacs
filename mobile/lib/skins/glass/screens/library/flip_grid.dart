import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';

/// Density reflow (glass 4.10, "Density reflow"): each visible tile, keyed by its id, animates from its old rect to its new cell on
/// `springSnappy`. One controller per tile drives a FLIP offset and scale. [snapshot] is called before the density changes; [play]
/// after the new layout has been built.
class FlipRegistry {
  final Map<Object, _FlipTileState> _tiles = {};
  Map<Object, Rect> _before = const {};

  Map<Object, Rect> _rects() => {
        for (final e in _tiles.entries)
          if (e.value._rect() != Rect.zero) e.key: e.value._rect(),
      };

  /// Remembers where every mounted tile is now.
  void snapshot() => _before = _rects();

  /// Animates every tile that was mounted before and still is, from where it was to where it is. [instant] (reduced motion) skips it.
  void play({bool instant = false}) {
    final before = _before;
    _before = const {};
    if (instant || before.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = _rects();
      for (final e in now.entries) {
        final was = before[e.key];
        if (was == null || was == e.value) continue;
        _tiles[e.key]?._from(was, e.value);
      }
    });
  }
}

/// One tile of a [FlipRegistry].
class FlipTile extends ConsumerStatefulWidget {
  const FlipTile({super.key, required this.id, required this.registry, required this.child});
  final Object id;
  final FlipRegistry registry;
  final Widget child;

  @override
  ConsumerState<FlipTile> createState() => _FlipTileState();
}

class _FlipTileState extends ConsumerState<FlipTile> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(vsync: this, value: 1);
  Offset _delta = Offset.zero;
  Size _ratio = const Size(1, 1);

  Rect _rect() {
    final ro = context.findRenderObject();
    return ro is RenderBox && ro.attached && ro.hasSize ? ro.localToGlobal(Offset.zero) & ro.size : Rect.zero;
  }

  @override
  void initState() {
    super.initState();
    widget.registry._tiles[widget.id] = this;
  }

  @override
  void didUpdateWidget(FlipTile old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) {
      widget.registry._tiles.remove(old.id);
      widget.registry._tiles[widget.id] = this;
    }
  }

  @override
  void dispose() {
    if (widget.registry._tiles[widget.id] == this) widget.registry._tiles.remove(widget.id);
    _c.dispose();
    super.dispose();
  }

  void _from(Rect was, Rect now) {
    if (!mounted) return;
    _delta = was.topLeft - now.topLeft;
    _ratio = Size(now.width == 0 ? 1 : was.width / now.width, now.height == 0 ? 1 : was.height / now.height);
    _c.value = 0;
    _c.animateWith(SpringSimulation(springOf(gt.springSnappy), 0, 1, 0));
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (context, child) {
          final t = _c.value;
          if (t == 1) return child!;
          final m = Matrix4.identity()
            ..translateByDouble(_delta.dx * (1 - t), _delta.dy * (1 - t), 0, 1)
            ..scaleByDouble(1 + (_ratio.width - 1) * (1 - t), 1 + (_ratio.height - 1) * (1 - t), 1, 1);
          return Transform(transform: m, child: child);
        },
      );
}
