import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart' show SpringSimulation;
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/drag_owner.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart' show GlassButtonIcon;
import 'package:manhwamaniacs/skins/glass/primitives/glyphs_more.dart';
import 'package:manhwamaniacs/skins/glass/primitives/icon_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/swipe_math.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';
import 'package:manhwamaniacs/skins/token_types.g.dart' show SpringToken;

enum SwipeTone { iris, success, warning, danger, neutral }

/// One action behind a row (glass 7.34). The first action of a side is its full-swipe action.
class SwipeAction {
  const SwipeAction({required this.id, required this.label, required this.glyph, this.tone = SwipeTone.neutral, this.destructive = false, required this.run, this.undo});
  final String id;
  final String label;
  final IconData glyph;
  final SwipeTone tone;
  final bool destructive;
  final Future<void> Function() run;
  final Future<void> Function()? undo;

  Color get color => switch (tone) {
        SwipeTone.iris => gt.colorIris400,
        SwipeTone.success => gt.colorSuccess,
        SwipeTone.warning => gt.colorWarning,
        SwipeTone.danger => gt.colorDanger,
        SwipeTone.neutral => gt.colorLabel1,
      };
}

/// The custom semantics actions of the swipe row above a row shell (VoiceOver's actions rotor, TalkBack's menu).
class GlassSwipeSemantics extends InheritedWidget {
  const GlassSwipeSemantics({super.key, required this.actions, required super.child});
  final Map<CustomSemanticsAction, VoidCallback> actions;

  static Map<CustomSemanticsAction, VoidCallback> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GlassSwipeSemantics>()?.actions ?? const {};

  @override
  bool updateShouldNotify(GlassSwipeSemantics old) => old.actions.length != actions.length;
}

/// One open tray per list: opening a row closes the others, and scrolling closes the open one.
class GlassSwipeGroup extends ConsumerStatefulWidget {
  const GlassSwipeGroup({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<GlassSwipeGroup> createState() => _GlassSwipeGroupState();
}

class _GlassSwipeGroupState extends ConsumerState<GlassSwipeGroup> {
  final ValueNotifier<Object?> _open = ValueNotifier(null);

  /// `u` undoes the last removal while its toast shows, wherever focus is (a removed row takes its focus with it).
  bool _undoKey(KeyEvent e) {
    if (e is! KeyDownEvent || e.logicalKey != LogicalKeyboardKey.keyU) return false;
    if (FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<EditableText>() != null) return false;
    return undoLast(ref);
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_undoKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_undoKey);
    _open.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _GroupScope(
        open: _open,
        child: NotificationListener<ScrollStartNotification>(
          onNotification: (n) {
            if (n.dragDetails != null) _open.value = null;
            return false;
          },
          child: widget.child,
        ),
      );
}

class _GroupScope extends InheritedWidget {
  const _GroupScope({required this.open, required super.child});
  final ValueNotifier<Object?> open;
  static ValueNotifier<Object?>? of(BuildContext c) => c.getInheritedWidgetOfExactType<_GroupScope>()?.open;
  @override
  bool updateShouldNotify(_GroupScope old) => false;
}

class _RowDrag extends HorizontalDragGestureRecognizer {
  _RowDrag({required this.leadingStrip});
  bool Function(PointerDownEvent) leadingStrip;

  @override
  bool isPointerAllowed(PointerEvent event) => super.isPointerAllowed(event) && !(event is PointerDownEvent && leadingStrip(event));
}

/// A row with swipe actions (glass 7.34, 4.6, 8.0.5). Tracks the finger 1:1 after 10 px of horizontal movement, never within
/// 24 px of the leading screen edge; opens its tray past half its width (projected) and commits its first action past 60 %.
/// Never gesture-only: a `dots-three` button opens a menu of every action, every action is a custom semantics action,
/// hover and focus show the actions as icon buttons, and `m`, `d`, `Delete`, `Backspace` and `u` work on a focused row.
class GlassSwipeRow extends ConsumerStatefulWidget {
  const GlassSwipeRow({
    super.key,
    required this.name,
    required this.child,
    this.leading = const [],
    this.trailing = const [],
    this.showMore = true,
    this.removedMessage,
  });

  /// The row's name, for "More actions for {name}" and the removal toast.
  final String name;
  final Widget child;
  final List<SwipeAction> leading;
  final List<SwipeAction> trailing;
  final bool showMore;
  final String? removedMessage;

  @override
  ConsumerState<GlassSwipeRow> createState() => _GlassSwipeRowState();
}

class _GlassSwipeRowState extends ConsumerState<GlassSwipeRow> with TickerProviderStateMixin {
  late final AnimationController _x = AnimationController.unbounded(vsync: this);
  late final AnimationController _h = AnimationController(vsync: this, value: 1);
  final VelocityTracker _vt = VelocityTracker.withKind(PointerDeviceKind.touch);
  ValueNotifier<Object?>? _group;
  double _width = 0;
  bool _dragging = false;
  bool _crossed = false;
  bool _hover = false;
  bool _focusWithin = false;
  bool _gone = false;

  bool get _reduced => ref.read(glassMotionPrefsProvider).reduced;
  List<SwipeAction> get _all => [...widget.leading, ...widget.trailing];
  List<SwipeAction> _side(double x) => x > 0 ? widget.leading : widget.trailing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final g = _GroupScope.of(context);
    if (g != _group) {
      _group?.removeListener(_groupChanged);
      _group = g?..addListener(_groupChanged);
    }
  }

  void _groupChanged() {
    if (_group?.value != this && _x.value != 0 && !_dragging) _close();
  }

  @override
  void dispose() {
    _group?.removeListener(_groupChanged);
    _x.dispose();
    _h.dispose();
    super.dispose();
  }

  void _spring(double target, SpringToken t, {double v = 0}) {
    if (_reduced) {
      unawaited(_x.animateTo(target, duration: const Duration(milliseconds: 150)));
    } else {
      unawaited(_x.springTo(target, t, velocityPxPerS: v));
    }
  }

  void _close({double v = 0}) {
    if (_group?.value == this) _group!.value = null;
    _spring(0, gt.springSettle, v: v);
  }

  double _liveV() {
    final v = _vt.getVelocity().pixelsPerSecond.dx;
    return v.isFinite ? v : 0;
  }

  void _start(DragStartDetails d) {
    _dragging = true;
    _crossed = false;
    _vt.addPosition(d.sourceTimeStamp ?? Duration.zero, d.globalPosition);
    _x.stop();
  }

  void _update(DragUpdateDetails d) {
    _vt.addPosition(d.sourceTimeStamp ?? Duration.zero, d.globalPosition);
    var next = _x.value + (d.primaryDelta ?? 0);
    if (_side(next).isEmpty) next = rubberband(next, _width == 0 ? 300 : _width * 0.2);
    _x.value = next;
    final v = _liveV();
    final crossed = _side(next).isNotEmpty && fullSwipeCrossed(next, v, _width);
    if (crossed != _crossed) {
      _crossed = crossed;
      glassFire(ref, crossed ? HapticEvent.thresholdCross : HapticEvent.thresholdBack);
    }
  }

  void _end(DragEndDetails d) {
    _dragging = false;
    final v = d.velocity.pixelsPerSecond.dx;
    final x = _x.value;
    final acts = _side(x);
    if (acts.isEmpty) {
      _close(v: v);
      return;
    }
    if (fullSwipeCrossed(x, v, _width)) {
      unawaited(_commit(acts.first, x > 0 ? 1 : -1, v));
    } else if (opensTray(x, v, acts.length)) {
      _group?.value = this;
      _spring((x > 0 ? 1 : -1) * trayWidth(acts.length), gt.springSnappy, v: v);
    } else {
      _close(v: v);
    }
  }

  void _cancel() {
    _dragging = false;
    _close();
  }

  Future<void> _commit(SwipeAction a, int dir, double v) async {
    if (a.destructive) {
      final done = Completer<void>();
      void watch() {
        if (_x.value.abs() >= _width - 1 && !done.isCompleted) done.complete();
      }

      _x.addListener(watch);
      if (_reduced) {
        unawaited(_x.animateTo(dir * _width, duration: const Duration(milliseconds: 150)).whenComplete(watch));
      } else {
        unawaited(_x.springTo(dir * _width, gt.springDismiss, velocityPxPerS: v));
      }
      await done.future.timeout(const Duration(seconds: 2), onTimeout: () {});
      _x.removeListener(watch);
      if (!mounted) return;
      if (_reduced) {
        _h.value = 0;
      } else {
        unawaited(_h.animateWith(SpringSimulation(springOf(gt.springSnappy), 1, 0, 0)));
      }
      setState(() => _gone = true);
      unawaited(a.run());
      showGlassToast(
        ref,
        GlassToastSpec(
          widget.removedMessage ?? '${widget.name} removed',
          undo: () async {
            await a.undo?.call();
            if (!mounted) return;
            setState(() => _gone = false);
            unawaited(_h.animateTo(1, duration: const Duration(milliseconds: 200)));
            _x.value = 0;
          },
        ),
      );
    } else {
      await a.run();
      if (!mounted) return;
      _close();
    }
  }

  Future<void> _trigger(SwipeAction a) async {
    if (a.destructive) {
      await _commit(a, a.id == widget.trailing.firstOrNull?.id ? -1 : 1, 0);
    } else {
      await a.run();
      if (mounted) _close();
    }
  }

  SwipeAction? _byId(String id) {
    for (final a in _all) {
      if (a.id == id) return a;
    }
    return null;
  }

  KeyEventResult _key(FocusNode n, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    SwipeAction? a;
    if (k == LogicalKeyboardKey.keyM) {
      a = _byId('markRead');
    } else if (k == LogicalKeyboardKey.keyD) {
      a = _byId('download');
    } else if (k == LogicalKeyboardKey.delete || k == LogicalKeyboardKey.backspace) {
      a = _byId('remove');
    }
    if (a == null) return KeyEventResult.ignored;
    unawaited(_trigger(a));
    return KeyEventResult.handled;
  }

  void _more(BuildContext c) {
    final box = c.findRenderObject();
    if (box is! RenderBox) return;
    unawaited(showGlassMenu(
      c,
      anchor: box.localToGlobal(Offset.zero) & box.size,
      title: widget.name,
      entries: [for (final a in _all) GlassMenuEntry(label: a.label, icon: a.glyph, destructive: a.destructive, run: () => _trigger(a))],
    ),);
  }

  Widget _pills(double x) {
    final acts = _side(x);
    if (acts.isEmpty || x == 0) return const SizedBox.shrink();
    final trailing = x < 0;
    final avail = x.abs();
    final v = _liveV();
    final full = (_dragging && _crossed) || (!_dragging && fullSwipeCrossed(x, v, _width) && _x.isAnimating && avail > kFullSwipeFraction * _width);
    return Positioned.fill(
      child: ClipRect(
        clipper: _Strip(trailing, avail),
        child: Stack(
          children: [
            for (var i = 0; i < acts.length; i++)
              _pill(acts[i], i, acts.length, trailing, avail, full),
          ],
        ),
      ),
    );
  }

  Widget _pill(SwipeAction a, int i, int n, bool trailing, double avail, bool full) {
    final reveal = (avail - i * kSwipeSlot).clamp(0.0, kSwipeSlot);
    final reduced = ref.watch(glassMotionPrefsProvider.select((m) => m.reduced));
    final scale = reduced ? 1.0 : pillScale(reveal);
    final hit = GlassFrame.hitMin(context);
    final stretch = full && i == 0;
    final solid = ref.watch(glassA11yProvider.select((s) => s.solid));
    final width = stretch ? math.max(kSwipeSlot - 16, avail - 16) : kSwipeSlot - 16;
    final fill = stretch ? a.color : (solid ? gt.glassSolid1 : const Color(0x9E131317));
    final fg = stretch ? const Color(0xFF000000) : a.color;
    final pill = Semantics(
      button: true,
      label: a.label,
      excludeSemantics: true,
      onTap: () => unawaited(_trigger(a)),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => unawaited(_trigger(a)),
        child: Opacity(
          opacity: full && i != 0 ? 0 : 1,
          child: Transform.scale(
            scale: scale,
            child: ClipRSuperellipse(
              borderRadius: BorderRadius.circular(22),
              child: DecoratedBox(
                decoration: BoxDecoration(color: fill, border: Border.all(color: const Color(0x38FFFFFF), width: 0.5), borderRadius: BorderRadius.circular(22)),
                child: SizedBox(
                  width: width,
                  height: math.max(44, hit),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(a.glyph, size: 20, color: fg),
                      GlassText(a.label, role: gt.typeCaption1, wght: 600, color: fg, maxLines: 1, overflow: TextOverflow.ellipsis, maxScale: 1.2),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final off = i * kSwipeSlot;
    return Positioned.directional(
      textDirection: TextDirection.ltr,
      start: trailing ? null : off + 8,
      end: trailing ? off + 8 : null,
      top: 0,
      bottom: 0,
      child: Align(child: pill),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final semantics = <CustomSemanticsAction, VoidCallback>{
      for (final a in _all) CustomSemanticsAction(label: a.label): () => unawaited(_trigger(a)),
    };
    final open = _x.value != 0;
    return GlassSwipeSemantics(
      actions: semantics,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _key,
        onFocusChange: (f) => setState(() => _focusWithin = f),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GlassDragOwner(
            kind: GlassDragOwnerKind.row,
            child: LayoutBuilder(
              builder: (context, box) {
                _width = box.maxWidth;
                return RawGestureDetector(
                  behavior: HitTestBehavior.translucent,
                  gestures: {
                    _RowDrag: GestureRecognizerFactoryWithHandlers<_RowDrag>(
                      () => _RowDrag(leadingStrip: (e) => startsInBackStrip(rtl ? box.maxWidth - e.localPosition.dx : e.localPosition.dx)),
                      (r) => r
                        ..dragStartBehavior = DragStartBehavior.down
                        ..gestureSettings = DeviceGestureSettings(touchSlop: gt.thresholdDragSlopTouch)
                        ..onStart = _start
                        ..onUpdate = _update
                        ..onEnd = _end
                        ..onCancel = _cancel,
                    ),
                  },
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_x, _h]),
                    builder: (context, _) {
                      final x = _x.value;
                      final row = Row(
                        children: [
                          Expanded(child: widget.child),
                          if ((_hover || _focusWithin) && !_gone)
                            for (final a in _all)
                              GlassIconButton(icon: GlassButtonIcon(a.glyph), label: a.label, onPressed: () => unawaited(_trigger(a))),
                          if (widget.showMore && _all.isNotEmpty)
                            Builder(
                              builder: (c) => GlassIconButton(icon: GlassButtonIcon(GlassGlyph28.dotsThree.regular), label: 'More actions for ${widget.name}', onPressed: () => _more(c)),
                            ),
                        ],
                      );
                      return ClipRect(
                        child: Align(
                          alignment: Alignment.topCenter,
                          heightFactor: _h.value.clamp(0.0, 1.0),
                          child: Stack(
                            children: [
                              _pills(x),
                              Transform.translate(
                                offset: Offset(x, 0),
                                child: open ? AbsorbPointer(child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _close, child: row)) : row,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows only the revealed strip behind the row.
class _Strip extends CustomClipper<Rect> {
  const _Strip(this.trailing, this.reveal);
  final bool trailing;
  final double reveal;
  @override
  Rect getClip(Size size) => trailing ? Rect.fromLTWH(size.width - reveal, 0, reveal, size.height) : Rect.fromLTWH(0, 0, reveal, size.height);
  @override
  bool shouldReclip(_Strip old) => old.reveal != reveal || old.trailing != trailing;
}
