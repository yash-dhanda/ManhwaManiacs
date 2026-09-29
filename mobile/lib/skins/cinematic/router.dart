import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_match_cut_page.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_screen.dart';
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
  ScreenId.numbers,
  ScreenId.annual,
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

GoRouter buildCinematicRouter(Ref ref) => GoRouter(
      initialLocation: ref.read(returnRouteProvider) ?? ScreenId.tonight.path,
      routes: [
        // Static /library/... paths precede /library/:followedId, so the real
        // routes sit where pendingRoutes would have put them: after those.
        ...pendingRoutes(PENDING),
        GoRoute(
          path: ScreenId.featureByFollow.path,
          name: ScreenId.featureByFollow.id,
          pageBuilder: (context, state) => cineMatchCutPage(
            state,
            FeatureByFollowScreen(
              followedId: int.tryParse(state.pathParameters['followedId'] ?? '') ?? -1,
            ),
          ),
        ),
        GoRoute(
          path: ScreenId.feature.path,
          name: ScreenId.feature.id,
          pageBuilder: (context, state) => cineMatchCutPage(
            state,
            FeatureScreen(
              sourceId: state.pathParameters['sourceId']!,
              seriesKey: state.pathParameters['seriesKey']!,
              chapter: state.uri.queryParameters['chapter'],
            ),
          ),
        ),
      ],
      errorBuilder: (context, state) =>
          PendingScreen(screenId: 'not-found', location: state.uri.toString()),
    );
