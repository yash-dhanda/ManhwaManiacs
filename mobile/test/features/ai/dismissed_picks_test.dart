import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/ai/models/similar_result.dart';
import 'package:manhwamaniacs/features/ai/providers/ai_providers.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';

void main() {
  test('dismissed set adds, removes and keys shelf rows by source', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    const a = WorldItem(title: 'A', anilistId: 7);
    const b = WorldItem(title: 'B', available: [WorldAvailability(sourceId: 's', sourceName: 'S', seriesKey: 'k')]);
    expect(pickId(a), 'a7');
    expect(pickId(b), 'ss:k');
    c.read(dismissedPicksProvider.notifier)
      ..add(pickId(a))
      ..add(pickId(b));
    expect(c.read(dismissedPicksProvider), {'a7', 'ss:k'});
    c.read(dismissedPicksProvider.notifier).remove('a7');
    expect(c.read(dismissedPicksProvider), {'ss:k'});
  });

  test('similar query params', () {
    expect(const SimilarQuery.series('s', 'k', fallbackGenres: true).params, {'source': 's', 'series': 'k', 'fallback': 'genres'});
    expect(const SimilarQuery.anilist(9).params, {'anilist_id': 9});
  });

  test('similar result parses genre fallback and stale time', () {
    final r = SimilarResult.fromJson({
      'items': [
        {'title': 'X', 'anilist_id': null, 'why': null}
      ],
      'available': false,
      'reason': 'not_configured',
      'basis': 'genres',
      'generated_at': '2026-09-01T00:00:00Z',
    });
    expect(r.isGenres, isTrue);
    expect(r.available, isFalse);
    expect(r.items.single.why, isNull);
    expect(r.generatedAt, isNotNull);
  });
}
