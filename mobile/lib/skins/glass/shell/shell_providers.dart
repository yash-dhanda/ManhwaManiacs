import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:manhwamaniacs/skins/glass/primitives/stack/route_snapshot.dart' show GlassTab;

/// Today's reading goal; `mobile/42` feeds [glassGoalRingProvider]. `null` draws no ring.
@immutable
class GoalProgress {
  const GoalProgress({required this.minutes, required this.goal});
  final int minutes;
  final int goal;
}

final glassGoalRingProvider = Provider<GoalProgress?>((ref) => null);

/// Incrementing it (with a destination) rebuilds the router: every branch, observer and snapshot resets (profile switch).
@immutable
class GlassRouterEpoch {
  const GlassRouterEpoch(this.epoch, this.destination);
  final int epoch;
  final String? destination;
}

final glassRouterEpochProvider = StateProvider<GlassRouterEpoch>((ref) => const GlassRouterEpoch(0, null));

enum GlassArrivalKind { profile, onboarding }

@immutable
class GlassArrival {
  const GlassArrival({required this.kind, required this.point});
  final GlassArrivalKind kind;
  final Offset point;
}

/// `mobile/30` writes it before navigating; the shell reads and clears it on mount.
final glassArrivalProvider = StateProvider<GlassArrival?>((ref) => null);

/// Centre of the tapped tab, so the destination's wave radiates from it.
final glassWaveOriginProvider = StateProvider<Offset?>((ref) => null);

/// Per-device "Single-key shortcuts" switch (default on; its Settings row is `mobile/39`).
final glassSingleKeyProvider = StateProvider<bool>((ref) => true);

/// Whether the device OCR engine exists (read once per launch).
final glassOcrAvailableProvider = StateProvider<bool>((ref) => false);

/// True while the bottom accessory shows (the bottom inset and edge read it).
final glassAccessoryVisibleProvider = StateProvider<bool>((ref) => false);

/// The manual sidebar choice for this app session: `null` follows the frame's default.
final glassSidebarChoiceProvider = StateProvider<bool?>((ref) => null);
