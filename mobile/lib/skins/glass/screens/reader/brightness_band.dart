import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/brightness_band_math.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/reader_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// Wins the arena for a pointer that went down inside the band once it has moved 10 px with `|dy| > 2 |dx|` (before the strip's
/// 18 px scroll slop); a pointer that moves sideways first is released to the strip. Pointers outside the band are never tracked.
class BrightnessBandRecognizer extends OneSequenceGestureRecognizer {
  BrightnessBandRecognizer({required this.inBand, super.debugOwner});

  final bool Function(Offset local) inBand;
  GestureDragStartCallback? onStart;
  void Function(double dy, Offset local)? onUpdate;
  VoidCallback? onEnd;

  Offset? _start;
  bool _accepted = false;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (!inBand(event.localPosition)) return;
    super.addAllowedPointer(event);
    _start = event.localPosition;
    _accepted = false;
  }

  @override
  void handleEvent(PointerEvent event) {
    final start = _start;
    if (start == null) return;
    if (event is PointerMoveEvent) {
      final d = event.localPosition - start;
      if (!_accepted) {
        final a = bandActivates(d.dx, d.dy);
        if (a ?? false) {
          _accepted = true;
          resolve(GestureDisposition.accepted);
          onStart?.call(DragStartDetails(globalPosition: event.position, localPosition: event.localPosition));
        } else if (a == false) {
          resolve(GestureDisposition.rejected);
          stopTrackingPointer(event.pointer);
          return;
        }
      }
      if (_accepted) onUpdate?.call(d.dy, event.localPosition);
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      if (_accepted) onEnd?.call();
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _start = null;
    _accepted = false;
  }

  @override
  String get debugDescription => 'brightness band';
}

/// The phone-only left-edge brightness band (glass 8.14.3): portrait phones, iOS x 24 to 24 + 12 % of the width, Android from the
/// edge. Up raises, down lowers (20 to 100 % over 60 % of the height); [onChanged] applies live, [onCommit] writes
/// `glass.brightness` on release. While dragging a 36 x 140 `glassThin` HUD sits 12 px right of the band, centred on the finger;
/// it fades 600 ms after release.
class BrightnessBand extends StatefulWidget {
  const BrightnessBand({
    super.key,
    required this.enabled,
    required this.brightness,
    required this.onChanged,
    required this.onCommit,
    required this.child,
    this.forceHud,
  });

  final bool enabled;
  final double brightness;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onCommit;
  final Widget child;

  /// Captures: the HUD at this finger y.
  final double? forceHud;

  @override
  State<BrightnessBand> createState() => _BrightnessBandState();
}

class _BrightnessBandState extends State<BrightnessBand> {
  double _from = 1;
  double _value = 1;
  double? _fingerY;
  bool _hud = false;
  Timer? _fade;

  @override
  void dispose() {
    _fade?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final platform = defaultTargetPlatform;
    final range = brightnessBandRange(size.width, platform);
    final hudY = widget.forceHud ?? _fingerY;
    final value = widget.forceHud != null ? widget.brightness : _value;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        RawGestureDetector(
          behavior: HitTestBehavior.translucent,
          gestures: {
            if (widget.enabled)
              BrightnessBandRecognizer: GestureRecognizerFactoryWithHandlers<BrightnessBandRecognizer>(
                () => BrightnessBandRecognizer(inBand: (p) => inBrightnessBand(p.dx, size.width, platform), debugOwner: this),
                (r) => r
                  ..onStart = (d) {
                    _fade?.cancel();
                    setState(() {
                      _from = widget.brightness;
                      _value = _from;
                      _hud = true;
                      _fingerY = d.localPosition.dy;
                    });
                  }
                  ..onUpdate = (dy, local) {
                    final v = bandBrightness(_from, dy, size.height);
                    setState(() {
                      _value = v;
                      _fingerY = local.dy;
                    });
                    widget.onChanged(v);
                  }
                  ..onEnd = () {
                    widget.onCommit(_value);
                    _fade = Timer(const Duration(milliseconds: 600), () {
                      if (mounted) setState(() => _hud = false);
                    });
                  },
              ),
          },
          child: widget.child,
        ),
        if (hudY != null)
          Positioned(
            left: range.end + 12,
            top: (hudY - 70).clamp(8.0, size.height - 148),
            child: AnimatedOpacity(
              opacity: _hud || widget.forceHud != null ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: _BandHud(value: value),
            ),
          ),
      ],
    );
  }
}

class _BandHud extends StatelessWidget {
  const _BandHud({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    final f = ((value - 0.2) / 0.8).clamp(0.0, 1.0);
    return IgnorePointer(
      child: Semantics(
        label: 'Brightness ${(value * 100).round()} %',
        child: SkinGlass(
          size: const Size(36, 140),
          tier: GlassTierId.t2,
          layer: GlassLayerKind.hud,
          debugLabel: 'reader brightness HUD',
          child: Column(
            children: [
              const SizedBox(height: 10),
              Icon(ReaderGlyph.sun.regular, size: 16, color: gt.colorOnGlass),
              const SizedBox(height: 6),
              Expanded(
                child: Container(
                  width: 8,
                  decoration: BoxDecoration(color: gt.colorWellOnGlass, borderRadius: BorderRadius.circular(4)),
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: f,
                    child: Container(decoration: BoxDecoration(color: gt.colorOnGlass, borderRadius: BorderRadius.circular(4))),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              GlassText('${(value * 100).round()}', role: gt.typeCaption1, onGlass: true),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
