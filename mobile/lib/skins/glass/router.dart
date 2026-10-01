import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/app/skin_boot.dart' show kSkinDebugKey;
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/auth/utils/route_guard.dart';
import 'package:manhwamaniacs/features/onboarding/store/onboarding_draft.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart' show setupCompletedProvider;
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/dev/auth_fixtures.dart';
import 'package:manhwamaniacs/skins/glass/dev/calibration_page.dart';
import 'package:manhwamaniacs/skins/glass/dev/dev_controls.dart';
import 'package:manhwamaniacs/skins/glass/dev/engine_probe_page.dart';
import 'package:manhwamaniacs/skins/glass/dev/glass_dev_index.dart';
import 'package:manhwamaniacs/skins/glass/dev/glass_gallery.dart';
import 'package:manhwamaniacs/skins/glass/dev/overlay_sections.dart';
import 'package:manhwamaniacs/skins/glass/dev/shell_demo.dart';
import 'package:manhwamaniacs/skins/glass/routes/depth_observer.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_swipe_route.dart';
import 'package:manhwamaniacs/skins/glass/routes/nav_extra.dart';
import 'package:manhwamaniacs/skins/glass/routes/redirect_hold.dart';
import 'package:manhwamaniacs/skins/glass/routes/route_frame.dart';
import 'package:manhwamaniacs/skins/glass/routes/sheet_param_host.dart';
import 'package:manhwamaniacs/skins/glass/screens/auth/login_screen.dart';
import 'package:manhwamaniacs/skins/glass/screens/auth/register_screen.dart';
import 'package:manhwamaniacs/skins/glass/screens/auth/setup_screen.dart';
import 'package:manhwamaniacs/skins/glass/screens/circle/circle_screen.dart';
import 'package:manhwamaniacs/skins/glass/screens/circle/friend_sheet.dart';
import 'package:manhwamaniacs/skins/glass/screens/dialogue/dialogue_screen.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_screen.dart';
import 'package:manhwamaniacs/skins/glass/screens/onboarding/glass_steps.dart';
import 'package:manhwamaniacs/skins/glass/screens/onboarding/onboarding_screen.dart';
import 'package:manhwamaniacs/skins/glass/screens/picks/for_you_screen.dart';
import 'package:manhwamaniacs/skins/glass/screens/profiles/picker_screen.dart';
import 'package:manhwamaniacs/skins/glass/screens/profiles/profile_form.dart';
import 'package:manhwamaniacs/skins/glass/screens/profiles/profiles_manage_screen.dart';
import 'package:manhwamaniacs/skins/glass/screens/recap/recap_sheet.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_screen.dart';
import 'package:manhwamaniacs/skins/glass/screens/sources/catalogue_screen.dart';
import 'package:manhwamaniacs/skins/glass/screens/sources/sources_screen.dart';
import 'package:manhwamaniacs/skins/glass/screens/stats/statistics_screen.dart';
import 'package:manhwamaniacs/skins/glass/screens/status/status_screen.dart';
import 'package:manhwamaniacs/skins/glass/screens/system/not_found.dart';
import 'package:manhwamaniacs/skins/glass/screens/system/route_error.dart';
import 'package:manhwamaniacs/skins/glass/screens/wrapped/wrapped_screen.dart';
import 'package:manhwamaniacs/skins/glass/screens/you/you_screen.dart';
import 'package:manhwamaniacs/skins/glass/shell/glass_migration.dart';
import 'package:manhwamaniacs/skins/glass/shell/glass_scaffold.dart';
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
  ScreenId.library,
  ScreenId.updates,
  ScreenId.collections,
  ScreenId.collection,
  ScreenId.history,
  ScreenId.bookmarks,
  ScreenId.featureByFollow,
  ScreenId.feature,
  ScreenId.reader,
  ScreenId.readAll,
  ScreenId.novel,
  ScreenId.downloads,
};

/// The Glass development routes (mobile/25), outside the `ScreenId` map. Settings -> Diagnostics links the calibration page (mobile/40).
const String kGlassDevPath = '/dev/glass';
const String kGlassCalibrationPath = '/dev/glass/calibration';

/// The primitives gallery (`mobile/26`); `?section=buttons|hold|icon-buttons|…` shows one family.
const String kGlassPrimitivesPath = '/dev/glass/primitives';

/// The shell demo (`mobile/29`): the frame with a scaffold, lists, a poster rail, accessories, the Dive and depth pushes.
const String kGlassShellDemoPath = '/dev/glass/shell';

/// The auth, profiles and onboarding fixtures (`mobile/30`).
const String kGlassAuthDemoPath = '/dev/glass/auth';

/// The route error screen on its own (its captures and its tests).
const String kGlassRouteErrorDemoPath = '/dev/glass/route-error';

/// The reader engine probe (`mobile/34`): `?fixture=long-strip` or `?source=&series=&chapter=`, `&mode=continuous|single`.
const String kGlassReaderEngineProbePath = '/dev/glass/reader-engine';

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

/// A finished screen (mobile/30 onwards): the route carries the plain id as its name and builds [build].
GoRoute _screen(ScreenId id, Widget Function(GoRouterState state) build, {String? path, GlobalKey<NavigatorState>? parent, bool takeover = false, bool reader = false}) {
  final isPattern = path == null || path == id.path;
  return GoRoute(
    path: path ?? id.path,
    name: isPattern ? _nameOf(id) : null,
    parentNavigatorKey: parent,
    pageBuilder: (context, state) => glassPage(state, build(state), reader: reader, takeover: takeover),
  );
}

/// The profile form: a sheet (a 560 px window on wide frames) over the picker when opened with a `GlassNavExtra`, else the page.
GoRoute _formSheetRoute(ScreenId id, GlobalKey<NavigatorState> root, {required String title, bool edit = false}) => GoRoute(
      path: id.path,
      name: _nameOf(id),
      parentNavigatorKey: root,
      pageBuilder: (context, state) {
        final pid = edit ? int.tryParse(state.pathParameters['id'] ?? '') : null;
        if (edit && pid == null) return glassPage(state, GlassNotFound(location: state.uri.toString()));
        void close(BuildContext c) => c.canPop() ? c.pop() : c.go(Routes.profiles());
        Widget form({bool embedded = false}) => Builder(builder: (c) => GlassProfileForm(profileId: pid, embedded: embedded, onClose: () => close(c)));
        final page = GlassScaffold(title: title, leading: GlassLeading.back, slivers: [SliverToBoxAdapter(child: form(embedded: true))]);
        return glassSheetOrPage(context, state, form(), title: title, detents: const [GlassDetent.large], screen: page);
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

/// `/welcome?step=n` while the active profile has not finished onboarding; null when it has, or the profile list has not loaded yet.
String? _onboardingRedirect(Ref ref) {
  final active = ref.read(activeProfileProvider);
  final profiles = ref.read(profilesProvider).valueOrNull;
  if (active == null || profiles == null) return null;
  final p = profiles.where((x) => x.id == active.id).firstOrNull;
  if (p == null || !needsOnboarding(p, ref.read(onboardingStoreProvider).readPending())) return null;
  final lookShown = Flags.glassAvailable || ref.read(sharedPrefsProvider).getString(kSkinDebugKey) == 'glass';
  return Routes.onboarding({'step': resumeGlassStep(p.onboarding, lookShown: lookShown) ?? 1});
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
    ..listen<bool>(glassRedirectHoldProvider, (_, __) => bridge.poke())
    ..listen(profilesProvider, (_, __) => bridge.poke())
    ..listen(profileHeaderSyncProvider, (_, __) {})
    ..listen(glassPrefsMigrationProvider, (_, __) {});

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
      // A success choreography on Setup, Login or Register runs before the guard moves the screen (mobile/30).
      if (ref.read(glassRedirectHoldProvider)) return null;
      final gate = _gate(ref);
      if (gate.auth == GateAuth.authenticated && gate.hasActiveProfile && !ref.read(profileSessionReadyProvider)) {
        Future.microtask(() {
          if (!ref.read(profileSessionReadyProvider)) ref.read(profileSessionReadyProvider.notifier).enter();
        });
      }
      final to = gateRedirect(gate, state.uri);
      if (to != null) return to;
      // A profile still in onboarding never sees Home (mobile/31): the redirect runs before any rail paints.
      return state.uri.path == Routes.tonightPattern ? _onboardingRedirect(ref) : null;
    },
    routes: [
      // Mobile's kept `/settings/storage` (glass 8.0.3, 8.25.9): Downloads -> Storage, before any Settings widget builds.
      _redirect('/settings/storage', (s) => Routes.downloads({'tab': 'storage'})),
      _devRoute(kGlassDevPath, () => const GlassDevIndex()),
      _devRoute(kGlassCalibrationPath, () => const GlassCalibrationPage()),
      _devRoute(kGlassAuthDemoPath, () => const GlassAuthDevPage()),
      GoRoute(
        path: kGlassReaderEngineProbePath,
        builder: (context, state) => _DevScaffold(child: EngineProbePage(params: state.uri.queryParameters)),
      ),
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
            _screen(ScreenId.tonight, (s) => const GlassHomeScreen()),
            _route(ScreenId.updates),
            _screen(ScreenId.picks, (s) => ForYouScreen(genre: s.uri.queryParameters['genre'])),
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
            _screen(ScreenId.sources, (s) => const GlassSourcesScreen()),
            _screen(ScreenId.source, (s) => GlassCatalogueScreen(sourceId: s.pathParameters['sourceId'] ?? '', mode: s.uri.queryParameters['mode'], genre: s.uri.queryParameters['genre'], q: s.uri.queryParameters['q'])),
            _screen(ScreenId.dialogue, (s) => GlassDialogueScreen(q: s.uri.queryParameters['q'])),
          ]),
          branch(GlassTab.you, [
            GoRoute(
              path: kGlassShellDemoPath,
              pageBuilder: (context, state) => glassPage(state, GlassShellDemo(level: int.tryParse(state.uri.queryParameters['level'] ?? '') ?? 0)),
            ),
            _screen(ScreenId.indexHub, (s) => const YouScreen()),
            _screen(ScreenId.settings, (s) => GlassSettingsScreen(row: s.uri.queryParameters['row'])),
            _screen(ScreenId.settings, (s) => GlassSettingsScreen(section: s.pathParameters['section'], row: s.uri.queryParameters['row']), path: Routes.settingsAliases.first),
            _screen(ScreenId.circle, (s) => CircleScreen(tab: s.uri.queryParameters['tab'])),
            _screen(ScreenId.numbers, (s) => GlassStatisticsScreen(range: s.uri.queryParameters['range'], year: s.uri.queryParameters['year'])),
            _screen(ScreenId.status, (s) => const StatusScreen()),
            _screen(ScreenId.profilesManage, (s) => const GlassProfilesManageScreen()),
          ]),
        ],
      ),
      // Root navigator: takeovers, readers, search and the sheet routes.
      _screen(ScreenId.setup, (s) => const GlassSetupScreen(), parent: rootKey, takeover: true),
      _screen(ScreenId.login, (s) => GlassLoginScreen(user: s.uri.queryParameters['user']), parent: rootKey, takeover: true),
      _screen(ScreenId.register, (s) => const GlassRegisterScreen(), parent: rootKey, takeover: true),
      _screen(ScreenId.profiles, (s) => const GlassProfilePicker(), parent: rootKey, takeover: true),
      _screen(ScreenId.onboarding, (s) => GlassOnboardingScreen(step: int.tryParse(s.uri.queryParameters['step'] ?? '')), parent: rootKey, takeover: true),
      _screen(ScreenId.annual, (s) => GlassWrappedScreen(yearParam: s.pathParameters['year']), parent: rootKey, takeover: true),
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
      GoRoute(
        path: ScreenId.recap.path,
        name: _nameOf(ScreenId.recap),
        parentNavigatorKey: rootKey,
        pageBuilder: (context, state) => glassSheetOrPage(
          context,
          state,
          RecapSheet(sourceId: state.pathParameters['sourceId']!, seriesKey: state.pathParameters['seriesKey']!, to: state.uri.queryParameters['to'], scope: state.uri.queryParameters['scope'] == 'chapter' ? 'chapter' : 'series'),
          title: 'Recap',
        ),
      ),
      // A friend (mobile/43, glass 9.3.5): a `large` sheet, the 560 px window on wide frames, a full page on a cold deep link.
      GoRoute(
        path: ScreenId.circleMember.path,
        name: _nameOf(ScreenId.circleMember),
        parentNavigatorKey: rootKey,
        pageBuilder: (context, state) {
          final id = int.tryParse(state.pathParameters['profileId'] ?? '');
          if (id == null) return glassPage(state, GlassNotFound(location: state.uri.toString()));
          return glassSheetOrPage(context, state, FriendSheet(profileId: id), title: 'Circle', detents: const [GlassDetent.large], screen: FriendScreen(profileId: id));
        },
      ),
      _formSheetRoute(ScreenId.profileNew, rootKey, title: 'Add profile'),
      _formSheetRoute(ScreenId.profileEdit, rootKey, title: 'Edit profile', edit: true),
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
