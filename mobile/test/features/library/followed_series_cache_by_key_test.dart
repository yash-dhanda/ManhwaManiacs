import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/utils/followed_series_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shelf_fixtures.dart';

void main() {
  test('cachedFollowedSeriesByKey finds the row by source and series key, honours the gate', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final key = followedSeriesCacheKeyFor('u1p1');
    await writeCachedFollowedSeries(prefs, key, [
      shelfSeries(1, source: 'a', cover: 'https://x/1.jpg'),
      shelfSeries(2, source: 'b', rating: 'mature', cover: 'https://x/2.jpg'),
    ]);
    expect(cachedFollowedSeriesByKey(prefs, key, 'a', 'series-1')?.coverUrl, 'https://x/1.jpg');
    expect(cachedFollowedSeriesByKey(prefs, key, 'b', 'series-1'), isNull);
    expect(cachedFollowedSeriesByKey(prefs, key, 'b', 'series-2'), isNotNull);
    expect(cachedFollowedSeriesByKey(prefs, key, 'b', 'series-2', gateOpen: false), isNull);
  });
}
