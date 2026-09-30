import 'dart:async';

import 'package:flutter/widgets.dart';

/// Plays a full-screen effect on the root overlay, so it survives the route change it covers (the Address drain, the Slab condense,
/// the Lens split). [build] receives `done`: call it to remove the layer; the future completes then.
Future<void> playRootOverlay(BuildContext context, Widget Function(VoidCallback done) build) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return Future<void>.value();
  final completer = Completer<void>();
  late OverlayEntry entry;
  void done() {
    if (completer.isCompleted) return;
    entry.remove();
    entry.dispose();
    completer.complete();
  }

  entry = OverlayEntry(builder: (_) => build(done));
  overlay.insert(entry);
  return completer.future;
}

/// The global rect of [key]'s render box, or null before layout.
Rect? globalRectOfKey(GlobalKey key) {
  final ro = key.currentContext?.findRenderObject();
  if (ro is! RenderBox || !ro.attached || !ro.hasSize) return null;
  return ro.localToGlobal(Offset.zero) & ro.size;
}

/// The far corner distance from [from] to the screen's corners: the radius at which a circle covers the screen.
double farCornerRadius(Offset from, Size size) {
  double d(Offset o) => (o - from).distance;
  return [d(Offset.zero), d(Offset(size.width, 0)), d(Offset(0, size.height)), d(Offset(size.width, size.height))].reduce((a, b) => a > b ? a : b);
}
