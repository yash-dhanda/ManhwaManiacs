import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' show LiquidGlassSettings;
import 'package:liquid_glass_widgets/theme/glass_theme_helpers.dart' show GlassThemeHelpers;
import 'package:manhwamaniacs/skins/glass/glass/axes.dart';
import 'package:manhwamaniacs/skins/glass/glass/focus_ring.dart' show GlassFocusRingHost;
import 'package:manhwamaniacs/skins/glass/glass/glow.dart';
import 'package:manhwamaniacs/skins/glass/glass/light_angle.dart';
import 'package:manhwamaniacs/skins/glass/glass/liquid.dart';
import 'package:manhwamaniacs/skins/glass/glass/registry.dart';
import 'package:manhwamaniacs/skins/glass/glass/rim_painter.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/glass/sweep.dart';
import 'package:manhwamaniacs/skins/glass/glass/tier_math.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/scroll_edge.dart' show GlassFastScrollListener;
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

export 'package:manhwamaniacs/skins/glass/glass/axes.dart';
export 'package:manhwamaniacs/skins/glass/glass/glow.dart' show GlassPressGlow;
export 'package:manhwamaniacs/skins/glass/glass/registry.dart';
export 'package:manhwamaniacs/skins/glass/glass/shape.dart' show GlassShape;
export 'package:manhwamaniacs/skins/glass/glass/sweep.dart' show GlassSweep, GlassSweepTarget;
export 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart' show GlassTierId;

// ---------------------------------------------------------------------------
// Vocabulary
// ---------------------------------------------------------------------------

/// The finish on a tier (glass 2.4.2). Named `...Kind` because the generated token class is `GlassFinish`.
enum GlassFinishKind { regular, clear, tinted }

/// A surface that never reads the backdrop (glass 2.4.1 rule 1, 2.4.2 rule 7).
enum GlassTwin { content, onGlass, dense, cover, tinted }

/// `chrome` is `GlassQuality.premium`; the two page-level controls and transient glass in scroll views are `standard`.
enum GlassRole { chrome, pageControl, transient }

enum GlassRenderer { liquid, frosted }

/// The recorded decision of the mobile/03 device gate (`docs/redesign/proof/mobile-03/glass-gate.md`).
/// The record's Decision line is still awaiting the owner's device pass, so this keeps the stack
/// decision's default, the liquid engine; the frosted path below is the one-file fallback. It changes
/// here and nowhere else. Where shader filters are unsupported, [resolveGlassRenderer] falls back to frost.
const GlassRenderer kGateRenderer = GlassRenderer.liquid;

/// The renderer for one process: a renderer capability, never a device tier.
GlassRenderer resolveGlassRenderer({GlassRenderer? override, required bool shadersSupported}) {
  final want = override ?? kGateRenderer;
  return want == GlassRenderer.liquid && shadersSupported ? GlassRenderer.liquid : GlassRenderer.frosted;
}

/// The calibration page sets this to force a renderer.
final glassRendererOverrideProvider = StateProvider<GlassRenderer?>((ref) => null);

final glassRendererProvider = Provider<GlassRenderer>((ref) => resolveGlassRenderer(
      override: ref.watch(glassRendererOverrideProvider),
      shadersSupported: liquidShadersSupported,
    ),);

// ---------------------------------------------------------------------------
// No glass on glass
// ---------------------------------------------------------------------------

/// Marks descendants of a live surface; a [SkinGlass] built inside one without an explicit `twin`
/// renders the `onGlass` twin (glass 2.4.1 rule 2).
class GlassHost extends InheritedWidget {
  const GlassHost({super.key, required super.child});

  static bool of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<GlassHost>() != null;

  @override
  bool updateShouldNotify(GlassHost old) => false;
}

// ---------------------------------------------------------------------------
// Fills of the non-live paths
// ---------------------------------------------------------------------------

class _TwinLook {
  const _TwinLook(this.fill, this.rim, {this.specular, this.tinted = false});
  final Color fill;
  final Color? rim;
  final Color? specular;
  final bool tinted;
}

const Map<GlassTwin, _TwinLook> _twins = {
  GlassTwin.content: _TwinLook(Color(0x9E131317), null),
  GlassTwin.onGlass: _TwinLook(Color(0x4D787880), Color(0x38FFFFFF)),
  GlassTwin.dense: _TwinLook(Color(0xD1131317), null),
  GlassTwin.cover: _TwinLook(Color(0xDB000000), Color(0x38FFFFFF)),
  GlassTwin.tinted: _TwinLook(Color(0xDB7563F2), Color(0x4DFFFFFF), specular: Color(0x99E4DFFF), tinted: true),
};

/// The twin's fill, exposed for tests.
@visibleForTesting
Color twinFill(GlassTwin t) => _twins[t]!.fill;

/// The solid path fill (glass 2.4.2 solid variants): T1 to T3 `glassSolid1`, T4 and T5 `glassSolid2`,
/// tinted `iris700` (pressed `#4A3CB0`).
Color solidFill(GlassTierId tier, GlassFinishKind finish, {bool pressed = false}) {
  if (finish == GlassFinishKind.tinted) return pressed ? const Color(0xFF4A3CB0) : glassTokens.colorIris700;
  return (tier == GlassTierId.t4 || tier == GlassTierId.t5) ? glassTokens.glassSolid2 : glassTokens.glassSolid1;
}

// ---------------------------------------------------------------------------
// SkinGlass
// ---------------------------------------------------------------------------

/// One shape of a [SkinGlassGroup] (the dock with its orb).
class SkinGlassShape {
  const SkinGlassShape({required this.size, required this.child, this.shape = const GlassShape.capsule(), this.twin});
  final Size size;
  final Widget child;
  final GlassShape shape;
  final GlassTwin? twin;
}

/// The only glass surface of the Glass skin, and the only wrapper around `liquid_glass_widgets`
/// (glass 15.3). Size it with a tight box (a `SizedBox`, or `size:`); the shape, the `auto` tier and the
/// capsule radius read that box.
class SkinGlass extends ConsumerStatefulWidget {
  const SkinGlass({
    super.key,
    required this.child,
    this.tier = GlassTierId.auto,
    this.finish = GlassFinishKind.regular,
    this.twin,
    this.shape = const GlassShape.capsule(),
    this.lb = 1.0,
    this.role = GlassRole.chrome,
    this.overContent = true,
    this.tierValue,
    this.glow,
    this.materialize = true,
    this.moving = false,
    this.layer = GlassLayerKind.controls,
    this.debugLabel,
    this.size,
    this.rimTint,
    this.tint,
  })  : groupShapes = null,
        groupAxis = Axis.horizontal,
        groupGap = 8,
        groupAligns = null,
        groupHeight = null,
        groupOffsets = null;

  const SkinGlass._group({
    super.key,
    required List<SkinGlassShape> shapes,
    required this.tier,
    required this.finish,
    required this.lb,
    required this.role,
    required this.overContent,
    required this.materialize,
    required this.layer,
    required this.debugLabel,
    required this.groupAxis,
    required this.groupGap,
    required this.rimTint,
    this.tint,
    this.groupOffsets,
    this.groupAligns,
    this.groupHeight,
  })  : groupShapes = shapes,
        child = const SizedBox.shrink(),
        twin = null,
        shape = const GlassShape.capsule(),
        tierValue = null,
        glow = null,
        moving = false,
        size = null;

  final Widget child;
  final GlassTierId tier;
  final GlassFinishKind finish;
  final GlassTwin? twin;
  final GlassShape shape;

  /// The relative luminance of what is behind this surface (glass 2.1.7). Unknown is 1.0.
  final double lb;
  final GlassRole role;
  final bool overContent;

  /// 1.0 to 5.0: every numeric tier parameter interpolates between the neighbouring tiers each frame.
  final Animation<double>? tierValue;
  final ValueListenable<GlassPressGlow?>? glow;
  final bool materialize;

  /// Holds the current settings while the surface moves (the library rebuilds geometry only at rest).
  final bool moving;
  final GlassLayerKind layer;
  final String? debugLabel;
  final Size? size;

  /// The field's rim tint (glass 2.1.8), mixed into the specular gradient at 18 %.
  final Color? rimTint;

  /// A tint layer inside the surface at 18 % (the reader's page-tinted chrome, glass 9.4.4). On the solid path (Solid glass,
  /// Reduce Transparency) only the rim keeps [rimTint].
  final Color? tint;

  final List<SkinGlassShape>? groupShapes;
  final Axis groupAxis;
  final double groupGap;

  /// Per-shape paint offsets of a group (the reaction picker's arc); the group is still one layer.
  final List<Offset>? groupOffsets;

  /// Bar groups that span their host (the nav row, the dock with its orb and accessory): one alignment per shape. The group then
  /// fills the width it is given and stays one layer.
  final List<Alignment>? groupAligns;

  /// The height of an aligned group (default: its tallest shape).
  final double? groupHeight;

  /// The device-corner radius on iOS phones (glass 2.3), `radiusSheet` 36 elsewhere.
  static double deviceCornerRadius(BuildContext context) {
    final phone = MediaQuery.sizeOf(context).shortestSide < 600;
    if (defaultTargetPlatform == TargetPlatform.iOS && phone) {
      final r = GlassThemeHelpers.resolveAdaptiveRadius(context);
      if (r > 0) return r;
    }
    return glassTokens.radiusSheet;
  }

  @override
  ConsumerState<SkinGlass> createState() => SkinGlassState();
}

/// The sibling shapes of one bar group drawn in one layer (glass 2.4.1): the dock with its orb, the nav
/// row's leading button, title capsule and trailing group.
class SkinGlassGroup extends SkinGlass {
  const SkinGlassGroup({
    super.key,
    required super.shapes,
    super.tier = GlassTierId.t3,
    super.finish = GlassFinishKind.regular,
    super.lb = 1.0,
    super.role = GlassRole.chrome,
    super.overContent = true,
    super.materialize = true,
    super.layer = GlassLayerKind.controls,
    super.debugLabel,
    Axis axis = Axis.horizontal,
    double gap = 8,
    super.rimTint,
    super.tint,
    List<Offset>? offsets,
    List<Alignment>? aligns,
    double? height,
  }) : super._group(
          groupAxis: axis,
          groupGap: gap,
          groupOffsets: offsets,
          groupAligns: aligns,
          groupHeight: height,
        );
}

class SkinGlassState extends ConsumerState<SkinGlass> with TickerProviderStateMixin implements GlassSweepTarget {
  late final AnimationController _mat = AnimationController(
    vsync: this,
    duration: glassTokens.curveMaterialize.duration,
    reverseDuration: glassTokens.curveDematerialize.duration,
    value: widget.materialize ? 0 : 1,
  );
  late final AnimationController _sweep = AnimationController(vsync: this, duration: glassTokens.curveSweep.duration);
  late final AnimationController _glowC = AnimationController(vsync: this);
  late final GlassRegistryController _registry = ref.read(glassRegistryProvider.notifier);
  late final int _id = _registry.newId();

  /// Holds a lone surface's child across tree-shape changes (materialize fade, solid/live flip, renderer change), so a
  /// TextField inside keeps its state and keyboard connection instead of being rebuilt as a new field.
  final GlobalKey _childKey = GlobalKey(debugLabel: 'SkinGlass child');

  /// Every mounted surface, so the skin melt can dematerialise them all at once.
  static final Set<SkinGlassState> _mounted = {};

  bool _registered = false;
  bool _disposed = false;

  /// Deactivated (moving in the tree or about to be disposed): the render object may not be read.
  bool _inactive = false;

  @override
  void deactivate() {
    _inactive = true;
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _inactive = false;
  }
  Offset _glowAt = Offset.zero;
  LiquidGlassSettings? _held;

  int get shapeCount => widget.groupShapes?.length ?? 1;

  // -- lifecycle --------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _mounted.add(this);
    widget.glow?.addListener(_onGlow);
    if (widget.materialize) {
      final reduced = ref.read(glassMotionPrefsProvider).reduced;
      _mat.duration = reduced ? glassTokens.curveReducedCrossfade.duration : glassTokens.curveMaterialize.duration;
      unawaited(_mat.forward().then((_) {
        if (!_disposed && mounted && !ref.read(glassMotionPrefsProvider).reduced && !ref.read(glassA11yProvider).solid) {
          GlassSweep.request(this);
        }
      }),);
    }
  }

  @override
  void didUpdateWidget(SkinGlass oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.glow != widget.glow) {
      oldWidget.glow?.removeListener(_onGlow);
      widget.glow?.addListener(_onGlow);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _mounted.remove(this);
    widget.glow?.removeListener(_onGlow);
    if (_registered) {
      final id = _id, registry = _registry;
      _registered = false;
      scheduleMicrotask(() => registry.unregisterSafe(id));
    }
    _mat.dispose();
    _sweep.dispose();
    _glowC.dispose();
    super.dispose();
  }

  // -- press glow, sweep, dematerialise ---------------------------------------

  void _onGlow() {
    final g = widget.glow?.value;
    if (g == null) return;
    _glowAt = g.local;
    const t = glassTokens;
    if (g.on) {
      _glowC.animateTo(1, duration: t.curveGlowIn.duration, curve: t.curveGlowIn.curve);
    } else {
      _glowC.animateTo(0, duration: t.curveGlowOut.duration, curve: t.curveGlowOut.curve);
    }
  }

  @override
  Future<void> playSweep() async {
    if (_disposed) return;
    try {
      await _sweep.forward(from: 0).orCancel; // a disposed controller never completes the plain future
    } on TickerCanceled {
      return;
    }
    if (!_disposed) _sweep.value = 0;
  }

  /// Runs the reverse of the materialise (350 ms; 120 ms under reduced motion) and completes so callers
  /// can remove the surface afterwards.
  Future<void> dematerialize() async {
    final reduced = ref.read(glassMotionPrefsProvider).reduced;
    _mat.reverseDuration = reduced ? const Duration(milliseconds: 120) : glassTokens.curveDematerialize.duration;
    await _mat.reverse();
  }

  double get materialiseValue => _mat.value;

  // -- registry ----------------------------------------------------------------

  Rect? _globalRect() {
    if (_disposed || !mounted || _inactive) return null;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _syncRegistration(bool live, bool exempt) {
    if (live == _registered) return;
    _registered = live;
    final registry = _registry;
    scheduleMicrotask(() {
      if (live) {
        if (_disposed || !_registered) return;
        registry.registerSafe(GlassRegistration(
          id: _id,
          label: widget.debugLabel ?? 'SkinGlass',
          kind: widget.layer,
          shapes: shapeCount,
          rect: _globalRect,
          exempt: exempt,
        ),);
      } else {
        registry.unregisterSafe(_id);
      }
    });
  }

  // -- build -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final a11y = ref.watch(glassA11yProvider);
    final reduced = ref.watch(glassMotionPrefsProvider.select((m) => m.reduced));
    final forcedSolid = ref.watch(glassRegistryProvider.select((s) => s.forcedSolid.contains(_id)));
    final angle = ref.watch(glassLightAngleProvider).valueOrNull ?? kLightAngleRest;
    final renderer = ref.watch(glassRendererProvider);
    final inHost = GlassHost.of(context);
    final budget = GlassBudgetScope.maybeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);

    // A group whose every shape is a twin draws no live glass, so it is not counted either.
    final wantsTwin = widget.twin != null || inHost || (widget.groupShapes?.every((s) => s.twin != null) ?? false);
    final solid = !wantsTwin && (a11y.solid || forcedSolid);
    final live = !wantsTwin && !solid;
    // A surface the registry forced solid stays registered: unregistering cleared its force, it went live, re-registered and was
    // forced again, a three-frame rebuild loop of every stacked surface.
    _syncRegistration(!wantsTwin && !a11y.solid, budget?.exempt ?? false);

    final env = _Env(
      live: live,
      a11y: a11y,
      reduced: reduced,
      angle: angle,
      renderer: renderer,
      solid: solid,
      dpr: dpr,
    );

    Widget body(Size? constraintSize) {
      final animations = <Listenable>[_mat, _sweep, _glowC, if (widget.tierValue != null) widget.tierValue!];
      return AnimatedBuilder(
        animation: Listenable.merge(animations),
        builder: (context, _) {
          final specs = widget.groupShapes ??
              [SkinGlassShape(size: constraintSize ?? Size.zero, child: widget.child, shape: widget.shape, twin: widget.twin)];
          if (widget.groupShapes != null) return _buildGroup(context, specs, env);
          return _buildShape(context, specs.first, specs.first.size, env, grouped: false);
        },
      );
    }

    if (widget.groupShapes != null) return body(null);
    if (widget.size != null) return SizedBox.fromSize(size: widget.size, child: body(widget.size));
    return LayoutBuilder(builder: (context, c) {
      final w = c.hasBoundedWidth ? c.maxWidth : 0.0;
      final h = c.hasBoundedHeight ? c.maxHeight : 0.0;
      return body(Size(w, h));
    },);
  }

  double _matT(_Env env) => env.reduced ? 1.0 : glassTokens.curveMaterialize.curve.transform(_mat.value.clamp(0.0, 1.0));

  /// Opacity ramps over the first 120 ms of the 250 ms lensing; reduced motion fades over its own 150 ms.
  double _opacity(_Env env) {
    if (env.reduced) return _mat.value.clamp(0.0, 1.0);
    final ms = glassTokens.curveMaterialize.ms;
    return (_mat.value * ms / 120).clamp(0.0, 1.0);
  }

  TierParams _params(double shorter) {
    if (widget.tierValue != null) return lerpTier(widget.tierValue!.value);
    final id = widget.tier == GlassTierId.auto ? tierFor(shorter) : widget.tier;
    return tierParams(id);
  }

  GlassTierId _tierId(double shorter) {
    if (widget.tier != GlassTierId.auto) return widget.tier;
    if (widget.tierValue != null) return GlassTierId.values[(widget.tierValue!.value.round().clamp(1, 5)) - 1];
    return tierFor(shorter);
  }

  Widget _buildGroup(BuildContext context, List<SkinGlassShape> specs, _Env env) {
    final aligns = widget.groupAligns;
    final Widget flex;
    if (aligns != null) {
      final shapes = [for (var i = 0; i < specs.length; i++) _buildShape(context, specs[i], specs[i].size, env, grouped: true)];
      flex = SizedBox(
        width: double.infinity,
        height: widget.groupHeight ?? specs.map((s) => s.size.height).reduce((a, b) => a > b ? a : b),
        child: Stack(children: [for (var i = 0; i < shapes.length; i++) Align(alignment: aligns[i], child: shapes[i])]),
      );
    } else {
      // Built only here: an aligned group (the dock, the nav row) used to build every shape twice per frame and drop one copy.
      final children = <Widget>[];
      for (var i = 0; i < specs.length; i++) {
        if (i > 0) children.add(SizedBox(width: widget.groupAxis == Axis.horizontal ? widget.groupGap : 0, height: widget.groupAxis == Axis.vertical ? widget.groupGap : 0));
        final shape = _buildShape(context, specs[i], specs[i].size, env, grouped: true);
        final off = widget.groupOffsets;
        children.add(off != null && i < off.length ? Transform.translate(offset: off[i], child: shape) : shape);
      }
      flex = Flex(direction: widget.groupAxis, mainAxisSize: MainAxisSize.min, children: children);
    }
    final live = env.live && specs.every((s) => s.twin == null);
    if (live && env.renderer == GlassRenderer.liquid) {
      // One layer for the whole group; its settings come from the first shape's tier.
      final shorter = specs.first.size.shortestSide;
      final look = _look(context, shorter, env);
      return liquidGroup(
        settings: liquidSettingsFor(
          p: look.p,
          fill: look.fill,
          angle: env.angle,
          materialize: _matT(env),
          visibility: _opacity(env),
          blur: look.blur,
          saturation: look.saturation,
          specular: look.specular,
        ),
        quality: liquidQuality(premium: widget.role == GlassRole.chrome),
        child: flex,
      );
    }
    return flex;
  }

  /// Everything a live or solid surface needs from the tier, the finish and the dim.
  _Look _look(BuildContext context, double shorter, _Env env) {
    const t = glassTokens;
    final tierId = _tierId(shorter);
    final p = _params(shorter);
    var blur = p.blur, saturation = p.saturate, specular = p.specular;
    var fill = p.fill;
    Color? specularColor;
    final pressed = (widget.glow?.value?.on ?? false);
    switch (widget.finish) {
      case GlassFinishKind.regular:
        break;
      case GlassFinishKind.clear:
        fill = t.glassClear.fill;
        blur = t.glassClear.blur;
        saturation = t.glassClear.saturate;
        specular = t.glassClear.specular ?? specular;
      case GlassFinishKind.tinted:
        fill = pressed ? (t.glassTinted.fillPressed ?? t.glassTinted.fill) : t.glassTinted.fill;
        blur = t.glassTinted.blur;
        saturation = t.glassTinted.saturate;
        specularColor = t.glassTinted.specularColor;
    }
    final shadow = widget.finish == GlassFinishKind.tinted ? t.glassTinted.shadow : null;
    return _Look(
      p: p,
      tier: tierId,
      fill: fill,
      blur: blur,
      saturation: saturation,
      specular: specular,
      specularColor: specularColor,
      shadowOffsetY: shadow?.offset.dy ?? p.shadowOffsetY,
      shadowBlur: shadow?.blurRadius ?? p.shadowBlur,
      shadowColor: shadow?.color ?? p.shadowColor,
      pressed: pressed,
    );
  }

  Widget _buildShape(BuildContext context, SkinGlassShape spec, Size size, _Env env, {required bool grouped}) {
    const t = glassTokens;
    final inHost = GlassHost.of(context);
    final twinKind = spec.twin ?? widget.twin ?? (inHost ? GlassTwin.onGlass : null);
    final shorter = size.shortestSide;
    final look = _look(context, shorter, env);
    final hc = env.a11y.increaseContrast;
    final op = _opacity(env);
    final shape = spec.shape;

    // Animated dim and grade: they ease together over dimShift, and change at once under reduced motion.
    Widget surface(double lb) {
      final dim = env.solid || twinKind != null ? 0.0 : dimFor(lb, highContrast: hc);
      final grad = gradFor(lb, bold: env.a11y.boldText);
      final content = GlassHost(
        child: GlassTextAxes(rond: look.p.rond, grad: grad, child: grouped ? spec.child : KeyedSubtree(key: _childKey, child: spec.child)),
      );
      final radius = BorderRadius.circular(shape.radiusFor(size));
      final tint = widget.rimTint;
      final light = look.tier != GlassTierId.t1;

      Widget rim({bool solidPath = false, Color? flat, Color? specColor}) => Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: GlassRimPainter(
                  shape: shape,
                  angle: env.angle,
                  specular: look.specular,
                  devicePixelRatio: env.dpr,
                  rimTint: flat != null || (solidPath && widget.tint == null) ? null : tint,
                  specularColor: specColor ?? look.specularColor ?? const Color(0xFFFFFFFF),
                  innerLight: light,
                  solid: solidPath,
                  highContrast: hc,
                  opacity: op,
                  flatRim: flat,
                ),
              ),
            ),
          );

      final overlays = <Widget>[
        if (twinKind == null && !env.solid && !env.reduced)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: GlassSweepPainter(shape: shape, angle: env.angle, progress: _sweep.value)),
            ),
          ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: GlassGlowPainter(
                shape: shape,
                at: _glowAt,
                amount: _glowC.value,
                tinted: widget.finish == GlassFinishKind.tinted || twinKind == GlassTwin.tinted,
              ),
            ),
          ),
        ),
      ];

      final shadow = widget.overContent && twinKind == null
          ? Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: GlassShadowPainter(
                    shape: shape,
                    offsetY: look.shadowOffsetY,
                    blur: look.shadowBlur,
                    color: look.shadowColor.withValues(alpha: look.shadowColor.a * op),
                  ),
                ),
              ),
            )
          : null;

      // Twin: no backdrop read, no displacement, no dim, not registered.
      if (twinKind != null) {
        final look2 = _twins[twinKind]!;
        return _stack(size, fixed: grouped || widget.size != null, children: [
          ClipRSuperellipse(borderRadius: radius, child: ColoredBox(color: look2.fill, child: content)),
          rim(flat: look2.rim, specColor: look2.specular),
          overlays.last,
        ],);
      }

      // Solid path: no library widget, no BackdropFilter, no dim, no caustic, no sweep, no dispersion.
      if (env.solid) {
        return _stack(size, fixed: grouped || widget.size != null, children: [
          if (shadow != null) shadow,
          ClipRSuperellipse(
            borderRadius: radius,
            child: ColoredBox(color: solidFill(look.tier, widget.finish, pressed: look.pressed), child: content),
          ),
          rim(solidPath: true),
          overlays.last,
        ],);
      }

      final layer = widget.tint;
      final fill = foldDim(layer == null ? look.fill : Color.alphaBlend(layer.withValues(alpha: 0.18), look.fill), dim);

      if (env.renderer == GlassRenderer.liquid) {
        final settings = liquidSettingsFor(
          p: look.p,
          fill: fill,
          angle: env.angle,
          materialize: _matT(env),
          visibility: op,
          blur: look.blur,
          saturation: look.saturation,
          specular: look.specular,
        );
        // `moving` holds the last settings: the library's geometry rebuilds only at rest.
        if (!widget.moving || _held == null) _held = settings;
        final use = widget.moving ? _held! : settings;
        final lshape = liquidShapeFor(shape, size);
        final quality = liquidQuality(premium: widget.role == GlassRole.chrome);
        final Widget glass = grouped
            ? liquidGroupedShape(shape: lshape, quality: quality, child: content)
            : liquidSurface(shape: lshape, settings: use, quality: quality, child: content);
        return _stack(size, fixed: grouped || widget.size != null, children: [if (shadow != null) shadow, glass, rim(), ...overlays]);
      }

      // Frost path: blur + 6, saturate, no displacement, no dispersion, painted rim (stack risk 4).
      assert(
        context.findAncestorWidgetOfExactType<BackdropGroup>() != null,
        'SkinGlass on the frost path needs a BackdropGroup ancestor (SkinGlassRoot installs one per screen).',
      );
      final sigma = (look.blur + 6) * _matT(env);
      final filled = fill.withValues(alpha: fill.a * op);
      return _stack(size, fixed: grouped || widget.size != null, children: [
        if (shadow != null) shadow,
        ClipRSuperellipse(
          borderRadius: radius,
          child: BackdropFilter.grouped(
            filter: ui.ImageFilter.compose(
              outer: ColorFilter.matrix(saturationMatrix(look.saturation)),
              inner: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            ),
            child: ColoredBox(color: filled, child: op < 1 ? Opacity(opacity: op, child: content) : content),
          ),
        ),
        rim(),
        ...overlays,
      ],);
    }

    // No dim over a twin or the solid path: the lb is irrelevant there.
    if (twinKind != null || env.solid) return surface(1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: widget.lb),
      duration: env.reduced ? Duration.zero : t.curveDimShift.duration,
      curve: t.curveDimShift.curve,
      builder: (context, lb, _) => surface(lb),
    );
  }

  Widget _stack(Size size, {required List<Widget> children, bool fixed = false}) {
    final stack = Stack(clipBehavior: Clip.none, fit: StackFit.passthrough, children: children);
    // A group shape (or a surface given `size:`) is exactly its declared size, whatever its parent asks.
    // The focus-ring host paints the ring of a control inside this glass outside the glass clip (glass 2.6).
    return GlassFocusRingHost(child: fixed ? SizedBox.fromSize(size: size, child: stack) : stack);
  }

}

class _Env {
  const _Env({required this.live, required this.a11y, required this.reduced, required this.angle, required this.renderer, required this.solid, required this.dpr});
  final bool live;
  final GlassA11y a11y;
  final bool reduced;
  final double angle;
  final GlassRenderer renderer;
  final bool solid;
  final double dpr;
}

class _Look {
  const _Look({
    required this.p,
    required this.tier,
    required this.fill,
    required this.blur,
    required this.saturation,
    required this.specular,
    required this.specularColor,
    required this.shadowOffsetY,
    required this.shadowBlur,
    required this.shadowColor,
    required this.pressed,
  });
  final TierParams p;
  final GlassTierId tier;
  final Color fill;
  final double blur;
  final double saturation;
  final double specular;
  final Color? specularColor;
  final double shadowOffsetY;
  final double shadowBlur;
  final Color shadowColor;
  final bool pressed;
}

// ---------------------------------------------------------------------------
// The root
// ---------------------------------------------------------------------------

/// Installs, once above the Glass tree: the library's accessibility scope with Reduce Transparency pinned
/// off (Increase Contrast must not turn glass into the library's frosted panel), one `BackdropGroup` for
/// the frost path, the registry's metrics watcher and the hover light. The library's app-wrapping
/// helper is not used and `adaptiveQuality` stays `false`.
class SkinGlassRoot extends ConsumerWidget {
  const SkinGlassRoot({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduced = ref.watch(glassMotionPrefsProvider.select((m) => m.reduced));
    return glassAccessibilityScope(
      reduceMotion: reduced,
      child: BackdropGroup(
        child: GlassFastScrollListener(child: GlassMetricsWatcher(child: GlassLightHover(child: child))),
      ),
    );
  }
}


/// Dematerialises every mounted glass surface at once (350 ms; the skin melt, glass 4.10). Completes when they are all gone.
Future<void> dematerializeAllGlass() => Future.wait([for (final s in SkinGlassState._mounted.toList()) s.dematerialize()]);

/// Brings them back (a melt undone).
void rematerializeAllGlass() {
  for (final s in SkinGlassState._mounted.toList()) {
    if (!s._disposed) s._mat.forward();
  }
}
