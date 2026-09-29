// ignore_for_file: require_trailing_commas, avoid_redundant_argument_values, library_private_types_in_public_api, directives_ordering
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/home/utils/local_feed.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';

import 'home_fixtures.dart';

final now = DateTime(2026, 9, 30, 21);
DateTime ago(int days) => now.subtract(Duration(days: days));

WorldItem world(String title, {bool available = true}) => WorldItem(
      title: title,
      anilistId: title.length,
      available: available ? [WorldAvailability(sourceId: 'shelf', sourceName: 'Shelf', seriesKey: title.toLowerCase())] : const [],
    );

void main() {
  test('case 1: a series in progress with new chapters is the cover, with chapter and title', () {
    final f = composeLocalFeed(
      LocalFeedInputs(
        continueRows: [contRow('a', at: ago(1), page: 40), contRow('b', at: ago(2))],
        followed: [followedRow('a', id: 1, position: 5, newCount: 3), followedRow('b', id: 2)],
      ),
      now,
    );
    expect(f.cover!.seriesKey, 'a');
    expect(f.cover!.reason, HomeCoverReason.newChapters);
    expect(f.cover!.chapterKey, 'c6'); // finished chapter 5: the next one opens
    expect(f.headline, 'Tonight: chapter 6 of Title a.');
    expect(f.ai.available, isFalse);
    expect(f.ai.reason, 'not_configured');
  });

  test('case 2: an unfinished chapter read within 21 days', () {
    final f = composeLocalFeed(
      LocalFeedInputs(continueRows: [contRow('b', at: ago(2), page: 28)], followed: [followedRow('b')]),
      now,
    );
    expect(f.cover!.reason, HomeCoverReason.inProgress);
    expect(f.headline, 'Tonight: finish chapter 5. Twelve pages left.');
    expect(f.cover!.progress, closeTo(0.7, 1e-9));
  });

  test('case 3 needs a recap; without one, older rows never become the cover', () {
    final rows = [contRow('c', at: ago(23))];
    var f = composeLocalFeed(LocalFeedInputs(continueRows: rows, followed: [followedRow('c')]), now);
    expect(f.cover?.reason, isNot(HomeCoverReason.paused));
    f = composeLocalFeed(
      LocalFeedInputs(
        continueRows: rows,
        followed: [followedRow('c')],
        recaps: {'shelf|c': const RecapAvailability(available: true)},
      ),
      now,
    );
    expect(f.cover!.reason, HomeCoverReason.paused);
    expect(f.deck, 'You paused 23 days ago at chapter 5. Previously on is ready.');
  });

  test('4b: follows and nothing read; and nothing at all is case 5', () {
    var f = composeLocalFeed(
      LocalFeedInputs(continueRows: const [], followed: [followedRow('z', started: false, sortOrder: 2), followedRow('y', id: 2, started: false, sortOrder: 0)]),
      now,
    );
    expect(f.cover!.reason, HomeCoverReason.firstPick);
    expect(f.cover!.seriesKey, 'y');
    expect(f.headline, 'Tonight: start Title y.');
    f = composeLocalFeed(const LocalFeedInputs(continueRows: [], followed: []), now);
    expect(f.cover, isNull);
    expect(f.headline, 'Your first issue starts here.');
  });

  test('also: newChapters, because, almostThere; never the cover series, never a repeat', () {
    final inputs = LocalFeedInputs(
      continueRows: [contRow('a', at: ago(1), page: 40)],
      followed: [
        followedRow('a', position: 5, newCount: 3),
        followedRow('b', id: 2, position: 5, newCount: 2),
        followedRow('c', id: 3, position: 19, total: 20, newCount: 1),
      ],
      world: WorldRecommendations(forYou: [world('W')]),
    );
    final f = composeLocalFeed(inputs, now);
    expect(f.cover!.seriesKey, 'a');
    expect(f.also.map((a) => a.kind), [HomeAlsoKind.newChapters, HomeAlsoKind.because, HomeAlsoKind.almostThere]);
    expect(f.also.map((a) => a.seriesKey), ['b', 'w', 'c']);
    expect(f.also.any((a) => a.seriesKey == 'a'), isFalse);
    expect(f.also.first.headline, 'Title b: 2 new chapters.');
    expect(f.also.last.headline, 'One chapter left in Title c.');
  });

  test('also with two, one and zero candidates', () {
    LocalFeedInputs base({bool world = false, bool second = false}) => LocalFeedInputs(
          continueRows: [contRow('a', at: ago(1), page: 40)],
          followed: [
            followedRow('a', position: 5, newCount: 3),
            if (second) followedRow('b', id: 2, newCount: 2),
          ],
          world: world ? WorldRecommendations(forYou: [globalWorld('W')]) : null,
        );
    expect(composeLocalFeed(base(world: true, second: true), now).also, hasLength(2));
    expect(composeLocalFeed(base(second: true), now).also, isEmpty, reason: 'one candidate is not a row');
    expect(composeLocalFeed(base(), now).also, isEmpty);
  });

  test('sections: continue, new this week, almost there, where were we, shelf, numbers', () {
    final f = composeLocalFeed(
      LocalFeedInputs(
        continueRows: [contRow('a', at: ago(1), page: 30), contRow('old', at: ago(40), page: 3)],
        recentlyUpdated: [followedRow('a', updatedAt: ago(2)), followedRow('stale', id: 9, updatedAt: ago(30))],
        followed: [followedRow('a', position: 19, total: 20, newCount: 1), followedRow('old', id: 2, favourite: true), followedRow('p', id: 3, status: 'plan_to_read')],
      ),
      now,
    );
    final c = f.section(HomeSectionType.continueReading)!.items.cast<HomeContinueItem>();
    expect(c.map((i) => i.row.seriesKey), ['a', 'old']);
    expect(c.first.nudge, ContinueNudge.newChapters);
    expect(f.section(HomeSectionType.newThisWeek)!.items, hasLength(1));
    expect(f.section(HomeSectionType.almostThere)!.items.cast<HomeSeriesItem>().single.chaptersLeft, 1);
    expect(f.section(HomeSectionType.whereWereWe)!.items.cast<HomeSeriesItem>().single.series.seriesKey, 'old');
    final shelf = f.section(HomeSectionType.picked)!;
    expect(shelf.title, 'From your shelf');
    expect(shelf.state, HomeSectionState.unavailable);
    expect(shelf.items, hasLength(2));
    expect(f.section(HomeSectionType.because), isNull);
    expect(f.section(HomeSectionType.numbers)!.state, HomeSectionState.unavailable, reason: 'statistics failed');
  });
}

WorldItem globalWorld(String t) => world(t);
