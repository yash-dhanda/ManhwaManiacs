import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

GoRouter buildCinematicRouter(Ref ref) => GoRouter(
      initialLocation: ref.read(returnRouteProvider) ?? ScreenId.tonight.path,
      routes: pendingRoutes(PENDING),
      errorBuilder: (context, state) =>
          PendingScreen(screenId: 'not-found', location: state.uri.toString()),
    );
