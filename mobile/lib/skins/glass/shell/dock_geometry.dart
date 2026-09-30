import 'dart:ui';

import 'package:flutter/painting.dart' show EdgeInsets;

import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';

/// Fixed lengths of the dock (glass 2.2): `dockInset` 21, `dockHeight` 64 / 50, `searchOrb` 50, `accessoryHeight` 48, `accessoryGap` 8.
const double kDockInset = 21;
const double kDockHeight = 64;
const double kDockMinHeight = 50;
const double kSearchOrb = 50;
const double kAccessoryHeight = 48;
const double kAccessoryGap = 8;

/// The dock, orb, accessory and minimised rects for a window (pure). `mobile/30` flies the chosen orb and the onboarding droplet to
/// [tabRect] before the shell mounts.
class GlassDockGeometry {
  const GlassDockGeometry._({required this.dock, required this.orb, required this.accessory, required this.minimised});

  final Rect dock;
  final Rect orb;
  final Rect accessory;
  final Rect minimised;

  factory GlassDockGeometry.of(Size size, EdgeInsets padding) {
    final bottom = size.height - kDockInset - padding.bottom;
    final orbRight = size.width - kDockInset;
    final orb = Rect.fromLTRB(orbRight - kSearchOrb, bottom - kSearchOrb, orbRight, bottom);
    final dock = Rect.fromLTRB(kDockInset, bottom - kDockHeight, orb.left - 8, bottom);
    final accessory = Rect.fromLTRB(kDockInset, dock.top - kAccessoryGap - kAccessoryHeight, orbRight, dock.top - kAccessoryGap);
    final minimised = Rect.fromLTWH(kDockInset, bottom - kDockMinHeight, kDockMinHeight, kDockMinHeight);
    return GlassDockGeometry._(dock: dock, orb: orb, accessory: accessory, minimised: minimised);
  }

  /// The accessory when the dock is minimised: inline between the minimised capsule and the orb.
  Rect get accessoryInline => Rect.fromLTRB(minimised.right + 8, orb.top, orb.left - 8, orb.bottom);

  /// One of four equal cells of the dock.
  Rect tabRect(GlassTab tab) {
    final w = dock.width / 4;
    return Rect.fromLTWH(dock.left + w * tab.index, dock.top, w, dock.height);
  }

  /// The 56 x 52 droplet under a tab.
  Rect dropletRect(GlassTab tab) => Rect.fromCenter(center: tabRect(tab).center, width: 56, height: 52);
}
