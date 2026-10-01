import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/scrim.dart';

enum GlassEdge { top, bottom }

/// True while any vertical scroll view moves faster than [kGlassFastScrollPx] per update (a fling). The soft edges drop their
/// backdrop blur then: their content changes every frame, the blur under a 72 % plateau is invisible at that speed, and two
/// full-width blur passes per frame are the cost of every scroll.
final ValueNotifier<bool> glassFastScroll = ValueNotifier(false);
const double kGlassFastScrollPx = 8;

/// Installed once at the Glass root: feeds [glassFastScroll] from every scroll notification below it.
class GlassFastScrollListener extends StatelessWidget {
  const GlassFastScrollListener({super.key, required this.child});
  final Widget child;

  static bool _on(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    if (n is ScrollUpdateNotification) {
      final fast = (n.scrollDelta ?? 0).abs() >= kGlassFastScrollPx;
      if (fast != glassFastScroll.value) glassFastScroll.value = fast;
    } else if (n is ScrollEndNotification && glassFastScroll.value) {
      glassFastScroll.value = false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => NotificationListener<ScrollNotification>(onNotification: _on, child: child);
}

/// The soft scroll edge (glass 7.32, `edgeSoft`): a plateau of `Color(0xB8000000)` from the screen edge to the far edge
/// of its bar group ([plateau] px: top safe-top + 52, or safe-top + 104 while a toast shows; desktop frames 60; bottom
/// safe-bottom + 85, + 56 while the accessory shows), then a 24 px linear fade to transparent, under a `BackdropFilter`
/// blur of sigma 6 (registered as a scrim). [opacity] follows how much content is under it. Under Solid glass and
/// Reduce Transparency it becomes the hard edge (`edgeHard`, no blur).
class GlassScrollEdge extends ConsumerWidget {
  const GlassScrollEdge({super.key, required this.edge, required this.plateau, this.opacity = 1});
  final GlassEdge edge;
  final double plateau;
  final double opacity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final solid = ref.watch(glassA11yProvider.select((a) => a.solid));
    if (opacity <= 0) return const SizedBox.shrink();
    final top = edge == GlassEdge.top;
    const fade = 24.0;
    if (solid) {
      return SizedBox(
        height: plateau + fade,
        child: Opacity(
          opacity: opacity,
          child: DecoratedBox(
            key: const ValueKey('glass-edge-hard'),
            decoration: BoxDecoration(color: GlassColors.edgeHard, border: Border(top: top ? BorderSide.none : BorderSide(color: gt.colorSeparator, width: 0.5), bottom: top ? BorderSide(color: gt.colorSeparator, width: 0.5) : BorderSide.none)),
            child: const SizedBox.expand(),
          ),
        ),
      );
    }
    final total = plateau + fade;
    final stopA = plateau / total;
    final begin = top ? Alignment.topCenter : Alignment.bottomCenter;
    final end = top ? Alignment.bottomCenter : Alignment.topCenter;
    const c = Color(0xB8000000);
    return SizedBox(
      height: total,
      child: Opacity(
        opacity: opacity,
        child: GlassScrimMark(
          label: 'edgeSoft',
          child: ClipRect(
            // No blur on a page covered by another (a push in flight, a page beneath) or during a fling.
            child: ValueListenableBuilder<bool>(
              valueListenable: glassFastScroll,
              child: DecoratedBox(
                key: const ValueKey('glass-edge-soft'),
                decoration: BoxDecoration(gradient: LinearGradient(begin: begin, end: end, colors: const [c, c, Color(0x00000000)], stops: [0, stopA, 1])),
                child: const SizedBox.expand(),
              ),
              builder: (context, fast, child) => BackdropFilter(
                enabled: !fast && (ModalRoute.isCurrentOf(context) ?? true),
                filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The hard edge (glass 7.32, `edgeHard`) under pinned section headers: `Color(0xEB000000)` with a 0.5 px `separator`
/// line.
class GlassHardEdge extends StatelessWidget {
  const GlassHardEdge({super.key, required this.height, this.child});
  final double height;
  final Widget? child;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(color: GlassColors.edgeHard, border: Border(bottom: BorderSide(color: gt.colorSeparator, width: 0.5))),
          child: child,
        ),
      );
}

/// A scroll view with its soft edges: their opacity follows how much content is under them, from the nearest
/// `ScrollNotification`s (top `clamp(pixels / 24, 0, 1)`, bottom `clamp(extentAfter / 24, 0, 1)`).
class GlassScrollEdges extends StatefulWidget {
  const GlassScrollEdges({super.key, required this.child, required this.topPlateau, required this.bottomPlateau, this.showTop = true, this.showBottom = true});
  final Widget child;
  final double topPlateau;
  final double bottomPlateau;
  final bool showTop;
  final bool showBottom;

  @override
  State<GlassScrollEdges> createState() => _GlassScrollEdgesState();
}

class _GlassScrollEdgesState extends State<GlassScrollEdges> {
  double _top = 0;
  double _bottom = 1;

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0) return false;
    final m = n.metrics;
    final top = (m.pixels / 24).clamp(0.0, 1.0);
    final bottom = (m.extentAfter / 24).clamp(0.0, 1.0);
    if (top != _top || bottom != _bottom) {
      setState(() {
      _top = top;
      _bottom = bottom;
    });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: Stack(
          children: [
            Positioned.fill(child: widget.child),
            if (widget.showTop) Positioned(left: 0, right: 0, top: 0, child: IgnorePointer(child: GlassScrollEdge(edge: GlassEdge.top, plateau: widget.topPlateau, opacity: _top))),
            if (widget.showBottom) Positioned(left: 0, right: 0, bottom: 0, child: IgnorePointer(child: GlassScrollEdge(edge: GlassEdge.bottom, plateau: widget.bottomPlateau, opacity: _bottom))),
          ],
        ),
      );
}
