import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/primitives/stack/route_snapshot.dart';
import 'package:manhwamaniacs/skins/glass/primitives/stack/snapshot_store.dart';
import 'package:manhwamaniacs/skins/glass/primitives/stack/stack_overview.dart';
import 'package:manhwamaniacs/skins/glass/routes/depth_observer.dart';
import 'package:manhwamaniacs/skins/glass/routes/route_frame.dart';
import 'package:manhwamaniacs/skins/glass/routes/route_meta.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';

/// Where the shell's navigators are, so a picked level can pop to it: the root navigator and the active branch's.
class GlassNavigatorsRef {
  GlassNavigatorsRef({required this.root, required this.branch});
  final GlobalKey<NavigatorState> root;

  /// The navigator key of the given tab's branch.
  final GlobalKey<NavigatorState> Function(GlassTab tab) branch;
}

final glassNavigatorsProvider =
    StateProvider<GlassNavigatorsRef?>((ref) => null);

/// The current tab's levels, oldest first, the current screen last. The covered levels come from the snapshot store; the current one
/// is captured now.
Future<List<GlassRouteSnapshot>> glassStackLevels(WidgetRef ref,
    {String? currentKey,}) async {
  final tab = ref.read(glassActiveTabProvider);
  final store = ref.read(glassSnapshotStoreProvider.notifier);
  final levels = store.levels(tab);
  if (currentKey != null) {
    final frame = GlassRouteFrame.captureKeyOf(currentKey);
    final meta = frame == null ? null : GlassRouteMetaRegistry.of(frame);
    final image = frame == null ? null : await captureRouteSnapshot(frame);
    store.put(
      GlassRouteSnapshot(
        routeKey: currentKey,
        title: (meta?.title.isNotEmpty ?? false) ? meta!.title : 'Now',
        depth: levels.length,
        tab: tab,
        mature: meta?.mature ?? false,
        rimTint: meta?.rimTint ?? const Color(0xFF7563F2),
        image: image,
      ),
    );
  }
  return store.levels(tab);
}

/// Pops the navigators (root first, then the active branch) until the level [target] is on top.
void glassPopToLevel(WidgetRef ref, GlassRouteSnapshot target) {
  final nav = ref.read(glassNavigatorsProvider);
  if (nav == null) return;
  final tab = ref.read(glassActiveTabProvider);
  bool onTop(NavigatorState n) {
    var top = false;
    n.popUntil((r) {
      top = glassRouteKeyOf(r) == target.routeKey;
      return true;
    });
    return top;
  }

  for (final n in [nav.root.currentState, nav.branch(tab).currentState]) {
    if (n == null) continue;
    n.popUntil((r) =>
        glassRouteKeyOf(r) == target.routeKey ||
        r.isFirst ||
        glassRouteKeyOf(r) == null && r.isFirst,);
    if (onTop(n)) break;
  }
}

/// Opens the stack overview (or the flat menu under Reduce Motion or a screen reader) over the current tab's levels. With one level
/// it does nothing (glass 7.37).
Future<void> openGlassOverviewFor(BuildContext context, WidgetRef ref,
    {required Rect backButtonRect, String? currentKey,}) async {
  final levels = await glassStackLevels(ref, currentKey: currentKey);
  if (!context.mounted || levels.length <= 1) return;
  final tab = ref.read(glassActiveTabProvider);
  await openGlassStackOverview(
    context,
    ref,
    levels: levels,
    backButtonRect: backButtonRect,
    tabName: switch (tab) {
      GlassTab.home => 'Home',
      GlassTab.library => 'Library',
      GlassTab.sources => 'Sources',
      GlassTab.you => 'You',
    },
    onPick: (l) => glassPopToLevel(ref, l),
    onRemove: (l) {
      final below = levels.where((x) => x.depth < l.depth).toList();
      if (below.isNotEmpty) glassPopToLevel(ref, below.last);
    },
  );
}
