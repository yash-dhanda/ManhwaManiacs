import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart' show Size, WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/logging/app_logger.dart' show appLogger;
import 'package:manhwamaniacs/features/downloads/providers/bookmark_outbox_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/providers/progress_outbox_provider.dart';
import 'package:manhwamaniacs/features/downloads/store/downloads_store.dart';
import 'package:manhwamaniacs/features/novels/engine/novel_paginator.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';
import 'package:manhwamaniacs/features/novels/models/novel_chapter.dart';
import 'package:manhwamaniacs/features/novels/models/novel_typography.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_cast_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_chapter_provider.dart';
import 'package:manhwamaniacs/features/novels/utils/novel_progress.dart';
import 'package:manhwamaniacs/features/novels/utils/novel_snippet.dart';
import 'package:manhwamaniacs/features/novels/utils/speaker_slots.dart';
import 'package:manhwamaniacs/features/reader/models/bookmark.dart';
import 'package:manhwamaniacs/features/reader/models/reading_progress.dart';
import 'package:manhwamaniacs/features/reader/utils/reading_clock.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

/// How often a scroll is turned into a progress position (the manga reader's 500 ms).
const int kNovelProgressSaveMs = 500;

/// The pause at the end of a chapter before the next one opens (the manga reader's 900 ms).
const int kNovelAutoNextMs = 900;

/// Frames a deferred restore may home in for before it settles wherever it has got to.
const int kNovelMaxRestoreFrames = 30;

/// Over-scroll at the bottom that opens the next chapter (cinematic 8.15.2).
const double kNovelOverscrollNextPx = 140;

/// Which chapter the reader shows and how it should behave. Equality is by value so the family
/// key is stable across rebuilds.
class NovelReaderArgs {
  const NovelReaderArgs({
    required this.sourceId,
    required this.seriesKey,
    required this.chapterKey,
    this.readingLineFraction = 0.25,
    this.initialBucket = 1,
    this.initialParagraph,
    this.initialFraction,
    this.attribution = false,
  });

  final String sourceId, seriesKey, chapterKey;

  /// Where the reading line sits, as a fraction of the viewport height from the top: the legacy
  /// screen passes 0.25, the Cinematic skin 0.38.
  final double readingLineFraction;
  final int initialBucket;

  /// A bookmark's exact paragraph (1-based) and how far into it (0-1); wins over [initialBucket].
  final int? initialParagraph;
  final double? initialFraction;

  /// Whether to load `GET /novels/attribution` (speaker tints). The legacy screen has none.
  final bool attribution;

  NovelChapterKey get key => (sourceId: sourceId, seriesKey: seriesKey, chapterKey: chapterKey);

  @override
  bool operator ==(Object other) =>
      other is NovelReaderArgs &&
      other.sourceId == sourceId &&
      other.seriesKey == seriesKey &&
      other.chapterKey == chapterKey &&
      other.readingLineFraction == readingLineFraction &&
      other.initialBucket == initialBucket &&
      other.initialParagraph == initialParagraph &&
      other.initialFraction == initialFraction &&
      other.attribution == attribution;

  @override
  int get hashCode => Object.hash(sourceId, seriesKey, chapterKey, readingLineFraction, initialBucket, initialParagraph, initialFraction, attribution);
}

/// The state of the chapter after this one.
enum NovelNextState { none, loading, ready, failed }

/// The reader is behind another device: the chapter and bucket the server holds.
class NovelFurtherAhead {
  const NovelFurtherAhead({required this.chapterKey, required this.chapterNumber, required this.bucket});
  final String chapterKey;
  final double? chapterNumber;
  final int bucket;

  @override
  bool operator ==(Object other) => other is NovelFurtherAhead && other.chapterKey == chapterKey && other.bucket == bucket;

  @override
  int get hashCode => Object.hash(chapterKey, bucket);
}

/// What a bookmark press came to.
enum NovelBookmarkResult { saved, failed, nothing }

class NovelReaderState {
  const NovelReaderState({
    required this.chapterValue,
    this.attribution = NovelAttribution.none,
    this.speakerRuns = const {},
    this.readingBucket = 1,
    this.prevKey,
    this.nextKey,
    this.nextState = NovelNextState.none,
    this.furtherElsewhere,
    this.saved = false,
    this.stale = false,
    this.pageIndex = 0,
    this.pageCount = 0,
    this.revision = 0,
  });

  final AsyncValue<NovelChapter> chapterValue;
  final NovelAttribution attribution;

  /// Tints by paragraph; empty when the chapter is unattributed or its fingerprint does not match.
  final Map<int, List<SpeakerRun>> speakerRuns;

  /// The 1-based paragraph bucket under the reading line.
  final int readingBucket;
  final String? prevKey, nextKey;
  final NovelNextState nextState;
  final NovelFurtherAhead? furtherElsewhere;

  /// A bookmark was just saved at the current spot.
  final bool saved;

  /// The bookmark this chapter opened on named a paragraph that no longer exists.
  final bool stale;

  /// Paged layout: the page shown and how many pages the chapter has.
  final int pageIndex, pageCount;

  /// Bumps every time a different chapter is swapped in (seamless next), so a view can re-key.
  final int revision;

  NovelChapter? get chapter => chapterValue.valueOrNull;
  List<String> get paragraphs => chapter?.paragraphs ?? const [];

  /// Percent of the book the reading bucket stands at (chapter number of the last chapter is
  /// unknown to the reader; the chapter percent is exposed instead).
  int get chapterPercent {
    final c = chapter;
    return c == null ? 0 : _chapterPercent(readingBucket, c.buckets);
  }

  bool get cacheStale => chapter?.cacheStale ?? false;
  bool get attributed => speakerRuns.isNotEmpty;

  NovelReaderState copyWith({
    AsyncValue<NovelChapter>? chapterValue,
    NovelAttribution? attribution,
    Map<int, List<SpeakerRun>>? speakerRuns,
    int? readingBucket,
    Object? prevKey = _keep,
    Object? nextKey = _keep,
    NovelNextState? nextState,
    Object? furtherElsewhere = _keep,
    bool? saved,
    bool? stale,
    int? pageIndex,
    int? pageCount,
    int? revision,
  }) =>
      NovelReaderState(
        chapterValue: chapterValue ?? this.chapterValue,
        attribution: attribution ?? this.attribution,
        speakerRuns: speakerRuns ?? this.speakerRuns,
        readingBucket: readingBucket ?? this.readingBucket,
        prevKey: identical(prevKey, _keep) ? this.prevKey : prevKey as String?,
        nextKey: identical(nextKey, _keep) ? this.nextKey : nextKey as String?,
        nextState: nextState ?? this.nextState,
        furtherElsewhere: identical(furtherElsewhere, _keep) ? this.furtherElsewhere : furtherElsewhere as NovelFurtherAhead?,
        saved: saved ?? this.saved,
        stale: stale ?? this.stale,
        pageIndex: pageIndex ?? this.pageIndex,
        pageCount: pageCount ?? this.pageCount,
        revision: revision ?? this.revision,
      );
}

const Object _keep = Object();

int _chapterPercent(int bucket, int buckets) => buckets <= 0 ? 0 : (bucket * 100 / buckets).round().clamp(0, 100);

/// The scrollable (or paged) thing the controller measures. The screen registers it with
/// [NovelReaderController.attach]; the controller never holds a `ScrollController` or a
/// `BuildContext`.
abstract interface class NovelReadingSurface {
  /// The paragraph under the reading line and how far into it, or null when nothing is laid out.
  ({int index, double fraction})? anchorAtReadingLine();

  /// Whether the reader is at the end of the chapter (the last scroll extent, or the last page).
  bool get atEnd;

  /// The furthest scroll extent, for estimating where an unbuilt paragraph is.
  double get maxExtent;

  /// Lands paragraph [index] exactly when it has been laid out (its top, or the point [fraction]
  /// into it at the reading line when [toReadingLine]); false when it is not built yet.
  bool landOn(int index, double fraction, {required bool toReadingLine});

  /// Jumps to [fraction] (0-1) of [maxExtent], forcing lazily built paragraphs to lay out.
  void jumpEstimate(double fraction);
}

/// The skin-neutral controller of the novel reader (stack-decision 2.3): the chapter and its
/// neighbours, the seamless next chapter, progress in paragraph buckets, bookmarks, attribution,
/// restore, the paged layout's pagination. Both the legacy `NovelReaderScreen` and the Cinematic
/// "page" render its state; neither owns any of this logic.
class NovelReaderController extends AutoDisposeFamilyNotifier<NovelReaderState, NovelReaderArgs> {
  late NovelChapterKey _current;
  late final ProgressOutboxController _progressOutbox;
  late final BookmarkOutboxController _bookmarkOutbox;
  DownloadsStore? _downloadsStore;
  late final SourceProgressNotifier _localProgress;
  final ReadingClock _clock = ReadingClock(DateTime.now());

  NovelReadingSurface? _surface;
  Timer? _progressTimer, _autoNextTimer;
  StreamSubscription<({String sourceId, String seriesKey})>? _notAdvancedSub;
  final List<ProviderSubscription<Object?>> _subs = [];
  ProviderSubscription<Object?>? _prefetchSub;
  int _furthestSent = 0;
  bool _scrolledToEnd = false;
  bool _autoNextTriggered = false;
  bool _disposed = false;

  int? _pendingRestoreParagraph;
  double _restoreFraction = 0;
  bool _restoreToReadingLine = false;
  int _restoreFrames = 0;
  double _lastRestoreMaxExtent = -1;
  bool _pagedAnchorSet = false;
  int _pagedAnchor = 0;

  /// Set by the screen: whether "Auto next chapter" is on, and whether narration is playing (an
  /// unfinished chapter is not over when its last line scrolls into view).
  bool autoNext = false;
  bool Function() narrationBusy = () => false;

  /// Set by the screen. Called with the key of the chapter to move to. The legacy screen
  /// navigates (`context.go`); the Cinematic one replaces the location in place.
  void Function(String chapterKey)? locationReplacer;

  /// Seamless next: the next chapter is swapped in here, the route location replaced without a
  /// navigation. Off (legacy), [next] and [previous] only call [locationReplacer].
  bool seamless = false;

  // Pagination.
  Size _viewport = Size.zero;
  double _margin = 24;
  double _bandTop = 0, _bandBottom = kNovelFolioBand, _openerHeight = 0;
  List<List<NovelPageSlice>> _pages = const [];

  /// The pages of the current pagination (see [paginateNovel]).
  List<List<NovelPageSlice>> get pages => _pages;

  @override
  NovelReaderState build(NovelReaderArgs args) {
    _current = args.key;
    _progressOutbox = ref.read(progressOutboxControllerProvider);
    _bookmarkOutbox = ref.read(bookmarkOutboxControllerProvider);
    _downloadsStore = ref.read(downloadsStoreProvider);
    _localProgress = ref.read(sourceProgressProvider.notifier);
    ref.onDispose(_onDispose);
    _notAdvancedSub = _progressOutbox.notAdvanced.listen((k) => unawaited(_checkFurther(k)));
    final initial = NovelReaderState(chapterValue: ref.read(resolvedNovelChapterProvider(_current)));
    // Bound after the first frame of state so the listeners never assign state during build.
    scheduleMicrotask(() {
      if (!_disposed) _bind(_current);
    });
    return initial;
  }

  // ── Binding ──────────────────────────────────────────────────────────────

  void _closeSubs() {
    for (final s in _subs) {
      s.close();
    }
    _subs.clear();
  }

  void _bind(NovelChapterKey key) {
    _closeSubs();
    _current = key;
    _subs
      ..add(ref.listen<AsyncValue<NovelChapter>>(resolvedNovelChapterProvider(key), (_, v) {
        if (_disposed || key != _current) return;
        state = state.copyWith(chapterValue: v, speakerRuns: _runs(v.valueOrNull, state.attribution));
        if (v.hasValue) _armPrefetch();
      }),)
      ..add(ref.listen<AsyncValue<NovelChapterNeighbours>>(novelChapterNeighboursProvider(key), (_, v) {
        if (_disposed || key != _current) return;
        final n = v.valueOrNull;
        if (n == null) return;
        state = state.copyWith(prevKey: n.previousChapterKey, nextKey: n.nextChapterKey);
        _armPrefetch();
      }),)
      ;
    if (arg.attribution) {
      _subs.add(ref.listen<AsyncValue<NovelAttribution>>(novelAttributionProvider(key), (_, v) {
        if (_disposed || key != _current) return;
        final a = v.valueOrNull ?? NovelAttribution.none;
        state = state.copyWith(attribution: a, speakerRuns: _runs(state.chapter, a));
      }),);
    }
    // Values already resolved before the listeners existed.
    final chapter = ref.read(resolvedNovelChapterProvider(key));
    final n = ref.read(novelChapterNeighboursProvider(key)).valueOrNull;
    final a = arg.attribution ? (ref.read(novelAttributionProvider(key)).valueOrNull ?? NovelAttribution.none) : NovelAttribution.none;
    state = state.copyWith(
      chapterValue: chapter,
      attribution: a,
      speakerRuns: _runs(chapter.valueOrNull, a),
      prevKey: n?.previousChapterKey ?? chapter.valueOrNull?.previousChapterKey,
      nextKey: n?.nextChapterKey ?? chapter.valueOrNull?.nextChapterKey,
    );
    _armPrefetch();
  }

  Map<int, List<SpeakerRun>> _runs(NovelChapter? chapter, NovelAttribution a) =>
      chapter == null || !a.attributed ? const {} : speakerRuns(a, chapter.paragraphs);

  /// The chapter to continue into, from whichever source knows it.
  String? get nextKey => state.nextKey ?? state.chapter?.nextChapterKey;
  String? get previousKey => state.prevKey ?? state.chapter?.previousChapterKey;

  /// Warms the next chapter (through the same provider the swap reads) so it is ready.
  void _armPrefetch() {
    final next = nextKey;
    if (next == null) {
      _prefetchSub?.close();
      _prefetchSub = null;
      if (state.nextState != NovelNextState.none) state = state.copyWith(nextState: NovelNextState.none);
      return;
    }
    final key = (sourceId: _current.sourceId, seriesKey: _current.seriesKey, chapterKey: next);
    _prefetchSub?.close();
    _prefetchSub = ref.listen<AsyncValue<NovelChapter>>(resolvedNovelChapterProvider(key), (_, v) {
      if (_disposed) return;
      state = state.copyWith(nextState: v.hasValue ? NovelNextState.ready : (v.hasError ? NovelNextState.failed : NovelNextState.loading));
    }, fireImmediately: false,);
    final v = ref.read(resolvedNovelChapterProvider(key));
    final s = v.hasValue ? NovelNextState.ready : (v.hasError ? NovelNextState.failed : NovelNextState.loading);
    if (s != state.nextState) state = state.copyWith(nextState: s);
  }

  void _onDispose() {
    _disposed = true;
    flush();
    _autoNextTimer?.cancel();
    unawaited(_notAdvancedSub?.cancel());
    _closeSubs();
    _prefetchSub?.close();
  }

  // ── Surface ──────────────────────────────────────────────────────────────

  void attach(NovelReadingSurface surface) => _surface = surface;

  void detach(NovelReadingSurface surface) {
    if (identical(_surface, surface)) _surface = null;
  }

  // ── Restore ──────────────────────────────────────────────────────────────

  /// Resume where the reader left off, never past it. Call once after the first frame.
  void beginRestore() {
    final chapter = state.chapter;
    if (chapter == null) return;
    final n = chapter.paragraphs.length;
    final requested = arg.initialParagraph;
    if (requested != null && n > 0) {
      final target = (requested - 1).clamp(0, n - 1);
      _restoreFraction = arg.initialFraction ?? 0;
      _restoreToReadingLine = true;
      _pendingRestoreParagraph = target;
      _furthestSent = bucketForParagraph(target, n);
      state = state.copyWith(readingBucket: _furthestSent, stale: requested > n);
      _restoreFrames = 0;
      _lastRestoreMaxExtent = -1;
      _attemptRestore();
      return;
    }
    final target = paragraphForBucket(arg.initialBucket, n);
    if (target <= 0) {
      state = state.copyWith(readingBucket: bucketForParagraph(0, n));
      _furthestSent = 0;
      return;
    }
    _pendingRestoreParagraph = target;
    _restoreFraction = 0;
    _restoreToReadingLine = false;
    _furthestSent = arg.initialBucket;
    state = state.copyWith(readingBucket: arg.initialBucket);
    _restoreFrames = 0;
    _lastRestoreMaxExtent = -1;
    _attemptRestore();
  }

  /// Aims the surface at [paragraph] (0-based), homing in over frames as the list lays out.
  void _startRestore(int paragraph, double fraction, {required bool toReadingLine}) {
    _pendingRestoreParagraph = paragraph;
    _restoreFraction = fraction;
    _restoreToReadingLine = toReadingLine;
    _restoreFrames = 0;
    _lastRestoreMaxExtent = -1;
    _attemptRestore();
  }

  void _attemptRestore() {
    final target = _pendingRestoreParagraph;
    if (target == null) return;
    final surface = _surface;
    if (_disposed || surface == null) {
      _pendingRestoreParagraph = null;
      return;
    }
    if (surface.landOn(target, _restoreFraction, toReadingLine: _restoreToReadingLine)) {
      _pendingRestoreParagraph = null;
      return;
    }
    final maxExtent = surface.maxExtent;
    final stoppedGrowing = maxExtent <= _lastRestoreMaxExtent;
    final outOfFrames = ++_restoreFrames >= kNovelMaxRestoreFrames;
    if (stoppedGrowing || outOfFrames) {
      _pendingRestoreParagraph = null;
      return;
    }
    _lastRestoreMaxExtent = maxExtent;
    final n = state.paragraphs.length;
    surface.jumpEstimate(n == 0 ? 0 : target / n);
    WidgetsBinding.instance.addPostFrameCallback((_) => _attemptRestore());
  }

  /// Whether a restore is still homing in (progress is not recorded meanwhile).
  bool get restoring => _pendingRestoreParagraph != null;

  /// Jumps to the first paragraph of [bucket] (1-100).
  void jumpToBucket(int bucket) {
    final n = state.paragraphs.length;
    if (n == 0) return;
    if (_pagedSurface) {
      final page = pageOfBucket(_pages, bucket, n);
      state = state.copyWith(pageIndex: page);
      onPaged(page);
      return;
    }
    _startRestore(paragraphForBucket(bucket, n), 0, toReadingLine: false);
  }

  /// Aims the surface at [paragraph] (0-based) from outside the controller (follow scroll, Listen).
  void jumpToParagraph(int paragraph, {double fraction = 0, bool toReadingLine = true}) => _startRestore(paragraph, fraction, toReadingLine: toReadingLine);

  bool get _pagedSurface => _pages.isNotEmpty && _pagedAnchorSet;

  // ── Progress ─────────────────────────────────────────────────────────────

  /// The surface scrolled: note whether it is at the end, debounce a progress save, consider
  /// auto-next.
  void onScrolled() {
    if (_pendingRestoreParagraph != null) return;
    _scrolledToEnd = _surface?.atEnd ?? false;
    _progressTimer ??= Timer(const Duration(milliseconds: kNovelProgressSaveMs), () {
      _progressTimer = null;
      recordPosition();
    });
    maybeScheduleAutoNext();
  }

  /// Paged layout: the page changed to [page]; its first paragraph is the reading position.
  void onPaged(int page) {
    _pagedAnchorSet = true;
    final n = state.paragraphs.length;
    _pagedAnchor = paragraphOfPage(_pages, page);
    state = state.copyWith(pageIndex: page);
    _scrolledToEnd = page >= _pages.length; // the end-matter page is one past the text pages
    _progressTimer ??= Timer(const Duration(milliseconds: kNovelProgressSaveMs), () {
      _progressTimer = null;
      recordPosition();
    });
    if (n > 0) maybeScheduleAutoNext();
  }

  /// Which paragraph is under the reading line, and what that means for progress.
  void recordPosition() {
    final chapter = state.chapter;
    if (chapter == null || _disposed) return;
    final n = chapter.paragraphs.length;
    final atEnd = _surface?.atEnd ?? _scrolledToEnd;
    int? index;
    if (_pagedSurface) {
      index = _pagedAnchor;
    } else {
      index = _surface?.anchorAtReadingLine()?.index;
    }
    if (index == null) return;
    final position = progressAtReadingLine(index, n, atEnd: atEnd);
    if (position.bucket != state.readingBucket) state = state.copyWith(readingBucket: position.bucket);
    _push(position);
  }

  void _push(NovelProgressPosition position) {
    final push = nextProgressPush(position, _furthestSent);
    if (push == null) return;
    _furthestSent = push.bucket;
    unawaited(_saveProgress(push));
  }

  /// Local-first, like the manga reader: every save goes to the on-device outbox and is flushed
  /// best-effort. Only through handles resolved in [build]: this runs on after the reader closed
  /// whenever it was a closing save.
  Future<void> _saveProgress(NovelProgressPosition position) async {
    final chapter = state.chapter;
    if (chapter == null) return;
    final store = _downloadsStore;
    await _progressOutbox.save(
      ProgressPush(
        sourceId: chapter.sourceId,
        seriesKey: chapter.seriesKey,
        chapterKey: chapter.chapterKey,
        chapterNumber: chapter.chapterNumber,
        lastPage: position.bucket,
        pageCount: position.buckets,
        isCompleted: position.completed,
        timeSpentSeconds: _clock.elapsed(DateTime.now()),
      ),
    );
    if (position.completed) {
      await store?.markRead((sourceId: chapter.sourceId, seriesKey: chapter.seriesKey, chapterKey: chapter.chapterKey));
    }
    await _localProgress.record(
      sourceId: chapter.sourceId,
      seriesId: chapter.seriesKey,
      chapterId: chapter.chapterKey,
      page: position.bucket,
      pageCount: position.buckets,
    );
  }

  /// A save the debounce was still holding, flushed on leave: only the end of the chapter
  /// survives (the surface can no longer be measured).
  void flush() {
    final pending = _progressTimer != null;
    _progressTimer?.cancel();
    _progressTimer = null;
    final chapter = state.chapter;
    if (pending && _scrolledToEnd && chapter != null) {
      _push(completedProgress(chapter.paragraphs.length));
    }
  }

  /// Marks the chapter complete now (`is_completed`, the 48 h phone-copy timer).
  void markComplete() {
    final chapter = state.chapter;
    if (chapter == null) return;
    _progressTimer?.cancel();
    _progressTimer = null;
    _push(completedProgress(chapter.paragraphs.length));
  }

  // ── Continuation ─────────────────────────────────────────────────────────

  /// The manga reader's mechanism: at the end of the chapter, with auto-next on and a next
  /// chapter, wait 900 ms and go. Once per chapter.
  void maybeScheduleAutoNext() {
    if (narrationBusy()) {
      _autoNextTimer?.cancel();
      _autoNextTimer = null;
      return;
    }
    final atEnd = _surface?.atEnd ?? _scrolledToEnd;
    if (!autoNext || nextKey == null || _autoNextTriggered || !atEnd) {
      _autoNextTimer?.cancel();
      _autoNextTimer = null;
      return;
    }
    if (_autoNextTimer != null) return;
    _autoNextTimer = Timer(const Duration(milliseconds: kNovelAutoNextMs), () {
      if (_disposed || _autoNextTriggered) return;
      _autoNextTriggered = true;
      next();
    });
  }

  /// Continue into the next chapter, saying first that this one is finished. Every way forward
  /// comes through here; a jump from Contents and Previous do not finish the chapter.
  void next() {
    final key = nextKey;
    if (key == null) return;
    markComplete();
    _go(key);
  }

  void previous() {
    final key = previousKey;
    if (key == null) return;
    _go(key);
  }

  /// Opens [chapterKey] (Contents, Jump): no completion.
  void open(String chapterKey) => _go(chapterKey);

  void _go(String chapterKey) {
    if (seamless) {
      swapTo(chapterKey);
    }
    locationReplacer?.call(chapterKey);
  }

  /// Swaps [chapterKey] in at the top without a navigation.
  void swapTo(String chapterKey) {
    final chapter = state.chapter;
    if (chapter == null) return;
    _autoNextTimer?.cancel();
    _autoNextTimer = null;
    _progressTimer?.cancel();
    _progressTimer = null;
    _autoNextTriggered = false;
    _furthestSent = 0;
    _scrolledToEnd = false;
    _pendingRestoreParagraph = null;
    _pagedAnchorSet = false;
    _pages = const [];
    final key = (sourceId: chapter.sourceId, seriesKey: chapter.seriesKey, chapterKey: chapterKey);
    state = NovelReaderState(
      chapterValue: ref.read(resolvedNovelChapterProvider(key)),
      revision: state.revision + 1,
    );
    _bind(key);
  }

  // ── Bookmark ─────────────────────────────────────────────────────────────

  Bookmark? _lastBookmark;

  /// The bookmark the last [bookmark] call saved.
  Bookmark? get lastBookmark => _lastBookmark;

  /// Save the exact spot being read in one action: the paragraph at the reading line, the point
  /// within it, the chapter's paragraph count and a 180-character snippet.
  Future<NovelBookmarkResult> bookmark() async {
    final chapter = state.chapter;
    if (chapter == null) return NovelBookmarkResult.nothing;
    ({int index, double fraction})? anchor;
    if (_pagedSurface) {
      anchor = (index: _pagedAnchor, fraction: 0.0);
    } else {
      anchor = _surface?.anchorAtReadingLine();
    }
    if (anchor == null) return NovelBookmarkResult.nothing;
    try {
      final total = chapter.paragraphs.length;
      final index = anchor.index + 1;
      final (snippet, _) = novelSnippetAt(chapter.paragraphs, index, anchor.fraction);
      final saved = await _bookmarkOutbox.create(
        id: (sourceId: chapter.sourceId, seriesKey: chapter.seriesKey, chapterKey: chapter.chapterKey),
        media: BookmarkMedia.novel,
        anchorIndex: index,
        anchorFraction: anchor.fraction,
        anchorTotal: total,
        chapterNumber: chapter.chapterNumber,
        snippet: snippet,
      );
      if (saved == null) return NovelBookmarkResult.failed;
      _lastBookmark = saved;
      if (!_disposed) state = state.copyWith(saved: true);
      return NovelBookmarkResult.saved;
    } catch (e) {
      appLogger.w('novel bookmark failed: $e');
      return NovelBookmarkResult.failed;
    }
  }

  /// The percent of the chapter a bookmark at the current spot stands at, for the toast.
  int? bookmarkPercent() {
    final chapter = state.chapter;
    final a = _surface?.anchorAtReadingLine();
    if (chapter == null || a == null) return null;
    return bookmarkPositionPercent(a.index + 1, a.fraction, chapter.paragraphs.length);
  }

  /// Adds [note] to the bookmark just saved.
  Future<bool> addNoteToLast(String note) async {
    final b = _lastBookmark;
    if (b == null) return false;
    final updated = await _bookmarkOutbox.setNote(b, note);
    if (updated != null) _lastBookmark = updated;
    return updated != null;
  }

  // ── Further on another device ────────────────────────────────────────────

  Future<void> _checkFurther(({String sourceId, String seriesKey}) k) async {
    final chapter = state.chapter;
    if (chapter == null || k.sourceId != chapter.sourceId || k.seriesKey != chapter.seriesKey) return;
    final rows = await ref.read(readerRepositoryProvider).seriesProgress(sourceId: k.sourceId, seriesKey: k.seriesKey);
    if (_disposed || rows.isErr) return;
    ReadingProgress? far;
    for (final r in rows.value) {
      if ((r.chapterNumber ?? -1) > (far?.chapterNumber ?? -1)) far = r;
    }
    final here = state.chapter?.chapterNumber ?? -1;
    if (far == null || far.chapterKey == chapter.chapterKey || (far.chapterNumber ?? -1) <= here) return;
    state = state.copyWith(furtherElsewhere: NovelFurtherAhead(chapterKey: far.chapterKey, chapterNumber: far.chapterNumber, bucket: far.lastPage));
  }

  /// The reader dismissed or took the jump offer.
  void clearFurther() => state = state.copyWith(furtherElsewhere: null);

  // ── Pagination (paged layout) ────────────────────────────────────────────

  /// Tells the controller the size of the page area and the reserved bands, for [paginateNovel].
  void setViewport(Size viewport, {required double margin, double bandTop = 0, double bandBottom = kNovelFolioBand, double openerHeight = 0}) {
    _viewport = viewport;
    _margin = margin;
    _bandTop = bandTop;
    _bandBottom = bandBottom;
    _openerHeight = openerHeight;
  }

  /// Paginates the chapter for a column of [measureCh] characters in [type] (glass 15.4): the
  /// column is `min(measureCh x advance of "0", viewport width - 2 x margin)` wide and each page
  /// as tall as the viewport minus the reserved bands. Keeps the first paragraph of the current
  /// page on screen across a re-pagination. Returns the pages; `pageIndex` and `pageCount` are
  /// updated in the state. Runs on the UI isolate (`TextPainter` needs `dart:ui`).
  List<List<NovelPageSlice>> paginateNovel(double measureCh, NovelType type) {
    final paragraphs = state.paragraphs;
    if (paragraphs.isEmpty || _viewport.isEmpty) {
      _pages = const [];
      state = state.copyWith(pageIndex: 0, pageCount: 0);
      return _pages;
    }
    final anchor = _pagedAnchorSet ? _pagedAnchor : paragraphOfPage(_pages, state.pageIndex);
    final sw = Stopwatch()..start();
    final width = novelColumnWidthCh(type.copyWith(measure: measureCh), viewportWidth: _viewport.width, margin: _margin);
    _pages = paginateNovelText(
      paragraphs: paragraphs,
      type: type,
      width: width,
      pageHeight: math.max(1, _viewport.height - _bandTop - _bandBottom),
      openerHeight: _openerHeight,
    );
    sw.stop();
    assert(() {
      // ignore: avoid_print
      print('paginate: ${paragraphs.length} paragraphs, ${sw.elapsedMilliseconds} ms');
      return true;
    }());
    final page = pageOfParagraph(_pages, anchor);
    _pagedAnchorSet = true;
    _pagedAnchor = paragraphOfPage(_pages, page);
    state = state.copyWith(pageIndex: page, pageCount: _pages.length);
    return _pages;
  }

  /// Leaves the paged layout (scroll again).
  void endPaged() {
    _pagedAnchorSet = false;
    _pages = const [];
    state = state.copyWith(pageIndex: 0, pageCount: 0);
  }
}

/// The controller of one chapter reference.
final novelReaderControllerProvider = NotifierProvider.autoDispose.family<NovelReaderController, NovelReaderState, NovelReaderArgs>(
  NovelReaderController.new,
  name: 'novelReaderController',
);
