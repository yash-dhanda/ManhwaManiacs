import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';
import 'package:manhwamaniacs/skins/glass/routes/sheet_registry.dart';

/// Turns `?sheet={id}` into a sheet on any route (glass 8.0.3): when an id appears (a tap, a deep link after the first frame) the
/// registered sheet is pushed on the nearest navigator unless a screen claimed it; when the sheet pops the parameter (and its
/// companions) is removed with `replace`; when the parameter disappears (back, a location change) the sheet pops.
class GlassSheetParamHost extends StatefulWidget {
  const GlassSheetParamHost({super.key, required this.child});
  final Widget child;

  @override
  State<GlassSheetParamHost> createState() => _GlassSheetParamHostState();
}

class _GlassSheetParamHostState extends State<GlassSheetParamHost> {
  Route<void>? _route;
  String? _open;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uri = _uri();
    final id = uri?.queryParameters['sheet'];
    if (id != null && _open == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _present(id));
    } else if (id == null && _route != null) {
      final r = _route!;
      _route = null;
      _open = null;
      if (r.isActive && r.navigator != null) r.navigator!.removeRoute(r);
    }
  }

  Uri? _uri() {
    try {
      return GoRouterState.of(context).uri;
    } catch (_) {
      return null;
    }
  }

  void _present(String id) {
    if (!mounted || _open != null) return;
    final spec = glassSheetSpec(id);
    if (spec == null || glassSheetClaimed(id)) return;
    final page = GlassSheetPage<void>(
      key: ValueKey('sheet:$id'),
      title: spec.title,
      builder: spec.builder,
      detents: spec.detents,
      opening: spec.opening ?? spec.detents.last,
      wideForm: spec.wideForm,
    );
    final route = page.createRoute(context);
    _route = route;
    _open = id;
    unawaited(Navigator.of(context).push<void>(route).whenComplete(() {
      final wasOurs = _route == route;
      _route = null;
      _open = null;
      if (!mounted || !wasOurs) return;
      final uri = _uri();
      if (uri != null && uri.queryParameters.containsKey('sheet')) {
        final q = {...uri.queryParameters}..remove('sheet');
        GoRouter.of(context).replace<void>(uri.replace(queryParameters: q.isEmpty ? null : q).toString());
      }
    }),);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
