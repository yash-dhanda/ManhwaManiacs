// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_stamper.dart';
import 'package:manhwamaniacs/features/sources/models/source_pin.dart';
import 'package:manhwamaniacs/features/sources/utils/source_pins_cache.dart';

import '../../support/downloads_test_support.dart';
import 'mature_gate_support.dart';

void main() {
  initSqfliteFfiForTests();

  test('resolve: the follow cache first (server rating and override), then the source pin', () async {
    final rig = await gateRig(follows: [
      follow(1, 'hot', rating: 'mature', override: true),
      follow(2, 'cleared', rating: 'safe', override: false, content: 'erotica'),
    ]);
    addTearDown(() async {
      rig.container.dispose();
      await rig.harness.dispose();
    });
    await writeCachedSourcePins(
      rig.prefs,
      sourcePinsCacheKeyFor(userId: 1, profileId: 1),
      const [SourcePin(sourceId: 'adult-src', sortOrder: 0, name: 'A', mature: true), SourcePin(sourceId: 'src', sortOrder: 1, name: 'B')],
    );
    final st = rig.container.read(matureStamperProvider);
    expect(await st.resolve('src', 'hot'), isTrue);
    expect(await st.resolve('src', 'cleared'), isFalse, reason: 'the resolved rating wins over the raw content rating');
    expect(await st.resolve('adult-src', 'unknown-series'), isTrue, reason: 'the pin says the source is 18+');
    expect(await st.resolve('src', 'unknown-series'), isFalse, reason: 'a known safe source');
    expect(await st.resolve('nowhere', 'x'), isNull);
  });

  test('restampMissing stamps unstamped rows from each source in order, else false', () async {
    final rig = await gateRig(follows: [follow(1, 'hot', rating: 'mature')]);
    addTearDown(() async {
      rig.container.dispose();
      await rig.harness.dispose();
    });
    // Rows written with no resolver leave the stamp null (a v3 database).
    final bare = rig.harness.storeFor(GateRig.scope);
    await bare.ensureQueued(id: (sourceId: 'src', seriesKey: 'hot', chapterKey: 'c1'));
    await bare.ensureQueued(id: (sourceId: 'src', seriesKey: 'plain', chapterKey: 'c1'));
    await bare.ensureQueued(id: (sourceId: 'zzz', seriesKey: 'x', chapterKey: 'c1'));
    expect(await bare.unstampedSeries(), hasLength(3));
    await rig.container.read(matureStamperProvider).restampMissing();
    final store = rig.container.read(downloadsStoreProvider)!;
    expect(await store.unstampedSeries(), isEmpty);
    final rows = {for (final c in await store.listChapters()) c.seriesKey: c.mature};
    expect(rows, {'hot': true, 'plain': false, 'x': false});
  });
}
