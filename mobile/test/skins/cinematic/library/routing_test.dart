// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_view.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/skins.dart';

import '../feature/feature_test_support.dart' show FakeUpdates;
import 'library_test_support.dart';

void main() {
  group('routes', () {
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

    test('library and its browse alias are built, not pending', () {
      expect(leaf('/library').name, ScreenId.library.id);
      expect(leaf('/library/browse').path, '/library/browse');
    });

    test('each static /library/... path reaches its own screen before /library/:followedId', () {
      expect(leaf('/library/collections').name, 'pending.collections');
      expect(leaf('/library/collections/7').name, 'pending.collection');
      expect(leaf('/library/history').name, 'pending.history');
      expect(leaf('/library/bookmarks').name, 'pending.bookmarks');
      expect(leaf('/library/statistics').name, 'pending.numbers');
      expect(leaf('/library/recommendations').name, 'pending.picks');
      expect(leaf('/library/statistics/annual/2026').name, 'pending.annual');
      expect(leaf('/library/42').name, ScreenId.featureByFollow.id);
    });
  });

  group('featureByFollow', () {
    testWidgets('an unknown id shows NOT IN THIS ISSUE, with no redirect', (t) async {
      final rig = await pumpShelf(t, start: '/library/77', extra: [updatesProvider.overrideWith(() => FakeUpdates(Recorder(), const []))]);
      final sem = t.ensureSemantics();
      await settleShelf(t, by: const Duration(seconds: 2));
      expect(find.text('NOT IN THIS ISSUE'), findsOneWidget);
      expect(find.bySemanticsLabel("This series isn't available here any more."), findsOneWidget);
      expect(rig.at, '/library/77');
      sem.dispose();
    });

    testWidgets('a server failure is a CORRECTION with Try again and Back to library', (t) async {
      final lib = ShelfLibrary(all: const []);
      final rig = await pumpShelf(t, lib: lib, start: '/library/77', extra: [
        updatesProvider.overrideWith(() => FakeUpdates(Recorder(), const [])),
        libraryDetailFails,
      ]);
      await settleShelf(t, by: const Duration(seconds: 2));
      expect(find.text('CORRECTION'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      await t.tap(find.text('Back to library'));
      await settleShelf(t);
      expect(rig.at, '/library');
    });

    testWidgets('a followed row in the follow cache renders FeatureView in place', (t) async {
      final row = shelfSeries(7, title: 'Tower of Dawn');
      final rig = await pumpShelf(t, start: '/library/7', extra: [updatesProvider.overrideWith(() => FakeUpdates(Recorder(), [row]))]);
      await settleShelf(t, by: const Duration(seconds: 2));
      expect(find.byType(FeatureView), findsOneWidget);
      expect(rig.at, '/library/7');
    });
  });
}
