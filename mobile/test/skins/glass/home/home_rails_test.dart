import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/home/providers/home_feed_provider.dart';
import 'package:manhwamaniacs/features/home/utils/continue_hidden.dart';
import 'package:manhwamaniacs/features/home/utils/offline_edition.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_rails.dart';

import '../../../features/home/home_fixtures.dart';

HomeFeedView view(HomeFeed f, {bool offline = false}) => (state: HomeFeedState.ready, feed: f, origin: offline ? HomeFeedOrigin.offline : HomeFeedOrigin.server, offline: offline, retryAfter: null);

List<String> ids(List<HomeRailSpec> r) => [for (final x in r) x.id];

void main() {
  test('ready maps sections to rails in the spec order with exact titles', () {
    final r = composeHomeRails(view(loadHome('ready')));
    expect(ids(r).first, 'continue');
    final titles = [for (final x in r) x.title];
    expect(titles, containsAllInOrder(['Continue reading', 'Updated for you']));
    expect(titles.any((t) => t.startsWith('Because you read ')), isTrue);
    expect(titles, containsAllInOrder(['For you', 'Almost there', 'Your genres', 'New in your pinned sources', 'This week']));
    final fy = r.firstWhere((x) => x.id == 'picked');
    expect(fy.subtitle, 'Picked from what you read');
    expect(fy.ai, isTrue);
    expect(r.firstWhere((x) => x.id == 'continue').seeAll, '/library/history');
    expect(r.firstWhere((x) => x.id == 'numbers').seeAll, '/library/statistics');
  });

  test('a rail with no items is omitted, an unavailable AI rail is kept', () {
    final r = composeHomeRails(view(loadHome('ai-unavailable')));
    final fy = r.firstWhere((x) => x.id == 'picked');
    expect(fy.unavailable, isTrue);
    expect(fy.items, isNotEmpty);
    final np = composeHomeRails(view(loadHome('new-profile')));
    expect(ids(np), isNot(contains('continue')));
    expect(ids(np), contains('popular'));
    expect(np.firstWhere((x) => x.id == 'picked').items, isEmpty);
  });

  test('hidden continue rows drop out and an empty rail is omitted', () {
    final f = loadHome('ready');
    final rows = f.section(HomeSectionType.continueReading)!.items.whereType<HomeContinueItem>().toList();
    final hidden = [for (final c in rows) hiddenOf(c.row)];
    expect(ids(composeHomeRails(view(f), hidden: hidden)), isNot(contains('continue')));
    expect(composeHomeRails(view(f), hidden: [hidden.first]).first.items.length, rows.length - 1);
  });

  test('circle: letters first, de-duplicated by series', () {
    final r = composeHomeRails(view(loadHome('circle')));
    final c = r.firstWhere((x) => x.id == 'circle');
    expect(c.items.first, isA<HomeCircleCard>());
    expect((c.items.first as HomeCircleCard).letter, isNotNull);
    final keys = [for (final i in c.items) (i as HomeCircleCard).key];
    expect(keys.toSet().length, keys.length);
    expect(c.seeAll, '/circle?tab=letters');
  });

  test('almost there captions come from chaptersLeft', () {
    final r = composeHomeRails(view(loadHome('ready')));
    final a = r.firstWhere((x) => x.id == 'almost-there');
    for (final p in a.items.cast<HomePoster>()) {
      expect(p.caption, matches(RegExp(r'^\d+ chapters? left$')));
    }
  });

  test('offline keeps only Ready offline and Continue reading', () {
    final last = loadHome('ready');
    final ed = decodeLastFeed(encodeLastFeed(last, sourceMature: (_) => false, savedAt: DateTime(2026, 9, 30)))!;
    final r = composeHomeRails(view(ed, offline: true));
    expect(ids(r).every((i) => i == 'continue' || i == 'ready-offline'), isTrue);
  });

  test('the re-rank moves an AI rail up one place and never above Continue', () {
    final f = loadHome('ready');
    final base = composeHomeRails(view(f));
    final ai = base.where((r) => r.ai && r.items.isNotEmpty && _genre(r) != null).toList();
    expect(ai, isNotEmpty);
    final g = _genre(ai.last)!;
    final moved = composeHomeRails(view(f), noted: [g]);
    expect(moved.first.id, 'continue');
    expect(ids(moved).indexOf(ai.last.id), lessThanOrEqualTo(ids(base).indexOf(ai.last.id)));
    expect(ids(moved).toSet(), ids(base).toSet());
  });
}

String? _genre(HomeRailSpec r) {
  for (final i in r.items) {
    if (i is HomePickItem && i.world != null && i.world!.genres.isNotEmpty) return i.world!.genres.first;
  }
  return null;
}
