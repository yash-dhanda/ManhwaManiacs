import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// The four tabs of the Glass dock (glass 7.13). `mobile/29`'s shell drives the real navigation; the snapshots are grouped by it.
enum GlassTab { home, library, sources, you }

/// One level of a tab's back stack: what the stack overview draws (glass 7.37). [image] is captured once at 0.5x pixel ratio and
/// is null after a memory-pressure drop, when the card draws its title over the level's ambient colour.
class GlassRouteSnapshot {
  const GlassRouteSnapshot({required this.routeKey, required this.title, required this.depth, required this.tab, this.mature = false, required this.rimTint, this.image});
  final String routeKey;
  final String title;
  final int depth;
  final GlassTab tab;
  final bool mature;
  final Color rimTint;
  final ui.Image? image;

  GlassRouteSnapshot withoutImage() => GlassRouteSnapshot(routeKey: routeKey, title: title, depth: depth, tab: tab, mature: mature, rimTint: rimTint);
}

/// Captures the route under [boundaryKey] once at 0.5x pixel ratio (glass 15.7). Null when the boundary is not painted.
Future<ui.Image?> captureRouteSnapshot(GlobalKey boundaryKey) async {
  final ro = boundaryKey.currentContext?.findRenderObject();
  if (ro is! RenderRepaintBoundary || ro.debugNeedsPaint) return null;
  try {
    return await ro.toImage(pixelRatio: 0.5);
  } catch (_) {
    return null;
  }
}
