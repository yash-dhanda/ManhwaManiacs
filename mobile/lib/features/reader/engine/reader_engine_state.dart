import 'package:flutter/foundation.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_anchor.dart';

/// Whether there is somewhere to go past the chapter being read.
enum ReaderNextState { loading, ready, failed, none }

/// Everything a reader chrome may draw, as one immutable value.
///
/// Published by [ReaderEngine] (a [ValueNotifier]) and handed to the chrome
/// builder of `ReaderEngineView`. The engine only notifies when a new value is
/// not `==` to the last one, which is why [progress] is quantised: a scroll
/// that moves less than 0.001 of the chapter costs no chrome rebuild.
@immutable
class ReaderEngineState {
  const ReaderEngineState({
    required this.chapterId,
    required this.chapterTitle,
    required this.chapterIndex,
    required this.page,
    required this.pageCount,
    required this.progress,
    required this.atStart,
    required this.atEnd,
    required this.hasPrevious,
    required this.hasNext,
    required this.loadedChapterIds,
    required this.nextState,
    required this.bookmarks,
    required this.zoom,
    required this.autoScrolling,
    required this.autoScrollSpeed,
    required this.chromeVisible,
    required this.locked,
  });

  /// The chapter under the reading line — an id, never a feed index.
  final String chapterId;
  final String chapterTitle;

  /// Index of [chapterId] in the feed's chapters.
  final int chapterIndex;

  /// 1-based and chapter-local: what the page counter shows.
  final int page;

  /// Pages in the chapter being read.
  final int pageCount;

  /// 0–1 through the chapter being read, quantised to 0.001.
  final double progress;

  final bool atStart;
  final bool atEnd;

  /// A previous / next chapter route exists.
  final bool hasPrevious;
  final bool hasNext;

  /// The feed's chapters, in order: the loaded neighbours.
  final List<String> loadedChapterIds;
  final ReaderNextState nextState;

  /// Bookmarks in the chapter being read.
  final List<ReaderAnchor> bookmarks;

  /// Zoom level, 0.5–3.0.
  final double zoom;
  final bool autoScrolling;

  /// Auto-scroll speed in pixels per second.
  final double autoScrollSpeed;
  final bool chromeVisible;
  final bool locked;

  static const ReaderEngineState initial = ReaderEngineState(
    chapterId: '',
    chapterTitle: '',
    chapterIndex: 0,
    page: 1,
    pageCount: 1,
    progress: 0,
    atStart: false,
    atEnd: false,
    hasPrevious: false,
    hasNext: false,
    loadedChapterIds: [],
    nextState: ReaderNextState.none,
    bookmarks: [],
    zoom: 1.0,
    autoScrolling: false,
    autoScrollSpeed: 60,
    chromeVisible: true,
    locked: false,
  );

  /// [value] rounded to 3 decimals and kept inside 0–1.
  static double quantiseProgress(double value) =>
      (value.clamp(0.0, 1.0) * 1000).round() / 1000;

  ReaderEngineState copyWith({
    String? chapterId,
    String? chapterTitle,
    int? chapterIndex,
    int? page,
    int? pageCount,
    double? progress,
    bool? atStart,
    bool? atEnd,
    bool? hasPrevious,
    bool? hasNext,
    List<String>? loadedChapterIds,
    ReaderNextState? nextState,
    List<ReaderAnchor>? bookmarks,
    double? zoom,
    bool? autoScrolling,
    double? autoScrollSpeed,
    bool? chromeVisible,
    bool? locked,
  }) =>
      ReaderEngineState(
        chapterId: chapterId ?? this.chapterId,
        chapterTitle: chapterTitle ?? this.chapterTitle,
        chapterIndex: chapterIndex ?? this.chapterIndex,
        page: page ?? this.page,
        pageCount: pageCount ?? this.pageCount,
        progress: progress ?? this.progress,
        atStart: atStart ?? this.atStart,
        atEnd: atEnd ?? this.atEnd,
        hasPrevious: hasPrevious ?? this.hasPrevious,
        hasNext: hasNext ?? this.hasNext,
        loadedChapterIds: loadedChapterIds ?? this.loadedChapterIds,
        nextState: nextState ?? this.nextState,
        bookmarks: bookmarks ?? this.bookmarks,
        zoom: zoom ?? this.zoom,
        autoScrolling: autoScrolling ?? this.autoScrolling,
        autoScrollSpeed: autoScrollSpeed ?? this.autoScrollSpeed,
        chromeVisible: chromeVisible ?? this.chromeVisible,
        locked: locked ?? this.locked,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReaderEngineState &&
          other.chapterId == chapterId &&
          other.chapterTitle == chapterTitle &&
          other.chapterIndex == chapterIndex &&
          other.page == page &&
          other.pageCount == pageCount &&
          other.progress == progress &&
          other.atStart == atStart &&
          other.atEnd == atEnd &&
          other.hasPrevious == hasPrevious &&
          other.hasNext == hasNext &&
          listEquals(other.loadedChapterIds, loadedChapterIds) &&
          other.nextState == nextState &&
          listEquals(other.bookmarks, bookmarks) &&
          other.zoom == zoom &&
          other.autoScrolling == autoScrolling &&
          other.autoScrollSpeed == autoScrollSpeed &&
          other.chromeVisible == chromeVisible &&
          other.locked == locked;

  @override
  int get hashCode => Object.hash(
        chapterId,
        chapterTitle,
        chapterIndex,
        page,
        pageCount,
        progress,
        atStart,
        atEnd,
        hasPrevious,
        hasNext,
        Object.hashAll(loadedChapterIds),
        nextState,
        Object.hashAll(bookmarks),
        zoom,
        autoScrolling,
        autoScrollSpeed,
        chromeVisible,
        locked,
      );

  @override
  String toString() =>
      'ReaderEngineState($chapterId p$page/$pageCount ${progress.toStringAsFixed(3)} '
      'next=${nextState.name} zoom=$zoom chrome=$chromeVisible locked=$locked)';
}
