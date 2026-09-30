import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/auth/utils/route_guard.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart' show setupCompletedProvider;
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/dev/calibration_page.dart';
import 'package:manhwamaniacs/skins/glass/dev/dev_controls.dart';
import 'package:manhwamaniacs/skins/glass/dev/glass_dev_index.dart';
import 'package:manhwamaniacs/skins/glass/dev/glass_gallery.dart';
import 'package:manhwamaniacs/skins/glass/dev/overlay_sections.dart';
import 'package:manhwamaniacs/skins/glass/dev/shell_demo.dart';
import 'package:manhwamaniacs/skins/glass/routes/depth_observer.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_swipe_route.dart';
import 'package:manhwamaniacs/skins/glass/routes/nav_extra.dart';
import 'package:manhwamaniacs/skins/glass/routes/route_frame.dart';
import 'package:manhwamaniacs/skins/glass/routes/sheet_param_host.dart';
import 'package:manhwamaniacs/skins/glass/screens/system/not_found.dart';
import 'package:manhwamaniacs/skins/glass/screens/system/route_error.dart';
import 'package:manhwamaniacs/skins/glass/shell/search_orb.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';
import 'package:manhwamaniacs/skins/glass/shell/stack_overview_host.dart';
import 'package:manhwamaniacs/skins/pending_routes.dart';
import 'package:manhwamaniacs/skins/pending_screen.dart';
import 'package:manhwamaniacs/skins/skins.dart';

// Every id is pending; finishing a screen deletes its line. mobile/45 deletes the set.
// `readerLanding` is built here: it redirects to the library (glass 8.0.3).
// ignore: constant_identifier_names
const Set<ScreenId> PENDING = {
  ScreenId.setup,
  ScreenId.login,
  ScreenId.register,
  ScreenId.profiles,
  ScreenId.profileNew,
  ScreenId.profileEdit,
  ScreenId.profilesManage,
  ScreenId.onboarding,
  ScreenId.tonight,
  ScreenId.library,
  ScreenId.updates,
  ScreenId.collections,
  ScreenId.collection,
  ScreenId.history,
  ScreenId.bookmarks,
  ScreenId.picks,
  ScreenId.numbers,
  ScreenId.annual,
  ScreenId.featureByFollow,
  ScreenId.feature,
  ScreenId.recap,
  ScreenId.circle,
  ScreenId.circleMember,
  ScreenId.discover,
  ScreenId.sources,
  ScreenId.source,
  ScreenId.reader,
  ScreenId.readAll,
  ScreenId.novel,
  ScreenId.downloads,
  ScreenId.dialogue,
  ScreenId.indexHub,
  ScreenId.settings,
  ScreenId.status,
};

/// The Glass development routes (mobile/25), outside the `ScreenId` map. `mobile/40` moves them into Glass Diagnostics.
const String kGlassDevPath = '/dev/glass';
const String kGlassCalibrationPath = '/dev/glass/calibration';

/// The primitives gallery (`mobile/26`); `?section=buttons|hold|icon-buttons|…` shows one family.
const String kGlassPrimitivesPath = '/dev/glass/primitives';

/// The shell demo (`mobile/29`): the frame with a scaffold, lists, a poster rail, accessories, the Dive and depth pushes.
const String kGlassShellDemoPath = '/dev/glass/shell';

/// The route error screen on its own (its captures and its tests).
const String kGlassRouteErrorDemoPath = '/dev/glass/route-error';

class _PendingWithDev extends StatelessWidget {
  const _PendingWithDev({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          child,
          Positioned(
            right: 16,
            top: 8,
            child: SafeArea(child: DevButton(label: 'Glass development', onTap: () => context.push(kGlassDevPath))),
          ),
        ],
      );
}

/// The development pages sit on the root's black and its ambient field, so they draw no background.
class _DevScaffold extends StatelessWidget {
  const _DevScaffold({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(type: MaterialType.transparency, child: child);
}

String _keyOf(GoRouterState state) => (state.pageKey).value;

/// A Glass page (glass 8.0.5): iOS pages are [GlassSwipePage] (full-width back swipe), Android pages [GlassMaterialPage] (the Glass
/// push and predictive-back card). Readers enter instantly (the Dive carries the entrance) and swipe only from a 20 px edge strip;
/// takeovers have no transition and no back swipe.
Page<void> glassPage(GoRouterState state, Widget child, {bool reader = false, bool takeover = false}) {
  final body = GlassRouteFrame(routeKey: _keyOf(state), sheetHost: (c) => GlassSheetParamHost(child: c), child: child);
  if (takeover) return NoTransitionPage<void>(key: state.pageKey, child: body);
  if (defaultTargetPlatform == TargetPlatform.android) {
    return GlassMaterialPage<void>(key: state.pageKey, name: state.name, builder: (_) => body, instantEnter: reader);
  }
  return GlassSwipePage<void>(key: state.pageKey, name: state.name, builder: (_) => body, edgeOnly: reader ? 20 : null, instantEnter: reader);
}

/// A sheet route (glass 8.0.3): a sheet when opened with a [GlassNavExtra], else the screen as a full page.
Page<void> glassSheetOrPage(BuildContext context, GoRouterState state, Widget child, {required String title, List<GlassDetent> detents = const [GlassDetent.medium, GlassDetent.large], GlassWideForm form = GlassWideForm.window, Widget? screen}) {
  final extra = state.extra;
  if (extra is GlassNavExtra && extra.presentation == GlassPresentation.sheet) {
    return GlassSheetPage<void>(
      key: state.pageKey,
      name: state.name,
      title: title,
      detents: detents,
      opening: detents.contains(GlassDetent.medium) ? GlassDetent.medium : detents.last,
      wideForm: form,
      originRect: extra.originRect,
      builder: (_) => GlassRouteFrame(routeKey: _keyOf(state), child: child),
    );
  }
  return glassPage(state, screen ?? child);
}

Widget _pending(ScreenId id, GoRouterState state) => _PendingWithDev(child: PendingScreen(screenId: id.id, location: state.uri.toString()));

String _nameOf(ScreenId id) => PENDING.contains(id) ? '$kPendingRoutePrefix${id.id}' : id.id;

/// A route for [id] (`path` defaults to its pattern; only the pattern carries the name).
GoRoute _route(ScreenId id, {String? path, GlobalKey<NavigatorState>? parent, bool reader = false, bool takeover = false}) {
  final isPattern = path == null || path == id.path;
  return GoRoute(
    path: path ?? id.path,
    name: isPattern ? _nameOf(id) : null,
    parentNavigatorKey: parent,
    pageBuilder: (context, state) => glassPage(state, _pending(id, state), reader: reader, takeover: takeover),
  );
}

GoRoute _sheetRoute(ScreenId id, GlobalKey<NavigatorState> root, {required String title, List<GlassDetent> detents = const [GlassDetent.medium, GlassDetent.large], GlassWideForm form = GlassWideForm.window, bool numericOnly = false}) => GoRoute(
      path: id.path,
      name: _nameOf(id),
      parentNavigatorKey: root,
      pageBuilder: (context, state) {
        if (numericOnly && int.tryParse(state.pathParameters['followedId'] ?? '') == null) {
          return glassPage(state, GlassNotFound(location: state.uri.toString()));
        }
        return glassSheetOrPage(context, state, _pending(id, state), title: title, detents: detents, form: form);
      },
    );

GoRoute _redirect(String path, String Function(GoRouterState state) to) => GoRoute(path: path, redirect: (context, state) => to(state));

GoRoute _devRoute(String path, Widget Function() page) => GoRoute(path: path, builder: (context, state) => _DevScaffold(child: page()));

class _GateBridge extends ChangeNotifier {
  void poke() => notifyListeners();
}

GateState _gate(Ref ref) {
  final auth = ref.read(authControllerProvider);
  return GateState(
    setupCompleted: ref.read(setupCompletedProvider),
    auth: switch (auth) {
      AuthUnknown() => GateAuth.unknown,
      AuthUnauthenticated() => GateAuth.unauthenticated,
      AuthAuthenticated() => GateAuth.authenticated,
    },
    hasActiveProfile: ref.read(activeProfileProvider) != null,
  );
}

/// The Glass router (glass 8.0.3): a `StatefulShellRoute.indexedStack` with the four branches, sheet routes and readers on the root
/// navigator, and the shared route guard. A profile switch increments `glassRouterEpochProvider`, which rebuilds it at a destination so
/// every branch stack, observer and snapshot resets at once.
GoRouter buildGlassRouter(Ref ref) {
  final epoch = ref.watch(glassRouterEpochProvider);
  final bridge = _GateBridge();
  ref
    ..onDispose(bridge.dispose)
    ..listen<bool>(setupCompletedProvider, (_, __) => bridge.poke())
    ..listen<AuthState>(authControllerProvider, (_, __) => bridge.poke())
    ..listen(activeProfileProvider, (_, __) => bridge.poke())
    ..listen<bool>(profileSessionReadyProvider, (_, __) => bridge.poke())
    ..listen<bool>(glassSignedOutPendingProvider, (_, __) => bridge.poke())
    ..listen(profileHeaderSyncProvider, (_, __) {});

  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'glass root');
  final branchKeys = {for (final t in GlassTab.values) t: GlobalKey<NavigatorState>(debugLabel: 'glass ${t.name}')};
  final depth = GlassDepth(ref);
  depth.reset();
  Future.microtask(() {
    ref.read(glassNavigatorsProvider.notifier).state = GlassNavigatorsRef(root: rootKey, branch: (t) => branchKeys[t]!);
  });

  StatefulShellBranch branch(GlassTab t, List<RouteBase> routes) =>
      StatefulShellBranch(navigatorKey: branchKeys[t], observers: [GlassDepthObserver(depth, tab: t)], routes: routes);

  final router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: epoch.destination ?? (epoch.epoch == 0 ? (ref.read(returnRouteProvider) ?? Routes.tonight()) : Routes.tonight()),
    refreshListenable: bridge,
    observers: [GlassDepthObserver(depth)],
    redirect: (context, state) {
      // While the signed-out alert is pending the guard does not redirect (glass 8.0.9).
      if (ref.read(glassSignedOutPendingProvider)) return null;
      final gate = _gate(ref);
      if (gate.auth == GateAuth.authenticated && gate.hasActiveProfile && !ref.read(profileSessionReadyProvider)) {
        Future.microtask(() {
          if (!ref.read(profileSessionReadyProvider)) ref.read(profileSessionReadyProvider.notifier).enter();
        });
      }
      return gateRedirect(gate, state.uri);
    },
    routes: [
      _devRoute(kGlassDevPath, () => const GlassDevIndex()),
      _devRoute(kGlassCalibrationPath, () => const GlassCalibrationPage()),
      _devRoute(kGlassRouteErrorDemoPath, () => GlassRouteError(error: StateError('demo'))),
      GoRoute(
        path: kGlassPrimitivesPath,
        builder: (context, state) => _DevScaffold(child: GlassGallery(section: state.uri.queryParameters['section'])),
      ),
      GoRoute(
        path: '$kGlassPrimitivesPath/sheet/:id',
        pageBuilder: (context, state) => glassDemoSheetPage(state.pathParameters['id']!, key: state.pageKey),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => GlassShell(navigationShell: shell, location: glassShellLocation(GoRouter.of(context))),
        branches: [
          branch(GlassTab.home, [
            _route(ScreenId.tonight),
            _route(ScreenId.updates),
            _route(ScreenId.picks),
          ]),
          branch(GlassTab.library, [
            _route(ScreenId.library),
            _route(ScreenId.library, path: Routes.libraryAliases.first),
            _route(ScreenId.collections),
            _route(ScreenId.collection),
            _route(ScreenId.history),
            _route(ScreenId.bookmarks),
            _route(ScreenId.downloads),
          ]),
          branch(GlassTab.sources, [
            _route(ScreenId.sources),
            _route(ScreenId.source),
            _route(ScreenId.dialogue),
          ]),
          branch(GlassTab.you, [
            GoRoute(
              path: kGlassShellDemoPath,
              pageBuilder: (context, state) => glassPage(state, GlassShellDemo(level: int.tryParse(state.uri.queryParameters['level'] ?? '') ?? 0)),
            ),
            _route(ScreenId.indexHub),
            _route(ScreenId.settings),
            _route(ScreenId.settings, path: Routes.settingsAliases.first),
            _route(ScreenId.circle),
            _route(ScreenId.numbers),
            _route(ScreenId.status),
            _route(ScreenId.profilesManage),
          ]),
        ],
      ),
      // Root navigator: takeovers, readers, search and the sheet routes.
      _route(ScreenId.setup, parent: rootKey, takeover: true),
      _route(ScreenId.login, parent: rootKey, takeover: true),
      _route(ScreenId.register, parent: rootKey, takeover: true),
      _route(ScreenId.profiles, parent: rootKey, takeover: true),
      _route(ScreenId.onboarding, parent: rootKey, takeover: true),
      _route(ScreenId.annual, parent: rootKey, takeover: true),
      _route(ScreenId.reader, parent: rootKey, reader: true),
      _route(ScreenId.readAll, parent: rootKey, reader: true),
      _route(ScreenId.novel, parent: rootKey, reader: true),
      GoRoute(
        path: ScreenId.discover.path,
        name: _nameOf(ScreenId.discover),
        parentNavigatorKey: rootKey,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: kGlassSearchDuration,
          reverseTransitionDuration: kGlassSearchDuration,
          child: const SizedBox.shrink(),
          transitionsBuilder: (context, animation, secondary, child) => GlassRouteFrame(routeKey: _keyOf(state), child: GlassSearchPage(animation: animation)),
        ),
      ),
      _sheetRoute(ScreenId.feature, rootKey, title: 'Series', form: GlassWideForm.detailWindow),
      _sheetRoute(ScreenId.recap, rootKey, title: 'Recap'),
      _sheetRoute(ScreenId.circleMember, rootKey, title: 'Circle', detents: const [GlassDetent.large]),
      _sheetRoute(ScreenId.profileNew, rootKey, title: 'New profile', detents: const [GlassDetent.large]),
      _sheetRoute(ScreenId.profileEdit, rootKey, title: 'Edit profile', detents: const [GlassDetent.large]),
      // `/library/:followedId` after every static /library path (the shell's branches are matched first).
      _sheetRoute(ScreenId.featureByFollow, rootKey, title: 'Series', form: GlassWideForm.detailWindow, numericOnly: true),
      // readerLanding: /reader goes to the library.
      GoRoute(path: ScreenId.readerLanding.path, name: ScreenId.readerLanding.id, redirect: (context, state) => Routes.readerLandingRedirect),
      // Mobile aliases (redirects).
      _redirect(Routes.profileNewAliases.first, (s) => Routes.profileNew()),
      _redirect(Routes.profileEditAliases.first, (s) => Routes.profileEdit(s.pathParameters['id']!)),
      _redirect(Routes.readerAliases[0], (s) => Routes.reader(s.pathParameters['sourceId']!, s.pathParameters['seriesKey']!, s.pathParameters['chapterKey']!)),
      _redirect(Routes.readerAliases[1], (s) => Routes.reader(s.pathParameters['sourceId']!, s.pathParameters['seriesKey']!, s.pathParameters['chapterKey']!)),
      _redirect(Routes.novelAliases.first, (s) => Routes.novel(s.pathParameters['sourceId']!, s.pathParameters['seriesKey']!, s.pathParameters['chapterKey']!)),
      _redirect(Routes.dialogueAliases.first, (s) => Routes.dialogue({'q': s.uri.queryParameters['q']})),
      _redirect(Routes.collectionsAliases.first, (s) => Routes.collections()),
      _redirect(Routes.collectionAliases.first, (s) => Routes.collection(s.pathParameters['id']!)),
    ],
    errorBuilder: (context, state) => GlassNotFound(location: state.uri.toString()),
  );
  ref.onDispose(router.dispose);
  return router;
}


/// The shell's own location, beneath any sheet route or reader pushed on the root navigator: the sidebar's activity follows it.
String glassShellLocation(GoRouter router) {
  final cfg = router.routerDelegate.currentConfiguration;
  for (final m in cfg.matches.reversed) {
    if (m is ShellRouteMatch && m.matches.isNotEmpty) return m.matches.last.matchedLocation;
  }
  return cfg.isEmpty ? '/' : cfg.last.matchedLocation;
}
