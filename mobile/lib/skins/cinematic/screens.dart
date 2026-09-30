import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/auth/login_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/auth/register_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/auth/setup_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/catalogue/catalogue_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/dialogue/dialogue_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/discover_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/sources/sources_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/library/library_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/profiles/picker_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/profiles/profile_form_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/profiles/profiles_manage_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/tonight_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/updates/updates_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/cine_scaffold.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/pending_screen.dart';

/// The built screens. A step that finishes a `ScreenId` registers its builder here and deletes
/// the id from `PENDING` in `router.dart` (the route's name follows: `pending.<id>` becomes the
/// bare id). Builders receive the route's `GoRouterState`; `state.extra` is a
/// `Map<String, String>?` (`transition`, `entry`, `mode`).
///
/// `feature` and `featureByFollow` are mobile/11's, already built.
final Map<ScreenId, GoRouterWidgetBuilder> cinematicScreens = {
  ScreenId.tonight: (context, state) => const TonightScreen(),
  ScreenId.library: (context, state) => LibraryScreen(params: state.uri.queryParameters, browse: state.uri.path == '/library/browse'),
  ScreenId.updates: (context, state) => const UpdatesScreen(),
  ScreenId.setup: (context, state) => const SetupScreen(),
  ScreenId.login: (context, state) => const LoginScreen(),
  ScreenId.register: (context, state) => const RegisterScreen(),
  ScreenId.profiles: (context, state) => ProfilePickerScreen(switchMode: state.extra is Map && (state.extra! as Map)['mode'] == 'switch'),
  ScreenId.profileNew: (context, state) => const ProfileFormScreen(),
  ScreenId.profileEdit: (context, state) => ProfileFormScreen(profileId: int.tryParse(state.pathParameters['id'] ?? '')),
  ScreenId.profilesManage: (context, state) => const ProfilesManageScreen(),
  ScreenId.discover: (context, state) => DiscoverScreen(
        q: state.uri.queryParameters['q'] ?? '',
        scope: state.uri.queryParameters['scope'],
        genre: state.uri.queryParameters['genre'],
      ),
  ScreenId.sources: (context, state) => const SourcesScreen(),
  ScreenId.source: (context, state) => CatalogueScreen(
        key: ValueKey(state.pathParameters['sourceId']),
        sourceId: state.pathParameters['sourceId']!,
        mode: state.uri.queryParameters['mode'],
        genre: state.uri.queryParameters['genre'],
        q: state.uri.queryParameters['q'],
      ),
  ScreenId.dialogue: (context, state) => DialogueScreen(q: state.uri.queryParameters['q'] ?? ''),
  ScreenId.featureByFollow: (context, state) => FeatureByFollowScreen(
        followedId: int.tryParse(state.pathParameters['followedId'] ?? '') ?? -1,
      ),
  ScreenId.feature: (context, state) => FeatureScreen(
        sourceId: state.pathParameters['sourceId']!,
        seriesKey: state.pathParameters['seriesKey']!,
        chapter: state.uri.queryParameters['chapter'],
      ),
};

/// The screen for [id]: the registered one, else mobile/01's skin-neutral pending screen inside the
/// real frame (running head, back arrow).
Widget cineScreenFor(BuildContext context, ScreenId id, GoRouterState state, {required bool pending}) {
  final built = cinematicScreens[id];
  if (!pending && built != null) return built(context, state);
  return _PendingInFrame(id: id, location: state.uri.toString());
}

class _PendingInFrame extends StatelessWidget {
  const _PendingInFrame({required this.id, required this.location});
  final ScreenId id;
  final String location;

  @override
  Widget build(BuildContext context) => CineScaffold(
        location: location,
        firstRunNote: false,
        // The pending screen brings its own safe area; the scaffold already inset the head.
        body: PendingScreen(screenId: id.id, location: location),
      );
}
