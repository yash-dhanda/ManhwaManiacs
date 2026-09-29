import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_reorderable_grid_view/widgets/widgets.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_announce.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_menu.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/reorder_announce.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_reorderable_list.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// A poster wall you reorder by dragging (cinematic 7.16) on `flutter_reorderable_grid_view` 5.7.0
/// (`ReorderableBuilder` over a `GridView`). A finger drag starts after the 450 ms long-press with
/// a 1 px `ink.100` outline lift; drop fires `select` and announces. [itemBuilder] gets a
/// [CineWallHandle] for `CinePoster.dragHandle`, the Move menu entries and the screen-reader
/// actions; the same `onMove(from, to)` as the list.
///
/// ponytail: the package lifts with its own 1.05 scale feedback; the outline is added around the
/// dragged child via `dragChildBoxDecoration`.
class CineReorderableWall<T> extends StatefulWidget {
  const CineReorderableWall({
    super.key,
    required this.items,
    required this.idOf,
    required this.titleOf,
    required this.itemBuilder,
    required this.onMove,
    this.crossAxisCount = 3,
    this.aspectRatio = 0.55,
    this.spacing = 12,
    this.scrollController,
    this.shrinkWrap = false,
    this.physics,
  });

  final List<T> items;
  final Object Function(T) idOf;
  final String Function(T) titleOf;
  final Widget Function(BuildContext context, T item, int index, Widget handle, List<CineMenuEntry<Object?>> moveEntries, Map<CustomSemanticsAction, VoidCallback> semantics) itemBuilder;
  final void Function(int from, int to) onMove;
  final int crossAxisCount;
  final double aspectRatio, spacing;
  final ScrollController? scrollController;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  State<CineReorderableWall<T>> createState() => _CineReorderableWallState<T>();
}

/// The bottom-left handle glyph on a poster: decorative here, the drag is the long-press.
class CineWallHandle extends StatelessWidget {
  const CineWallHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Container(
      color: const Color(0xFF000000),
      padding: const EdgeInsets.all(4),
      child: CineGlyphIcon(CineGlyph.dotsSixVertical, color: c.colorInk100),
    );
  }
}

class _CineReorderableWallState<T> extends State<CineReorderableWall<T>> {
  late final ScrollController _sc = widget.scrollController ?? ScrollController();

  @override
  void dispose() {
    if (widget.scrollController == null) _sc.dispose();
    super.dispose();
  }

  void _moved(int from, int to) {
    final n = widget.items.length;
    final title = widget.titleOf(widget.items[from]);
    widget.onMove(from, to);
    cineFeedback(context, HapticEvent.select);
    cineAnnounce(context, moveAnnouncement(title, to + 1, n));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final n = widget.items.length;
    final children = <Widget>[
      for (var i = 0; i < n; i++)
        KeyedSubtree(
          key: ValueKey(widget.idOf(widget.items[i])),
          child: widget.itemBuilder(
            context,
            widget.items[i],
            i,
            const CineWallHandle(),
            cineMoveEntries(context, title: widget.titleOf(widget.items[i]), index: i, count: n, onMove: _moved),
            cineMoveSemantics(context, title: widget.titleOf(widget.items[i]), index: i, count: n, onMove: _moved),
          ),
        ),
    ];
    return ReorderableBuilder<Widget>(
      scrollController: _sc,
      longPressDelay: const Duration(milliseconds: 450),
      dragChildBoxDecoration: BoxDecoration(border: Border.all(color: c.colorInk100)),
      onReorderPositions: (moves) {
        for (final m in moves) {
          _moved(m.oldIndex, m.newIndex);
        }
      },
      children: children,
      builder: (kids) => GridView(
        key: const Key('cine-wall-grid'),
        controller: _sc,
        shrinkWrap: widget.shrinkWrap,
        physics: widget.physics,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.crossAxisCount,
          childAspectRatio: widget.aspectRatio,
          mainAxisSpacing: widget.spacing,
          crossAxisSpacing: widget.spacing,
        ),
        children: kids,
      ),
    );
  }
}
