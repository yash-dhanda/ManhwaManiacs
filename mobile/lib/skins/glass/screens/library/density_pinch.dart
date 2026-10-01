import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/library/utils/glass_density.dart';

/// The live pinch: the scale so far and the midpoint of the two fingers (global), or null while none is down.
typedef PinchState = ({double scale, Offset focal});

/// Density by pinch, trackpad pinch and Ctrl/Cmd + wheel (glass 8.17, 11 "Pinch the grid"). A [Listener] counts pointers: when a second
/// one lands [onPinching] says so (the grid's physics become non-scrollable for the gesture, so one-finger scrolling never meets a
/// scale recogniser); the scale is the ratio of the two pointers' distance; on release [onStep] gets [pinchSteps] (+1 larger items, -1
/// smaller, at most one per gesture). [live] carries the scale to the rows that paint it. A plain wheel is never consumed.
class DensityPinch extends StatefulWidget {
  const DensityPinch({super.key, required this.child, required this.live, required this.onStep, this.onPinching, this.wheel = true});
  final Widget child;
  final ValueNotifier<PinchState?> live;

  /// `+1` toward larger items, `-1` toward smaller.
  final ValueChanged<int> onStep;
  final ValueChanged<bool>? onPinching;

  /// Hardware mouse: Ctrl/Cmd + wheel steps density (tablet and desktop frames).
  final bool wheel;

  @override
  State<DensityPinch> createState() => _DensityPinchState();
}

class _DensityPinchState extends State<DensityPinch> {
  final Map<int, Offset> _pointers = {};
  double _start = 0;
  bool _pinching = false;
  final WheelAccumulator _wheel = WheelAccumulator();

  double get _distance {
    final p = _pointers.values.toList();
    return p.length < 2 ? 0 : (p[0] - p[1]).distance;
  }

  Offset get _focal {
    final p = _pointers.values.toList();
    return (p[0] + p[1]) / 2;
  }

  void _begin() {
    _pinching = true;
    _start = _distance;
    widget.onPinching?.call(true);
  }

  void _end({double? scale}) {
    if (!_pinching) return;
    _pinching = false;
    final s = scale ?? widget.live.value?.scale ?? 1;
    widget.live.value = null;
    widget.onPinching?.call(false);
    widget.onStep(pinchSteps(s));
  }

  @override
  Widget build(BuildContext context) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (e) {
          if (e.kind == PointerDeviceKind.mouse) return;
          _pointers[e.pointer] = e.position;
          if (_pointers.length == 2 && !_pinching && _distance > 0) _begin();
        },
        onPointerMove: (e) {
          if (!_pointers.containsKey(e.pointer)) return;
          _pointers[e.pointer] = e.position;
          if (_pinching && _pointers.length >= 2 && _start > 0) widget.live.value = (scale: _distance / _start, focal: _focal);
        },
        onPointerUp: (e) {
          final was = _pinching;
          final scale = was && _start > 0 && _pointers.length >= 2 ? _distance / _start : null;
          _pointers.remove(e.pointer);
          if (was && _pointers.length < 2) _end(scale: scale);
        },
        onPointerCancel: (e) {
          _pointers.remove(e.pointer);
          if (_pinching && _pointers.length < 2) {
            _pinching = false;
            widget.live.value = null;
            widget.onPinching?.call(false);
          }
        },
        onPointerPanZoomStart: (e) {
          _pinching = true;
          widget.onPinching?.call(true);
        },
        onPointerPanZoomUpdate: (e) {
          if (_pinching) widget.live.value = (scale: e.scale, focal: e.position);
        },
        onPointerPanZoomEnd: (e) => _end(),
        onPointerSignal: (e) {
          if (!widget.wheel || e is! PointerScrollEvent) return;
          final kb = HardwareKeyboard.instance;
          if (!kb.isControlPressed && !kb.isMetaPressed) return;
          GestureBinding.instance.pointerSignalResolver.register(e, (_) {});
          final steps = _wheel.add(e.scrollDelta.dy, e.timeStamp);
          if (steps != 0) widget.onStep(steps);
        },
        child: widget.child,
      );
}
