import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';

/// The grain fragment shader (cinematic 15.3): Gaussian luminance noise, overlay blended over art
/// only, stepping through four offsets at 12 fps.
class CineGrain extends StatefulWidget {
  const CineGrain({super.key, required this.child, this.opacity = 0.06});
  final Widget child;
  final double opacity;

  /// Loads the program once. Tests inject a failing loader to prove the child renders alone.
  @visibleForTesting
  static Future<ui.FragmentProgram> Function() loader = () => ui.FragmentProgram.fromAsset('lib/skins/cinematic/shaders/grain.frag');

  @visibleForTesting
  static void resetForTest() {
    _program = null;
    _logged = false;
  }

  static Future<ui.FragmentProgram>? _program;
  static bool _logged = false;

  static const offsets = [Offset.zero, Offset(-64, 32), Offset(48, -96), Offset(-128, -16)];

  @override
  State<CineGrain> createState() => _CineGrainState();
}

class _CineGrainState extends State<CineGrain> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<int> _step = ValueNotifier(0);
  ui.FragmentShader? _shader;
  ScrollPosition? _pos;
  bool _failed = false, _reduced = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) => _step.value = (d.inMilliseconds ~/ 83) % CineGrain.offsets.length);
    final future = CineGrain._program ??= CineGrain.loader();
    future.then((p) {
      if (!mounted) return;
      setState(() => _shader = p.fragmentShader());
    }, onError: (Object e) {
      if (!CineGrain._logged) {
        CineGrain._logged = true;
        debugPrint('CineGrain: shader failed to load, rendering without grain: $e');
      }
      if (mounted) setState(() => _failed = true);
    },);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = CineMotion.reduced(context);
    _pos?.removeListener(_visibility);
    _pos = Scrollable.maybeOf(context)?.position;
    _pos?.addListener(_visibility);
    if (_reduced) {
      _ticker.stop();
      _step.value = 0;
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  void _visibility() {
    if (!mounted || _reduced) return;
    _ticker.muted = !cineOnScreen(context);
  }

  @override
  void dispose() {
    _pos?.removeListener(_visibility);
    _ticker.dispose();
    _step.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shader = _shader;
    if (_failed || shader == null) return widget.child;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: CustomPaint(painter: _GrainPainter(shader, _step, widget.opacity)),
            ),
          ),
        ),
      ],
    );
  }
}

class _GrainPainter extends CustomPainter {
  _GrainPainter(this.shader, this.step, this.opacity) : super(repaint: step);
  final ui.FragmentShader shader;
  final ValueNotifier<int> step;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final o = CineGrain.offsets[step.value];
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, o.dx)
      ..setFloat(3, o.dy)
      ..setFloat(4, opacity);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader..blendMode = BlendMode.overlay);
  }

  @override
  bool shouldRepaint(_GrainPainter o) => o.opacity != opacity || o.shader != shader;
}
