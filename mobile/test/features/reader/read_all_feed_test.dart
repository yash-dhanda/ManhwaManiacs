import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/network/bulk_limiter.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/models/reader_page.dart';
import 'package:manhwamaniacs/features/reader/utils/read_all_feed.dart';

ReaderChapter ch(String id, {int pages = 3}) => ReaderChapter(
      id: id,
      seriesId: 's',
      title: 'Chapter $id',
      pageCount: pages,
      pages: [for (var n = 1; n <= pages; n++) ReaderPage(id: '$id-$n', number: n, imageUrl: 'http://x/$id/$n')],
    );

void main() {
  final keys = [for (var i = 1; i <= 50; i++) 'c$i'];

  ReadAllFeedController make({
    required ReadAllWindowLoader loadWindow,
    String start = 'c1',
    BulkLimiter? limiter,
    int max = 60,
    void Function(Duration)? onLimited,
  }) =>
      ReadAllFeedController(
        anchor: ch(start),
        keys: keys,
        loadChapter: (k) async => ch(k),
        loadWindow: loadWindow,
        limiter: limiter ?? BulkLimiter(),
        seriesKey: 's',
        maxChapters: max,
        onRateLimited: onLimited,
      );

  test('the first chapter is on screen before any batch returns', () async {
    final gate = Completer<ReadAllWindowResult>();
    final c = make(loadWindow: (_) => gate.future);
    expect(c.feed.chapters.map((e) => e.id), ['c1']);
    final f = c.extendForward();
    await Future<void>.delayed(Duration.zero);
    expect(c.isExtending, isTrue);
    expect(c.feed.chapters.length, 1);
    gate.complete(ReadAllWindowResult(chapters: {for (final k in keys.sublist(1, 21)) k: ch(k)}));
    await f;
    expect(c.feed.chapters.length, 21);
    expect(c.stateFor('c1').total, 50);
    expect(c.stateFor('c2').index, 2);
    expect(c.stateFor('c1').boundaries, [3, 6, 9, 12, 15, 18, 21, 24, 27, 30, 33, 36, 39, 42, 45, 48, 51, 54, 57, 60]);
  });

  test('a window is at most 20 keys, in series order', () async {
    final asked = <List<String>>[];
    final c = make(loadWindow: (ks) async {
      asked.add(ks);
      return ReadAllWindowResult(chapters: {for (final k in ks) k: ch(k)});
    },);
    await c.extendForward();
    await c.extendForward();
    await c.extendForward();
    expect(asked.map((a) => a.length), [20, 20, 9]);
    expect(asked.first.first, 'c2');
    expect(asked[1].first, 'c22');
    expect(c.nextBeyondFeed, isNull);
    await c.extendForward();
    expect(asked, hasLength(3), reason: 'nothing left to ask for');
  });

  test('a failed item is a placeholder inside the feed; retry swaps the chapter in', () async {
    var round = 0;
    final c = make(loadWindow: (ks) async {
      round++;
      if (round == 1) return ReadAllWindowResult(chapters: {for (final k in ks) if (k != 'c3') k: ch(k)}, failed: {'c3'});
      return ReadAllWindowResult(chapters: {for (final k in ks) k: ch(k, pages: 5)});
    },);
    await c.extendForward();
    final chapters = c.feed.chapters;
    expect(chapters.length, 21, reason: 'reading continues past it');
    final failed = chapters.firstWhere((e) => e.id == 'c3');
    expect(isFailedChapter(failed), isTrue);
    expect(c.failedKeys, {'c3'});
    await c.retry('c3');
    expect(isFailedChapter(c.feed.chapters.firstWhere((e) => e.id == 'c3')), isFalse);
    expect(c.feed.chapters.firstWhere((e) => e.id == 'c3').pages.length, 5);
    expect(c.failedKeys, isEmpty);
  });

  test('the bulk limiter never starts a seventh batch inside 60 s', () async {
    var t = DateTime(2026);
    final wakes = <void Function()>[];
    final limiter = BulkLimiter(now: () => t, createTimer: (d, f) {
      wakes.add(f);
      return Timer(const Duration(days: 1), () {});
    },);
    var calls = 0;
    // A tiny window so seven extensions fit in 50 keys.
    final c = ReadAllFeedController(
      anchor: ch('c1'),
      keys: keys,
      loadChapter: (k) async => ch(k),
      loadWindow: (ks) async {
        calls++;
        return ReadAllWindowResult(chapters: {for (final k in ks) k: ch(k)});
      },
      limiter: limiter,
      seriesKey: 's',
      window: 5,
    );
    for (var i = 0; i < 6; i++) {
      await c.extendForward();
    }
    expect(calls, 6);
    final seventh = c.extendForward();
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(calls, 6, reason: 'the seventh waits for the window');
    t = t.add(const Duration(seconds: 59));
    for (final w in List.of(wakes)) {
      w();
    }
    await Future<void>.delayed(Duration.zero);
    expect(calls, 6, reason: 'still inside 60 s of the first start');
    t = t.add(const Duration(seconds: 1));
    for (final w in List.of(wakes)) {
      w();
    }
    await seventh;
    expect(calls, 7);
  });

  test('a 429 pauses the limiter, reports the wait and leaves the feed where it was', () async {
    Duration? told;
    final limiter = BulkLimiter();
    final c = make(
      limiter: limiter,
      onLimited: (d) => told = d,
      loadWindow: (ks) async => const ReadAllWindowResult(rateLimited: Duration(seconds: 12)),
    );
    await c.extendForward();
    expect(told, const Duration(seconds: 12));
    expect(limiter.pausedUntil, isNotNull);
    expect(c.feed.chapters.length, 1);
    expect(c.nextBeyondFeed, 'c2', reason: 'not consumed: the next call asks again');
  });

  test('starting mid-series extends both ways; the far end is released past the cap', () async {
    final c = make(
      start: 'c25',
      max: 30,
      loadWindow: (ks) async => ReadAllWindowResult(chapters: {for (final k in ks) k: ch(k)}),
    );
    await c.extendForward();
    expect(c.feed.chapters.first.id, 'c25');
    expect(c.feed.chapters.last.id, 'c45');
    await c.extendBackward();
    expect(c.feed.chapters.first.id, 'c5');
    expect(c.feed.chapters.length, 30, reason: 'trimmed to the cap from the far end');
    expect(c.feed.chapters.last.id, 'c34');
    expect(c.previousBeforeFeed, 'c4');
  });

  test('offline: saved chapters in order, the first unsaved one ends the feed', () async {
    final c = make(loadWindow: (ks) async => ReadAllWindowResult(chapters: {'c2': ch('c2'), 'c3': ch('c3'), 'c5': ch('c5')}, offline: true));
    await c.extendForward();
    expect(c.feed.chapters.map((e) => e.id), ['c1', 'c2', 'c3']);
    expect(c.nextBeyondFeed, isNull, reason: 'no next chapter: the offline end band shows');
    expect(c.failedKeys, isEmpty, reason: 'nothing is marked failed offline');
  });
}
