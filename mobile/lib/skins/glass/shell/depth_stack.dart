import 'package:manhwamaniacs/skins/glass/primitives/stack/route_snapshot.dart';

/// Depth bookkeeping per tab (glass 7.37). A level is one pushed route above the tab root; a sheet route and a reader each count as
/// one level in the tab that pushed them. Pure, so the counting and the pop target are unit tests.
class GlassDepthStack {
  final Map<GlassTab, List<String>> _levels = {for (final t in GlassTab.values) t: <String>[]};

  int depthOf(GlassTab tab) => _levels[tab]!.length;

  /// The depth that weighs on haptics and sound: beyond 4 counts as 4.
  int weighed(GlassTab tab) => depthOf(tab).clamp(0, 4);

  List<String> levels(GlassTab tab) => List.unmodifiable(_levels[tab]!);

  void push(GlassTab tab, String routeKey) => _levels[tab]!.add(routeKey);

  void pop(GlassTab tab, String routeKey) => _levels[tab]!.remove(routeKey);

  void clear([GlassTab? tab]) => tab == null ? _levels.forEach((_, v) => v.clear()) : _levels[tab]!.clear();

  /// How many pops bring [tab] back to the level [routeKey]; null when it is not in the stack. Picking the root (`null` key) pops all.
  int? popsTo(GlassTab tab, String? routeKey) {
    final l = _levels[tab]!;
    if (routeKey == null) return l.length;
    final i = l.indexOf(routeKey);
    return i < 0 ? null : l.length - 1 - i;
  }
}
