import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/app_frame.dart';
import 'package:manhwamaniacs/skins/cinematic/router_gate.dart';
import 'package:manhwamaniacs/skins/cinematic/screens.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_route_page.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/system/cine_error_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/shell.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/hub_shell_scope.dart';
import 'package:manhwamaniacs/skins/cinematic/transitions.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/pending_routes.dart';
import 'package:manhwamaniacs/skins/skins.dart';

// Every id is pending except the series page; finishing a screen deletes its line. mobile/24
// deletes the set.
// ignore: constant_identifier_names
const Set<ScreenId> PENDING = {
  ScreenId.onboarding,
  ScreenId.updates,
  ScreenId.collections,
  ScreenId.collection,
  ScreenId.history,
  ScreenId.bookmarks,
  ScreenId.numbers,
  ScreenId.annual,
  ScreenId.circle,
  ScreenId.circleMember,
  ScreenId.reader,
  ScreenId.readAll,
  ScreenId.novel,
  ScreenId.readerLanding,
};

/// The one root navigator key of the Cinematic router.
final GlobalKey<NavigatorState> cineRootKey = GlobalKey<NavigatorState>(debugLabel: 'cine-root');

/// How a route is placed in a page.
enum _Move { cut, page, match, dip, reader }

Page<void> _page(_Move move, BuildContext context, GoRouterState state, Widget child) => switch (move) {
      _Move.cut => cineCutPage(state, child),
      _Move.page => cinePage(state, child),
      _Move.match => cineMatchCutPage(state, child),
      _Move.dip => cineDipPage(state, child),
      _Move.reader => cineReaderPage(context, state, child),
    };

String _nameOf(ScreenId id) => PENDING.contains(id) ? '$kPendingRoutePrefix${id.id}' : id.id;

/// A route for [id] at [path] (the pattern by default). Only the pattern carries the name, so the
/// completeness test finds every pending id exactly once.
GoRoute _route(ScreenId id, _Move move, {String? path, GlobalKey<NavigatorState>? parent}) {
  final isPattern = path == null || path == id.path;
  return GoRoute(
    path: path ?? id.path,
    name: isPattern ? _nameOf(id) : null,
    parentNavigatorKey: parent,
    pageBuilder: (context, state) =>
        _page(move, context, state, cineScreenFor(context, id, state, pending: PENDING.contains(id))),
  );
}

GoRoute _redirect(String path, String Function(GoRouterState state) to) =>
    GoRoute(path: path, redirect: (context, state) => to(state));

StatefulShellBranch _branch(List<RouteBase> routes) => StatefulShellBranch(routes: routes);

/// `/library/:followedId` last among the `/library` paths: go_router matches in declaration order.
List<RouteBase> _shellRoutes() => [
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, navigationShell) =>
            cineCutPage(state, CineShell(navigationShell: navigationShell, location: state.uri.toString())),
        branches: [
          // 0 Tonight
          _branch([_route(ScreenId.tonight, _Move.cut)]),
          // 1 Library: the nested hub. Five tabs are branch roots; collection detail is pushed.
          _branch([
            StatefulShellRoute.indexedStack(
              pageBuilder: (context, state, hub) => cineCutPage(state, HubShellScope(shell: hub, child: hub)),
              branches: [
                _branch([
                  _route(ScreenId.library, _Move.cut),
                  for (final a in Routes.libraryAliases) _route(ScreenId.library, _Move.cut, path: a),
                ]),
                _branch([_route(ScreenId.updates, _Move.cut)]),
                _branch([_route(ScreenId.collections, _Move.cut), _route(ScreenId.collection, _Move.page)]),
                _branch([_route(ScreenId.history, _Move.cut)]),
                _branch([_route(ScreenId.bookmarks, _Move.cut)]),
              ],
            ),
          ]),
          // 2 Discover
          _branch([
            _route(ScreenId.discover, _Move.cut),
            _route(ScreenId.sources, _Move.page),
            _route(ScreenId.source, _Move.page),
            _route(ScreenId.dialogue, _Move.page),
            _route(ScreenId.picks, _Move.page),
          ]),
          // 3 Downloads
          _branch([_route(ScreenId.downloads, _Move.cut)]),
          // 4 Index
          _branch([
            _route(ScreenId.indexHub, _Move.cut),
            _route(ScreenId.settings, _Move.page),
            for (final a in Routes.settingsAliases) _route(ScreenId.settings, _Move.page, path: a),
            _route(ScreenId.status, _Move.page),
            _route(ScreenId.numbers, _Move.page),
            _route(ScreenId.circle, _Move.page),
            _route(ScreenId.circleMember, _Move.page),
            _route(ScreenId.profilesManage, _Move.page),
          ]),
        ],
      ),
    ];

/// The root-navigator routes: no thumb index.
List<RouteBase> _rootRoutes() => [
      GoRoute(
        path: kSplashHoldPath,
        pageBuilder: (context, state) => cineCutPage(state, const ColoredBox(color: Color(0xFF000000))),
      ),
      _route(ScreenId.setup, _Move.dip),
      _route(ScreenId.login, _Move.dip),
      _route(ScreenId.register, _Move.page),
      _route(ScreenId.profiles, _Move.dip),
      _route(ScreenId.profileNew, _Move.page),
      for (final a in Routes.profileNewAliases) _route(ScreenId.profileNew, _Move.page, path: a),
      _route(ScreenId.profileEdit, _Move.page),
      for (final a in Routes.profileEditAliases) _route(ScreenId.profileEdit, _Move.page, path: a),
      _route(ScreenId.onboarding, _Move.dip),
      _route(ScreenId.recap, _Move.dip),
      _route(ScreenId.annual, _Move.dip),
      _route(ScreenId.reader, _Move.reader),
      for (final a in Routes.readerAliases) _route(ScreenId.reader, _Move.reader, path: a),
      _route(ScreenId.readAll, _Move.reader),
      _route(ScreenId.novel, _Move.reader),
      for (final a in Routes.novelAliases) _route(ScreenId.novel, _Move.reader, path: a),
      _route(ScreenId.readerLanding, _Move.page),
      _route(ScreenId.feature, _Move.match),
      // `/library/:followedId` after every static `/library/...` path (the shell above and the
      // annual and read-alias routes here).
      _route(ScreenId.featureByFollow, _Move.match),
      // Mobile aliases that redirect into the owning branch.
      _redirect('/collections', (s) => Routes.collections()),
      _redirect('/collections/:collectionId', (s) => Routes.collection(s.pathParameters['collectionId']!)),
      _redirect('/ocr/search', (s) => Routes.dialogue({'q': s.uri.queryParameters['q']})),
    ];

/// The change notifier the router refreshes on: setup, auth, the active profile and the profile
/// session gate. The router is built once per boot; recreating it would drop every branch stack.
class _GateBridge extends ChangeNotifier {
  void poke() => notifyListeners();
}

CineGateState _gateState(Ref ref) {
  final auth = ref.read(authControllerProvider);
  return CineGateState(
    setupCompleted: ref.read(setupCompletedProvider),
    auth: switch (auth) {
      AuthUnknown() => CineAuth.unknown,
      AuthUnauthenticated() => CineAuth.unauthenticated,
      AuthAuthenticated() => CineAuth.authenticated,
    },
    hasActiveProfile: ref.read(activeProfileProvider) != null,
  );
}

/// One `GoRouter` per boot (cinematic 8.0.3, 8.2).
GoRouter buildCinematicRouter(Ref ref) {
  final bridge = _GateBridge();
  ref
    ..onDispose(bridge.dispose)
    ..listen<bool>(setupCompletedProvider, (_, __) => bridge.poke())
    ..listen<AuthState>(authControllerProvider, (_, __) => bridge.poke())
    ..listen(activeProfileProvider, (_, __) => bridge.poke())
    ..listen<bool>(profileSessionReadyProvider, (_, __) => bridge.poke())
    // Keeps the X-Profile-Id header installed for the app's lifetime without rebuilding the router.
    ..listen(profileHeaderSyncProvider, (_, __) {});

  final router = GoRouter(
    navigatorKey: cineRootKey,
    initialLocation: ref.read(returnRouteProvider) ?? Routes.tonight(),
    refreshListenable: bridge,
    observers: [cineTopRouteObserver],
    redirect: (context, state) {
      final gate = _gateState(ref);
      // A remembered profile passes the picker (8.5): open the legacy session gate too, so both
      // agree. Never during the redirect itself.
      if (gate.auth == CineAuth.authenticated && gate.hasActiveProfile && !ref.read(profileSessionReadyProvider)) {
        Future.microtask(() {
          if (!ref.read(profileSessionReadyProvider)) ref.read(profileSessionReadyProvider.notifier).enter();
        });
      }
      return cineRedirect(gate, state.uri);
    },
    routes: [
      ..._shellRoutes(),
      ..._rootRoutes(),
    ],
    errorBuilder: (context, state) => CineErrorScreen.notFound(location: state.uri.toString()),
  );
  ref.onDispose(router.dispose);
  return router;
}

@visibleForTesting
Set<ScreenId> get cinePendingIds => PENDING;

/// Whether [id] still shows the pending screen (screens that branch on another screen existing).
bool cineIsPending(ScreenId id) => PENDING.contains(id);
