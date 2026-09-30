import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/shell/handoff_layer.dart';

/// The Skin melt (glass 4.10, 615 ms), reused by `mobile/30` and `mobile/39`: every live glass surface dematerialises, the root blurs
/// and a circular clip closes over black. Reduced motion: a 200 ms fade to black. Fires the `skin.switch` haptic and the `melt` cue.
Future<void> playMelt(WidgetRef ref) =>
    ref.read(glassEffectsProvider).playMelt();

/// Reverses the melt over 200 ms (a failed switch).
Future<void> unmelt(WidgetRef ref) => ref.read(glassEffectsProvider).unmelt();
