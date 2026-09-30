import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/models/reader_feed.dart';
import 'package:manhwamaniacs/features/reader/utils/page_extents.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_anchor.dart';

/// Which of the two ways into a chapter built the reader.
enum ReaderOrigin { manifest, source }

/// The resolved reader body `ReaderScreen` and `SourceReaderScreen` hand to a frame: the feed and
/// every callback the engine takes, plus which chapter and which way in. `ReaderContent`, the
/// legacy frame, implements it, so a skin frame reads the same data without importing widgets.
abstract interface class ReaderFrameBody {
  ReaderFeed get feed;
  String get scrollStorageKey;
  VoidCallback get onBack;
  VoidCallback get onOpenSeries;
  int get initialPage;
  ReaderAnchor? get initialAnchor;
  bool get showBookmark;
  Future<void> Function(ReaderChapter chapter, int page)? get onSaveProgress;
  Future<bool> Function(ReaderChapter chapter, ReaderAnchor anchor)? get onAddBookmark;
  VoidCallback? get onPreviousChapter;
  VoidCallback? get onNextChapter;
  Future<void> Function()? get onReachedFeedEnd;
  Future<void> Function()? get onReachedFeedStart;
  ReaderPageExtents? get pageExtents;
  Map<String, List<ReaderAnchor>> get bookmarkAnchors;
  ({String sourceId, String seriesKey, String chapterKey, ReaderOrigin origin})? get identity;
}

/// What a skin's error frame needs to draw the states of a chapter that did not open.
class ReaderFailure {
  const ReaderFailure({required this.error, required this.noPages, required this.retry, required this.back});

  /// The error, or null when the chapter opened with no pages.
  final AppError? error;
  final bool noPages;
  final VoidCallback retry;

  /// Leaves for the series page.
  final VoidCallback back;
}

/// The reader frames a skin supplies. Every field null is the legacy reader: `ReaderContent`,
/// `ReaderSkeleton` and `ReaderErrorState`. The two entry screens (`ReaderScreen`,
/// `SourceReaderScreen`) read this, so a skin swaps the frame without owning a data path.
class ReaderFrames {
  const ReaderFrames({this.content, this.loading, this.failure});

  /// Receives the resolved reader body (feed, callbacks, identity).
  final Widget Function(BuildContext context, ReaderFrameBody body)? content;
  final Widget Function(BuildContext context)? loading;
  final Widget Function(BuildContext context, ReaderFailure failure)? failure;
}

/// Overridden by the Cinematic reader route; the default keeps the legacy frame.
final readerFramesProvider = Provider<ReaderFrames>((ref) => const ReaderFrames(), name: 'readerFrames');
