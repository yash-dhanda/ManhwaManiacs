import 'dart:ui' as ui;

import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/glass/tier_math.dart';

/// Where the library is touched. Only `skin_glass.dart` and the files of this folder import it.

/// glass 2.4.3 Flutter mapping: one tier's parameters as `LiquidGlassSettings`.
///
/// [materialize] is 0 to 1 and scales the refraction (`thickness`, `chromaticAberration`); [visibility]
/// is the opacity ramp. [fill] arrives with the legibility dim already folded in.
LiquidGlassSettings liquidSettingsFor({
  required TierParams p,
  required Color fill,
  required double angle,
  double materialize = 1,
  double visibility = 1,
  double? blur,
  double? saturation,
  double? specular,
}) =>
    LiquidGlassSettings(
      visibility: visibility,
      glassColor: fill,
      thickness: p.thickness * materialize,
      blur: blur ?? p.blur,
      saturation: saturation ?? p.saturate,
      lightIntensity: specular ?? p.specular,
      chromaticAberration: p.chromatic * materialize,
      lightAngle: angle,
    );

/// Squircle, capsule (radius = height / 2) or oval (circle) for the library.
LiquidShape liquidShapeFor(GlassShape shape, Size size) =>
    shape.isCircle ? const LiquidOval() : LiquidRoundedSuperellipse(borderRadius: shape.radiusFor(size));

/// The two page-level qualities of glass 2.4.4: chrome is premium, everything else standard.
GlassQuality liquidQuality({required bool premium}) => premium ? GlassQuality.premium : GlassQuality.standard;

/// One surface on its own layer.
Widget liquidSurface({
  required LiquidShape shape,
  required LiquidGlassSettings settings,
  required GlassQuality quality,
  required Widget child,
}) =>
    AdaptiveGlass(shape: shape, settings: settings, quality: quality, child: child);

/// A group: one layer whose children are grouped shapes.
Widget liquidGroup({
  required LiquidGlassSettings settings,
  required GlassQuality quality,
  required Widget child,
}) =>
    AdaptiveLiquidGlassLayer(settings: settings, quality: quality, child: child);

Widget liquidGroupedShape({required LiquidShape shape, required GlassQuality quality, required Widget child}) =>
    AdaptiveGlass.grouped(shape: shape, quality: quality, child: child);

/// True when the engine can run shader backdrop filters (Impeller); a renderer capability, never a device tier.
bool get liquidShadersSupported => ui.ImageFilter.isShaderFilterSupported;

/// `GlassAccessibilityScope` with reduce-transparency pinned off, so iOS Increase Contrast never turns
/// glass into the library's frosted panel; Glass paints its own solid path instead.
Widget glassAccessibilityScope({required bool reduceMotion, required Widget child}) =>
    GlassAccessibilityScope(reduceMotion: reduceMotion, reduceTransparency: false, child: child);

// --- shader init (moved from glass_engine.dart) ---

Future<void> _initShaders() => LiquidGlassWidgets.initialize();

/// Test seam: what [ensureLiquidGlassReady] runs. Production always uses [LiquidGlassWidgets.initialize].
@visibleForTesting
Future<void> Function() liquidGlassInitializer = _initShaders;

Future<void>? _ready;

/// Initialises the liquid-glass shaders once per process (glass 15.3). Reached
/// only from `GlassSkin.prepare()` and the device-gate page, so Cinematic and
/// legacy boots never load them. The package's app-wrapping helper is not used.
Future<void> ensureLiquidGlassReady() => _ready ??= liquidGlassInitializer();

@visibleForTesting
void resetLiquidGlassReadyForTest() => _ready = null;
