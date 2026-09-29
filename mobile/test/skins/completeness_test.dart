import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/cinematic/router.dart' as cine;
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/router.dart' as glass;
import 'package:manhwamaniacs/skins/pending_routes.dart';
import 'package:manhwamaniacs/skins/skins.dart';

// mobile/24 sets cinematic to true, mobile/45 sets glass to true (release gates).
const mustBeComplete = {SkinId.cinematic: false, SkinId.glass: false};

Set<ScreenId> _pendingOf(SkinId id) =>
    id == SkinId.cinematic ? cine.PENDING : glass.PENDING;

Set<String> _namedPending(GoRouter r) => {
      for (final route in r.configuration.routes)
        if (route is GoRoute &&
            (route.name ?? '').startsWith(kPendingRoutePrefix))
          route.name!.substring(kPendingRoutePrefix.length),
    };

String _fill(String path) => path.replaceAllMapped(RegExp(r':\w+'), (_) => 'x');

void main() {
  for (final id in [SkinId.cinematic, SkinId.glass]) {
    test('${id.name} router covers every ScreenId', () {
      final c =
          ProviderContainer(overrides: [skinIdProvider.overrideWithValue(id)]);
      addTearDown(c.dispose);
      final router = c.read(skinRouterProvider);
      final pending = _pendingOf(id);

      for (final s in ScreenId.values) {
        final m = router.configuration.findMatch(Uri.parse(_fill(s.path)));
        expect(m.isError, isFalse, reason: s.id);
      }
      final aliases = [
        ...Routes.profileNewAliases,
        ...Routes.profileEditAliases,
        ...Routes.libraryAliases,
        ...Routes.collectionsAliases,
        ...Routes.collectionAliases,
        ...Routes.readerAliases,
        ...Routes.novelAliases,
        ...Routes.dialogueAliases,
        ...Routes.settingsAliases,
      ];
      for (final a in aliases) {
        expect(router.configuration.findMatch(Uri.parse(_fill(a))).isError,
            isFalse,
            reason: a,);
      }
      // Static /library/... paths win over /library/:followedId.
      final hist =
          router.configuration.findMatch(Uri.parse('/library/history'));
      expect((hist.routes.last as GoRoute).name,
          '$kPendingRoutePrefix${ScreenId.history.id}',);
      final byFollow = router.configuration.findMatch(Uri.parse('/library/42'));
      expect((byFollow.routes.last as GoRoute).name,
          '$kPendingRoutePrefix${ScreenId.featureByFollow.id}',);

      expect(ScreenId.values.toSet().containsAll(pending), isTrue);
      expect(_namedPending(router), pending.map((e) => e.id).toSet());
      if (mustBeComplete[id]!) expect(pending, isEmpty);
      // ignore: avoid_print
      print(
          '${id.name} pending: ${pending.length} / ${ScreenId.values.length}',);
    });
  }
}
