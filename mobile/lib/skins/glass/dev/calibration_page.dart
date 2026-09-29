import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/dev/calibration_covers.dart';
import 'package:manhwamaniacs/skins/glass/dev/dev_controls.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/ambient_field.dart';
import 'package:manhwamaniacs/skins/glass/glass/caustic.dart';
import 'package:manhwamaniacs/skins/glass/glass/follow_ring.dart';
import 'package:manhwamaniacs/skins/glass/glass/lb.dart';
import 'package:manhwamaniacs/skins/glass/glass/light_angle.dart';
import 'package:manhwamaniacs/skins/glass/glass/palette.dart';
import 'package:manhwamaniacs/skins/glass/glass/tier_math.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The "Glass calibration" page (glass 2.4.3 calibration knobs, 15.8): the checkerboard the owner counts
/// bent squares on, the accessibility controls, the legibility bar over 24 painted covers, the light
/// effects, the ambient field and the physics tile. Development only; `mobile/40` moves it into Diagnostics.
class GlassCalibrationPage extends ConsumerStatefulWidget {
  const GlassCalibrationPage({super.key});

  @override
  ConsumerState<GlassCalibrationPage> createState() => _GlassCalibrationPageState();
}

class _GlassCalibrationPageState extends ConsumerState<GlassCalibrationPage> with TickerProviderStateMixin {
  // Section 3
  final ValueNotifier<double> _barLb = ValueNotifier(1);

  // Section 4
  final ValueNotifier<GlassPressGlow?> _glow = ValueNotifier(null);
  final GlobalKey<SkinGlassState> _sweepKey = GlobalKey<SkinGlassState>();
  final GlobalKey<SkinGlassState> _demoKey = GlobalKey<SkinGlassState>();
  final GlassFollowRingController _ring = GlassFollowRingController();
  bool _pressed = false;
  int _demoGeneration = 0;
  double _demoLb = 1;

  // Section 5
  int _ambientStep = 0;

  // Section 6
  late final AnimationController _tile = AnimationController.unbounded(vsync: this);
  late final AnimationController _demo = AnimationController(vsync: this, duration: const Duration(milliseconds: 1));
  double _dragOffset = 0;
  bool _dragging = false;
  static const double _tileSize = 120;
  static const double _trackHeight = 300;
  static const List<double> _detents = [0, 90, 180];

  StateController<GlassAmbientSpec?>? _ambient;

  @override
  void initState() {
    super.initState();
    _ambient = ref.read(glassAmbientProvider.notifier);
    _tile.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    final a = _ambient;
    Future.microtask(() {
      if (a != null && a.mounted) a.state = null;
    });
    _tile.dispose();
    _demo.dispose();
    _barLb.dispose();
    _glow.dispose();
    super.dispose();
  }

  // -- section helpers -----------------------------------------------------------

  Widget _tierDemo({
    required String caption,
    required double height,
    required Widget glass,
    Alignment align = Alignment.center,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: height,
            child: Stack(
              children: [
                const Positioned.fill(child: CustomPaint(painter: _CheckerPainter(16))),
                Align(alignment: align, child: glass),
              ],
            ),
          ),
          DevCaption(caption),
        ],
      );

  String _tierCaption(GlassTierId id) {
    final p = tierParams(id);
    return '${id.name.toUpperCase()}  n $kRefractiveIndex  thickness ${p.thickness.toStringAsFixed(0)}  '
        'blur ${p.blur.toStringAsFixed(0)}  sat ${p.saturate}  CA ${p.chromatic}';
  }

  Widget _label(String s, {double? size}) => GlassText(s, role: glassTokens.typeCaption1, onGlass: true, size: size);

  Widget _checkerboard(double width) {
    final t5 = math.min(420.0, width - 32);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tierDemo(
          caption: _tierCaption(GlassTierId.t2),
          height: 120,
          glass: SkinGlass(
            tier: GlassTierId.t2,
            shape: const GlassShape.circle(),
            size: const Size(44, 44),
            debugLabel: 'calibration T2',
            child: Center(child: _label('T2')),
          ),
        ),
        const SizedBox(height: 16),
        _tierDemo(
          caption: '${_tierCaption(GlassTierId.t3)}  (dock 290 x 64 + orb 50)',
          height: 140,
          glass: SkinGlassGroup(
            debugLabel: 'calibration dock',
            shapes: [
              SkinGlassShape(size: const Size(290, 64), child: Center(child: _label('T3 dock'))),
              SkinGlassShape(size: const Size(50, 50), shape: const GlassShape.circle(), child: Center(child: _label('O'))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _tierDemo(
          caption: '${_tierCaption(GlassTierId.t4)}  (240 x 220, r 26)',
          height: 300,
          glass: SkinGlass(
            tier: GlassTierId.t4,
            shape: const GlassShape.superellipse(26),
            size: const Size(240, 220),
            debugLabel: 'calibration T4',
            child: Center(child: _label('T4 menu')),
          ),
        ),
        const SizedBox(height: 16),
        _tierDemo(
          caption: '${_tierCaption(GlassTierId.t5)}  (${t5.toStringAsFixed(0)} square)',
          height: t5 + 40,
          glass: SkinGlass(
            tier: GlassTierId.t5,
            shape: const GlassShape.superellipse(40),
            size: Size(t5, t5),
            debugLabel: 'calibration T5',
            child: Center(child: _label('T5')),
          ),
        ),
      ],
    );
  }

  Widget _controls() {
    final inApp = ref.watch(glassInAppPrefsProvider);
    final ctl = ref.read(glassInAppPrefsProvider.notifier);
    final override = ref.watch(glassRendererOverrideProvider);
    final effective = ref.watch(glassRendererProvider);
    final reg = ref.watch(glassRegistryProvider);
    final angle = ref.watch(glassLightAngleProvider).valueOrNull ?? kLightAngleRest;
    final choice = inApp.solidGlass ? 'Solid' : (override ?? effective) == GlassRenderer.frosted ? 'Frosted' : 'Liquid';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DevSegmented<String>(
          values: const ['Liquid', 'Frosted', 'Solid'],
          labelOf: (s) => s,
          selected: choice,
          onSelected: (s) {
            ctl.setSolidGlass(s == 'Solid');
            ref.read(glassRendererOverrideProvider.notifier).state = switch (s) {
              'Liquid' => GlassRenderer.liquid,
              'Frosted' => GlassRenderer.frosted,
              _ => override,
            };
          },
        ),
        DevToggle(label: 'Increase contrast', value: inApp.increaseContrast, onChanged: ctl.setIncreaseContrast),
        DevToggle(label: 'Reduce motion', value: inApp.reduceMotion, onChanged: ctl.setReduceMotion),
        DevToggle(label: 'Light follows the device', value: inApp.lightFollowsDevice, onChanged: ctl.setLightFollowsDevice),
        ValueListenableBuilder<double>(
          valueListenable: _barLb,
          builder: (context, lb, _) => DevCaption(
            'light ${(angle * 180 / math.pi).toStringAsFixed(1)} deg   '
            'layers ${reg.layers}/$kGlassLayerBudget  shapes ${reg.shapes}/$kGlassShapeBudget   '
            'bar Lb ${lb.toStringAsFixed(2)}  dim ${dimFor(lb, highContrast: inApp.increaseContrast).toStringAsFixed(2)}',
          ),
        ),
      ],
    );
  }

  Widget _legibility(double width) {
    return SizedBox(
      height: 360,
      child: GlassLbScope(
        child: Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.only(top: 80),
              itemCount: kCalibrationCovers.length,
              itemBuilder: (context, i) {
                final c = kCalibrationCovers[i];
                return GlassLbItem(
                  lMax: c.lMax,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(height: 132, child: CustomPaint(painter: CalibrationCoverPainter(c), size: Size.infinite)),
                  ),
                );
              },
            ),
            // The bar floats over the scroll view; its Lb is the max of the field term and the items under it.
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(
                child: GlassLbBar(
                  fieldTerm: Lb.field(0.1, 0.18),
                  builder: (context, lb) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && _barLb.value != lb) _barLb.value = lb;
                    });
                    return SkinGlassGroup(
                      lb: lb,
                      debugLabel: 'calibration bar',
                      shapes: [
                        SkinGlassShape(
                          size: Size(math.min(width - 32, 320), 56),
                          child: Center(child: GlassText('Legibility over art', role: glassTokens.typeHeadline, onGlass: true)),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _light(double width) {
    final band = math.min(360.0, width - 32);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 130,
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: CalibrationCoverPainter(kCalibrationCovers[2]))),
              Center(
                child: Listener(
                  onPointerDown: (e) {
                    _pressed = true;
                    _glow.value = GlassPressGlow(e.localPosition, on: true);
                    setState(() {});
                  },
                  onPointerUp: (_) {
                    _pressed = false;
                    _glow.value = const GlassPressGlow(Offset.zero, on: false);
                    setState(() {});
                  },
                  child: GlassCaustic(
                    pressed: _pressed,
                    child: SkinGlass(
                      tier: GlassTierId.t2,
                      finish: GlassFinishKind.tinted,
                      size: const Size(140, 50),
                      glow: _glow,
                      debugLabel: 'calibration lit',
                      child: Center(child: GlassText('Read', role: glassTokens.typeHeadline, color: glassTokens.colorOnTint)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const DevCaption('Press: glow and caustic 0.14 to 0.22'),
        const SizedBox(height: 16),
        GlassFollowRing(
          controller: _ring,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _ring.play(Rect.fromLTWH(0, 0, band, 200), d.localPosition),
            child: SizedBox(
              width: band,
              height: 200,
              child: DecoratedBox(
                decoration: BoxDecoration(color: glassTokens.colorFill1, borderRadius: BorderRadius.circular(glassTokens.radiusLg)),
                child: Center(child: GlassText('Tap for the follow ring', role: glassTokens.typeCallout, color: glassTokens.colorLabel2)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            SkinGlass(
              key: _sweepKey,
              tier: GlassTierId.t2,
              size: const Size(120, 50),
              debugLabel: 'calibration sweep',
              child: Center(child: _label('Surface')),
            ),
            const SizedBox(width: 12),
            DevButton(label: 'Sweep', onTap: () => GlassSweep.request(_sweepKey.currentState!)),
          ],
        ),
      ],
    );
  }

  static final List<CoverPalette> _demoPalettes = [
    for (final i in const [0, 8, 16])
      CoverPalette(a: kCalibrationCovers[i].palette, l: kCalibrationCovers[i].l, lMax: kCalibrationCovers[i].lMax),
  ];

  void _setAmbient(GlassAmbientSpec spec) => ref.read(glassAmbientProvider.notifier).state = spec;

  Widget _ambientSection() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < _demoPalettes.length; i++)
            DevButton(
              label: 'Palette ${i + 1}',
              selected: _ambientStep == i + 1,
              onTap: () {
                setState(() => _ambientStep = i + 1);
                _setAmbient(GlassAmbientSpec.palette(_demoPalettes[i], opacity: 0.26));
                unawaited(GlassMotion.play(MotionName.lightFollowsTheStory, controller: _demo, target: _demo.value < 0.5 ? 1 : 0));
              },
            ),
          for (final m in Mood.values)
            DevButton(
              label: m.name,
              onTap: () {
                setState(() => _ambientStep = 10 + m.index);
                _setAmbient(GlassAmbientSpec.mood(m));
              },
            ),
          DevButton(label: 'Aurora', onTap: () => _setAmbient(const GlassAmbientSpec.aurora())),
        ],
      );

  // -- physics tile ---------------------------------------------------------------

  double _shown(double y) {
    const max = _trackHeight - _tileSize;
    if (y < 0) return -rubberband(-y, _tileSize);
    if (y > max) return max + rubberband(y - max, _tileSize);
    return y;
  }

  void _dragStart(DragStartDetails d) {
    if (_tile.isAnimating) {
      final caught = _tile.catchMotion();
      _tile.value = caught.value;
      unawaited(ref.read(glassHapticsProvider).fire(HapticEvent.motionCatch, velocity: caught.velocity));
      GlassMotion.recorder.mark('CATCH');
    }
    _dragging = true;
    _dragOffset = _tile.value;
  }

  void _dragUpdate(DragUpdateDetails d) {
    _dragOffset += d.delta.dy;
    _tile.value = _dragOffset;
  }

  void _dragEnd(DragEndDetails d) {
    _dragging = false;
    final v = d.velocity.pixelsPerSecond.dy;
    final projected = project(_tile.value, v).clamp(_detents.first, _detents.last);
    final target = nearest(_detents, projected);
    unawaited(GlassMotion.play(MotionName.rubberBand, controller: _tile, target: target, velocityPxPerS: v));
    unawaited(ref.read(glassHapticsProvider).fire(HapticEvent.detentTick));
  }

  Widget _physics(double width) {
    final tileValue = _shown(_tile.value);
    final w = width - 32;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: w,
          height: _trackHeight,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragStart: _dragStart,
            onVerticalDragUpdate: _dragUpdate,
            onVerticalDragEnd: _dragEnd,
            child: Stack(
              children: [
                Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(color: glassTokens.colorFill1, borderRadius: BorderRadius.circular(glassTokens.radiusLg)))),
                for (final d in _detents)
                  Positioned(left: 0, right: 0, top: d + _tileSize / 2, child: Container(height: 1, color: glassTokens.colorSeparator)),
                Positioned(
                  left: (w - _tileSize) / 2,
                  top: tileValue,
                  child: SkinGlass(
                    tier: GlassTierId.t3,
                    shape: const GlassShape.superellipse(28),
                    size: const Size(_tileSize, _tileSize),
                    moving: _dragging,
                    materialize: false,
                    debugLabel: 'calibration tile',
                    child: Center(child: _label('Drag')),
                  ),
                ),
              ],
            ),
          ),
        ),
        DevCaption('y ${tileValue.toStringAsFixed(1)}  detents 0 / 90 / 180'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            DevButton(label: 'Materialise', onTap: _materialise),
            DevButton(label: 'Dematerialise', onTap: _dematerialise),
            DevButton(
              label: 'Specular sweep',
              onTap: () {
                GlassSweep.request(_sweepKey.currentState!);
                unawaited(GlassMotion.play(MotionName.specularSweep, controller: _demo, target: _demo.value < 0.5 ? 1 : 0));
              },
            ),
            DevButton(
              label: 'Light follows the story',
              onTap: () {
                _ambientStep = (_ambientStep + 1) % _demoPalettes.length;
                _setAmbient(GlassAmbientSpec.palette(_demoPalettes[_ambientStep], opacity: 0.26));
                unawaited(GlassMotion.play(MotionName.lightFollowsTheStory, controller: _demo, target: _demo.value < 0.5 ? 1 : 0));
              },
            ),
            DevButton(
              label: 'Dim shift',
              onTap: () {
                setState(() => _demoLb = _demoLb > 0.5 ? 0.0 : 1.0);
                unawaited(GlassMotion.play(MotionName.dimShift, controller: _demo, target: _demo.value < 0.5 ? 1 : 0));
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        KeyedSubtree(
          key: ValueKey(_demoGeneration),
          child: SkinGlass(
            key: _demoKey,
            tier: GlassTierId.t3,
            size: const Size(220, 56),
            lb: _demoLb,
            debugLabel: 'calibration demo',
            child: Center(child: GlassText('Lb ${_demoLb.toStringAsFixed(0)}', role: glassTokens.typeHeadline, onGlass: true)),
          ),
        ),
      ],
    );
  }

  void _materialise() {
    setState(() => _demoGeneration++);
    unawaited(GlassMotion.play(MotionName.materialise, controller: _demo, target: _demo.value < 0.5 ? 1 : 0));
  }

  Future<void> _dematerialise() async {
    unawaited(GlassMotion.play(MotionName.dematerialise, controller: _demo, target: _demo.value < 0.5 ? 1 : 0));
    await _demoKey.currentState?.dematerialize();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final margin = GlassFrame.screenMargin(context);
    const t = glassTokens;
    return GlassBudgetScope(
      exempt: true,
      label: 'calibration',
      child: ColoredBox(
        color: const Color(0x00000000),
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(margin, 16, margin, 48),
            children: [
              GlassText('Glass calibration', role: t.typeLargeTitle),
              const DevCaption('Count the 16 px squares the rims bend and compare with /dev/glass-calibration on the web.'),
              const DevHeading('Checkerboard'),
              _checkerboard(width - margin * 2),
              const DevHeading('Controls'),
              _controls(),
              const DevHeading('Legibility over art'),
              _legibility(width - margin * 2),
              const DevHeading('Light'),
              _light(width - margin * 2),
              const DevHeading('Ambient'),
              _ambientSection(),
              const DevHeading('Physics and motion'),
              _physics(width - margin * 2 + 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckerPainter extends CustomPainter {
  const _CheckerPainter(this.cell);
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final dark = Paint()..color = const Color(0xFF000000);
    final light = Paint()..color = const Color(0xFFFFFFFF);
    for (var y = 0; y * cell < size.height; y++) {
      for (var x = 0; x * cell < size.width; x++) {
        canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), (x + y).isEven ? light : dark);
      }
    }
  }

  @override
  bool shouldRepaint(_CheckerPainter old) => old.cell != cell;
}
