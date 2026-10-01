import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/profiles/providers/profile_scope.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';

import 'fakes.dart';

void main() {
  for (final (name, list) in [('profile switch', profileScopedInvalidators), ('18+ gate change', matureScopedInvalidators)]) {
    test('a $name drops the Glass Circle caches (members per series, the friend feed)', () async {
      final repo = FakeCircleRepository(membersList: [member(riya, canReceive: true)]);
      final run = Provider<void Function()>((ref) => () {
            for (final i in list) {
              try {
                i(ref);
              } catch (_) {}
            }
          },);
      final c = ProviderContainer(overrides: [circleRepositoryProvider.overrideWithValue(repo)]);
      addTearDown(c.dispose);
      final keep = [c.listen(seriesMembersProvider((sourceId: 's', seriesKey: 'k')), (_, __) {}), c.listen(memberFeedProvider(2), (_, __) {})];
      await c.read(seriesMembersProvider((sourceId: 's', seriesKey: 'k')).future);
      await c.read(memberFeedProvider(2).future);
      final before = repo.log.length;
      c.read(run)();
      await c.read(seriesMembersProvider((sourceId: 's', seriesKey: 'k')).future);
      await c.read(memberFeedProvider(2).future);
      expect(repo.log.skip(before), containsAll(['members', 'feed all ']));
      for (final k in keep) {
        k.close();
      }
    });
  }
}
