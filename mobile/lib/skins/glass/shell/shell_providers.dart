import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart' show singleKeyShortcutsProvider;
import 'package:manhwamaniacs/core/network/network_connectivity.dart';
import 'package:manhwamaniacs/core/network/request_failures.dart';
import 'package:manhwamaniacs/features/auth/providers/session_offline_provider.dart';
import 'package:manhwamaniacs/skins/glass/primitives/stack/route_snapshot.dart'
    show GlassTab;

export 'package:manhwamaniacs/skins/glass/primitives/stack/route_snapshot.dart'
    show GlassTab;

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

final glassRouterEpochProvider =
    StateProvider<GlassRouterEpoch>((ref) => const GlassRouterEpoch(0, null));

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

/// Per-device "Single-key shortcuts" switch (default on; its Settings row is `mobile/39`), the shared skin-neutral preference.
final glassSingleKeyProvider = Provider<bool>((ref) => ref.watch(singleKeyShortcutsProvider));

/// Whether the device OCR engine exists (read once per launch).
final glassOcrAvailableProvider = StateProvider<bool>((ref) => false);

/// True while the bottom accessory shows (the bottom inset and edge read it).
final glassAccessoryVisibleProvider = StateProvider<bool>((ref) => false);

/// The manual sidebar choice for this app session: `null` follows the frame's default.
final glassSidebarChoiceProvider = StateProvider<bool?>((ref) => null);

/// The tab the user is on; the shell sets it from the navigation shell's index.
final glassActiveTabProvider = StateProvider<GlassTab>((ref) => GlassTab.home);

/// Levels above each tab's root (the depth observers write it; the back buttons and the depth glyph read it).
final glassDepthProvider = StateProvider<Map<GlassTab, int>>((ref) => const {});

/// `GlassScaffold` and the reader publish that their surface hides the dock, edges and large title (readers, full-height sheets).
final glassBareRouteProvider = StateProvider<bool>((ref) => false);

/// Offline for the shell's purposes: the device has no connection, the session runs on the cached identity, or the server did not answer
/// three times in ten seconds. The "Offline" capsule and the unreachable notice read it.
final glassOfflineProvider = Provider<bool>((ref) {
  final online = ref.watch(networkOnlineChangesProvider).valueOrNull;
  return online == false ||
      ref.watch(sessionOfflineProvider) ||
      ref.watch(requestFailuresProvider);
});

/// The shell registers what `mod+B` and the expand button call.
final glassSidebarToggleProvider = StateProvider<void Function()?>((ref) => null);

/// True while the "You were signed out" alert is pending: the guard does not redirect (glass 8.0.9).
final glassSignedOutPendingProvider = StateProvider<bool>((ref) => false);
