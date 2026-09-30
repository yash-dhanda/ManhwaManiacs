import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart' show GlassMenuBack;
import 'package:manhwamaniacs/skins/glass/routes/route_meta.dart';

/// Every page the Glass router builds sits in one of these: the stack-overview capture target (a `RepaintBoundary` on [frameKey]),
/// one `BackdropGroup` for the frost path, a route focus scope, and the route's [GlassRouteMeta] for `GlassScaffold` to publish to.
class GlassRouteFrame extends StatefulWidget {
  const GlassRouteFrame({super.key, required this.routeKey, required this.child, this.sheetHost});
  final String routeKey;
  final Widget child;

  /// `GlassSheetParamHost` (installed by the router) wraps the page here so `?sheet=` works on any route.
  final Widget Function(Widget child)? sheetHost;

  /// The capture key of the frame with [routeKey], or null.
  static GlobalKey? captureKeyOf(String routeKey) => _keys[routeKey];
  static final Map<String, GlobalKey> _keys = {};

  static GlobalKey keyFor(String routeKey) => _keys.putIfAbsent(routeKey, () => GlobalKey(debugLabel: 'GlassRouteFrame:$routeKey'));

  @override
  State<GlassRouteFrame> createState() => _GlassRouteFrameState();
}

class _GlassRouteFrameState extends State<GlassRouteFrame> {
  late GlobalKey _key = GlassRouteFrame.keyFor(widget.routeKey);
  late GlassRouteMeta _meta = GlassRouteMetaRegistry.register(_key);
  final FocusScopeNode _scope = FocusScopeNode(debugLabel: 'route focus');

  @override
  void didUpdateWidget(GlassRouteFrame old) {
    super.didUpdateWidget(old);
    if (old.routeKey != widget.routeKey) {
      GlassRouteMetaRegistry.unregister(_key);
      _key = GlassRouteFrame.keyFor(widget.routeKey);
      _meta = GlassRouteMetaRegistry.register(_key);
    }
  }

  @override
  void dispose() {
    GlassRouteMetaRegistry.unregister(_key);
    GlassRouteFrame._keys.remove(widget.routeKey);
    _scope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget body = widget.child;
    if (widget.sheetHost != null) body = widget.sheetHost!(body);
    // Android back order rule 2: an open anchored menu closes before the page pops.
    body = ValueListenableBuilder<int>(
      valueListenable: GlassMenuBack.open,
      child: body,
      builder: (context, open, child) => PopScope(
        canPop: open == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) GlassMenuBack.closeTop();
        },
        child: child!,
      ),
    );
    return GlassRouteMetaScope(
      meta: _meta,
      child: RepaintBoundary(
        key: _key,
        child: BackdropGroup(child: FocusScope(node: _scope, child: body)),
      ),
    );
  }
}
