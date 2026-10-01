import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';
import 'package:manhwamaniacs/skins/glass/routes/sheet_registry.dart';

/// Turns `?sheet={id}` into a sheet on any route (glass 8.0.3): when an id appears (a tap, a deep link after the first frame) the
/// registered sheet is pushed on the root navigator (above the shell, its dock and the page recede, which would otherwise blur the
/// sheet with the page) unless a screen claimed it; when the sheet pops the parameter (and its
/// companions) is removed with `replace`; when the parameter disappears (back, a location change) the sheets pop. A second id while
/// one is open stacks over it (the player's Voices tile opens the cast sheet); when the upper one pops the parameter falls back to
/// the one beneath.
class GlassSheetParamHost extends StatefulWidget {
  const GlassSheetParamHost({super.key, required this.child});
  final Widget child;

  @override
  State<GlassSheetParamHost> createState() => _GlassSheetParamHostState();
}

class _GlassSheetParamHostState extends State<GlassSheetParamHost> {
  final List<(String, Route<void>)> _stack = [];

  String? get _open => _stack.isEmpty ? null : _stack.last.$1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uri = _uri();
    final id = uri?.queryParameters['sheet'];
    if (id != null && id != _open) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _present(id));
    } else if (id == null && _stack.isNotEmpty) {
      final all = [..._stack];
      _stack.clear();
      for (final (_, r) in all.reversed) {
        if (r.isActive && r.navigator != null) r.navigator!.removeRoute(r);
      }
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
    if (!mounted || _open == id) return;
    final spec = glassSheetSpec(id);
    if (spec == null || glassSheetClaimed(id)) return;
    final page = GlassSheetPage<void>(
      key: ValueKey('sheet:$id'),
      title: spec.title,
      builder: spec.builder,
      detents: spec.detents,
      opening: spec.opening ?? spec.detents.last,
      wideForm: spec.wideForm,
      material: spec.material,
      originRect: spec.origin?.call(),
      centerTitle: spec.centerTitle,
      trailing: spec.trailing,
    );
    final route = page.createRoute(context);
    _stack.add((id, route));
    unawaited(Navigator.of(context, rootNavigator: true).push<void>(route).whenComplete(() {
      final at = _stack.indexWhere((e) => e.$2 == route);
      final wasOurs = at >= 0;
      if (wasOurs) _stack.removeAt(at);
      if (!mounted || !wasOurs) return;
      final uri = _uri();
      if (uri != null && uri.queryParameters.containsKey('sheet')) {
        final q = {...uri.queryParameters};
        if (_stack.isEmpty) {
          q.remove('sheet');
        } else {
          q['sheet'] = _stack.last.$1;
        }
        GoRouter.of(context).replace<void>(Uri(path: uri.path, queryParameters: q.isEmpty ? null : q).toString());
      }
    }),);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
