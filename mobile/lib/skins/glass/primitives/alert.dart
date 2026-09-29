import 'dart:async';

import 'package:flutter/physics.dart' show SpringSimulation;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass_motion_recorder.dart' show GlassMotionEntry;
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/lit.dart';
import 'package:manhwamaniacs/skins/glass/primitives/overlay_queue.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// `cancel` is the least destructive action; `destructive` is the solid `danger` confirm.
enum GlassAlertRole { cancel, normal, destructive }

/// One button of an alert. [run] is awaited while the alert is pending; a throw becomes the inline error.
class GlassAlertAction<T> {
  const GlassAlertAction(this.label, {this.role = GlassAlertRole.normal, this.value, this.run, this.errorText});
  final String label;
  final GlassAlertRole role;
  final T? value;
  final Future<void> Function()? run;
  final String? errorText;
}

/// A warning or danger box: a `surface2` slab with a 3 px leading bar in the semantic colour.
class GlassAlertNote {
  const GlassAlertNote(this.text, {this.danger = false});
  final String text;
  final bool danger;
}

/// glass 7.11: a `PopupRoute` with the `dimModal` barrier fading in over 180 ms. The route never dismisses by a
/// barrier tap; the alert's own cancel action does.
class GlassAlertRoute<T> extends PopupRoute<T> {
  GlassAlertRoute({required this.builder});
  final WidgetBuilder builder;

  @override
  Color? get barrierColor => GlassColors.dimModal;
  @override
  bool get barrierDismissible => false;
  @override
  String? get barrierLabel => null;
  @override
  Duration get transitionDuration => const Duration(milliseconds: 180);
  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 350);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) => builder(context);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) => child;
}

/// Shows an alert (glass 7.11). Returns the value of the pressed action, or null when dismissed with `Esc` or
/// Android back. [sourceRect] is the global rect of the control that opened it: the alert blooms from it.
Future<T?> showGlassAlert<T>(
  BuildContext context, {
  required String title,
  String? body,
  List<String> notes = const [],
  GlassAlertNote? note,
  required List<GlassAlertAction<T>> actions,
  Rect? sourceRect,
}) =>
    Navigator.of(context, rootNavigator: true).push<T>(
      GlassAlertRoute<T>(
        builder: (context) => GlassAlert<T>(title: title, body: body, notes: notes, note: note, actions: actions, sourceRect: sourceRect),
      ),
    );

/// The alert surface: T4 on the `interruptions` layer, width 300 (420 on tablet and desktop frames), radius 26.
class GlassAlert<T> extends ConsumerStatefulWidget {
  const GlassAlert({super.key, required this.title, required this.actions, this.body, this.notes = const [], this.note, this.sourceRect});

  final String title;
  final String? body;
  final List<String> notes;
  final GlassAlertNote? note;
  final List<GlassAlertAction<T>> actions;
  final Rect? sourceRect;

  @override
  ConsumerState<GlassAlert<T>> createState() => _GlassAlertState<T>();
}

class _GlassAlertState<T> extends ConsumerState<GlassAlert<T>> with TickerProviderStateMixin {
  late final AnimationController _bloom = AnimationController.unbounded(vsync: this);
  late final AnimationController _shrink = AnimationController(vsync: this);
  final GlobalKey<SkinGlassState> _glass = GlobalKey();
  final FocusNode _cancelFocus = FocusNode(debugLabel: 'GlassAlert.cancel');
  VoidCallback? _unsuppress;
  OverlayQueue? _queue;
  Animation<double>? _routeAnim;
  GlassMotionEntry? _entry;
  bool _pending = false;
  String? _error;
  int _errorTrigger = 0;
  final GlobalKey _boxKey = GlobalKey();
  Offset? _sourceLocal;

  bool get _phone => GlassFrame.of(context) == GlassFrameKind.phone;

  @override
  void initState() {
    super.initState();
    _unsuppress = suppressLit();
    _queue = ref.read(overlayQueueProvider.notifier);
    scheduleMicrotask(() {
      _queue?.setPhone(mounted ? _phone : true);
      _queue?.requestSlot(OverlayKind.alert);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _startBloom());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final a = ModalRoute.of(context)?.animation;
    if (a != _routeAnim) {
      _routeAnim?.removeStatusListener(_onRoute);
      _routeAnim = a?..addStatusListener(_onRoute);
    }
  }

  void _onRoute(AnimationStatus s) {
    if (s != AnimationStatus.reverse || !mounted) return;
    _bloom.stop();
    if (ref.read(glassMotionPrefsProvider).reduced) {
      _shrink.animateTo(1, duration: const Duration(milliseconds: 150));
    } else {
      _shrink.animateWith(SpringSimulation(springOf(gt.springDismiss), 0, 1, 0));
    }
    unawaited(_glass.currentState?.dematerialize());
  }

  void _startBloom() {
    if (!mounted) return;
    final box = _boxKey.currentContext?.findRenderObject();
    final src = widget.sourceRect;
    if (src != null && box is RenderBox && box.hasSize) {
      final rect = box.localToGlobal(Offset.zero) & box.size;
      _sourceLocal = src.center - rect.topLeft;
    }
    if (ref.read(glassMotionPrefsProvider).reduced) {
      _bloom.animateTo(1, duration: const Duration(milliseconds: 150));
    } else {
      _entry = GlassMotion.recorder.begin(MotionName.bloom.label, 434);
      _bloom.animateWith(SpringSimulation(springOf(gt.springMorph), 0, 1, 0)).whenComplete(() {
        if (_entry != null) GlassMotion.recorder.end(_entry!);
      });
    }
    setState(() {});
  }

  @override
  void dispose() {
    _routeAnim?.removeStatusListener(_onRoute);
    _unsuppress?.call();
    final q = _queue;
    scheduleMicrotask(() {
      try {
        q?.release(OverlayKind.alert);
      } on StateError {
        // container disposed first
      }
    });
    _bloom.dispose();
    _shrink.dispose();
    _cancelFocus.dispose();
    super.dispose();
  }

  void _cancel() {
    if (_pending) return;
    Navigator.of(context).pop();
  }

  Future<void> _press(GlassAlertAction<T> a) async {
    if (_pending) return;
    if (a.role == GlassAlertRole.destructive) glassFire(ref, HapticEvent.deleteConfirm);
    if (a.run == null) {
      Navigator.of(context).pop(a.value);
      return;
    }
    setState(() {
      _pending = true;
      _error = null;
    });
    try {
      await a.run!();
      if (mounted) Navigator.of(context).pop(a.value);
    } catch (e) {
      if (!mounted) return;
      final msg = a.errorText ?? "Couldn't finish that";
      setState(() {
        _pending = false;
        _error = msg;
        _errorTrigger++;
      });
      glassFire(ref, HapticEvent.error);
      announceAssertive(context, msg);
    }
  }

  double _labelW(String label) =>
      measureText(context, label, roleStyle(context, gt.typeHeadline, onGlass: true, wght: gt.typeHeadline.wght.round() + 40, maxScale: 1.5)).width;

  @override
  Widget build(BuildContext context) {
    final phone = _phone;
    final width = phone ? 300.0 : 420.0;
    final inner = width - 40;
    final actions = widget.actions;
    final stacked = actions.length >= 3 || (actions.length == 2 && actions.any((a) => _labelW(a.label) + 40 > (inner - 8) / 2));

    Widget button(GlassAlertAction<T> a, {required bool large}) {
      final isCancel = a.role == GlassAlertRole.cancel;
      final isDestructive = a.role == GlassAlertRole.destructive;
      final b = GlassButton(
        label: a.label,
        size: large ? GlassButtonSize.large : GlassButtonSize.medium,
        variant: isDestructive ? GlassButtonVariant.destructiveConfirm : GlassButtonVariant.secondary,
        fullWidth: true,
        loading: _pending && !isCancel && a.run != null,
        onPressed: _pending && a.run != null && isCancel ? null : (_pending ? null : () => isCancel ? _cancelWith(a) : _press(a)),
        focusNode: isCancel ? _cancelFocus : null,
      );
      return isDestructive ? GlassShake(trigger: _errorTrigger, child: b) : b;
    }

    // Order: the least destructive first on top of a stack; trailing when side by side.
    final ordered = [...actions]..sort((a, b) => b.role.index.compareTo(a.role.index));
    final Widget buttons;
    if (stacked) {
      final top = [...actions]..sort((a, b) => a.role.index.compareTo(b.role.index));
      buttons = Column(children: [
        for (var i = 0; i < top.length; i++) Padding(padding: EdgeInsets.only(top: i == 0 ? 0 : 8), child: button(top[i], large: true)),
      ],);
    } else {
      buttons = Row(children: [
        for (var i = 0; i < ordered.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: button(ordered[i], large: false)),
        ],
      ],);
    }

    final content = Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassText(widget.title, role: gt.typeTitle3, wght: 700, onGlass: true, maxScale: 1.5),
          if (widget.body != null) ...[const SizedBox(height: 8), GlassText(widget.body!, role: gt.typeCallout, onGlass: true, maxScale: 1.5)],
          for (final n in widget.notes) ...[const SizedBox(height: 8), GlassText(n, role: gt.typeFootnote, onGlass: true, maxScale: 1.5)],
          if (widget.note != null) ...[
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(color: gt.colorSurface2, borderRadius: BorderRadius.circular(gt.radiusMd)),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: widget.note!.danger ? gt.colorDanger : gt.colorWarning,
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(3)),
                      ),
                      child: const SizedBox(width: 3),
                    ),
                    Expanded(child: Padding(padding: const EdgeInsets.all(12), child: GlassText(widget.note!.text, role: gt.typeFootnote, onGlass: true, maxScale: 1.5))),
                  ],
                ),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Row(
                children: [
                  GlassBacking(size: 28, child: GlyphIcon(GlassGlyph.warningCircle, color: gt.colorDanger)),
                  const SizedBox(width: 8),
                  Expanded(child: GlassText(_error!, role: gt.typeFootnote, onGlass: true, maxScale: 1.5)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          buttons,
        ],
      ),
    );

    final src = widget.sourceRect;
    final from = src != null ? 0.9 : 0.94;
    final panel = SizedBox(
      width: width,
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: widget.title,
        hint: widget.body,
        child: GlassHost(
          child: Stack(
            key: _boxKey,
            children: [
              Positioned.fill(
                child: SkinGlass(key: _glass, tier: GlassTierId.t4, shape: GlassShape.superellipse(gt.radiusXl), layer: GlassLayerKind.interruptions, debugLabel: 'GlassAlert', child: const SizedBox.shrink()),
              ),
              content,
            ],
          ),
        ),
      ),
    );

    return PopScope(
      canPop: !_pending,
      onPopInvokedWithResult: (didPop, _) {},
      child: CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): _cancel},
        child: FocusScope(
          autofocus: true,
          child: FocusTraversalGroup(
            child: Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_bloom, _shrink]),
                child: panel,
                builder: (context, child) {
                  final t = _bloom.value;
                  final s = (from + (1 - from) * t) * (1 - 0.04 * _shrink.value);
                  final o = _sourceLocal;
                  return Opacity(
                    opacity: (ref.read(glassMotionPrefsProvider).reduced ? t : 1).clamp(0.0, 1.0) * (1 - _shrink.value * (ref.read(glassMotionPrefsProvider).reduced ? 1 : 0)),
                    child: Transform.scale(
                      key: const ValueKey('glass-alert-scale'),
                      scale: ref.read(glassMotionPrefsProvider).reduced ? 1 : s,
                      alignment: o == null ? Alignment.center : Alignment.topLeft,
                      origin: o,
                      child: child,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _cancelWith(GlassAlertAction<T> a) {
    if (a.run != null) {
      unawaited(_press(a));
    } else {
      Navigator.of(context).pop(a.value);
    }
  }
}
