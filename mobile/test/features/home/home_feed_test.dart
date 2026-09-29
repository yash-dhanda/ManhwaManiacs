// ignore_for_file: require_trailing_commas, avoid_redundant_argument_values, library_private_types_in_public_api, directives_ordering
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';

import 'home_fixtures.dart';

void main() {
  test('ready.json parses into typed sections in the server order', () {
    final f = loadHome('ready');
    expect(f.issueNo, 184);
    expect(f.headline, 'Tonight: chapter 143 of The Lantern Courier.');
    expect(f.streak.currentDays, 12);
    expect(f.streak.lastActiveDate, DateTime(2026, 9, 29));
    expect(f.streak.milestonesSeen, [7]);
    expect(f.cover!.title, 'The Lantern Courier');
    expect(f.cover!.recap!.available, isTrue);
    expect(f.cover!.ambient, isNotNull);
    expect(f.also.map((a) => a.kind), [HomeAlsoKind.newChapters, HomeAlsoKind.because, HomeAlsoKind.almostThere]);
    expect(f.sections.map((s) => s.type), [
      HomeSectionType.continueReading,
      HomeSectionType.newThisWeek,
      HomeSectionType.almostThere,
      HomeSectionType.whereWereWe,
      HomeSectionType.picked,
      HomeSectionType.because,
      HomeSectionType.sources,
      HomeSectionType.genres,
      HomeSectionType.numbers,
    ]);
    final cont = f.section(HomeSectionType.continueReading)!.items.cast<HomeContinueItem>();
    expect(cont.first.nudge, ContinueNudge.newChapters);
    expect(cont.first.newCount, 2);
    expect(cont[3].nudge, ContinueNudge.paused);
    expect(cont.first.row.ambient, isNotNull);
    final almost = f.section(HomeSectionType.almostThere)!.items.cast<HomeSeriesItem>();
    expect(almost.first.chaptersLeft, 2);
    final picked = f.section(HomeSectionType.picked)!.items.cast<HomePickItem>();
    expect(picked.first.world!.title, 'Harbor of Small Lights');
    expect(picked.last.source, isNotNull);
    expect(f.section(HomeSectionType.because)!.seed!.title, 'Sword of the Ninth Spring');
    expect(f.section(HomeSectionType.sources)!.items.cast<HomeSourceItem>().first.latestCovers, hasLength(3));
    expect(f.section(HomeSectionType.genres)!.items.cast<HomeGenreItem>().first.genre, 'Fantasy');
    final n = f.section(HomeSectionType.numbers)!.items.single as HomeNumbersItem;
    expect((n.chaptersWeek, n.secondsWeek, n.streak.currentDays), (18, 12000, 12));
    expect(f.ai.available, isTrue);
  });

  test('every fixture parses', () {
    for (final n in ['ready', 'novel', 'new-profile', 'onboarded', 'caught-up', 'at-risk', 'ai-unavailable', 'stale']) {
      expect(loadHome(n).headline, isNotEmpty, reason: n);
    }
    expect(loadHome('novel').cover!.isNovel, isTrue);
    expect(loadHome('ai-unavailable').section(HomeSectionType.picked)!.fallback, 'shelf');
    expect(loadHome('stale').section(HomeSectionType.newThisWeek)!.state, HomeSectionState.stale);
  });

  test('an unknown section type, unknown fields and a missing ai block are ignored', () {
    final f = HomeFeed.fromJson({
      'headline': 'Tonight: x.',
      'deck': 'd',
      'surprise': 1,
      'sections': [
        {'type': 'from_the_future', 'items': <Object>[]},
        {'type': 'genres', 'items': [{'genre': 'Fantasy', 'weight': 1}, {'nope': 1}], 'state': 'ready'},
        'junk',
      ],
    });
    expect(f.sections.single.type, HomeSectionType.genres);
    expect(f.sections.single.items, hasLength(1));
    expect(f.ai.available, isFalse);
    expect(f.ai.reason, 'not_configured');
    expect(f.cover, isNull);
    expect(f.streak.currentDays, 0);
  });
}
