import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/screens.dart' show cinematicScreens;
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/router.dart' as glass;
import 'package:manhwamaniacs/skins/pending_routes.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Cinematic is strict (mobile/24); mobile/45 makes glass strict too.
const mustBeComplete = {SkinId.cinematic: true, SkinId.glass: false};

Set<ScreenId> _pendingOf(SkinId id) =>
    id == SkinId.cinematic ? const {} : glass.PENDING;

Set<String> _namedPending(GoRouter r) => {
      for (final route in RouteBase.routesRecursively(r.configuration.routes))
        if (route is GoRoute &&
            (route.name ?? '').startsWith(kPendingRoutePrefix))
          route.name!.substring(kPendingRoutePrefix.length),
    };

String _fill(String path) => path.replaceAllMapped(RegExp(r':\w+'), (_) => 'x');

void main() {
  for (final id in [SkinId.cinematic, SkinId.glass]) {
    test('${id.name} router covers every ScreenId', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final c =
          ProviderContainer(overrides: [skinIdProvider.overrideWithValue(id), sharedPrefsProvider.overrideWithValue(prefs)]);
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
          pending.contains(ScreenId.history)
              ? '$kPendingRoutePrefix${ScreenId.history.id}'
              : ScreenId.history.id,);
      final byFollow = router.configuration.findMatch(Uri.parse('/library/42'));
      expect((byFollow.routes.last as GoRoute).name,
          pending.contains(ScreenId.featureByFollow)
              ? '$kPendingRoutePrefix${ScreenId.featureByFollow.id}'
              : ScreenId.featureByFollow.id,);

      expect(ScreenId.values.toSet().containsAll(pending), isTrue);
      expect(_namedPending(router), pending.map((e) => e.id).toSet());
      if (mustBeComplete[id]!) expect(pending, isEmpty);
      // ignore: avoid_print
      print(
          '${id.name} pending: ${pending.length} / ${ScreenId.values.length}',);
    });
  }

  test('cinematic: no PENDING identifier on disk, a builder for every ScreenId, readerLanding redirects', () {
    for (final f in Directory('lib/skins/cinematic').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      expect(f.readAsStringSync().contains(RegExp(r'\bPENDING\b|pending_screen\.dart|pending_routes\.dart')), isFalse, reason: f.path);
    }
    for (final s in ScreenId.values.where((s) => s != ScreenId.readerLanding)) {
      expect(cinematicScreens.containsKey(s), isTrue, reason: 'no builder for ${s.id}');
    }
    final c = ProviderContainer(overrides: [skinIdProvider.overrideWithValue(SkinId.cinematic)]);
    addTearDown(c.dispose);
    final m = c.read(skinRouterProvider).configuration.findMatch(Uri.parse(ScreenId.readerLanding.path));
    expect((m.routes.last as GoRoute).redirect, isNotNull);
    expect(Routes.readerLandingRedirect, '/library');
  });
}
