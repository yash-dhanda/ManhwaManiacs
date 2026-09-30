import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/primitives/stack/route_snapshot.dart';
import 'package:manhwamaniacs/skins/glass/primitives/stack/snapshot_store.dart';
import 'package:manhwamaniacs/skins/glass/routes/route_frame.dart';
import 'package:manhwamaniacs/skins/glass/routes/route_meta.dart';
import 'package:manhwamaniacs/skins/glass/shell/depth_stack.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';

/// The page key a route was built with (go_router gives every page a `ValueKey<String>`), or null for anonymous routes.
String? glassRouteKeyOf(Route<dynamic> route) {
  final s = route.settings;
  if (s is Page<dynamic> && s.key is ValueKey<String>) {
    return (s.key! as ValueKey<String>).value;
  }
  return null;
}

/// One depth stack for the whole shell: each branch navigator's observer and the root navigator's write to it.
class GlassDepth {
  GlassDepth(this.ref);
  final Ref ref;
  final GlassDepthStack stack = GlassDepthStack();

  bool _queued = false;

  /// Publishes the depths after the current frame's build (observers fire while navigators mount; a provider must not change then).
  void _publish() {
    if (_queued) return;
    _queued = true;
    Future.microtask(() {
      _queued = false;
      try {
        ref.read(glassDepthProvider.notifier).state = {for (final t in GlassTab.values) t: stack.depthOf(t)};
      } catch (_) {}
    });
  }

  /// Clears every branch's levels; the published depths follow after the current build (a provider must not write while building).
  void reset() {
    stack.clear();
    _publish();
  }
}

/// Tracks depth per branch and captures the covered route once (glass 7.37, 15.7). One per branch navigator (`tab` set) and one on the
/// root navigator (`tab` null: sheets and readers count in the tab that pushed them).
class GlassDepthObserver extends NavigatorObserver {
  GlassDepthObserver(this.depth, {this.tab});
  final GlassDepth depth;
  final GlassTab? tab;

  GlassTab get _tab => tab ?? depth.ref.read(glassActiveTabProvider);

  /// The keys per tab that this observer pushed, so a pop removes the right entry.
  final Map<String, GlassTab> _owner = {};

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final key = glassRouteKeyOf(route);
    if (key == null) return;
    // The first route of a branch navigator is the tab root, not a level.
    if (previousRoute == null && tab != null) return;
    final t = _tab;
    _owner[key] = t;
    final prev = previousRoute == null ? null : glassRouteKeyOf(previousRoute);
    if (prev != null) unawaited(_capture(prev, t, depth.stack.depthOf(t)));
    depth.stack.push(t, key);
    depth._publish();
  }

  Future<void> _capture(String routeKey, GlassTab t, int levelIndex) async {
    final frame = GlassRouteFrame.captureKeyOf(routeKey);
    if (frame == null) return;
    // The covered page has painted; capture after this frame so the snapshot is the page as the user left it.
    await WidgetsBinding.instance.endOfFrame;
    final image = await captureRouteSnapshot(frame);
    final meta = GlassRouteMetaRegistry.of(frame);
    final store = depth.ref.read(glassSnapshotStoreProvider.notifier);
    store.put(
      GlassRouteSnapshot(
        routeKey: routeKey,
        title: (meta?.title.isNotEmpty ?? false) ? meta!.title : routeKey,
        depth: levelIndex,
        tab: t,
        mature: meta?.mature ?? false,
        rimTint: meta?.rimTint ?? const Color(0xFF7563F2),
        image: image,
      ),
    );
  }

  void _left(Route<dynamic> route) {
    final key = glassRouteKeyOf(route);
    if (key == null) return;
    final t = _owner.remove(key);
    if (t == null) return;
    depth.stack.pop(t, key);
    Future.microtask(() {
      try {
        depth.ref.read(glassSnapshotStoreProvider.notifier).drop(key);
      } catch (_) {}
    });
    depth._publish();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _left(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _left(route);
}
