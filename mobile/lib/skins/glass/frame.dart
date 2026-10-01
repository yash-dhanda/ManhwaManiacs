import 'dart:ui' show FlutterView;

import 'package:flutter/material.dart' show Theme;
import 'package:flutter/widgets.dart';

enum GlassFrameKind { phone, tablet, desktop, wide }

/// Wraps content that is already inset by [GlassFrame.screenMargin] (see [GlassFrame.contentMargin]).
class GlassMarginApplied extends InheritedWidget {
  const GlassMarginApplied({super.key, required super.child});

  @override
  bool updateShouldNotify(GlassMarginApplied oldWidget) => false;
}

/// Frames are chosen by the window's shorter side, so a rotated phone is still a phone (glass 8.0.1).
abstract final class GlassFrame {
  static GlassFrameKind ofSize(Size size) {
    if (size.shortestSide < 600) return GlassFrameKind.phone;
    if (size.width >= 1440) return GlassFrameKind.wide;
    if (size.width >= 1024) return GlassFrameKind.desktop;
    return GlassFrameKind.tablet;
  }

  static GlassFrameKind of(BuildContext context) => ofSize(MediaQuery.sizeOf(context));

  /// `touchMin`: 48 on Android, 44 elsewhere.
  static double hitMin(BuildContext context) =>
      Theme.of(context).platform == TargetPlatform.android ? 48 : 44;

  /// s6 to s10: 16 up to 413 px wide, 20 from 414 on phones, 24 tablet, 32 desktop, 40 wide.
  static double screenMargin(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return switch (ofSize(size)) {
      GlassFrameKind.phone => size.width < 414 ? 16 : 20,
      GlassFrameKind.tablet => 24,
      GlassFrameKind.desktop => 32,
      GlassFrameKind.wide => 40,
    };
  }

  /// The horizontal inset a screen or a list primitive still owes: the screen margin, or 0 inside content `GlassScaffold` already
  /// insets (its large title and slivers), so a grouped list, chip row or rail there sits on the same gutter as the title.
  static double contentMargin(BuildContext context) =>
      context.getInheritedWidgetOfExactType<GlassMarginApplied>() != null ? 0 : screenMargin(context);

  /// True on a phone-sized window of [view] (used before a BuildContext exists).
  static bool isPhoneView(FlutterView view) =>
      ofSize(view.physicalSize / view.devicePixelRatio) == GlassFrameKind.phone;
}
