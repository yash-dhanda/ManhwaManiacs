import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_announce.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_menu.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/reorder_announce.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Performs a move from [from] to [to], announces it and fires the haptic. The caller's [onMove]
/// writes `sort_order`.
void cineApplyMove(BuildContext context, {required String title, required int from, required int to, required int count, required void Function(int from, int to) onMove}) {
  onMove(from, to);
  cineFeedback(context, HapticEvent.select);
  cineAnnounce(context, moveAnnouncement(title, to + 1, count));
}

/// The four Move items every reorderable row and poster menu gains; disabled at the ends.
List<CineMenuEntry<Object?>> cineMoveEntries(
  BuildContext context, {
  required String title,
  required int index,
  required int count,
  required void Function(int from, int to) onMove,
}) =>
    [
      for (final m in CineMove.values)
        CineMenuEntry<Object?>(
          label: m.label,
          separatorBefore: m == CineMove.up,
          glyph: switch (m) {
            CineMove.up => CineGlyph.caretUp,
            CineMove.down => CineGlyph.caretDown,
            CineMove.top => CineGlyph.arrowLineUp,
            CineMove.bottom => CineGlyph.arrowLineDown,
          },
          disabled: m.target(index, count) == null,
          onSelected: () {
            final to = m.target(index, count);
            if (to != null) cineApplyMove(context, title: title, from: index, to: to, count: count, onMove: onMove);
          },
        ),
    ];

/// The same four actions as screen-reader custom actions.
Map<CustomSemanticsAction, VoidCallback> cineMoveSemantics(
  BuildContext context, {
  required String title,
  required int index,
  required int count,
  required void Function(int from, int to) onMove,
}) =>
    {
      for (final m in CineMove.values)
        if (m.target(index, count) != null)
          CustomSemanticsAction(label: m.label): () => cineApplyMove(context, title: title, from: index, to: m.target(index, count)!, count: count, onMove: onMove),
    };

/// The trailing `dots-six-vertical` drag handle (a 20 px Regular glyph with a 44 / 48 hit).
class CineDragHandle extends StatelessWidget {
  const CineDragHandle({super.key, required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final hit = Theme.of(context).platform == TargetPlatform.android ? c.hitAndroid : c.hitMin;
    return ReorderableDragStartListener(
      index: index,
      child: Semantics(
        label: 'Reorder',
        child: MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: SizedBox(width: hit, height: hit, child: Center(child: CineGlyphIcon(CineGlyph.dotsSixVertical, color: c.colorInk45))),
        ),
      ),
    );
  }
}

/// A reorderable list on `ReorderableListView.builder` (cinematic 7.16). The lifted row rises 1 px
/// and gains a 1 px `ink.100` outline, no shadow; drop fires `select`; `Alt+Up` / `Alt+Down` move
/// the focused row; [itemBuilder] receives the [CineDragHandle] to put in the row's `handle` slot.
/// Menu moves and key moves shift the siblings in 240 ms `easeSet`.
///
/// ponytail: `ReorderableListView` shifts siblings for a finger drag in its own fixed 200 ms; only
/// programmatic moves use the 240 ms shift. A fork of the list would be needed to match exactly.
class CineReorderableList<T> extends StatefulWidget {
  const CineReorderableList({
    super.key,
    required this.items,
    required this.idOf,
    required this.titleOf,
    required this.itemBuilder,
    required this.onMove,
    this.shrinkWrap = false,
    this.physics,
    this.padding,
  });

  final List<T> items;
  final Object Function(T) idOf;
  final String Function(T) titleOf;

  /// Builds one row; pass [handle] to the row and [moveEntries] to its menu.
  final Widget Function(BuildContext context, T item, int index, Widget handle, List<CineMenuEntry<Object?>> moveEntries, Map<CustomSemanticsAction, VoidCallback> semantics) itemBuilder;
  final void Function(int from, int to) onMove;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsets? padding;

  @override
  State<CineReorderableList<T>> createState() => _CineReorderableListState<T>();
}

class _CineReorderableListState<T> extends State<CineReorderableList<T>> {
  final ValueNotifier<int> _epoch = ValueNotifier(0);

  @override
  void dispose() {
    _epoch.dispose();
    super.dispose();
  }

  void _move(BuildContext ctx, int from, int to) {
    _epoch.value++;
    cineApplyMove(ctx, title: widget.titleOf(widget.items[from]), from: from, to: to, count: widget.items.length, onMove: widget.onMove);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final n = widget.items.length;
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      padding: widget.padding,
      itemCount: n,
      proxyDecorator: (child, index, animation) => Transform.translate(
        offset: const Offset(0, -1),
        child: DecoratedBox(
          decoration: BoxDecoration(color: c.colorPaper1, border: Border.all(color: c.colorInk100)),
          child: Material(type: MaterialType.transparency, child: child),
        ),
      ),
      onReorderItem: (from, to) {
        if (to == from) return;
        cineFeedback(context, HapticEvent.select);
        widget.onMove(from, to);
        cineAnnounce(context, moveAnnouncement(widget.titleOf(widget.items[from]), to + 1, n));
      },
      itemBuilder: (context, i) {
        final item = widget.items[i];
        final title = widget.titleOf(item);
        void move(int from, int to) => _move(context, from, to);
        return _FlipShift(
          key: ValueKey(widget.idOf(item)),
          epoch: _epoch,
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): () {
                final to = CineMove.up.target(i, n);
                if (to != null) move(i, to);
              },
              const SingleActivator(LogicalKeyboardKey.arrowDown, alt: true): () {
                final to = CineMove.down.target(i, n);
                if (to != null) move(i, to);
              },
            },
            child: widget.itemBuilder(
              context,
              item,
              i,
              CineDragHandle(index: i),
              cineMoveEntries(context, title: title, index: i, count: n, onMove: (f, t) => _move(context, f, t)),
              cineMoveSemantics(context, title: title, index: i, count: n, onMove: (f, t) => _move(context, f, t)),
            ),
          ),
        );
      },
    );
  }
}

/// Animates a programmatic position change (FLIP): when [epoch] bumps, remembers where the child
/// was and slides it from there to its new place in 240 ms `easeSet` (instant in reduced motion).
class _FlipShift extends StatefulWidget {
  const _FlipShift({super.key, required this.epoch, required this.child});
  final ValueNotifier<int> epoch;
  final Widget child;

  @override
  State<_FlipShift> createState() => _FlipShiftState();
}

class _FlipShiftState extends State<_FlipShift> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: CineDur.line);
  double? _lastDy;
  double _delta = 0;
  int _seen = 0;

  double? _dy() {
    final box = context.findRenderObject() as RenderBox?;
    return box != null && box.attached && box.hasSize ? box.localToGlobal(Offset.zero).dy : null;
  }

  @override
  void initState() {
    super.initState();
    _seen = widget.epoch.value;
    WidgetsBinding.instance.addPostFrameCallback((_) => _lastDy = mounted ? _dy() : null);
  }

  @override
  void didUpdateWidget(_FlipShift old) {
    super.didUpdateWidget(old);
    final was = _lastDy;
    if (widget.epoch.value != _seen) {
      _seen = widget.epoch.value;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final now = _dy();
        if (was != null && now != null && (was - now).abs() > 0.5 && !CineMotion.reduced(context)) {
          setState(() => _delta = was - now);
          _c.value = 0;
          _c.animateTo(1, curve: CineCurves.easeSet);
        }
        _lastDy = now;
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _lastDy = mounted ? _dy() : null);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (_, child) => Transform.translate(offset: Offset(0, _delta * (1 - _c.value)), child: child),
      );
}
