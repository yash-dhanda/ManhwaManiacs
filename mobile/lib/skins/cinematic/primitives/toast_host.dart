import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/network/db_busy.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_announce.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Where the stack sits (cinematic 7.11 "Reader and Page frames").
enum CineToastFrame { page, reader }

/// The stock colours of the novel reader's page frame.
typedef CineToastStock = ({Color page, Color ink, Color muted});

/// Hosts the toast stack over [child] with one `OverlayEntry`. mobile/06 mounts one in the shell.
///
/// [anchorBottom] is the distance from the bottom edge (thumb index height + 16, or the safe area
/// + 16); [bannerHeight] lifts the stack `bannerHeight + 8` and shows one toast; [frame] `reader`
/// sits [readerBottomInset] + 16 above the highest bottom element, or 24 when it is 0.
class CineToastHost extends ConsumerStatefulWidget {
  const CineToastHost({
    super.key,
    required this.child,
    this.anchorBottom = 16,
    this.bannerHeight = 0,
    this.frame = CineToastFrame.page,
    this.readerBottomInset = 0,
    this.stockColours,
    this.hidden = false,
  });

  final Widget child;

  /// Hides the stack (a Lightbox route is on top).
  final bool hidden;
  final double anchorBottom, bannerHeight, readerBottomInset;
  final CineToastFrame frame;
  final CineToastStock? stockColours;

  /// The nearest host, for `focusNewestAction()` (mobile/06 binds `Alt+T` to it).
  static CineToastHostState? maybeOf(BuildContext context) => context.findAncestorStateOfType<CineToastHostState>();

  @override
  ConsumerState<CineToastHost> createState() => CineToastHostState();
}

class _Shown {
  _Shown(this.toast, this.key);
  final CineToast toast;
  final GlobalKey<_ToastSlotState> key;
  bool leaving = false;
}

class CineToastHostState extends ConsumerState<CineToastHost> {
  late final OverlayEntry _childEntry = OverlayEntry(builder: (_) => widget.child);
  late final OverlayEntry _toastEntry = OverlayEntry(builder: _layer);
  final List<_Shown> _shown = [];
  bool _pausedAll = false;

  @override
  void didUpdateWidget(CineToastHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    _childEntry.markNeedsBuild();
    _toastEntry.markNeedsBuild();
  }

  @override
  void dispose() {
    _childEntry.remove();
    _toastEntry.remove();
    _childEntry.dispose();
    _toastEntry.dispose();
    super.dispose();
  }

  int get _maxVisible => widget.bannerHeight > 0 ? 1 : 2;

  /// Reconciles [_shown] with the queue: newest [_maxVisible] stay, the rest are dropped.
  void _sync(List<CineToast> queue) {
    final live = queue.length > _maxVisible ? queue.sublist(queue.length - _maxVisible) : queue;
    for (final s in _shown) {
      if (!s.leaving && !live.any((t) => t.id == s.toast.id)) s.leaving = true;
    }
    for (final t in live) {
      if (!_shown.any((s) => s.toast.id == t.id)) _shown.add(_Shown(t, GlobalKey<_ToastSlotState>()));
    }
    if (queue.length > live.length) {
      final drop = [for (final t in queue.sublist(0, queue.length - live.length)) t.id];
      scheduleMicrotask(() {
        if (!mounted) return;
        for (final id in drop) {
          ref.read(cineToastsProvider.notifier).dismiss(id);
        }
      });
    }
  }

  void _gone(int id) {
    _shown.removeWhere((s) => s.toast.id == id);
    _toastEntry.markNeedsBuild();
  }

  /// Moves focus to the newest toast's action and pauses every hold.
  void focusNewestAction() {
    for (final s in _shown.reversed) {
      if (s.leaving || !s.toast.hasAction) continue;
      _pausedAll = true;
      _toastEntry.markNeedsBuild();
      s.key.currentState?.focusAction();
      return;
    }
  }

  void _focusLeft() {
    if (!_pausedAll) return;
    _pausedAll = false;
    _toastEntry.markNeedsBuild();
  }

  Widget _layer(BuildContext context) => Consumer(
        builder: (context, ref, _) {
          final queue = ref.watch(cineToastsProvider);
          _sync(queue);
          final c = context.cine;
          final safe = MediaQuery.viewPaddingOf(context).bottom;
          double bottom;
          if (widget.frame == CineToastFrame.reader) {
            bottom = (widget.readerBottomInset > 0 ? widget.readerBottomInset + 16 : 24 + safe);
          } else {
            bottom = widget.anchorBottom;
          }
          if (widget.bannerHeight > 0) bottom += widget.bannerHeight + 8;
          if (widget.hidden) return const SizedBox.shrink();
          final visible = [for (final s in _shown) s];
          return Positioned.fill(
            child: Padding(
              padding: EdgeInsets.fromLTRB(c.space4, 0, c.space4, bottom),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    // Newest first, growing upwards: a new toast pushes the older one up.
                    verticalDirection: VerticalDirection.up,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final s in visible.reversed)
                        Padding(
                          key: ValueKey('toast-${s.toast.id}'),
                          padding: EdgeInsets.only(top: c.space2),
                          child: _ToastSlot(
                            key: s.key,
                            toast: s.toast,
                            leaving: s.leaving,
                            paused: _pausedAll,
                            stock: widget.stockColours,
                            onDismiss: () => ref.read(cineToastsProvider.notifier).dismiss(s.toast.id),
                            onGone: () => _gone(s.toast.id),
                            onFocusLeft: _focusLeft,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(dbBusyExhaustedProvider, (a, b) {
      if (b > (a ?? 0)) ref.read(cineToastsProvider.notifier).info('The server is busy. Your progress is saved on this device and will sync.');
    });
    // Re-run the reconcile when the queue changes even if the layer did not rebuild first.
    ref.listen<List<CineToast>>(cineToastsProvider, (_, __) => _toastEntry.markNeedsBuild());
    return Overlay(initialEntries: [_childEntry, _toastEntry]);
  }
}

class _ToastSlot extends StatefulWidget {
  const _ToastSlot({
    super.key,
    required this.toast,
    required this.leaving,
    required this.paused,
    required this.stock,
    required this.onDismiss,
    required this.onGone,
    required this.onFocusLeft,
  });

  final CineToast toast;
  final bool leaving, paused;
  final CineToastStock? stock;
  final VoidCallback onDismiss, onGone, onFocusLeft;

  @override
  State<_ToastSlot> createState() => _ToastSlotState();
}

class _ToastSlotState extends State<_ToastSlot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  final _action = FocusNode(debugLabel: 'toast-action');
  Timer? _hold;
  bool _focusInside = false, _entered = false, _exiting = false;
  double _drag = 0;
  Duration _left = Duration.zero;
  DateTime? _startedAt;

  @override
  void initState() {
    super.initState();
    _left = widget.toast.hold;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_entered) {
      if (widget.toast.kind == CineToastKind.error) cineAnnounce(context, widget.toast.text);
      _entered = true;
      if (CineMotion.reduced(context)) {
        CineMotion.play(MotionName.set, _c, duration: CineDur.reduced, curve: Curves.linear);
      } else {
        CineMotion.play(MotionName.set, _c, duration: CineDur.line, curve: CineCurves.easeSet);
      }
    }
    _schedule();
  }

  @override
  void didUpdateWidget(_ToastSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.leaving && !_exiting) _exit();
    _schedule();
  }

  bool get _sticky =>
      _focusInside || widget.paused || (MediaQuery.accessibleNavigationOf(context) && widget.toast.hasAction);

  void _schedule() {
    if (_exiting) return;
    if (_sticky) {
      if (_startedAt != null) {
        _left -= DateTime.now().difference(_startedAt!);
        if (_left < Duration.zero) _left = Duration.zero;
      }
      _startedAt = null;
      _hold?.cancel();
      _hold = null;
    } else if (_hold == null) {
      _startedAt = DateTime.now();
      _hold = Timer(_left, widget.onDismiss);
    }
  }

  void _exit() {
    if (_exiting) return;
    _exiting = true;
    _hold?.cancel();
    final reduced = CineMotion.reduced(context);
    CineMotion.play(MotionName.set, _c,
            target: 0, duration: reduced ? CineDur.reduced : CineDur.beat, curve: reduced ? Curves.linear : CineCurves.lift,)
        .whenComplete(() {
      if (mounted) widget.onGone();
    });
  }

  void focusAction() => _action.requestFocus();

  @override
  void dispose() {
    _hold?.cancel();
    _action.dispose();
    _c.dispose();
    super.dispose();
  }

  void _act() {
    final t = widget.toast;
    if (t.kind == CineToastKind.undo) {
      cineFeedback(context, HapticEvent.undo, sound: SoundEvent.undo);
    } else {
      cineFeedback(context, HapticEvent.tapSecondary);
    }
    t.onAction?.call();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final t = widget.toast;
    final reduced = CineMotion.reduced(context);
    final edge = switch (t.kind) {
      CineToastKind.error => c.colorProof,
      CineToastKind.success => c.colorSet,
      _ => c.colorSpot,
    };
    final stock = widget.stock;
    final ink = stock?.ink ?? c.colorInk100;
    Widget body = Container(
      decoration: BoxDecoration(
        color: stock?.page ?? c.colorPaper2,
        border: Border.all(color: stock?.muted ?? c.colorRule2),
      ),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(width: 2, color: edge),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                Expanded(child: CineRoleText(t.text, c.typeUi, color: ink)),
                if (t.hasAction) ...[
                  SizedBox(width: c.space4),
                  CinePressable(
                    focusNode: _action,
                    onTap: _act,
                    builder: (context, st) => CineRoleText(t.actionLabel!, c.typeLabel, color: ink),
                  ),
                ],
              ],),
            ),
          ),
        ],),
      ),
    );
    body = stock == null ? CineStock.raised(body) : body;
    body = CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): widget.onDismiss},
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (v) {
          _focusInside = v;
          if (!v) widget.onFocusLeft();
          _schedule();
        },
        child: body,
      ),
    );
    return Semantics(
      liveRegion: true,
      container: true,
      label: t.text,
      child: GestureDetector(
        onVerticalDragStart: (_) => _drag = 0,
        onVerticalDragUpdate: (d) => _drag += d.delta.dy,
        onVerticalDragEnd: (d) {
          if (_drag > 24 || d.velocity.pixelsPerSecond.dy > 600) widget.onDismiss();
        },
        child: AnimatedBuilder(
          animation: _c,
          child: body,
          builder: (_, child) => Opacity(
            opacity: _c.value.clamp(0.0, 1.0),
            child: reduced
                ? child
                : Align(
                    alignment: Alignment.bottomCenter,
                    heightFactor: CineCurves.easeSet.transform(_c.value.clamp(0.0, 1.0)),
                    child: Transform.translate(offset: Offset(0, 8 * (1 - _c.value)), child: child),
                  ),
          ),
        ),
      ),
    );
  }
}
