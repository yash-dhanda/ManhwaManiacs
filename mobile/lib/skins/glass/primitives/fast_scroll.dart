import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// Lists over this many rows get a fast-scroll strip (chapter lists, the source catalogue).
const int kFastScrollMinRows = 200;

/// The fast-scroll strip (glass 7.32): a `hitMin`-wide drag strip on the trailing edge; dragging it shows a `glassThin`
/// capsule bubble at the thumb with the chapter number or the first letter ([labelAt]), with a `select` tick per 10
/// chapters; `Semantics(slider: true, value: "Chapter 120")` with increase and decrease actions that jump by 10 rows.
class GlassFastScroll extends ConsumerStatefulWidget {
  const GlassFastScroll({super.key, required this.controller, required this.itemCount, required this.labelAt, required this.child, this.rowExtent = 56, this.semanticsLabel = 'Fast scroll', this.tickEvery = 10});
  final ScrollController controller;
  final int itemCount;
  final String Function(int index) labelAt;
  final Widget child;

  /// The fixed row height, to turn a scroll offset into a row index.
  final double rowExtent;
  final String semanticsLabel;
  final int tickEvery;

  @override
  ConsumerState<GlassFastScroll> createState() => _GlassFastScrollState();
}

class _GlassFastScrollState extends ConsumerState<GlassFastScroll> {
  bool _drag = false;
  int _index = 0;
  double _fraction = 0;

  int _rowOf(double fraction) => (fraction * (widget.itemCount - 1)).round().clamp(0, widget.itemCount - 1);

  void _jumpRows(int rows) {
    final i = (_currentIndex() + rows).clamp(0, widget.itemCount - 1);
    _goTo(i);
  }

  int _currentIndex() {
    if (!widget.controller.hasClients) return 0;
    return (widget.controller.offset / widget.rowExtent).round().clamp(0, widget.itemCount - 1);
  }

  void _goTo(int i) {
    if (!widget.controller.hasClients) return;
    final max = widget.controller.position.maxScrollExtent;
    widget.controller.jumpTo((i * widget.rowExtent).clamp(0.0, max));
    setState(() => _index = i);
  }

  void _at(double y, double height) {
    _fraction = (y / height).clamp(0.0, 1.0);
    final i = _rowOf(_fraction);
    if (i ~/ widget.tickEvery != _index ~/ widget.tickEvery) glassFire(ref, HapticEvent.select);
    _goTo(i);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount <= kFastScrollMinRows) return widget.child;
    final hit = GlassFrame.hitMin(context);
    return Stack(
      children: [
        Positioned.fill(child: widget.child),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: hit,
          child: LayoutBuilder(
            builder: (context, c) => Semantics(
              slider: true,
              excludeSemantics: true,
              label: widget.semanticsLabel,
              value: widget.labelAt(_drag ? _index : _currentIndex()),
              increasedValue: widget.labelAt((_currentIndex() + 10).clamp(0, widget.itemCount - 1)),
              decreasedValue: widget.labelAt((_currentIndex() - 10).clamp(0, widget.itemCount - 1)),
              onIncrease: () => _jumpRows(10),
              onDecrease: () => _jumpRows(-10),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragStart: (d) {
                  setState(() => _drag = true);
                  _at(d.localPosition.dy, c.maxHeight);
                },
                onVerticalDragUpdate: (d) => _at(d.localPosition.dy, c.maxHeight),
                onVerticalDragEnd: (_) => setState(() => _drag = false),
                onVerticalDragCancel: () => setState(() => _drag = false),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const SizedBox.expand(),
                    if (_drag)
                      Positioned(
                        right: hit + 4,
                        top: math.max(0, _fraction * c.maxHeight - 18),
                        child: SkinGlass(
                          key: const ValueKey('glass-fast-scroll-bubble'),
                          size: Size(math.max(56, 20.0 + widget.labelAt(_index).length * 12), 36),
                          tier: GlassTierId.t2,
                          layer: GlassLayerKind.hud,
                          debugLabel: 'GlassFastScrollBubble',
                          child: Center(child: GlassText(widget.labelAt(_index), role: gt.typeSubhead, onGlass: true)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
