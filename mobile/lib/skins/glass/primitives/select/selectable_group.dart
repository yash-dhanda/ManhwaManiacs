import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/reorder_math.dart' show edgeScrollVelocity;
import 'package:manhwamaniacs/skins/glass/primitives/select/select_mode.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/select_paint.dart';

class _Scope<K> extends InheritedWidget {
  const _Scope({required this.state, required this.active, required this.selected, required super.child});
  final _GlassSelectableGroupState<K> state;
  final bool active;
  final Set<K> selected;

  @override
  bool updateShouldNotify(_Scope<K> old) => old.active != active || old.selected != selected;
}

class _PaintDrag extends HorizontalDragGestureRecognizer {
  _PaintDrag({required this.allowed});
  bool Function(PointerDownEvent) allowed;

  @override
  bool isPointerAllowed(PointerEvent event) => super.isPointerAllowed(event) && event is PointerDownEvent && allowed(event);
}

/// Wraps a grid or list in select mode (glass 7.35): `Ctrl+A` / `⌘A` selects all, `Esc` clears then exits, Android back exits,
/// a horizontal drag paints a range once something is selected (auto-scrolling in the 64 px edge zones), and the region is a
/// labelled `Semantics` container with a polite count.
class GlassSelectableGroup<K> extends ConsumerStatefulWidget {
  const GlassSelectableGroup({super.key, required this.controller, required this.ids, required this.label, required this.child});
  final GlassSelectModeController<K> controller;

  /// The visible ids in order (ranges and select-all read them).
  final List<K> ids;

  /// "Select series", "Select chapters", "Select downloads".
  final String label;
  final Widget child;

  @override
  ConsumerState<GlassSelectableGroup<K>> createState() => _GlassSelectableGroupState<K>();
}

class _GlassSelectableGroupState<K> extends ConsumerState<GlassSelectableGroup<K>> with SingleTickerProviderStateMixin {
  final Map<K, GlobalKey> _items = {};
  int _lastCount = 0;
  bool? _mode;
  Offset _at = Offset.zero;
  Ticker? _ticker;
  Duration _lastTick = Duration.zero;

  GlassSelectModeController<K> get c => widget.controller;

  @override
  void initState() {
    super.initState();
    c.order = () => widget.ids;
    c.addListener(_changed);
    _lastCount = c.count;
  }

  @override
  void didUpdateWidget(GlassSelectableGroup<K> old) {
    super.didUpdateWidget(old);
    c.order = () => widget.ids;
    if (old.controller != c) {
      old.controller.removeListener(_changed);
      c.addListener(_changed);
    }
  }

  @override
  void dispose() {
    c.removeListener(_changed);
    _ticker?.dispose();
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    if (c.active && c.count != _lastCount) {
      try {
        unawaited(SemanticsService.sendAnnouncement(View.of(context), selectedCountLabel(c.count), Directionality.of(context)));
      } catch (_) {}
    }
    _lastCount = c.count;
  }

  void register(K id, GlobalKey key) => _items[id] = key;
  void unregister(K id, GlobalKey key) {
    if (_items[id] == key) _items.remove(id);
  }

  K? _idAt(Offset global) {
    for (final e in _items.entries) {
      final ro = e.value.currentContext?.findRenderObject();
      if (ro is RenderBox && ro.attached && ro.hasSize && (ro.localToGlobal(Offset.zero) & ro.size).contains(global)) return e.key;
    }
    return null;
  }

  BuildContext? _anyItemContext() {
    for (final k in _items.values) {
      if (k.currentContext != null) return k.currentContext;
    }
    return null;
  }

  // ---- range painting ----

  void _paintStart(DragStartDetails d) {
    final id = _idAt(d.globalPosition);
    _at = d.globalPosition;
    if (id == null) return;
    _mode = paintModeFrom(firstWasSelected: c.isSelected(id));
    c.setSelected(paintAlong(c.selected, [id], _mode!));
    _ticker ??= createTicker(_tick);
    _lastTick = Duration.zero;
    if (!_ticker!.isActive) unawaited(_ticker!.start());
  }

  void _paintUpdate(DragUpdateDetails d) {
    final mode = _mode;
    if (mode == null) return;
    final from = _at;
    _at = d.globalPosition;
    final steps = ((d.globalPosition - from).distance / 6).ceil().clamp(1, 60);
    final path = <K>[];
    for (var i = 1; i <= steps; i++) {
      final id = _idAt(Offset.lerp(from, d.globalPosition, i / steps)!);
      if (id != null && (path.isEmpty || path.last != id)) path.add(id);
    }
    final next = paintAlong(c.selected, path, mode);
    if (next.length != c.selected.length || !next.containsAll(c.selected)) c.setSelected(next);
  }

  void _paintEnd() {
    _mode = null;
    _ticker?.stop();
  }

  void _tick(Duration elapsed) {
    final dt = _lastTick == Duration.zero ? 0.0 : (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    final ctx = _anyItemContext();
    final scrollable = ctx == null ? null : Scrollable.maybeOf(ctx);
    final ro = scrollable?.context.findRenderObject();
    if (scrollable == null || ro is! RenderBox || !ro.attached || dt == 0) return;
    final top = ro.localToGlobal(Offset.zero).dy;
    final v = edgeScrollVelocity(_at.dy, top, top + ro.size.height);
    if (v == 0) return;
    final p = scrollable.position;
    final next = (p.pixels + v * dt).clamp(p.minScrollExtent, p.maxScrollExtent);
    if (next != p.pixels) p.jumpTo(next);
  }

  @override
  Widget build(BuildContext context) {
    final active = c.active;
    Widget body = _Scope<K>(state: this, active: active, selected: c.selected, child: widget.child);
    body = RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: {
        _PaintDrag: GestureRecognizerFactoryWithHandlers<_PaintDrag>(
          () => _PaintDrag(allowed: (e) => c.active && c.selected.isNotEmpty && _idAt(e.position) != null),
          (r) => r
            ..dragStartBehavior = DragStartBehavior.down
            ..onStart = _paintStart
            ..onUpdate = _paintUpdate
            ..onEnd = (_) {
              _paintEnd();
            }
            ..onCancel = _paintEnd,
        ),
      },
      child: body,
    );
    body = Semantics(container: active, explicitChildNodes: active, label: active ? widget.label : null, child: body);
    return PopScope(
      canPop: !active,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && c.active) c.exit();
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyA, control: true): () {
            if (c.active) c.selectAll();
          },
          const SingleActivator(LogicalKeyboardKey.keyA, meta: true): () {
            if (c.active) c.selectAll();
          },
          const SingleActivator(LogicalKeyboardKey.escape): () {
            if (!c.active) return;
            if (c.selected.isNotEmpty) {
              c.clear();
            } else {
              c.exit();
            }
          },
        },
        child: body,
      ),
    );
  }
}

/// One selectable item (a poster, a series row, a chapter row). Outside select mode it is transparent (`x` enters select
/// mode with it picked, `Shift+x` selects the range to it). In select mode a tap, `Space` and `Enter` toggle (`Enter` never
/// opens), `Shift+Space` selects the range from the last toggled item, and semantics read as a checked button.
class GlassSelectableItem<K> extends StatefulWidget {
  const GlassSelectableItem({super.key, required this.id, required this.child, this.enabled = true, this.disabledHint = 'Already on this device'});
  final K id;
  final Widget child;

  /// False for a row that cannot be picked (an already saved chapter).
  final bool enabled;
  final String disabledHint;

  @override
  State<GlassSelectableItem<K>> createState() => _GlassSelectableItemState<K>();
}

class _GlassSelectableItemState<K> extends State<GlassSelectableItem<K>> {
  final GlobalKey _key = GlobalKey();
  final FocusNode _node = FocusNode(debugLabel: 'GlassSelectableItem');
  bool _wasActive = false;
  _GlassSelectableGroupState<K>? _group;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final g = context.dependOnInheritedWidgetOfExactType<_Scope<K>>()?.state;
    if (g != _group) {
      _group?.unregister(widget.id, _key);
      _group = g?..register(widget.id, _key);
    }
  }

  @override
  void didUpdateWidget(GlassSelectableItem<K> old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) {
      _group?.unregister(old.id, _key);
      _group?.register(widget.id, _key);
    }
  }

  @override
  void dispose() {
    _group?.unregister(widget.id, _key);
    _node.dispose();
    super.dispose();
  }

  KeyEventResult _keys(FocusNode n, KeyEvent e) {
    final g = _group;
    if (g == null || e is! KeyDownEvent) return KeyEventResult.ignored;
    final c = g.c;
    final k = e.logicalKey;
    final shift = HardwareKeyboard.instance.isShiftPressed;
    if (!c.active) {
      if (k == LogicalKeyboardKey.keyX && widget.enabled) {
        if (shift) {
          c.extendTo(widget.id);
        } else {
          c.enter(widget.id);
        }
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (!widget.enabled) return KeyEventResult.ignored;
    if (k == LogicalKeyboardKey.space && shift) {
      c.extendTo(widget.id);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.space || k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      c.toggle(widget.id);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.keyX) {
      if (shift) {
        c.extendTo(widget.id);
      } else {
        c.toggle(widget.id);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_Scope<K>>();
    final active = scope?.active ?? false;
    final selected = scope?.selected.contains(widget.id) ?? false;
    if (active && !_wasActive && _node.hasFocus) {
      // Entering select mode with a row focused: the row keeps the keyboard (its own controls are excluded now).
      WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _node.requestFocus() : null);
    }
    _wasActive = active;
    final core = KeyedSubtree(key: _key, child: widget.child);
    if (!active) return Focus(focusNode: _node, canRequestFocus: false, skipTraversal: true, onKeyEvent: _keys, child: core);
    final c = _group!.c;
    return Focus(
      focusNode: _node,
      canRequestFocus: widget.enabled,
      onKeyEvent: _keys,
      child: MergeSemantics(
        child: Semantics(
          checked: selected,
          button: true,
          enabled: widget.enabled,
          hint: widget.enabled ? null : widget.disabledHint,
          onTap: widget.enabled ? () => c.toggle(widget.id) : null,
          child: ExcludeFocus(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.enabled ? () => c.toggle(widget.id) : null,
              child: AbsorbPointer(child: core),
            ),
          ),
        ),
      ),
    );
  }
}
