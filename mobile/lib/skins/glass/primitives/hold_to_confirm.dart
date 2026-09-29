import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/glass_motion_recorder.dart' show GlassMotionEntry;
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/hold.dart';
import 'package:manhwamaniacs/skins/glass/primitives/liquid_progress.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';
import 'package:motor/motor.dart';

/// Where the always-visible alternative lives (WCAG 2.5.1; glass 7.1, 14.8).
enum HoldMode {
  /// A click calls [HoldToConfirm.onRequestConfirm], which opens the confirm alert.
  standalone,

  /// Inside an alert: the widget renders the explicit confirm button under itself, visibly, for everyone.
  inAlert,
}

/// The 1,200 ms liquid hold (glass 7.1, 4.6). The state machine is `hold.dart`; this widget is its view:
/// a `glassThin` capsule, L 50, whose `iris600` fill rises from 200 ms with a 3 px meniscus.
class HoldToConfirm extends ConsumerStatefulWidget {
  const HoldToConfirm({
    super.key,
    required this.label,
    required this.onConfirm,
    this.onRequestConfirm,
    this.mode = HoldMode.standalone,
    this.fallbackLabel = 'Confirm',
    this.icon,
    this.twin,
    this.forceStates = GlassWidgetStates.none,
    this.forceHelper,
  }) : assert(mode == HoldMode.inAlert || onRequestConfirm != null, 'A standalone hold needs onRequestConfirm: the fallback is never optional (WCAG 2.5.1).');

  final String label;
  final VoidCallback onConfirm;
  final VoidCallback? onRequestConfirm;
  final HoldMode mode;
  final String fallbackLabel;
  final GlassButtonIcon? icon;
  final GlassTwin? twin;
  final GlassWidgetStates forceStates;

  /// For captures: show this helper line.
  final String? forceHelper;

  @override
  ConsumerState<HoldToConfirm> createState() => _HoldToConfirmState();
}

class _HoldToConfirmState extends ConsumerState<HoldToConfirm> with TickerProviderStateMixin {
  final HoldMachine _m = HoldMachine();
  Duration _t0 = Duration.zero;
  double _nowMs = 0;
  late final Ticker _ticker = createTicker(_onTick);
  late final SingleMotionController _drain = SingleMotionController(motion: SpringMotion(springOf(gt.springDismiss)), vsync: this);
  final FocusNode _fallback = FocusNode(debugLabel: 'HoldToConfirm.fallback');
  double _level = 0;
  bool _filling = false;
  bool _flash = false;
  String? _helper;
  Timer? _helperTimer;
  Timer? _flashTimer;
  GlassMotionEntry? _holdEntry;

  bool get _reduced => ref.read(glassMotionPrefsProvider).reduced;

  @override
  void initState() {
    super.initState();
    _ticker.isActive; // create the ticker while the element is active
    _drain.value = 0;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _drain.dispose();
    _fallback.dispose();
    _helperTimer?.cancel();
    _flashTimer?.cancel();
    super.dispose();
  }

  double get _t => _nowMs;

  void _onTick(Duration elapsed) {
    _nowMs = elapsed.inMicroseconds / 1000;
    _handle(_m.tick(_t));
    final l = _m.levelAt(_t, stepped: _reduced);
    if (l != _level) setState(() => _level = l);
    if (!_m.active) _ticker.stop();
  }

  void _showHelper(String text) {
    _helperTimer?.cancel();
    setState(() => _helper = text);
    _helperTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _helper = null);
    });
  }

  void _handle(List<HoldEvent> events) {
    for (final e in events) {
      switch (e) {
        case HoldClick():
          _click();
        case HoldCancel():
          _endFill(drain: false);
        case HoldFillStart():
          setState(() => _filling = true);
          _holdEntry = GlassMotion.recorder.begin(MotionName.holdFill.label, 1000);
        case HoldRamp():
          glassFire(ref, HapticEvent.holdRamp);
        case HoldAborted(:final level):
          _drainFrom(level);
          _showHelper('Keep holding, or tap once to confirm');
        case HoldDone():
          _done();
      }
    }
  }

  void _click() {
    if (widget.mode == HoldMode.standalone) {
      widget.onRequestConfirm!.call();
    } else {
      _fallback.requestFocus();
      _showHelper('Hold, or use the button below');
    }
  }

  void _endEntry() {
    final e = _holdEntry;
    _holdEntry = null;
    if (e != null) GlassMotion.recorder.end(e);
  }

  void _endFill({required bool drain}) {
    _endEntry();
    _ticker.stop();
    if (mounted) {
      setState(() {
        _filling = false;
        _level = 0;
      });
    }
  }

  void _drainFrom(double level) {
    _endEntry();
    _ticker.stop();
    _filling = false;
    _level = 0;
    if (_reduced) {
      _drain.value = 0;
      setState(() {});
    } else {
      _drain.value = level;
      unawaited(GlassMotion.playMotor(MotionName.drain, _drain, 0));
      setState(() {});
    }
  }

  void _done() {
    _endEntry();
    _ticker.stop();
    glassFire(ref, HapticEvent.holdDone);
    setState(() {
      _flash = true;
      _level = 1;
    });
    widget.onConfirm();
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() {
        _flash = false;
        _filling = false;
        _level = 0;
      });
    });
  }

  void _down(PointerDownEvent e) {
    _drain.stop();
    _drain.value = 0;
    _t0 = e.timeStamp;
    _nowMs = 0;
    _m.down(0, e.position);
    if (!_ticker.isActive) unawaited(_ticker.start());
  }

  @override
  Widget build(BuildContext context) {
    final legible = ref.watch(glassA11yProvider.select((a) => a.legible));
    final reduced = ref.watch(glassReducedProvider);
    final states = widget.forceStates;
    final label = _filling && !_flash ? 'Keep holding…' : widget.label;
    final st = roleStyle(context, gt.typeHeadline, onGlass: true, legible: legible, maxScale: 1.5);
    final w = [widget.label, 'Keep holding…'].map((t) => measureText(context, t, st).width).reduce((a, b) => a > b ? a : b);
    final size = Size((w + 24 * 2 + (widget.icon != null ? 28 : 0)).ceilToDouble(), 50);
    final helper = widget.forceHelper ?? _helper;

    final button = GlassPressable(
      suppressTap: true,
      claimAfter: const Duration(milliseconds: 200),
      cancelDistance: double.infinity,
      onRawDown: _down,
      onRawMove: (e) {
        _nowMs = (e.timeStamp - _t0).inMicroseconds / 1000;
        _handle(_m.move(_t, e.position));
      },
      onRawUp: (e) {
        _nowMs = (e.timeStamp - _t0).inMicroseconds / 1000;
        _handle(_m.up(_t));
      },
      onRawCancel: () => _handle(_m.cancel()),
      onTap: _click,
      forceStates: states,
      semanticsLabel: widget.label,
      semanticsHint: widget.mode == HoldMode.standalone ? 'Opens a confirmation' : 'Activate to hold, or use the button below',
      builder: (context, info) => SkinGlass(
        size: size,
        tier: GlassTierId.t2,
        finish: _flash ? GlassFinishKind.tinted : GlassFinishKind.regular,
        twin: widget.twin,
        glow: info.glow,
        debugLabel: 'HoldToConfirm',
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _drain,
                  builder: (context, _) {
                    final level = _drain.value > 0 && !_filling ? _drain.value : (states.pressed && !_filling ? 0.5 : _level);
                    return CustomPaint(painter: LiquidPainter(level: level, velocity: 0, color: const Color(0x997563F2), meniscus: !reduced));
                  },
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[Icon(widget.icon!.regular, size: 20, color: gt.colorOnGlass), const SizedBox(width: 8)],
                GlassText(label, role: gt.typeHeadline, onGlass: true, maxScale: 1.5, maxLines: 1),
              ],
            ),
          ],
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        button,
        if (helper != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Semantics(liveRegion: true, child: GlassLabel(helper, role: gt.typeFootnote, color: widget.mode == HoldMode.inAlert ? gt.colorOnGlass : gt.colorLabel2, maxLines: 2)),
          ),
        if (widget.mode == HoldMode.inAlert)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: GlassButton(label: widget.fallbackLabel, onPressed: widget.onConfirm, focusNode: _fallback, size: GlassButtonSize.medium),
          ),
      ],
    );
  }
}

