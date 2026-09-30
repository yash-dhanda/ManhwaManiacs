import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/physics.dart' show SpringSimulation;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass_motion_recorder.dart' show GlassMotionEntry;
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/sheet_scaffold.dart' show GlassCloseButton;
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

enum GlassToastKind { info, success, warning, error }

/// One toast (glass 7.12): a message, an optional plain action and an optional Undo.
class GlassToastSpec {
  const GlassToastSpec(this.message, {this.kind = GlassToastKind.info, this.actionLabel, this.onAction, this.undo, this.duration, this.tag});
  final String message;
  final GlassToastKind kind;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Registers the action `undoLast()` runs (and shows Undo, with the draining rim and 10 s).
  final VoidCallback? undo;
  final Duration? duration;

  /// A label the shell can dismiss by prefix ("mature:{source}:{series}": the 18+ purge removes those).
  final String? tag;

  Duration get effectiveDuration => duration ?? (undo != null ? const Duration(seconds: 10) : const Duration(seconds: 4));
}

class GlassToastEntry {
  GlassToastEntry(this.id, this.spec);
  final int id;
  final GlassToastSpec spec;
  final FocusNode focus = FocusNode(debugLabel: 'GlassToast');
  bool leaving = false;
}

/// The toasts on screen: at most two, oldest first.
class GlassToastController extends Notifier<List<GlassToastEntry>> {
  int _next = 0;
  VoidCallback? _lastUndo;
  Timer? _undoExpiry;

  @override
  List<GlassToastEntry> build() {
    ref.onDispose(() => _undoExpiry?.cancel());
    return const [];
  }

  void show(GlassToastSpec spec) {
    final e = GlassToastEntry(++_next, spec);
    final list = [...state, e];
    while (list.length > 2) {
      final gone = list.removeAt(0);
      _left(gone);
    }
    if (spec.undo != null) {
      _lastUndo = spec.undo;
      _undoExpiry?.cancel();
    }
    state = list;
  }

  /// Removes every toast whose tag starts with [prefix] at once (no animation): the 18+ purge.
  void removeTagged(String prefix) {
    final gone = [for (final e in state) if (e.spec.tag?.startsWith(prefix) ?? false) e];
    if (gone.isEmpty) return;
    for (final e in gone) {
      _left(e);
    }
    state = [for (final e in state) if (!gone.contains(e)) e];
  }

  /// A toast starts leaving (the view animates out, then calls [remove]).
  void dismiss(int id) {
    final i = state.indexWhere((e) => e.id == id);
    if (i < 0 || state[i].leaving) return;
    state[i].leaving = true;
    state = [...state];
  }

  void remove(int id) {
    final i = state.indexWhere((e) => e.id == id);
    if (i < 0) return;
    final e = state[i];
    _left(e);
    state = [for (final x in state) if (x.id != id) x];
  }

  void _left(GlassToastEntry e) {
    if (e.spec.undo != null && identical(_lastUndo, e.spec.undo)) {
      _undoExpiry?.cancel();
      _undoExpiry = Timer(const Duration(seconds: 60), () => _lastUndo = null);
    }
  }

  /// Runs the last destructive action's undo while its toast shows and for 60 s after it leaves.
  bool undoLast() {
    final u = _lastUndo;
    if (u == null) return false;
    _lastUndo = null;
    _undoExpiry?.cancel();
    unawaited(ref.read(glassHapticsProvider).fire(HapticEvent.undo));
    u();
    for (final e in state) {
      if (e.spec.undo == u) dismiss(e.id);
    }
    return true;
  }
}

final glassToastProvider = NotifierProvider<GlassToastController, List<GlassToastEntry>>(GlassToastController.new);

/// Shows a toast through the overlay queue (one toast system, no package).
void showGlassToast(WidgetRef ref, GlassToastSpec spec) => ref.read(glassToastProvider.notifier).show(spec);

/// `undoLast()` (the `mod+Z` binding is registered by `mobile/29`).
bool undoLast(WidgetRef ref) => ref.read(glassToastProvider.notifier).undoLast();

/// One toast capsule: falls in on `springSnappy`, leaves upward on `springDismiss`, can be caught and flicked.
class GlassToastView extends ConsumerStatefulWidget {
  const GlassToastView({super.key, required this.entry, required this.present, required this.rank, this.forceRim});

  final GlassToastEntry entry;

  /// The overlay queue lets it show (false while a menu is open: it leaves, and falls back in later).
  final bool present;

  /// 0 for the newest, 1 for the one behind it.
  final int rank;

  /// For captures: the remaining fraction of the rim.
  final double? forceRim;

  @override
  ConsumerState<GlassToastView> createState() => _GlassToastViewState();
}

class _GlassToastViewState extends ConsumerState<GlassToastView> with TickerProviderStateMixin {
  late final AnimationController _y = AnimationController.unbounded(vsync: this, value: -60);
  late final AnimationController _x = AnimationController.unbounded(vsync: this);
  late final AnimationController _o = AnimationController(vsync: this, value: 0);
  late final AnimationController _rim = AnimationController(vsync: this, duration: widget.entry.spec.effectiveDuration);
  bool _hover = false, _focused = false, _touch = false, _dragging = false, _in = false, _closing = false;
  GlassMotionEntry? _move;
  Offset _drag = Offset.zero;

  GlassToastEntry get e => widget.entry;
  bool get _reduced => ref.read(glassMotionPrefsProvider).reduced;

  @override
  void initState() {
    super.initState();
    _rim.addStatusListener((st) {
      if (st == AnimationStatus.completed && mounted && !_paused && !_sticky) ref.read(glassToastProvider.notifier).dismiss(e.id);
    });
    e.focus.addListener(_onFocus);
    if (_reduced) _y.value = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
    _announce();
  }

  @override
  void didUpdateWidget(GlassToastView old) {
    super.didUpdateWidget(old);
    if (old.present != widget.present || e.leaving) _sync();
  }

  @override
  void dispose() {
    e.focus.removeListener(_onFocus);
    _y.dispose();
    _x.dispose();
    _o.dispose();
    _rim.dispose();
    super.dispose();
  }

  void _announce() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        unawaited(SemanticsService.sendAnnouncement(
          View.of(context),
          e.spec.message,
          Directionality.of(context),
          assertiveness: e.spec.kind == GlassToastKind.error ? Assertiveness.assertive : Assertiveness.polite,
        ),);
      } catch (_) {}
    });
  }

  void _onFocus() {
    _focused = e.focus.hasFocus;
    _updateTimer();
  }

  // -- presence ---------------------------------------------------------------

  void _sync() {
    if (!mounted || _closing) return;
    if (e.leaving) {
      _leave(remove: true);
      return;
    }
    if (widget.present && !_in) {
      _in = true;
      _fall();
    } else if (!widget.present && _in) {
      _in = false;
      _leave(remove: false);
    }
    _updateTimer();
  }

  void _fall() {
    _y.stop();
    if (_reduced) {
      _y.value = 0;
      _o.animateTo(1, duration: const Duration(milliseconds: 150));
      return;
    }
    _move = GlassMotion.recorder.begin(MotionName.toastFall.label, 431);
    _o.animateTo(1, duration: gt.curveMaterialize.duration, curve: gt.curveMaterialize.curve);
    _y.animateWith(SpringSimulation(springOf(gt.springSnappy), _y.value, 0, _y.velocity)).whenComplete(_endMove);
  }

  void _endMove() {
    if (_move != null) GlassMotion.recorder.end(_move!);
    _move = null;
  }

  void _leave({required bool remove}) {
    _rim.stop();
    if (remove) _closing = true;
    void done() {
      if (remove && mounted) ref.read(glassToastProvider.notifier).remove(e.id);
    }

    if (_reduced) {
      _o.animateTo(0, duration: const Duration(milliseconds: 150)).whenComplete(done);
      return;
    }
    _o.animateTo(0, duration: gt.curveFadeOut.duration + const Duration(milliseconds: 120), curve: gt.curveFadeOut.curve);
    _y.animateWith(SpringSimulation(springOf(gt.springDismiss), _y.value, -80, _y.velocity)).whenComplete(done);
  }

  // -- timer: the rim controller is the clock (proportional resume, faked in tests) ----------------

  bool get _paused => _hover || _focused || _touch || _dragging || !widget.present || e.leaving;
  bool get _sticky => ref.read(glassAssistiveProvider);

  void _updateTimer() {
    if (!mounted) return;
    if (_paused || _sticky || !_in) {
      _rim.stop();
      return;
    }
    if (!_rim.isAnimating && _rim.status != AnimationStatus.completed) _rim.forward();
  }

  // -- drag ------------------------------------------------------------------------

  void _dragStart(DragStartDetails d) {
    if (_o.isAnimating || _y.isAnimating) {
      if (_y.isAnimating && _move != null) glassFire(ref, HapticEvent.motionCatch);
      _y.stop();
      _endMove();
    }
    _dragging = true;
    _drag = Offset(_x.value, _y.value);
    _updateTimer();
  }

  void _dragUpdate(DragUpdateDetails d) {
    _drag += d.delta;
    // Down holds (rubber-banded); up and sideways track 1:1.
    _y.value = _drag.dy > 0 ? rubberband(_drag.dy, 300, 0.35) : _drag.dy;
    _x.value = _drag.dx;
  }

  void _dragEnd(DragEndDetails d) {
    _dragging = false;
    final v = d.velocity.pixelsPerSecond;
    // glass 4.4: a release whose projection passes 40 px up or sideways dismisses it.
    final away = project(_y.value, v.dy) <= -40 || project(_x.value, v.dx).abs() >= 40;
    if (away) {
      ref.read(glassToastProvider.notifier).dismiss(e.id);
    } else {
      _y.animateWith(SpringSimulation(springOf(gt.springSettle), _y.value, 0, v.dy));
      _x.animateWith(SpringSimulation(springOf(gt.springSettle), _x.value, 0, v.dx));
      _updateTimer();
    }
  }

  // -- build ------------------------------------------------------------------------

  Color get _color => switch (e.spec.kind) {
        GlassToastKind.info => gt.colorInfo,
        GlassToastKind.success => gt.colorSuccess,
        GlassToastKind.warning => gt.colorWarning,
        GlassToastKind.error => gt.colorDanger,
      };

  IconData get _glyph => switch (e.spec.kind) {
        GlassToastKind.info => PhosphorFill.bellSimple,
        GlassToastKind.success => PhosphorFill.checkCircle,
        GlassToastKind.warning => GlassGlyph.warningCircle.fill,
        GlassToastKind.error => GlassGlyph.warningCircle.fill,
      };

  @override
  Widget build(BuildContext context) {
    final hit = GlassFrame.hitMin(context);
    final spec = e.spec;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final multi = scale >= 1.6;
    final content = Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: multi ? 12 : 0),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: multi ? 60 : 44),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassBacking(size: 28, child: Icon(_glyph, size: 20, color: _color)),
            const SizedBox(width: 10),
            Flexible(child: GlassText(spec.message, role: gt.typeCallout, onGlass: true, maxScale: 1.5)),
            if (spec.undo != null || spec.actionLabel != null) ...[
              const SizedBox(width: 8),
              GlassButton(
                label: spec.undo != null ? 'Undo' : spec.actionLabel!,
                variant: GlassButtonVariant.plain,
                size: GlassButtonSize.small,
                onPressed: () {
                  if (spec.undo != null) {
                    ref.read(glassToastProvider.notifier).undoLast();
                  } else {
                    spec.onAction?.call();
                    ref.read(glassToastProvider.notifier).dismiss(e.id);
                  }
                },
              ),
            ],
            GlassCloseButton(
              key: ValueKey('glass-toast-close-${e.id}'),
              label: 'Dismiss',
              visual: 24,
              glyphSize: 16,
              filled: false,
              onTap: () => ref.read(glassToastProvider.notifier).dismiss(e.id),
            ),
          ],
        ),
      ),
    );

    final capsule = Stack(
          children: [
            const Positioned.fill(
              child: SkinGlass(tier: GlassTierId.t2, shape: GlassShape.superellipse(22), layer: GlassLayerKind.hud, debugLabel: 'GlassToast', child: SizedBox.shrink()),
            ),
            if (spec.undo != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _rim,
                    builder: (context, _) => CustomPaint(painter: _RimSweepPainter(consumed: widget.forceRim ?? _rim.value, radius: 22, color: gt.colorOnGlass)),
                  ),
                ),
              ),
            GlassHost(child: content),
          ],
        );

    return MouseRegion(
      onEnter: (_) {
        _hover = true;
        _updateTimer();
      },
      onExit: (_) {
        _hover = false;
        _updateTimer();
      },
      child: Listener(
        onPointerDown: (_) {
          _touch = true;
          _updateTimer();
        },
        onPointerUp: (_) {
          _touch = false;
          _updateTimer();
        },
        onPointerCancel: (_) {
          _touch = false;
          _updateTimer();
        },
        child: GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          onPanStart: _dragStart,
          onPanUpdate: _dragUpdate,
          onPanEnd: _dragEnd,
          child: Focus(
            focusNode: e.focus,
            onKeyEvent: (n, ev) {
              if (ev is KeyDownEvent && ev.logicalKey == LogicalKeyboardKey.escape) {
                ref.read(glassToastProvider.notifier).dismiss(e.id);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Semantics(
              liveRegion: true,
              container: true,
              label: spec.message,
              onDismiss: () => ref.read(glassToastProvider.notifier).dismiss(e.id),
              customSemanticsActions: {
                const CustomSemanticsAction(label: 'Dismiss'): () => ref.read(glassToastProvider.notifier).dismiss(e.id),
              },
              child: AnimatedBuilder(
                animation: Listenable.merge([_y, _x, _o]),
                child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 420, minHeight: hit > 44 ? 44 : 44), child: capsule),
                builder: (context, child) {
                  final rank = widget.rank;
                  final behind = rank > 0;
                  return Opacity(
                    opacity: _o.value.clamp(0.0, 1.0) * (behind ? 0.9 : 1),
                    child: Transform.translate(
                      offset: Offset(_x.value, _y.value + 8.0 * rank),
                      child: Transform.scale(key: ValueKey('glass-toast-scale-${e.id}'), scale: math.pow(0.94, rank).toDouble(), child: child),
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
}

/// The draining rim: a `SweepGradient`-masked outline that starts at 12 o'clock and runs clockwise; the part
/// already consumed is transparent.
class _RimSweepPainter extends CustomPainter {
  const _RimSweepPainter({required this.consumed, required this.radius, required this.color});
  final double consumed;
  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final c = consumed.clamp(0.0, 1.0);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [color.withValues(alpha: 0), color.withValues(alpha: 0), color, color],
        stops: [0, c, c, 1],
      ).createShader(rect);
    canvas.drawPath(GlassShape.superellipse(radius).path(rect.deflate(0.75)), paint);
  }

  @override
  bool shouldRepaint(_RimSweepPainter old) => old.consumed != consumed || old.color != color;
}
