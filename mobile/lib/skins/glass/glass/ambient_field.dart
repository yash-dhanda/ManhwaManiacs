import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/skins/glass/glass/palette.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

/// What a screen declares for the field behind it (glass 2.1.8): a cover palette, a mood, or the brand aurora.
@immutable
class GlassAmbientSpec {
  const GlassAmbientSpec.palette(CoverPalette this.palette, {required this.opacity, this.fallbackMood = Mood.neutral})
      : mood = null,
        aurora = false;
  const GlassAmbientSpec.mood(Mood this.mood, {double? opacity})
      : palette = null,
        aurora = false,
        fallbackMood = Mood.neutral,
        opacity = opacity ?? -1;
  const GlassAmbientSpec.aurora({this.opacity = 0.20})
      : palette = null,
        mood = null,
        aurora = true,
        fallbackMood = Mood.neutral;

  final CoverPalette? palette;
  final Mood? mood;
  final bool aurora;
  final Mood fallbackMood;

  /// Blob alpha; -1 for a mood means "the mood's own".
  final double opacity;

  @override
  bool operator ==(Object other) =>
      other is GlassAmbientSpec &&
      other.palette == palette &&
      other.mood == mood &&
      other.aurora == aurora &&
      other.opacity == opacity &&
      other.fallbackMood == fallbackMood;

  @override
  int get hashCode => Object.hash(palette, mood, aurora, opacity, fallbackMood);
}

/// The mood colours and their own opacities (glass 2.1.6, 2.1.8 "mood fallback before data").
const Map<Mood, double> kMoodOpacity = {
  Mood.romantic: 0.20,
  Mood.action: 0.20,
  Mood.comedy: 0.16,
  Mood.horror: 0.26,
  Mood.sliceOfLife: 0.16,
  Mood.fantasy: 0.22,
  Mood.neutral: 0.30,
};

Color moodColour(Mood m) {
  const t = glassTokens;
  return switch (m) {
    Mood.romantic => t.colorMoodRomantic,
    Mood.action => t.colorMoodAction,
    Mood.comedy => t.colorMoodComedy,
    Mood.horror => t.colorMoodHorror,
    Mood.sliceOfLife => t.colorMoodSliceOfLife,
    Mood.fantasy => t.colorMoodFantasy,
    Mood.neutral => t.colorMoodDefault,
  };
}

/// Default mood's second colour (glass 2.1.8: `#4336A3` + `#2B2370`).
const Color kMoodDefaultDeep = Color(0xFF2B2370);

/// The resolved blobs of a spec: three colours, the size each draws at, and the alpha.
class GlassBlobs {
  const GlassBlobs(this.colors, this.scales, this.alpha);
  final List<Color> colors;
  final List<double> scales;
  final double alpha;

  static GlassBlobs of(GlassAmbientSpec s) {
    const t = glassTokens;
    if (s.aurora) return GlassBlobs([t.colorAurora1, t.colorAurora2, t.colorAurora3], const [1, 1, 1], s.opacity);
    if (s.palette != null) {
      final f = fieldColours(s.palette, moodColour(s.fallbackMood));
      return GlassBlobs(f.colors, f.scales, s.opacity);
    }
    final m = s.mood!;
    final a = s.opacity >= 0 ? s.opacity : kMoodOpacity[m]!;
    if (m == Mood.neutral) return GlassBlobs([t.colorMoodDefault, kMoodDefaultDeep, t.colorMoodDefault], const [1, 1, 1], a);
    final c = moodColour(m);
    return GlassBlobs([c, c, c], const [1, 0.6, 0.6], a);
  }
}

/// The screen's declaration.
final glassAmbientProvider = StateProvider<GlassAmbientSpec?>((ref) => null);

/// A screen wraps itself in this to declare its field; leaving the screen clears it.
class GlassAmbientScope extends ConsumerStatefulWidget {
  const GlassAmbientScope({super.key, required this.spec, required this.child});
  final GlassAmbientSpec spec;
  final Widget child;

  @override
  ConsumerState<GlassAmbientScope> createState() => _GlassAmbientScopeState();
}

class _GlassAmbientScopeState extends ConsumerState<GlassAmbientScope> {
  late final StateController<GlassAmbientSpec?> _target = ref.read(glassAmbientProvider.notifier);

  void _publish() => Future.microtask(() {
        if (mounted && _target.mounted && _target.state != widget.spec) _target.state = widget.spec;
      });

  @override
  void initState() {
    super.initState();
    _publish();
  }

  @override
  void didUpdateWidget(GlassAmbientScope old) {
    super.didUpdateWidget(old);
    if (old.spec != widget.spec) _publish();
  }

  @override
  void dispose() {
    final spec = widget.spec, target = _target;
    Future.microtask(() {
      if (target.mounted && target.state == spec) target.state = null;
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Blob centres as fractions of the viewport (glass 2.1.8).
const List<Offset> kFieldAnchors = [Offset(0.18, 0.08), Offset(0.78, 0.14), Offset(0.46, 0.36)];

/// Every 14 s each anchor takes a new random target within +-6 %.
const Duration kDriftEvery = Duration(seconds: 14);
const double kDriftRange = 0.06;

/// The field: ONE `CustomPaint` behind content (z 0.5), no `BackdropFilter`, no `ImageFiltered`.
class GlassAmbientField extends ConsumerStatefulWidget {
  const GlassAmbientField({super.key, this.random});

  /// Test seam for the drift targets.
  final math.Random? random;

  @override
  ConsumerState<GlassAmbientField> createState() => GlassAmbientFieldState();
}

class GlassAmbientFieldState extends ConsumerState<GlassAmbientField> with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _shift = AnimationController(vsync: this, duration: glassTokens.curveTintShift.duration, value: 1);
  late final AnimationController _drift = AnimationController.unbounded(vsync: this, value: 1);
  late final math.Random _rng = widget.random ?? math.Random();

  GlassBlobs _from = const GlassBlobs([Color(0x00000000), Color(0x00000000), Color(0x00000000)], [1, 1, 1], 0);
  GlassBlobs _to = const GlassBlobs([Color(0x00000000), Color(0x00000000), Color(0x00000000)], [1, 1, 1], 0);
  List<Offset> _prev = List.filled(3, Offset.zero);
  List<Offset> _next = List.filled(3, Offset.zero);
  Timer? _timer;
  bool _resumed = true;
  bool _reduced = false;

  /// The current anchor offsets (fractions of the viewport), for tests.
  @visibleForTesting
  List<Offset> get anchors => [for (var i = 0; i < 3; i++) Offset.lerp(_prev[i], _next[i], _drift.value.clamp(0.0, 1.0))!];

  /// The colours being drawn right now, for tests.
  @visibleForTesting
  List<Color> get currentColours => _blend().colors;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.listenManual<GlassAmbientSpec?>(glassAmbientProvider, (_, s) => _onSpec(s), fireImmediately: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    _startTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _shift.dispose();
    _drift.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = null;
    if (_reduced || !_resumed || !TickerMode.valuesOf(context).enabled) return; // frozen; paused offscreen and in the background
    _timer = Timer.periodic(kDriftEvery, (_) {
      if (!mounted || _reduced || !_resumed) return;
      _prev = anchors;
      _next = [for (var i = 0; i < 3; i++) Offset((_rng.nextDouble() * 2 - 1) * kDriftRange, (_rng.nextDouble() * 2 - 1) * kDriftRange)];
      _drift.value = 0;
      _drift.animateWith(SpringSimulation(springOf(glassTokens.springDrift), 0, 1, 0));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startTimer();
  }

  GlassBlobs _blend() {
    final t = _shift.value.clamp(0.0, 1.0);
    final c = _reduced ? Curves.linear.transform(t) : glassTokens.curveTintShift.curve.transform(t);
    return GlassBlobs(
      [for (var i = 0; i < 3; i++) Color.lerp(_from.colors[i], _to.colors[i], c)!],
      [for (var i = 0; i < 3; i++) ui.lerpDouble(_from.scales[i], _to.scales[i], c)!],
      ui.lerpDouble(_from.alpha, _to.alpha, c)!,
    );
  }

  void _onSpec(GlassAmbientSpec? spec) {
    final now = _blend();
    final target = spec == null ? GlassBlobs(now.colors, now.scales, 0) : GlassBlobs.of(spec);
    _from = now;
    _to = target;
    _shift.duration = _reduced ? glassTokens.curveReducedRoute.duration : glassTokens.curveTintShift.duration;
    _shift.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    _reduced = ref.watch(glassMotionPrefsProvider.select((m) => m.reduced));
    final solid = ref.watch(glassA11yProvider.select((a) => a.solid));
    final wide = MediaQuery.sizeOf(context).shortestSide >= 600;
    const t = glassTokens;
    final blur = wide ? t.blurFieldDesktop : t.blurFieldPhone;
    return RepaintBoundary(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: Listenable.merge([_shift, _drift]),
          builder: (context, _) => CustomPaint(
            painter: GlassFieldPainter(
              blobs: _blend(),
              anchors: anchors,
              blur: blur,
              dim: solid ? 0.5 : 1.0,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

/// Three radial gradients and the black floor, in one paint (glass 2.1.8).
class GlassFieldPainter extends CustomPainter {
  const GlassFieldPainter({required this.blobs, required this.anchors, required this.blur, this.dim = 1});

  final GlassBlobs blobs;
  final List<Offset> anchors;
  final double blur;

  /// Solid glass and Reduce Transparency: the field stays behind content at half opacity.
  final double dim;

  @override
  void paint(Canvas canvas, Size size) {
    final alpha = blobs.alpha * dim;
    if (alpha <= 0.001) return;
    final r = size.width * 0.35;
    for (var i = 0; i < 3; i++) {
      final scale = blobs.scales[i];
      final radius = r * scale;
      final centre = Offset((kFieldAnchors[i].dx + anchors[i].dx) * size.width, (kFieldAnchors[i].dy + anchors[i].dy) * size.height);
      final outer = radius + blur;
      final base = blobs.colors[i].withValues(alpha: alpha);
      canvas.drawCircle(
        centre,
        outer,
        Paint()
          ..shader = ui.Gradient.radial(
            centre,
            outer,
            [base, base, base.withValues(alpha: alpha * 0.45), base.withValues(alpha: 0)],
            [0, math.max(0, radius - blur / 2) / outer, radius / outer, 1],
          ),
      );
    }
    // The lower screen stays true black for AMOLED: g25 at 60 %, #000000 from 70 %.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, size.height),
          [const Color(0x00060608), GlassColors.g25, GlassColors.g0, GlassColors.g0],
          const [0.55, 0.60, 0.70, 1.0],
        ),
    );
  }

  @override
  bool shouldRepaint(GlassFieldPainter old) =>
      old.blobs != blobs || !listEquals(old.anchors, anchors) || old.blur != blur || old.dim != dim;
}
