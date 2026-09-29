import 'package:flutter/foundation.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

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
