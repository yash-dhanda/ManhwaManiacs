import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/admin/status_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/auth/login_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/auth/register_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/auth/setup_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/bookmarks/bookmarks_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/collections/collection_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/collections/collections_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/catalogue/catalogue_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/dialogue/dialogue_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/discover_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/sources/sources_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/downloads/downloads_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/history/history_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/index/index_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/library/library_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/profiles/picker_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/profiles/profile_form_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/profiles/profiles_manage_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/cine_reader_route.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_screen.dart';
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
  ScreenId.collections: (context, state) => const CollectionsScreen(),
  ScreenId.collection: (context, state) => CollectionScreen(collectionId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1),
  ScreenId.history: (context, state) => const HistoryScreen(),
  ScreenId.bookmarks: (context, state) => const BookmarksScreen(),
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
  ScreenId.settings: (context, state) => SettingsScreen(
        key: ValueKey(state.pathParameters['section'] ?? ''),
        slug: state.pathParameters['section'],
        jumpRow: state.extra is Map ? (state.extra! as Map)['jump'] as String? : null,
        licenses: state.uri.queryParameters['licenses'] == '1',
      ),
  ScreenId.status: (context, state) => const StatusScreen(),
  ScreenId.indexHub: (context, state) => const IndexScreen(),
  ScreenId.downloads: (context, state) =>
      DownloadsScreen(tab: state.uri.queryParameters['tab'], view: state.uri.queryParameters['view']),
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
  ScreenId.reader: (context, state) => _readerFor(state),
  ScreenId.feature: (context, state) => FeatureScreen(
        sourceId: state.pathParameters['sourceId']!,
        seriesKey: state.pathParameters['seriesKey']!,
        chapter: state.uri.queryParameters['chapter'],
      ),
};

/// The reader for `/reader/...`, `/library/read/...` (the manifest path) and
/// `/sources/.../read` (the source path, which keeps its own progress). Each segment is decoded
/// once by go_router; the page and anchor come from the query.
Widget _readerFor(GoRouterState state) {
  final p = state.pathParameters;
  final q = state.uri.queryParameters;
  final page = int.tryParse(q['page'] ?? '') ?? 1;
  final at = double.tryParse(q['at'] ?? '');
  final all = q['all'] == '1' || q['all'] == 'true';
  final key = ValueKey<String>(state.uri.toString());
  if (state.uri.path.startsWith('/sources/')) {
    return CineReaderRoute.source(key: key, sourceId: p['sourceId']!, seriesKey: p['seriesKey']!, chapterKey: p['chapterKey']!, initialPage: page, readAll: all);
  }
  return CineReaderRoute.manifest(
    key: key,
    sourceId: p['sourceId']!,
    seriesKey: p['seriesKey']!,
    chapterKey: p['chapterKey']!,
    initialPage: page,
    initialAnchor: at == null || at.isNaN ? null : (page: page, fraction: at.clamp(0.0, 1.0)),
    readAll: all,
  );
}

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
