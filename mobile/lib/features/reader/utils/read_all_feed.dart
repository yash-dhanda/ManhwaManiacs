import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:manhwamaniacs/core/network/bulk_limiter.dart';
import 'package:manhwamaniacs/features/reader/engine/read_all_window.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/models/reader_feed.dart';
import 'package:manhwamaniacs/features/reader/models/reader_page.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_feed_controller.dart';

/// What one batch of chapter manifests answered (`POST /reader/chapters/manifest`, or a saved
/// chapter read from disk): the chapters that came, the keys that did not, and a 429's wait.
class ReadAllWindowResult {
  const ReadAllWindowResult({this.chapters = const {}, this.failed = const {}, this.rateLimited, this.offline = false});

  final Map<String, ReaderChapter> chapters;
  final Set<String> failed;

  /// The `Retry-After` of a 429 on the batch call: nothing in it was answered.
  final Duration? rateLimited;

  /// The device could not reach the server: only saved chapters came, and the first unsaved one
  /// ends the feed (`Next chapter isn't saved on this device`) instead of failing.
  final bool offline;
}

typedef ReadAllWindowLoader = Future<ReadAllWindowResult> Function(List<String> keys);

/// The prefix of a failed chapter's placeholder page id.
const String kFailedPagePrefix = 'failed:';

/// A chapter that did not load, standing in its place in the feed: one short page the skin covers
/// with the `CORRECTION` notice. The picture never loads (a missing file), so no request is made.
ReaderChapter failedChapterPlaceholder(String key, {required String seriesKey, String? sourceId, String? title}) => ReaderChapter(
      id: key,
      seriesId: seriesKey,
      sourceId: sourceId,
      title: title ?? 'Chapter',
      pageCount: 1,
      pages: [
        ReaderPage(id: '$kFailedPagePrefix$key', number: 1, imageUrl: '', width: 390, height: 260, localFile: File('/nonexistent/$kFailedPagePrefix$key')),
      ],
    );

/// Whether [chapter] is a failed chapter's placeholder.
bool isFailedChapter(ReaderChapter chapter) => chapter.pages.length == 1 && chapter.pages.first.id.startsWith(kFailedPagePrefix);

/// The read-all feed (cinematic 8.14.4-8.14.6, mobile/13 A6): the first chapter is on screen at
/// once from its own manifest, and windows of up to [window] chapter keys in series order fill in
/// behind it, each window one batch call through the [limiter] (6 starts per 60 s; a 429 pauses
/// it for its `Retry-After`). An item that failed becomes a retryable placeholder inside the feed,
/// never a failed feed. Past [maxChapters] loaded chapters the far end is released.
class ReadAllFeedController extends ReaderFeedController {
  ReadAllFeedController({
    required ReaderChapter anchor,
    required List<String> keys,
    required super.loadChapter,
    required this.loadWindow,
    required this.limiter,
    required this.seriesKey,
    this.sourceId,
    this.window = kReadAllWindow,
    super.maxChapters = 60,
    this.onRateLimited,
    String? Function(String key)? titleOf,
  })  : _keys = keys,
        _titleOf = titleOf,
        super(anchor: anchor, order: keys) {
    _lo = _hi = keys.indexOf(anchor.id);
    if (_lo < 0) _lo = _hi = 0;
    _slots[anchor.id] = anchor;
  }

  final ReadAllWindowLoader loadWindow;
  final BulkLimiter limiter;
  final String seriesKey;
  final String? sourceId;
  final int window;

  final void Function(Duration wait)? onRateLimited;
  final String? Function(String key)? _titleOf;
  final List<String> _keys;

  /// The loaded chapters (or failed placeholders) by key; `_lo`..`_hi` is the contiguous run of
  /// series indexes they cover.
  final Map<String, ReaderChapter> _slots = {};
  int _lo = 0, _hi = 0;
  bool _busyForward = false, _busyBackward = false, _gone = false, _offlineStop = false;
  ReaderFeed? _composed;

  /// Keys of chapters that failed and can be retried.
  final Set<String> failedKeys = {};

  /// The series index of the first chapter of the feed and the count of chapters in the series.
  int get firstIndex => _lo;
  int get total => _keys.length;

  @override
  ReaderFeed get feed => _composed ??= _compose();

  ReaderFeed _compose() => ReaderFeed.of([
        for (var i = _lo; i <= _hi; i++)
          if (_slots[_keys[i]] != null) _slots[_keys[i]]!,
      ]);

  @override
  bool get isExtending => _busyForward || _busyBackward;

  @override
  String? get nextBeyondFeed => !_offlineStop && _hi + 1 < _keys.length ? _keys[_hi + 1] : null;

  @override
  String? get previousBeforeFeed => _lo > 0 ? _keys[_lo - 1] : null;

  @override
  void setOrder(List<String> order) {}

  @override
  void noteNeighbours(String chapterId, {String? prev, String? next}) {}

  @override
  void replaceChapter(ReaderChapter chapter) {
    if (!_slots.containsKey(chapter.id) || _slots[chapter.id] == chapter) return;
    _slots[chapter.id] = chapter;
    _composed = null;
  }

  @override
  void dispose() {
    _gone = true;
    super.dispose();
  }

  ReaderChapter _placeholder(String key) =>
      failedChapterPlaceholder(key, seriesKey: seriesKey, sourceId: sourceId, title: _titleOf?.call(key));

  @override
  Future<void> extendForward() => _extendWindow(forward: true);

  @override
  Future<void> extendBackward() => _extendWindow(forward: false);

  Future<void> _extendWindow({required bool forward}) async {
    if (_gone) return;
    if (forward ? _busyForward : _busyBackward) return;
    final List<String> keys;
    if (forward) {
      final from = _hi + 1;
      keys = from >= _keys.length ? const [] : _keys.sublist(from, (from + window).clamp(0, _keys.length));
    } else {
      final to = _lo;
      keys = to <= 0 ? const [] : _keys.sublist((to - window).clamp(0, to), to);
    }
    if (keys.isEmpty) return;
    if (forward) {
      _busyForward = true;
    } else {
      _busyBackward = true;
    }
    try {
      await limiter.acquire();
      if (_gone) return;
      final result = await loadWindow(keys);
      if (_gone) return;
      final wait = result.rateLimited;
      if (wait != null) {
        limiter.pause(wait);
        onRateLimited?.call(wait);
        return;
      }
      var took = keys.length;
      if (result.offline) {
        // Saved chapters in order; the first one missing ends the feed, offline.
        took = keys.takeWhile((k) => result.chapters[k]?.pages.isNotEmpty ?? false).length;
        if (took < keys.length && forward) _offlineStop = true;
      }
      for (final k in keys.take(took)) {
        final c = result.chapters[k];
        if (c != null && c.pages.isNotEmpty) {
          _slots[k] = c;
          failedKeys.remove(k);
        } else {
          _slots[k] = _placeholder(k);
          failedKeys.add(k);
        }
      }
      if (forward) {
        _hi += took;
      } else {
        _lo -= took;
      }
      _trim(forward: forward);
      _composed = null;
      notifyListeners();
    } finally {
      if (forward) {
        _busyForward = false;
      } else {
        _busyBackward = false;
      }
    }
  }

  /// Releases the far end past [maxChapters]: the reader is at the end just extended, so the
  /// other end is far behind.
  void _trim({required bool forward}) {
    final excess = (_hi - _lo + 1) - maxChapters;
    if (excess <= 0) return;
    for (var i = 0; i < excess; i++) {
      if (forward) {
        _slots.remove(_keys[_lo]);
        failedKeys.remove(_keys[_lo]);
        _lo++;
      } else {
        _slots.remove(_keys[_hi]);
        failedKeys.remove(_keys[_hi]);
        _hi--;
      }
    }
  }

  /// `Try again` on a failed chapter: asks for it alone (through the same limiter) and, on
  /// success, swaps it in place of its placeholder.
  Future<void> retry(String key) async {
    if (_gone || !failedKeys.contains(key)) return;
    await limiter.acquire();
    if (_gone) return;
    final result = await loadWindow([key]);
    if (_gone) return;
    final wait = result.rateLimited;
    if (wait != null) {
      limiter.pause(wait);
      onRateLimited?.call(wait);
      return;
    }
    final c = result.chapters[key];
    if (c == null || c.pages.isEmpty) return;
    _slots[key] = c;
    failedKeys.remove(key);
    _composed = null;
    notifyListeners();
  }

  /// The published `readAll` state for the chapter [chapterId] (1-based position in the series).
  ReadAllState stateFor(String chapterId) {
    final at = _keys.indexOf(chapterId);
    final starts = chapterStarts([for (final c in feed.chapters) c.pages.length]);
    return ReadAllState(index: at < 0 ? 1 : at + 1, total: _keys.length, boundaries: starts.skip(1).toList());
  }

  @visibleForTesting
  int get loadedCount => _slots.length;
}
