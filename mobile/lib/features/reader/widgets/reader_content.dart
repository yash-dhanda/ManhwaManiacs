import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/app/theme/app_colors.dart';
import 'package:manhwamaniacs/app/theme/app_presets.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_state.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_view.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_surface_slots.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/models/reader_feed.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_filter_provider.dart';
import 'package:manhwamaniacs/features/reader/theme/reader_colors.dart';
import 'package:manhwamaniacs/features/reader/utils/page_extents.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_anchor.dart';
import 'package:manhwamaniacs/features/reader/widgets/chapter_seam.dart';
import 'package:manhwamaniacs/features/reader/widgets/reader_controls.dart';
import 'package:manhwamaniacs/features/reader/widgets/reader_edge_back_gesture.dart';
import 'package:manhwamaniacs/features/reader/widgets/reader_shortcuts.dart';
import 'package:manhwamaniacs/features/settings/models/reader_defaults.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';

/// Shared reader body used by both the local library reader and the online
/// source reader.
///
/// It owns no data fetching and no persistence — callers pass the resolved
/// [ReaderFeed] plus optional callbacks for progress/bookmark saves and
/// chapter navigation. Every reader behaviour (fullscreen, scroll restore,
/// zoom, virtualized page list, cached images, edge prompts, auto-next) lives
/// here exactly once so the two entry points cannot drift.
///
/// It renders a FEED, not a chapter (spec R1). A feed of one is the ordinary
/// read and behaves exactly as it always did; a feed of several is one
/// continuous scroll across a chapter boundary, with the seam marked and
/// never blocking. Growing the feed is the caller's job — this widget only
/// says *when* ([onReachedFeedEnd] / [onReachedFeedStart]) — because only the
/// caller knows how to fetch a chapter and which one comes next.
///
/// Since the engine extraction this is the legacy FRAME: every behaviour
/// lives in [ReaderEngineView] and this widget only supplies today's chrome —
/// the bars, edge prompts, filter overlay, back gesture, more-options sheet
/// and SnackBars — through the engine's chrome builder and slots.
class ReaderContent extends ConsumerStatefulWidget {
  const ReaderContent({
    super.key,
    required this.feed,
    required this.scrollStorageKey,
    required this.onBack,
    required this.onOpenSeries,
    this.initialPage = 1,
    this.initialAnchor,
    this.showBookmark = true,
    this.onSaveProgress,
    this.onAddBookmark,
    this.onPreviousChapter,
    this.onNextChapter,
    this.onReachedFeedEnd,
    this.onReachedFeedStart,
    this.pageExtents,
    this.bookmarkAnchors = const {},
  });

  /// The chapters being read, as one page list. [ReaderFeed.single] is the
  /// ordinary case.
  final ReaderFeed feed;

  /// Opaque key used to persist/restore scroll position for the chapter this
  /// reader was OPENED at — the feed's anchor. Positions inside chapters the
  /// feed later grew into are carried by reading progress instead, which is
  /// per-chapter and already saved.
  final String scrollStorageKey;
  final int initialPage;

  /// Open at an EXACT position rather than at the top of [initialPage] — what
  /// tapping a bookmark hands over.
  ///
  /// Its page is chapter-local, like [initialPage], and the two agree by
  /// construction (the router derives one from the other). When it is set it
  /// also **beats the persisted scroll position**: a reader who deliberately
  /// tapped "62% of chapter 14" is asking to go there, and resuming them
  /// wherever they last stopped instead would silently ignore the tap.
  final ReaderAnchor? initialAnchor;

  final bool showBookmark;
  final VoidCallback onBack;

  /// Open the series page for this chapter, so the chapter list is reachable
  /// without retracing however the reader was entered. Required rather than
  /// optional: both entry points always know their series, and a null here
  /// would silently remove the only affordance for it.
  final VoidCallback onOpenSeries;

  /// Persist reading progress. Only the local library reader supplies this.
  ///
  /// Takes the chapter as well as the page because a continuous feed spans
  /// several: reading into chapter 12 has to record chapter 12, page N — the
  /// page number is chapter-local, never an index into the feed.
  final Future<void> Function(ReaderChapter chapter, int page)? onSaveProgress;

  /// Create a bookmark at the EXACT visible position of the chapter it
  /// belongs to. Only the local library reader. Return ``true`` when saved.
  ///
  /// The anchor's page is chapter-local (a continuous feed spans several
  /// chapters, and "page 3" means nothing without saying page 3 of what) and
  /// its fraction is of that page's own height.
  final Future<bool> Function(ReaderChapter chapter, ReaderAnchor anchor)?
      onAddBookmark;

  /// Navigate to the previous/next chapter as a fresh route. ``null`` disables
  /// that direction. In a continuous feed these are the edge prompts for a
  /// boundary the feed could not absorb (nothing beyond it, or the fetch
  /// failed) — crossing a loaded boundary never navigates.
  final VoidCallback? onPreviousChapter;
  final VoidCallback? onNextChapter;

  /// Called as the reader comes within [kSeamPrefetchPages] of either end of
  /// the feed, so the caller can fetch the adjacent chapter and hand back a
  /// longer feed **before** the seam is reached. Null in single-chapter mode,
  /// which is what keeps that mode exactly as it was.
  final Future<void> Function()? onReachedFeedEnd;
  final Future<void> Function()? onReachedFeedStart;

  /// Page geometry for this feed. The reader owns one per session when this
  /// is omitted; supplying it lets a test resolve a page's real size without a
  /// decoding image, which is otherwise unreachable from outside.
  final ReaderPageExtents? pageExtents;

  /// Bookmarks already stored, by chapter id, for the engine state.
  final Map<String, List<ReaderAnchor>> bookmarkAnchors;

  @override
  ConsumerState<ReaderContent> createState() => _ReaderContentState();
}

class _ReaderContentState extends ConsumerState<ReaderContent> {
  final ReaderEngine _engine = ReaderEngine();

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }

  // ── Engine events → today's SnackBars ────────────────────────────────────

  void _handleEvent(ReaderEngineEvent event) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    switch (event) {
      case ReaderUnlocked():
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Reader unlocked'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      case ReaderBookmarkSaved(:final page, :final percent):
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              percent == null
                  ? 'Bookmarked page $page'
                  : 'Bookmarked page $page — $percent% of the chapter',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      case ReaderStaleAnchor(:final openedPage, :final requestedPage):
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'This chapter changed — opened at page $openedPage '
              'instead of $requestedPage.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  // ── More options sheet ────────────────────────────────────────────────────

  void _showMoreOptions() {
    // Re-arm hide timer so controls stay visible while sheet is open
    _engine.holdChrome();
    showModalBottomSheet<void>(
      context: context,
      // Elevated surface (#181818) so the sheet lifts off the reader's near-
      // black page backdrop.
      backgroundColor: context.colors.surfaceElevated,
      // Scroll-controlled so the settings sheet is never clipped and its
      // actions stay reachable regardless of content height.
      isScrollControlled: true,
      // Swipe-down-to-dismiss with a visible grab handle (system back alone was
      // not discoverable). enableDrag defaults to true.
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(context.radii.xl)),
      ),
      builder: (_) => ReaderMoreSheet(
        onPreviousChapter: widget.onPreviousChapter,
        onNextChapter: widget.onNextChapter,
        onOpenSeries: widget.onOpenSeries,
        onBookmark: (widget.showBookmark &&
                widget.onAddBookmark != null &&
                !_engine.bookmarkPending)
            ? _engine.bookmark
            : null,
        showBookmark: widget.showBookmark,
      ),
    ).whenComplete(() {
      // Restart auto-hide once sheet is dismissed
      if (mounted) _engine.scheduleHideChrome();
    });
  }

  // ── Slots: today's decorations inside the strip ──────────────────────────

  static Widget _chapterSeam(
    BuildContext context,
    ReaderChapter chapter,
    Axis axis,
  ) =>
      ChapterSeam(title: chapter.title, axis: axis);

  /// Shared by both the network and on-device sources — the reader must not
  /// look different depending on which one served a page, only whether it
  /// loaded.
  static Widget _brokenPage(BuildContext context, VoidCallback retry) => Center(
        child: Padding(
          padding: EdgeInsets.all(context.space.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.broken_image_outlined, color: ReaderColors.muted),
              SizedBox(height: context.space.sm),
              Text(
                'Failed to load page',
                style: context.text.bodySm.copyWith(color: ReaderColors.muted),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.space.md),
              OutlinedButton(onPressed: retry, child: const Text('Retry')),
            ],
          ),
        ),
      );

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final direction =
        ref.watch(readerDefaultsProvider.select((d) => d.direction));
    final readerBackground =
        ref.watch(readerFilterProvider.select((f) => f.background));
    final engine = _engine;

    return ReaderShortcuts(
      onPreviousChapter: engine.previousChapter,
      onNextChapter: engine.nextChapter,
      onBookmark: engine.bookmark,
      onZoomIn: engine.zoomIn,
      onZoomOut: engine.zoomOut,
      onZoomReset: engine.resetZoom,
      child: Scaffold(
        backgroundColor: readerBackground.color,
        body: ReaderEngineView(
          controller: engine,
          feed: widget.feed,
          scrollStorageKey: widget.scrollStorageKey,
          onBack: widget.onBack,
          onOpenSeries: widget.onOpenSeries,
          initialPage: widget.initialPage,
          initialAnchor: widget.initialAnchor,
          showBookmark: widget.showBookmark,
          onSaveProgress: widget.onSaveProgress,
          onAddBookmark: widget.onAddBookmark,
          onPreviousChapter: widget.onPreviousChapter,
          onNextChapter: widget.onNextChapter,
          onReachedFeedEnd: widget.onReachedFeedEnd,
          onReachedFeedStart: widget.onReachedFeedStart,
          pageExtents: widget.pageExtents,
          bookmarkAnchors: widget.bookmarkAnchors,
          slots: ReaderSurfaceSlots(
            chapterSeam: _chapterSeam,
            brokenPage: _brokenPage,
            pagedCornerRadius: context.radii.sm,
          ),
          autoHideAfter: context.readerChrome.autoHideAfter,
          onEvent: _handleEvent,
          chromeBuilder: (context, state) => Stack(
            children: [
              // iOS has no system back-swipe inside the reader (the route is
              // a fade `CustomTransitionPage`, which bypasses
              // `PageTransitionsTheme`), and an iPhone has no hardware back
              // button — so once the controls auto-hide there is no visible
              // and no gestural way out. Hand the platform gesture back, but
              // only in vertical mode, where nothing else wants horizontal
              // drags. In LTR/RTL mode the page list itself pages on that
              // axis and the strip must not exist at all.
              ReaderEdgeBackGesture(
                enabled: direction.isVertical &&
                    Theme.of(context).platform == TargetPlatform.iOS,
                onBack: widget.onBack,
              ),
              // Dim + warmth filter — its own ConsumerWidget so brightness
              // drags repaint only this layer, never the page list.
              const ReaderFilterOverlay(),
              // Controls, edge-prompts, and page indicator live in their own
              // widget so toggling visibility never rebuilds the list.
              _ReaderControlsLayer(
                state: state,
                direction: direction,
                onBack: widget.onBack,
                onOpenSeries: widget.onOpenSeries,
                onMoreOptions: _showMoreOptions,
                onSeekToPage: engine.seekToPage,
                onPreviousChapter:
                    state.hasPrevious ? engine.previousChapter : null,
                onNextChapter: state.hasNext ? engine.nextChapter : null,
                showBookmark: widget.showBookmark,
                onBookmark:
                    (widget.showBookmark && widget.onAddBookmark != null)
                        ? engine.bookmark
                        : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Controls overlay (fed from the engine state, never from the page list)

class _ReaderControlsLayer extends StatelessWidget {
  const _ReaderControlsLayer({
    required this.state,
    required this.direction,
    required this.onBack,
    required this.onOpenSeries,
    required this.onMoreOptions,
    required this.onSeekToPage,
    required this.showBookmark,
    this.onBookmark,
    this.onPreviousChapter,
    this.onNextChapter,
  });

  /// Which chapter is on screen and where in it — everything the bars say.
  /// A feed-wide page number would be meaningless ("page 4 of 812") and a
  /// scrub rail spanning three hundred chapters would be unusable, so the
  /// chrome is always about the chapter under the reading line.
  final ReaderEngineState state;
  final ReadingDirection direction;
  final VoidCallback onBack;
  final VoidCallback onOpenSeries;
  final VoidCallback onMoreOptions;
  final ValueChanged<int> onSeekToPage;
  final bool showBookmark;
  final VoidCallback? onBookmark;
  final VoidCallback? onPreviousChapter;
  final VoidCallback? onNextChapter;

  @override
  Widget build(BuildContext context) {
    final hasPrevious = state.hasPrevious;
    final hasNext = state.hasNext;

    return Stack(
      children: [
        // Previous-chapter edge prompt
        if (!hasPrevious)
          const SizedBox.shrink()
        else
          Positioned(
            top: direction.isVertical ? 0 : null,
            bottom: direction.isVertical ? null : 96,
            left: 0,
            right: direction.isHorizontal ? null : 0,
            child: _AnimatedEdgePrompt(
              visible: state.atStart,
              child: ChapterEdgePrompt(
                label: 'Previous chapter',
                direction: EdgeDirection.previous,
                onTap: onPreviousChapter!,
              ),
            ),
          ),
        // Next-chapter edge prompt
        if (!hasNext)
          const SizedBox.shrink()
        else
          Positioned(
            top: direction.isVertical ? null : 96,
            bottom: direction.isVertical ? 96 : null,
            left: direction.isHorizontal ? null : 0,
            right: 0,
            child: _AnimatedEdgePrompt(
              visible: state.atEnd,
              child: ChapterEdgePrompt(
                label: 'Next chapter',
                direction: EdgeDirection.next,
                onTap: onNextChapter!,
              ),
            ),
          ),
        // Nothing is drawn over the reading area itself: the page counter that
        // used to float there sat on top of the artwork every time the controls
        // hid, which is exactly when the reader is looking at the page.
        // Top bar — back (top-left), title (opens the series), bookmark, settings.
        Align(
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () {},
            child: ReaderTopBar(
              // Names the chapter being READ, which in a continuous feed is
              // not always the one the reader opened.
              chapterTitle: state.chapterTitle,
              visible: state.chromeVisible,
              onBack: onBack,
              onOpenSeries: onOpenSeries,
              onSettings: onMoreOptions,
              onBookmark: showBookmark ? onBookmark : null,
            ),
          ),
        ),
        // Bottom bar — prev/next chapter, page indicator, scrub rail.
        Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: ReaderBottomBar(
              visiblePage: state.page,
              pageCount: state.pageCount,
              direction: direction,
              visible: state.chromeVisible,
              hasPrevious: hasPrevious,
              hasNext: hasNext,
              onSeekToPage: onSeekToPage,
              onPreviousChapter: onPreviousChapter,
              onNextChapter: onNextChapter,
              onSettings: onMoreOptions,
            ),
          ),
        ),
      ],
    );
  }
}

/// Fades and gently pops a chapter edge prompt in and out as the reader reaches
/// the start/end of a chapter, instead of letting it appear abruptly.
class _AnimatedEdgePrompt extends StatelessWidget {
  const _AnimatedEdgePrompt({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedScale(
        scale: visible ? 1.0 : 0.9,
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 240),
        curve: Curves.easeOutBack,
        child: AnimatedOpacity(
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
          opacity: visible ? 1.0 : 0.0,
          child: child,
        ),
      ),
    );
  }
}
