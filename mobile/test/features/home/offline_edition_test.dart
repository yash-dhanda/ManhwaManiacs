// ignore_for_file: require_trailing_commas, avoid_redundant_argument_values, library_private_types_in_public_api, directives_ordering
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/models/downloaded_series_group.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/home/utils/offline_edition.dart';

import 'home_fixtures.dart';

final now = DateTime(2026, 9, 30, 21);

SavedChapter chapter(String series, String key, {bool? mature, DownloadChapterState state = DownloadChapterState.complete}) => SavedChapter(
      rowId: 1,
      scopeId: 'u1p1',
      sourceId: 'shelf',
      seriesKey: series,
      chapterKey: key,
      chapterNumber: 5,
      title: null,
      seriesTitle: 'Title $series',
      pageCount: 10,
      bytes: 100,
      state: state,
      pinned: false,
      readAt: null,
      createdAt: DateTime(2026, 9, 1),
      retryCount: 0,
      error: null,
      mature: mature,
    );

DownloadedSeriesGroup group(String series, String key, {bool? mature}) =>
    DownloadedSeriesGroup(sourceId: 'shelf', seriesKey: series, seriesTitle: 'Title $series', chapters: [chapter(series, key, mature: mature)]);

HomeFeed lastFeed() {
  final full = loadHome('ready');
  final encoded = encodeLastFeed(full, sourceMature: (id) => false, savedAt: now);
  return decodeLastFeed(encoded)!;
}

void main() {
  test('the stored feed keeps continue rows and stamps mature with the server rule order', () {
    final feed = loadHome('ready');
    final back = decodeLastFeed(encodeLastFeed(feed, sourceMature: (id) => id == 'shelf', savedAt: now))!;
    final rows = back.section(HomeSectionType.continueReading)!.items.cast<HomeContinueItem>();
    expect(rows, hasLength(5));
    // The feed carries a resolved 'safe' rating for these series, and that outranks the source flag.
    expect(rows.any((r) => r.mature), isFalse);
    // Continue rows with no rating anywhere in the feed follow the source's own flag.
    final bare = HomeFeed(headline: '', deck: '', sections: [feed.section(HomeSectionType.continueReading)!]);
    final flagged = decodeLastFeed(encodeLastFeed(bare, sourceMature: (id) => id == 'shelf', savedAt: now))!;
    expect(flagged.section(HomeSectionType.continueReading)!.items.cast<HomeContinueItem>().every((r) => r.mature), isTrue);
    expect(decodeLastFeed('not json'), isNull);
    expect(decodeLastFeed(null), isNull);
  });

  test('offline edition: headline, saved series and saved continue rows', () {
    final last = lastFeed();
    final f = composeOfflineEdition(
      lastFeed: last,
      saved: [group('the-lantern-courier', 'c142'), group('other', 'c1')],
      matureEnabled: false,
      now: now,
    );
    expect(f.headline, 'Offline edition.');
    expect(f.deck, "Only what's saved on this device is here.");
    expect(f.section(HomeSectionType.saved)!.items, hasLength(2));
    final cont = f.section(HomeSectionType.continueReading)!;
    expect(cont.title, 'Continue (saved chapters)');
    expect(cont.items.cast<HomeContinueItem>().single.row.seriesKey, 'the-lantern-courier');
    expect(f.cover!.seriesKey, 'the-lantern-courier');
    expect(f.sections.map((s) => s.type), [HomeSectionType.saved, HomeSectionType.continueReading]);
  });

  test('a closed gate hides a saved mature series and its continue row without a trace', () {
    final mature = decodeLastFeed(encodeLastFeed(loadHome('ready'), sourceMature: (id) => true, savedAt: now))!;
    final saved = [group('the-lantern-courier', 'c142', mature: true), group('other', 'c1', mature: false)];
    final closed = composeOfflineEdition(lastFeed: mature, saved: saved, matureEnabled: false, now: now);
    expect(closed.section(HomeSectionType.continueReading), isNull);
    final titles = closed.section(HomeSectionType.saved)!.items.cast<HomeSavedItem>().map((i) => i.seriesKey);
    expect(titles, ['other']);
    expect(closed.cover!.seriesKey, 'other');
    final open = composeOfflineEdition(lastFeed: mature, saved: saved, matureEnabled: true, now: now);
    expect(open.section(HomeSectionType.saved)!.items, hasLength(2));
    expect(open.section(HomeSectionType.continueReading), isNotNull);
  });

  test('no saved chapters and no last feed: only the headline block', () {
    final f = composeOfflineEdition(saved: const [], matureEnabled: true, now: now);
    expect(f.cover, isNull);
    expect(f.sections, isEmpty);
    final downloading = composeOfflineEdition(
      saved: [DownloadedSeriesGroup(sourceId: 's', seriesKey: 'k', seriesTitle: 't', chapters: [chapter('k', 'c1', state: DownloadChapterState.queued)])],
      matureEnabled: true,
      now: now,
    );
    expect(downloading.sections, isEmpty, reason: 'a queued chapter is not readable offline');
  });
}
