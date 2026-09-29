import 'package:flutter/widgets.dart' show ValueKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/catalogue/catalogue_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/dialogue/dialogue_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/discover_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/sources/sources_screen.dart';
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
  ScreenId.reader,
  ScreenId.readAll,
  ScreenId.novel,
  ScreenId.downloads,
  ScreenId.indexHub,
  ScreenId.settings,
  ScreenId.status,
  ScreenId.readerLanding,
};

GoRouter buildCinematicRouter(Ref ref) => GoRouter(
      initialLocation: ref.read(returnRouteProvider) ?? ScreenId.tonight.path,
      routes: [
        ...pendingRoutes(PENDING),
        ..._discoverRoutes(),
      ],
      errorBuilder: (context, state) =>
          PendingScreen(screenId: 'not-found', location: state.uri.toString()),
    );

/// Branch 2: Discover, Sources, the catalogue and Dialogue search (mobile/16).
List<GoRoute> _discoverRoutes() => [
      GoRoute(
        path: ScreenId.discover.path,
        name: ScreenId.discover.id,
        builder: (context, state) => DiscoverScreen(
          q: state.uri.queryParameters['q'] ?? '',
          scope: state.uri.queryParameters['scope'],
          genre: state.uri.queryParameters['genre'],
        ),
      ),
      GoRoute(
        path: ScreenId.sources.path,
        name: ScreenId.sources.id,
        builder: (context, state) => const SourcesScreen(),
      ),
      GoRoute(
        path: ScreenId.source.path,
        name: ScreenId.source.id,
        builder: (context, state) => CatalogueScreen(
          key: ValueKey(state.pathParameters['sourceId']),
          sourceId: state.pathParameters['sourceId']!,
          mode: state.uri.queryParameters['mode'],
          genre: state.uri.queryParameters['genre'],
          q: state.uri.queryParameters['q'],
        ),
      ),
      for (final path in [ScreenId.dialogue.path, ...Routes.dialogueAliases])
        GoRoute(
          path: path,
          name: path == ScreenId.dialogue.path ? ScreenId.dialogue.id : null,
          builder: (context, state) => DialogueScreen(q: state.uri.queryParameters['q'] ?? ''),
        ),
    ];
