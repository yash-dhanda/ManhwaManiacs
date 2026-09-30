import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where the Droplet's lens lands (glass 8.2). `mobile/30` registers Setup's, Login's and the picker's marks (in that order); otherwise it lands in the dock
/// capsule (phone) or the sidebar's profile capsule (wider frames).
enum GlassSplashTarget { setup, login, picker }

final Map<GlassSplashTarget, GlobalKey> _targets = {};

/// Registers the key of the widget the lens flies into. Returns the disposer.
VoidCallback registerSplashTarget(GlassSplashTarget target, GlobalKey key) {
  _targets[target] = key;
  return () {
    if (identical(_targets[target], key)) _targets.remove(target);
  };
}

/// The global rect of the first registered target that is laid out, or null.
Rect? registeredSplashTargetRect() {
  for (final t in GlassSplashTarget.values) {
    final ro = _targets[t]?.currentContext?.findRenderObject();
    if (ro is RenderBox && ro.attached && ro.hasSize) return ro.localToGlobal(Offset.zero) & ro.size;
  }
  return null;
}

/// The sidebar and dock publish their resting rect here for the splash to land in.
final glassSplashFallbackProvider = StateProvider<Rect?>((ref) => null);
