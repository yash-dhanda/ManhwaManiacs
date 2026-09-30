import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart' show SpringSimulation;
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/context_menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart' show GlassButtonIcon;
import 'package:manhwamaniacs/skins/glass/primitives/glyphs_more.dart';
import 'package:manhwamaniacs/skins/glass/primitives/icon_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/reorder_controller.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/reorder_math.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/swipe_row.dart' show GlassSwipeSemantics;
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/spring_value.dart';

enum GlassReorderLayout { list, grid }

/// What an item builder learns about its slot.
class GlassReorderItemInfo {
  const GlassReorderItemInfo({required this.dragging, required this.handle, required this.moveEntries});

  /// True for the lifted copy drawn under the finger and for the context preview.
  final bool dragging;

  /// The trailing `dots-six-vertical` handle (hit `hitMin`, label "Reorder {name}"): a press lifts the row at once.
  final Widget Function() handle;

  /// "Move up", "Move down", "Move to top" and "Move to bottom" (WCAG 2.5.7), for the row's own menu.
  final List<GlassMenuEntry> moveEntries;
}

/// A reorderable list or grid (glass 7.35). Lift from the context preview (a 450 ms press) or the handle, drag with
/// neighbours parting on `springSnappy`, edge auto-scroll up to 1,200 px/s, keyboard `Alt+arrows`, and four Move actions
/// in the menu and the semantics actions. Screens write the order in [onReorder].
class GlassReorderList<T> extends ConsumerStatefulWidget {
  const GlassReorderList({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.onReorder,
    required this.nameOf,
    this.layout = GlassReorderLayout.list,
    this.columns = 2,
    this.spacing = 12,
    this.menuEntries,
    this.controller,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item, int index, GlassReorderItemInfo info) itemBuilder;
  final void Function(int from, int to) onReorder;
  final String Function(T item) nameOf;
  final GlassReorderLayout layout;
  final int columns;
  final double spacing;

  /// The row's own context-menu entries; the Move entries follow them.
  final List<GlassMenuEntry> Function(T item, int index)? menuEntries;
  final GlassReorderController? controller;

  @override
  ConsumerState<GlassReorderList<T>> createState() => _GlassReorderListState<T>();
}

class _Signal extends ChangeNotifier {
  void fire() => notifyListeners();
}

class _GlassReorderListState<T> extends ConsumerState<GlassReorderList<T>> with TickerProviderStateMixin implements GlassReorderHost {
  final Map<int, GlobalKey> _slots = {};
  final Map<int, FocusNode> _focus = {};
  final _Signal _closeMenu = _Signal();
  final ValueNotifier<Offset> _pos = ValueNotifier(Offset.zero);
  late final AnimationController _drop;
  late final AnimationController _fade;
  Ticker? _ticker;
  Duration _last = Duration.zero;
  OverlayEntry? _entry;
  int? _drag;
  int _target = 0;
  Offset _grab = Offset.zero;
  Offset _pointer = Offset.zero;
  int? _pointerId;
  bool _routed = false;
  Size _liftSize = Size.zero;
  Rect _liftRect = Rect.zero;

  // long-press bookkeeping
  Timer? _pressTimer;
  int? _pressIndex;
  Offset _downPos = Offset.zero;
  int? _menuIndex;

  bool get _reduced => ref.read(glassMotionPrefsProvider).reduced;
  bool get _grid => widget.layout == GlassReorderLayout.grid;

  @override
  bool get lifted => _drag != null;

  @override
  void initState() {
    super.initState();
    _drop = AnimationController.unbounded(vsync: this);
    _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    widget.controller?.attach(this);
  }

  @override
  void didUpdateWidget(GlassReorderList<T> old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?.detach(this);
      widget.controller?.attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller?.detach(this);
    _pressTimer?.cancel();
    _endPointer();
    _ticker?.dispose();
    _entry?.remove();
    _entry?.dispose();
    _pos.dispose();
    _drop.dispose();
    _fade.dispose();
    _closeMenu.dispose();
    for (final n in _focus.values) {
      n.dispose();
    }
    super.dispose();
  }

  GlobalKey _slot(int i) => _slots.putIfAbsent(i, GlobalKey.new);
  FocusNode _node(int i) => _focus.putIfAbsent(i, () => FocusNode(debugLabel: 'GlassReorder $i'));

  Rect? _slotRect(int i) {
    final ro = _slots[i]?.currentContext?.findRenderObject();
    return ro is RenderBox && ro.attached && ro.hasSize ? ro.localToGlobal(Offset.zero) & ro.size : null;
  }

  List<Rect> _rects() => [for (var i = 0; i < widget.items.length; i++) _slotRect(i) ?? Rect.zero];

  // ---- lift ----

  void _openMenu(int i) {
    final rect = _slotRect(i);
    if (rect == null || _drag != null) return;
    _menuIndex = i;
    final item = widget.items[i];
    var fwd = Offset.zero;
    unawaited(showGlassContextMenu(
      context,
      sourceRect: rect,
      kind: GlassPreviewKind.row,
      title: widget.nameOf(item),
      closeSignal: _closeMenu,
      onClosed: () => _menuIndex = null,
      preview: SizedBox(width: rect.width, height: rect.height, child: IgnorePointer(child: widget.itemBuilder(context, item, i, _info(i, dragging: true)))),
      entries: [...?widget.menuEntries?.call(item, i), ..._moveEntries(i)],
      onPreviewDrag: (d) {
        fwd += d.delta;
        if (fwd.distance > 10 && _drag == null) liftFromPreview(i, d.globalPosition);
      },
    ),);
  }

  @override
  void liftFromPreview(int index, Offset globalPosition) => _lift(index, globalPosition);

  void _lift(int index, Offset pos, {int? pointer}) {
    if (_drag != null || index < 0 || index >= widget.items.length) return;
    final rects = _rects();
    final r = rects[index];
    if (r.isEmpty) return;
    _pressTimer?.cancel();
    if (_menuIndex != null) _closeMenu.fire();
    _drag = index;
    _target = index;
    _pointer = pos;
    _pointerId = pointer;
    _grab = pos - r.topLeft;
    _liftRect = r;
    _liftSize = r.size;
    _pos.value = r.topLeft;
    _fade.value = 0;
    glassFire(ref, HapticEvent.reorderLift);
    final overlay = Overlay.of(context, rootOverlay: true);
    _entry = OverlayEntry(builder: _liftedBuilder);
    overlay.insert(_entry!);
    _routed = true;
    GestureBinding.instance.pointerRouter.addGlobalRoute(_route);
    _ticker = createTicker(_tick)..start();
    _last = Duration.zero;
    setState(() {});
  }

  Widget _liftedBuilder(BuildContext context) {
    final i = _drag;
    if (i == null || i >= widget.items.length) return const SizedBox.shrink();
    return ValueListenableBuilder<Offset>(
      valueListenable: _pos,
      builder: (context, p, _) => Positioned(
        left: p.dx,
        top: p.dy,
        width: _liftSize.width,
        height: _liftSize.height,
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _fade,
            builder: (context, child) => Opacity(opacity: 1 - _fade.value, child: child),
            child: SpringValue(
              value: 1,
              spring: gt.springPress,
              builder: (context, v, _) => Transform.scale(
                key: const ValueKey('glass-reorder-lifted'),
                scale: _reduced ? 1.03 : 1.02 + 0.01 * v.clamp(0.0, 1.5),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(gt.radiusMd),
                    border: Border.all(color: const Color(0x4DFFFFFF), width: 0.5),
                    boxShadow: const [BoxShadow(color: Color(0x8C000000), offset: Offset(0, 12), blurRadius: 28)],
                    color: gt.colorSurface1,
                  ),
                  child: ClipRSuperellipse(borderRadius: BorderRadius.circular(gt.radiusMd), child: widget.itemBuilder(context, widget.items[i], i, _info(i, dragging: true))),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _route(PointerEvent e) {
    if (_drag == null) return;
    _pointerId ??= e is PointerMoveEvent ? e.pointer : null;
    if (e.pointer != _pointerId) return;
    if (e is PointerMoveEvent) {
      _pointer = e.position;
      _pos.value = _pointer - _grab;
      _retarget();
    } else if (e is PointerUpEvent || e is PointerCancelEvent) {
      unawaited(_dropNow());
    }
  }

  void _retarget() {
    final rects = _rects();
    final t = reorderTarget(rects, _pointer, grid: _grid);
    if (t != _target) {
      _target = t;
      glassFire(ref, HapticEvent.reorderPass);
      setState(() {});
    }
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero ? 0.0 : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    final scrollable = Scrollable.maybeOf(context);
    final ro = scrollable?.context.findRenderObject();
    if (scrollable == null || ro is! RenderBox || !ro.attached) return;
    final top = ro.localToGlobal(Offset.zero).dy;
    final v = edgeScrollVelocity(_pointer.dy, top, top + ro.size.height);
    if (v == 0 || dt == 0) return;
    final pos = scrollable.position;
    final next = (pos.pixels + v * dt).clamp(pos.minScrollExtent, pos.maxScrollExtent);
    if (next != pos.pixels) {
      pos.jumpTo(next);
      WidgetsBinding.instance.addPostFrameCallback((_) => mounted && _drag != null ? _retarget() : null);
    }
  }

  void _endPointer() {
    if (!_routed) return;
    _routed = false;
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_route);
  }

  Future<void> _dropNow() async {
    final from = _drag;
    if (from == null) return;
    final to = _target;
    _endPointer();
    _ticker?.stop();
    glassFire(ref, HapticEvent.reorderDrop);
    final dest = _slotRect(to)?.topLeft ?? _liftRect.topLeft;
    if (_reduced) {
      await _fade.forward();
    } else {
      final start = _pos.value;
      void follow() => _pos.value = Offset.lerp(start, dest, _drop.value) ?? dest;
      _drop.value = 0;
      _drop.addListener(follow);
      final done = Completer<void>();
      void watch() {
        if ((_drop.value - 1).abs() < 0.002 && !done.isCompleted) done.complete();
      }

      _drop.addListener(watch);
      unawaited(_drop.animateWith(SpringSimulation(springOf(gt.springSnappy), 0, 1, 0)));
      await done.future.timeout(const Duration(milliseconds: 800), onTimeout: () {});
      _drop.removeListener(follow);
      _drop.removeListener(watch);
    }
    if (!mounted) return;
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
    _drag = null;
    setState(() {});
    if (to != from) widget.onReorder(from, to);
  }

  // ---- keyboard, menu, semantics ----

  void _move(int i, ReorderMove m) {
    final to = movedIndex(i, m, widget.items.length);
    if (to == i) return;
    final name = widget.nameOf(widget.items[i]);
    widget.onReorder(i, to);
    announceAssertive(context, reorderAnnouncement(name, to + 1, widget.items.length));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _node(to).requestFocus();
    });
  }

  List<GlassMenuEntry> _moveEntries(int i) {
    final n = widget.items.length;
    return [
      if (i > 0) GlassMenuEntry(label: 'Move up', icon: GlassGlyph28.arrowUp.regular, separatorBefore: true, onSelected: () => _move(i, ReorderMove.up)),
      if (i < n - 1) GlassMenuEntry(label: 'Move down', icon: GlassGlyph28.arrowDown.regular, onSelected: () => _move(i, ReorderMove.down)),
      if (i > 0) GlassMenuEntry(label: 'Move to top', icon: GlassGlyph28.caretUp.regular, onSelected: () => _move(i, ReorderMove.top)),
      if (i < n - 1) GlassMenuEntry(label: 'Move to bottom', icon: GlassGlyph28.caretDown.regular, onSelected: () => _move(i, ReorderMove.bottom)),
    ];
  }

  Map<CustomSemanticsAction, VoidCallback> _actions(int i) {
    final n = widget.items.length;
    return {
      if (i > 0) const CustomSemanticsAction(label: 'Move up'): () => _move(i, ReorderMove.up),
      if (i < n - 1) const CustomSemanticsAction(label: 'Move down'): () => _move(i, ReorderMove.down),
      if (i > 0) const CustomSemanticsAction(label: 'Move to top'): () => _move(i, ReorderMove.top),
      if (i < n - 1) const CustomSemanticsAction(label: 'Move to bottom'): () => _move(i, ReorderMove.bottom),
    };
  }

  KeyEventResult _key(int i, KeyEvent e) {
    if (e is! KeyDownEvent || !HardwareKeyboard.instance.isAltPressed) return KeyEventResult.ignored;
    final shift = HardwareKeyboard.instance.isShiftPressed;
    final k = e.logicalKey;
    ReorderMove? m;
    if (k == LogicalKeyboardKey.arrowUp) {
      m = shift ? ReorderMove.top : ReorderMove.up;
    } else if (k == LogicalKeyboardKey.arrowDown) {
      m = shift ? ReorderMove.bottom : ReorderMove.down;
    } else if (_grid && shift && k == LogicalKeyboardKey.arrowLeft) {
      m = ReorderMove.left;
    } else if (_grid && shift && k == LogicalKeyboardKey.arrowRight) {
      m = ReorderMove.right;
    }
    if (m == null) return KeyEventResult.ignored;
    _move(i, m);
    return KeyEventResult.handled;
  }

  GlassReorderItemInfo _info(int i, {required bool dragging}) => GlassReorderItemInfo(
        dragging: dragging,
        moveEntries: _moveEntries(i),
        handle: () => Listener(
          onPointerDown: (e) => _lift(i, e.position, pointer: e.pointer),
          child: GlassIconButton(
            icon: GlassButtonIcon(GlassGlyph28.dotsSixVertical.regular),
            label: 'Reorder ${widget.nameOf(widget.items[i])}',
            onPressed: () {
              final rect = _slotRect(i);
              if (rect == null) return;
              unawaited(showGlassMenu(context, anchor: rect, entries: _moveEntries(i), title: 'Reorder ${widget.nameOf(widget.items[i])}'));
            },
          ),
        ),
      );

  // ---- build ----

  Widget _item(int i, {double? width}) {
    final item = widget.items[i];
    final dragging = _drag == i;
    Offset shift = Offset.zero;
    final d = _drag;
    if (d != null && i != d) {
      final from = _slotRect(i);
      final slot = displacedSlot(i, d, _target);
      final to = slot == i ? from : _slotRect(slot);
      if (from != null && to != null) shift = to.topLeft - from.topLeft;
    }
    final inner = widget.itemBuilder(context, item, i, _info(i, dragging: false));
    Widget child = SpringValue(
      value: shift.dx,
      spring: gt.springSnappy,
      builder: (context, dx, _) => SpringValue(
        value: shift.dy,
        spring: gt.springSnappy,
        builder: (context, dy, _) => Transform.translate(offset: Offset(dx, dy), child: inner),
      ),
    );
    child = Opacity(opacity: dragging ? 0 : 1, child: child);
    child = SizedBox(key: _slot(i), width: width, child: child);
    return Focus(
      focusNode: _node(i),
      skipTraversal: true,
      onKeyEvent: (n, e) => _key(i, e),
      child: GlassSwipeSemantics(
        actions: _actions(i),
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (e) {
            _pressIndex = i;
            _downPos = e.position;
            _pressTimer?.cancel();
            _pressTimer = Timer(const Duration(milliseconds: 450), () {
              if (mounted && _pressIndex == i) _openMenu(i);
            });
          },
          onPointerMove: (e) {
            if (_pressIndex != i) return;
            final moved = (e.position - _downPos).distance;
            if (_menuIndex == i && _drag == null && moved > 10) {
              _lift(i, e.position, pointer: e.pointer);
            } else if (_menuIndex == null && moved > kTouchSlop) {
              _pressTimer?.cancel();
            }
          },
          onPointerUp: (_) => _pressTimer?.cancel(),
          onPointerCancel: (_) => _pressTimer?.cancel(),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.items.length;
    if (_grid) {
      return LayoutBuilder(
        builder: (context, box) {
          final w = (box.maxWidth - widget.spacing * (widget.columns - 1)) / widget.columns;
          return Wrap(spacing: widget.spacing, runSpacing: widget.spacing, children: [for (var i = 0; i < n; i++) _item(i, width: w)]);
        },
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [for (var i = 0; i < n; i++) _item(i)]);
  }
}
