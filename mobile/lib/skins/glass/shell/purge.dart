import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;

import 'package:flutter/painting.dart' show PaintingBinding;
import 'package:flutter/widgets.dart' show Route, VoidCallback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/utils/recent_searches.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/glass/primitives/stack/snapshot_store.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/routes/depth_observer.dart';
import 'package:manhwamaniacs/skins/glass/routes/route_frame.dart';
import 'package:manhwamaniacs/skins/glass/routes/route_meta.dart';
import 'package:manhwamaniacs/skins/glass/shell/accessory_controller.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';
import 'package:manhwamaniacs/skins/glass/shell/stack_overview_host.dart';

/// Things that play or run for the active profile and must stop when the profile switches, the session ends or the 18+ gate closes:
/// narration (`mobile/37`), cruise and the soundscape (`mobile/44`), recaps (`mobile/41`). Each registers a stop.
abstract final class GlassStops {
  static final Map<String, VoidCallback> _mature = {};
  static final Map<String, VoidCallback> _playback = {};
  static final Map<String, void Function(Ref ref)> _holders = {};

  static void stopAllPlayback() {
    for (final s in _playback.values.toList()) {
      s();
    }
    for (final s in _mature.values.toList()) {
      s();
    }
  }

  static void stopMature() {
    for (final s in _mature.values.toList()) {
      s();
    }
  }

  static void runHolders(Ref ref) {
    for (final h in _holders.values.toList()) {
      h(ref);
    }
  }

  @visibleForTesting
  static void reset() {
    _mature.clear();
    _playback.clear();
    _holders.clear();
  }
}

/// Registers what stops when a mature series is open and the gate closes. Returns the disposer.
VoidCallback registerMatureStop(String key, VoidCallback stop) {
  GlassStops._mature[key] = stop;
  return () => GlassStops._mature.remove(key);
}

/// Registers something that stops on sign-out and on a profile switch (narration, cruise, the soundscape).
VoidCallback registerPlaybackStop(String key, VoidCallback stop) {
  GlassStops._playback[key] = stop;
  return () => GlassStops._playback.remove(key);
}

/// Registers a payload holder the purge deletes outright (home, statistics, Wrapped, recap and Circle payloads).
VoidCallback registerPurgeHolder(String key, void Function(Ref ref) purge) {
  GlassStops._holders[key] = purge;
  return () => GlassStops._holders.remove(key);
}

/// The steps of the purge, in order (glass 8.0.8). A fake in the test records the order.
abstract class PurgeSteps {
  void stopMatureAndClearAccessory();
  void popMatureLevels();
  void dropSnapshotsAndRecents();
  void clearImageCaches();
  void runHoldersAndInvalidate();
}

/// The 18+ purge (glass 8.0.8): runs before the next frame paints when the gate closes. Downloads are filtered on read, never deleted.
void runMaturePurge(PurgeSteps s) {
  s.stopMatureAndClearAccessory();
  s.popMatureLevels();
  s.dropSnapshotsAndRecents();
  s.clearImageCaches();
  s.runHoldersAndInvalidate();
}

class _RealSteps implements PurgeSteps {
  _RealSteps(this.ref);
  final Ref ref;

  @override
  void stopMatureAndClearAccessory() {
    GlassStops.stopMature();
    ref.read(glassToastProvider.notifier).removeTagged('mature:');
    ref.read(glassAccessoryProvider.notifier).setNarration(null);
  }

  @override
  void popMatureLevels() {
    final nav = ref.read(glassNavigatorsProvider);
    if (nav == null) return;
    bool mature(Route<dynamic> r) {
      final k = glassRouteKeyOf(r);
      final frame = k == null ? null : GlassRouteFrame.captureKeyOf(k);
      return frame != null && (GlassRouteMetaRegistry.of(frame)?.mature ?? false);
    }

    for (final n in [nav.root.currentState, for (final t in GlassTab.values) nav.branch(t).currentState]) {
      if (n == null) continue;
      n.popUntil((r) => r.isFirst || !mature(r));
    }
  }

  @override
  void dropSnapshotsAndRecents() {
    ref.read(glassSnapshotStoreProvider.notifier).dropMature();
    final id = ref.read(activeProfileProvider)?.id;
    unawaited(dropGateOpenRecentSearches(ref.read(sharedPrefsProvider),
        profileId: id,),);
  }

  @override
  void clearImageCaches() {
    final cache = PaintingBinding.instance.imageCache;
    cache.clear();
    cache.clearLiveImages();
  }

  @override
  void runHoldersAndInvalidate() => GlassStops.runHolders(ref);
}

void purgeMatureLocal(Ref ref) => runMaturePurge(_RealSteps(ref));
