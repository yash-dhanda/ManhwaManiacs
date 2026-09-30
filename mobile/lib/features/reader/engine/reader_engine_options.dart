import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/reader/engine/tap_classifier.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/models/reader_feed.dart';

/// What a page box holds when it has no picture.
enum PageStatus { placeholder, broken }

/// The bands the strip carries between and around chapters.
enum BandKind {
  seam,
  top,
  topLoading,
  nextLoading,
  nextFailed,
  offlineEnd,
  rateLimited
}

/// How much of the chapter-end credits shows: one line in a continuous strip, the full block
/// (with the Coming up card and pull to continue) when the next chapter is not stitched below.
enum CreditsMode { compact, full }

/// The tone applied to the pages, through the matrices of `reader_filter_provider.dart`.
enum ReaderColourFilter { none, sepia, grey }

/// A tap, as the skin sees it: where, on what size, single or the second of a double.
class ReaderTapInfo {
  const ReaderTapInfo(
      {required this.position, required this.size, required this.kind,});
  final Offset position;
  final Size size;
  final TapKind kind;
}

/// Replaces the engine's built-in tap rules (lock counting, double-tap zoom, tap zones and the
/// chrome toggle) with the skin's. Called after the scroll cooldown filter.
typedef ReaderTapHandler = void Function(ReaderTapInfo info);

/// Drawn inside a page's reserved box while it has no picture: [PageStatus.placeholder] while it
/// loads, [PageStatus.broken] when it failed ([retry] refetches that image only).
typedef PageStateBuilder = Widget Function(
  BuildContext context,
  int page,
  PageStatus status,
  String? reason,
  VoidCallback retry,
);

/// A band of the strip. [from] and [to] name the chapters either side; [retryIn] is a live
/// countdown for `rateLimited`.
typedef BandBuilder = Widget Function(
  BuildContext context,
  BandKind kind, {
  String? from,
  String? to,
  Duration? retryIn,
});

/// Placed after the feed's last page. [nextChapterId] is null when nothing follows.
typedef CreditsBuilder = Widget Function(
  BuildContext context,
  ReaderChapter chapter,
  String? nextChapterId,
  CreditsMode mode,
);

/// Wraps one page's item in semantics (the skin's "Page 18 of 40" and its recognised text).
typedef PageSemanticsBuilder = Widget Function(BuildContext context, ReaderChapter chapter, int pageNumber, Widget page);

/// Wraps the page list (the skin's warmth layer).
typedef PageLayerBuilder = Widget Function(BuildContext context, Widget pages);

/// The scroll-driven chrome rules of cinematic 8.14.3: hide after a cumulative [hidePx] of
/// downward scroll since the last direction change, show after [showPx] upward, never inside the
/// first [grace] of a chapter. Off (null) the engine hides on the start of a drag as it always did.
class ReaderAutoHide {
  const ReaderAutoHide(
      {this.hidePx = 24,
      this.showPx = 56,
      this.grace = const Duration(milliseconds: 800),
      this.onScroll = true,});
  final double hidePx, showPx;
  final Duration grace;

  /// False while a screen reader runs: the chrome never hides by scrolling.
  final bool onScroll;
}

/// Presentation and input parameters a skin passes to `ReaderEngineView`. Every default is what
/// the legacy reader does, so a view built without options is unchanged.
class ReaderEngineOptions {
  const ReaderEngineOptions({
    this.ground,
    this.gapPx = 0,
    this.columnWidth,
    this.sideMarginPct = 0,
    this.colourFilter,
    this.doubleTapWindow = const Duration(milliseconds: 280),
    this.doubleTapSlop,
    this.tapSlop,
    this.tapHandler,
    this.autoHide,
    this.pinch = false,
    this.pageStateBuilder,
    this.bandBuilder,
    this.creditsBuilder,
    this.creditsMode = CreditsMode.compact,
    this.seamExtent = kChapterSeamExtent,
    this.topBandExtent = 0,
    this.footerExtent = 0,
    this.offline = false,
    this.pageLayerBuilder,
    this.pageSemantics,
    this.slotSignature,
    this.lifecycleVolumeKeys = false,
  });

  /// The colour behind and between pages; null follows the legacy backdrop setting.
  final Color? ground;

  /// 0 or 8 px of ground between pages.
  final double gapPx;

  /// The widest the strip column gets, in logical px (tablets); null is the screen.
  final double? columnWidth;

  /// 0-25 % of the width taken off each side.
  final int sideMarginPct;

  /// Null follows the legacy colour setting.
  final ReaderColourFilter? colourFilter;

  final Duration doubleTapWindow;
  final double? doubleTapSlop;

  /// Largest movement of a tap, in px. When set the engine classifies taps from raw pointers
  /// (slop and duration) instead of `GestureDetector.onTap`, which allows 18 px.
  final double? tapSlop;
  final ReaderTapHandler? tapHandler;
  final ReaderAutoHide? autoHide;

  /// Two-finger pinch with a focal point, and a horizontal pan above 1.0x.
  final bool pinch;
  final PageStateBuilder? pageStateBuilder;
  final BandBuilder? bandBuilder;
  final CreditsBuilder? creditsBuilder;
  final CreditsMode creditsMode;

  /// Height of the band a chapter seam reserves (the legacy 96 px by default).
  final double seamExtent;

  /// Height reserved above the first page when a previous chapter exists (0 = none).
  final double topBandExtent;

  /// Height reserved after the last page for the credits and the next-chapter bands.
  final double footerExtent;

  /// The chapter is read from disk: the footer says the next one is not saved here.
  final bool offline;
  final PageLayerBuilder? pageLayerBuilder;
  final PageSemanticsBuilder? pageSemantics;

  /// Whatever the slot builders read that is not a parameter here (the skin's series data): when it
  /// changes the pages, bands and footer are built again.
  final Object? slotSignature;

  /// Stops volume-key interception while the app is not resumed (Cinematic).
  final bool lifecycleVolumeKeys;
}
