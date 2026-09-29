import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/pending_screen.dart';

const String kPendingRoutePrefix = 'pending.';

List<String> _aliases(ScreenId id) => switch (id) {
      ScreenId.profileNew => Routes.profileNewAliases,
      ScreenId.profileEdit => Routes.profileEditAliases,
      ScreenId.library => Routes.libraryAliases,
      ScreenId.collections => Routes.collectionsAliases,
      ScreenId.collection => Routes.collectionAliases,
      ScreenId.reader => Routes.readerAliases,
      ScreenId.novel => Routes.novelAliases,
      ScreenId.dialogue => Routes.dialogueAliases,
      ScreenId.settings => Routes.settingsAliases,
      _ => const [],
    };

/// One route per [ScreenId] in the contract's declaration order (static
/// `/library/...` paths already precede `/library/:followedId`), each alias
/// right after its screen. Ids in [pending] build the [PendingScreen] and are
/// named `pending.<id>`; a step that builds a screen removes it from the set
/// and registers the real route here.
List<GoRoute> pendingRoutes(Set<ScreenId> pending) {
  GoRoute route(ScreenId id, String path, {String? name}) => GoRoute(
        path: path,
        name: name,
        builder: (context, state) =>
            PendingScreen(screenId: id.id, location: state.uri.toString()),
      );
  return [
    for (final id in ScreenId.values)
      if (pending.contains(id)) ...[
        route(id, id.path, name: '$kPendingRoutePrefix${id.id}'),
        for (final a in _aliases(id)) route(id, a),
      ],
  ];
}
