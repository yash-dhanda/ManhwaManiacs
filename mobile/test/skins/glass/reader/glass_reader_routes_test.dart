import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/router.dart' as glass;
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('reader and readAll are out of PENDING; readerLanding stays a redirect to /library; the aliases are reader routes', () async {
    expect(glass.PENDING.contains(ScreenId.reader), isFalse);
    expect(glass.PENDING.contains(ScreenId.readAll), isFalse);
    expect(glass.PENDING.contains(ScreenId.readerLanding), isFalse);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [skinIdProvider.overrideWithValue(SkinId.glass), sharedPrefsProvider.overrideWithValue(prefs)]);
    addTearDown(c.dispose);
    final router = c.read(skinRouterProvider);
    final landing = router.configuration.findMatch(Uri.parse('/reader'));
    expect((landing.routes.last as GoRoute).name, ScreenId.readerLanding.id);
    expect(Routes.readerLandingRedirect, '/library');
    for (final p in ['/reader/s/k/c', '/library/read/s/k/c', '/sources/s/series/k/chapters/c/read']) {
      final m = router.configuration.findMatch(Uri.parse(p));
      expect(m.isError, isFalse, reason: p);
      expect((m.routes.last as GoRoute).redirect, isNull, reason: '$p is a reader route, not a redirect');
    }
    expect(((router.configuration.findMatch(Uri.parse('/read-all/s/k'))).routes.last as GoRoute).name, ScreenId.readAll.id);
  });
}
