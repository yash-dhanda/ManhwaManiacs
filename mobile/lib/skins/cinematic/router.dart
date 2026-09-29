import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/dip_page.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/annual/annual_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/numbers_screen.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/pending_routes.dart';
import 'package:manhwamaniacs/skins/pending_screen.dart';
import 'package:manhwamaniacs/skins/skins.dart';

// Every id is pending; finishing a screen deletes its line. mobile/24 deletes the set.
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
  ScreenId.readerLanding,
};

/// The screens mobile/21 builds. `/library/statistics` must precede
/// `/library/:followedId`, so they are inserted ahead of it.
List<RouteBase> _routes() {
  final routes = <RouteBase>[...pendingRoutes(PENDING)];
  final at = routes.indexWhere((r) => r is GoRoute && r.path == ScreenId.featureByFollow.path);
  routes.insertAll(at < 0 ? routes.length : at, [
    // TODO(mobile/06): pushed with Page from Index once the shell exists.
    GoRoute(path: ScreenId.numbers.path, name: ScreenId.numbers.id, builder: (context, state) => const NumbersScreen()),
    // A takeover entered and left by Dip.
    GoRoute(
      path: ScreenId.annual.path,
      name: ScreenId.annual.id,
      pageBuilder: (context, state) => dipPage(key: state.pageKey, child: AnnualScreen(yearParam: state.pathParameters['year'] ?? '')),
    ),
  ]);
  return routes;
}

GoRouter buildCinematicRouter(Ref ref) => GoRouter(
      initialLocation: ref.read(returnRouteProvider) ?? ScreenId.tonight.path,
      routes: _routes(),
      errorBuilder: (context, state) =>
          PendingScreen(screenId: 'not-found', location: state.uri.toString()),
    );
