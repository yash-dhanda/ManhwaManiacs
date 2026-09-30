import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/skins.dart';

void main() {
  late GoRouter router;
  late ProviderContainer c;

  setUp(() {
    c = ProviderContainer(overrides: [skinIdProvider.overrideWithValue(SkinId.cinematic)]);
    router = c.read(skinRouterProvider);
  });
  tearDown(() => c.dispose());

  GoRoute leaf(String loc) {
    final m = router.configuration.findMatch(Uri.parse(loc));
    expect(m.isError, isFalse, reason: loc);
    return m.routes.last as GoRoute;
  }

  String name(String loc) => leaf(loc).name ?? leaf(loc).path;

  test('static /library/... paths win over /library/:followedId', () {
    expect(name('/library/history'), 'pending.history');
    expect(name('/library/bookmarks'), 'pending.bookmarks');
    expect(name('/library/collections'), 'pending.collections');
    expect(name('/library/collections/7'), 'pending.collection');
    expect(name('/library/recommendations'), 'picks');
    expect(name('/library/statistics'), 'pending.numbers');
    expect(name('/library/statistics/annual/2026'), 'pending.annual');
    expect(leaf('/library/browse').path, '/library/browse');
    expect(name('/library/read/a/b/c'), '/library/read/:sourceId/:seriesKey/:chapterKey');
  });

  test('/library/:followedId is the series page by follow id', () {
    expect(name('/library/42'), ScreenId.featureByFollow.id);
  });

  test('every ScreenId resolves on its branch or the root navigator', () {
    for (final s in ScreenId.values) {
      final loc = s.path.replaceAllMapped(RegExp(r':\w+'), (_) => 'x');
      expect(router.configuration.findMatch(Uri.parse(loc)).isError, isFalse, reason: s.id);
    }
  });

  test('branch routes sit inside the shell, root routes do not', () {
    bool inShell(String loc) =>
        router.configuration.findMatch(Uri.parse(loc)).routes.any((r) => r is StatefulShellRoute);
    for (final l in ['/', '/library', '/updates', '/library/collections', '/library/history', '/library/bookmarks', '/search', '/sources', '/sources/x', '/ocr', '/library/recommendations', '/downloads', '/more', '/settings', '/settings/storage', '/admin/status', '/library/statistics', '/circle', '/circle/3', '/profiles/manage']) {
      expect(inShell(l), isTrue, reason: l);
    }
    for (final l in ['/setup', '/login', '/register', '/profiles', '/profiles/new', '/profiles/3/edit', '/welcome', '/library/statistics/annual/2026', '/library/42', '/sources/a/series/b', '/reader/a/b/c', '/read-all/a/b', '/novels/a/b/c', '/recap/a/b', '/splash']) {
      expect(inShell(l), isFalse, reason: l);
    }
  });

  test('the Library hub is a nested shell of five tabs', () {
    final m = router.configuration.findMatch(Uri.parse('/updates'));
    final shells = m.routes.whereType<StatefulShellRoute>().toList();
    expect(shells.length, 2);
    expect(shells.first.branches.length, 5);
    expect(shells.last.branches.length, 5);
  });

  test('mobile aliases resolve', () {
    for (final a in [
      ...Routes.profileNewAliases,
      ...Routes.profileEditAliases,
      ...Routes.libraryAliases,
      ...Routes.collectionsAliases,
      ...Routes.collectionAliases,
      ...Routes.readerAliases,
      ...Routes.novelAliases,
      ...Routes.dialogueAliases,
      ...Routes.settingsAliases,
    ]) {
      final loc = a.replaceAllMapped(RegExp(r':\w+'), (_) => 'x');
      expect(router.configuration.findMatch(Uri.parse(loc)).isError, isFalse, reason: a);
    }
  });

  test('redirect aliases land on the branch-1 paths', () {
    final r = router.configuration.findMatch(Uri.parse('/collections/9')).routes.last as GoRoute;
    expect(r.redirect, isNotNull);
    expect(router.configuration.findMatch(Uri.parse('/collections')).routes.last, isA<GoRoute>());
  });
}
