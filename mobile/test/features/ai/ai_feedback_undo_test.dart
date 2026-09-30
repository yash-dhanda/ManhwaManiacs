import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/ai/providers/ai_providers.dart';
import 'package:manhwamaniacs/features/ai/providers/suggested_tags_provider.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';

import '../../skins/cinematic/picks/picks_test_support.dart' show FakeAi;

void main() {
  test('not_interested then undo send the signals and restore the card', () async {
    final ai = FakeAi();
    final c = ProviderContainer(overrides: [aiRepositoryProvider.overrideWithValue(ai)]);
    addTearDown(c.dispose);
    const w = WorldItem(title: 'A', anilistId: 7);
    const s = WorldItem(title: 'B', available: [WorldAvailability(sourceId: 's', sourceName: 'S', seriesKey: 'k')]);
    final fb = c.read(aiFeedbackProvider);
    await fb.notInterested(w);
    expect(c.read(dismissedPicksProvider), {'a7'});
    await fb.undoNotInterested(w);
    expect(c.read(dismissedPicksProvider), isEmpty);
    await fb.notInterested(s);
    await fb.undoNotInterested(s);
    expect([for (final m in ai.sent) (m['signal'], m['anilist_id'], m['source_id'], m['series_key'])], [
      ('not_interested', 7, null, null),
      ('undo', 7, null, null),
      ('not_interested', null, 's', 'k'),
      ('undo', null, 's', 'k'),
    ]);
  });
}
