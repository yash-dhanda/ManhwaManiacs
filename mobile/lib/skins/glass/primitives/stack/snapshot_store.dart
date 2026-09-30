import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/primitives/stack/route_snapshot.dart';

/// The snapshots of the current session's levels, by route key (glass 7.37, 15.7). Images are disposed on memory pressure (the
/// records stay), on [drop], on [dropMature] (the gate closing) and when the container is disposed (a skin or profile switch).
class GlassSnapshotStore extends Notifier<Map<String, GlassRouteSnapshot>> {
  late final _Observer _observer = _Observer(_pressure);

  @override
  Map<String, GlassRouteSnapshot> build() {
    WidgetsBinding.instance.addObserver(_observer);
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(_observer);
      for (final s in state.values) {
        s.image?.dispose();
      }
    });
    return const {};
  }

  /// Adds or replaces a level. A replaced image is disposed.
  void put(GlassRouteSnapshot s) {
    final old = state[s.routeKey];
    if (old != null && !identical(old.image, s.image)) old.image?.dispose();
    state = {...state, s.routeKey: s};
  }

  bool has(String routeKey) => state[routeKey]?.image != null;

  void drop(String routeKey) {
    final s = state[routeKey];
    if (s == null) return;
    s.image?.dispose();
    state = {...state}..remove(routeKey);
  }

  /// Every mature level's image is disposed and its record removed (`mobile/29`'s purge when the gate closes).
  void dropMature() {
    final next = {...state};
    for (final e in state.entries) {
      if (e.value.mature) {
        e.value.image?.dispose();
        next.remove(e.key);
      }
    }
    state = next;
  }

  /// The levels of [tab], oldest first.
  List<GlassRouteSnapshot> levels(GlassTab tab) => [for (final s in state.values) if (s.tab == tab) s]..sort((a, b) => a.depth.compareTo(b.depth));

  void _pressure() {
    if (state.isEmpty) return;
    state = {
      for (final e in state.entries) e.key: e.value.image == null ? e.value : _dropImage(e.value),
    };
  }

  GlassRouteSnapshot _dropImage(GlassRouteSnapshot s) {
    s.image?.dispose();
    return s.withoutImage();
  }
}

class _Observer with WidgetsBindingObserver {
  _Observer(this.onPressure);
  final VoidCallback onPressure;

  @override
  void didHaveMemoryPressure() => onPressure();
}

final glassSnapshotStoreProvider = NotifierProvider<GlassSnapshotStore, Map<String, GlassRouteSnapshot>>(GlassSnapshotStore.new);

/// Renders [child] for capture: wraps it in the boundary that [captureRouteSnapshot] reads.
class SnapshotBoundary extends StatelessWidget {
  const SnapshotBoundary({super.key, required this.boundaryKey, required this.child});
  final GlobalKey boundaryKey;
  final Widget child;

  @override
  Widget build(BuildContext context) => RepaintBoundary(key: boundaryKey, child: child);
}

/// Convenience for tests and the gallery: a solid image of [size].
Future<ui.Image> paintedImage(Size size, Color color) {
  final rec = ui.PictureRecorder();
  Canvas(rec).drawRect(Offset.zero & size, Paint()..color = color);
  return rec.endRecording().toImage(size.width.ceil(), size.height.ceil());
}
