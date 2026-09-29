import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Resting system bars on every Cinematic screen outside the readers, both OSes (cinematic
/// 8.0.5): transparent, light icons, edge to edge, no scrim from the OS.
final SystemUiOverlayStyle cineRestingOverlayStyle = SystemUiOverlayStyle.light.copyWith(
  statusBarColor: const Color(0x00000000),
  systemNavigationBarColor: const Color(0x00000000),
  systemNavigationBarDividerColor: const Color(0x00000000),
  systemNavigationBarContrastEnforced: false,
  systemStatusBarContrastEnforced: false,
);

/// Applied when the Cinematic root mounts; mobile/12 calls it on reader exit.
void applyCineRestingSystemUi() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(cineRestingOverlayStyle);
}

/// Width of the strip at a screen edge that in-reader horizontal gestures ignore: at least 24,
/// and the system gesture inset, which also clears iOS's 20 pt back strip.
double cineEdgeWidth(BuildContext context, {required bool left}) {
  final inset = MediaQuery.systemGestureInsetsOf(context);
  return math.max(24, left ? inset.left : inset.right);
}
