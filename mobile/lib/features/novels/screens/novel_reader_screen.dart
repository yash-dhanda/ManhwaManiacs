
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/app/router/routes.dart';
import 'package:manhwamaniacs/app/theme/app_colors.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/platform/system_ui.dart';
import 'package:manhwamaniacs/features/downloads/providers/open_chapter_scope.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/controllers/novel_reader_controller.dart';
import 'package:manhwamaniacs/features/novels/models/novel_chapter.dart';
import 'package:manhwamaniacs/features/novels/models/novel_palette.dart';
import 'package:manhwamaniacs/features/novels/models/novel_typography.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_audio_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_chapter_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_preferences_provider.dart';
import 'package:manhwamaniacs/features/novels/utils/novel_book.dart';
import 'package:manhwamaniacs/features/novels/utils/novel_progress.dart';
import 'package:manhwamaniacs/features/novels/utils/novel_speaking.dart';
import 'package:manhwamaniacs/features/novels/widgets/narration_save_button.dart';
import 'package:manhwamaniacs/features/novels/widgets/novel_audio_player.dart';
import 'package:manhwamaniacs/features/novels/widgets/novel_cast_panel.dart';
import 'package:manhwamaniacs/features/novels/widgets/novel_chapter_view.dart';
import 'package:manhwamaniacs/features/novels/widgets/novel_contents_sheet.dart';
import 'package:manhwamaniacs/features/novels/widgets/novel_reader_chrome.dart';
import 'package:manhwamaniacs/features/novels/widgets/novel_type_panel.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_series_navigation.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_wakelock.dart';
import 'package:manhwamaniacs/features/reader/widgets/reader_error_state.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';

/// The novel reader.
///
/// Identity is the same opaque `(sourceId, seriesKey, chapterKey)` triple as
/// the manga reader's, and [initialBucket] is the progress BUCKET (see
/// `utils/novel_progress.dart`) carried in the same `?page=` query parameter —
/// so a "Continue" link needs no novel-specific branch to build.
///
/// The logic (chapter, neighbours, progress, bookmark, restore, auto next)
/// lives in `NovelReaderController`; this screen only renders its state.
class NovelReaderScreen extends ConsumerWidget {
  const NovelReaderScreen({
    super.key,
    required this.sourceId,
    required this.seriesKey,
    required this.chapterKey,
    this.initialBucket = 1,
    this.initialParagraph,
    this.initialFraction,
  });

  final String sourceId;
  final String seriesKey;
  final String chapterKey;
  final int initialBucket;

  /// The exact paragraph (1-based) to open on — what tapping a bookmark
  /// hands over, and what [initialBucket] deliberately is not. A bucket is at
  /// worst ~1% of the chapter; a bookmark is a line.
  ///
  /// When set it wins over [initialBucket]: the reader asked for one place.
  final int? initialParagraph;

  /// How far into [initialParagraph], 0.0–1.0. A long paragraph on a phone is
  /// several screens, so its top is not the same place as its middle.
  final double? initialFraction;

  NovelChapterKey get _key =>
      (sourceId: sourceId, seriesKey: seriesKey, chapterKey: chapterKey);

  NovelReaderArgs get _args => NovelReaderArgs(
        sourceId: sourceId,
        seriesKey: seriesKey,
        chapterKey: chapterKey,
        initialBucket: initialBucket,
        initialParagraph: initialParagraph,
        initialFraction: initialFraction,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(novelReaderControllerProvider(_args));
    final chapterAsync = controller.chapterValue;

    void retry() {
      // The payload is its own cache entry; invalidating only the resolved
      // provider would re-read its stored error and do nothing visible.
      ref.invalidate(novelChapterPayloadProvider(_key));
      ref.invalidate(resolvedNovelChapterProvider(_key));
    }

    void back() =>
        leaveReader(context, sourceId: sourceId, seriesKey: seriesKey);

    // The Android back gesture and the hardware key never reach the chrome's
    // button — they go to the router, which for this top-level route has
    // nothing to pop after a chapter change and would close the app instead.
    // This is what routes them through the same exit as everything else.
    //
    // Unconditionally `canPop: false` rather than `context.canPop()`: this
    // route is either the whole stack or not depending on how the reader was
    // reached, the two answers disagree for the frame a chapter change is
    // fading out, and a back pressed in that frame is precisely the one that
    // must not be wrong. [leaveReader] pops for itself when it can, so the
    // destination is identical either way.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        back();
      },
      child: chapterAsync.when(
        loading: () => const _NovelReaderSkeleton(),
        error: (error, _) {
          final appError = error is AppError
              ? error
              : UnknownError(message: error.toString(), cause: error);
          return ReaderErrorState(
            error: appError,
            onRetry: retry,
            onBack: back,
          );
        },
        data: (chapter) {
          if (chapter.paragraphs.isEmpty) {
            return ReaderErrorState(
              error: const UnknownError(message: 'This chapter has no text.'),
              onRetry: retry,
              onBack: back,
            );
          }
          return OpenChapterScope(
            chapterId: (
              sourceId: sourceId,
              seriesKey: seriesKey,
              chapterKey: chapterKey,
            ),
            child: _NovelReaderBody(
              key: ValueKey('$sourceId:$seriesKey:$chapterKey'),
              chapter: chapter,
              args: _args,
            ),
          );
        },
      ),
    );
  }
}

class _NovelReaderBody extends ConsumerStatefulWidget {
  const _NovelReaderBody({
    super.key,
    required this.chapter,
    required this.args,
  });

  final NovelChapter chapter;
  final NovelReaderArgs args;

  @override
  ConsumerState<_NovelReaderBody> createState() => _NovelReaderBodyState();
}

class _NovelReaderBodyState extends ConsumerState<_NovelReaderBody>
    implements NovelReadingSurface {
  final _scrollController = ScrollController();
  late List<GlobalKey> _paragraphKeys;

  bool _chromeVisible = false;

  /// The progress bucket, as a notifier rather than a field.
  ///
  /// Buckets are 1% of a chapter (kMaxProgressBuckets = 100) and the scroll
  /// debounce fires every 500 ms, so during ordinary reading the bucket changes
  /// on nearly every tick. As setState that rebuilt the whole body — the
  /// CustomScrollView and every built paragraph — about twice a second, for the
  /// entire session. Only the chrome's percent actually depends on it.
  final ValueNotifier<int> _bucket = ValueNotifier<int>(1);

  /// Which words the voice is on. The same argument as [_bucket], one order of
  /// magnitude worse: the playhead ticks many times a second where the
  /// progress bucket moved twice, so it must never reach `setState`.
  late final NovelAudioFollower _follower;

  /// The paragraph follow-scroll last moved to, so a new sentence inside the
  /// paragraph already on screen does not re-aim the viewport.
  int _followedParagraph = -1;

  /// A save is in flight; the chrome's bookmark button is disabled meanwhile
  /// so a double tap cannot make two bookmarks of one spot.
  bool _bookmarkPending = false;

  /// Resolved once, while the element is alive, because [dispose] has to
  /// release it and cannot ask for it there (`ref` is unusable in `dispose`).
  late final ReaderWakelock _wakelock;
  late final NovelReaderController _controller;
  ProviderSubscription<NovelReaderState>? _sub;

  NovelChapter get _chapter => widget.chapter;

  /// The chapter to continue into, from whichever source knows it: the
  /// online payload carries its own, a disk copy learns it out of band.
  String? get _nextKey =>
      ref.read(novelReaderControllerProvider(widget.args)).nextKey ?? _chapter.nextChapterKey;

  String? get _previousKey =>
      ref.read(novelReaderControllerProvider(widget.args)).prevKey ?? _chapter.previousChapterKey;

  @override
  void initState() {
    super.initState();
    _wakelock = ref.read(readerWakelockProvider);
    _controller = ref.read(novelReaderControllerProvider(widget.args).notifier)
      ..attach(this)
      ..seamless = false
      ..locationReplacer = _openChapter;
    _paragraphKeys = List.generate(
      _chapter.paragraphs.length,
      (_) => GlobalKey(),
    );
    _follower = NovelAudioFollower(_chapter.paragraphs);
    _controller.narrationBusy =
        () => _follower.range.value != null || _follower.voicing.value;
    _follower.range.addListener(_onSpeakingChanged);
    _follower.voicing.addListener(_onVoicingChanged);
    _scrollController.addListener(_controller.onScrolled);
    // Only the percent and the stale-anchor note depend on the controller here.
    _sub = ref.listenManual<NovelReaderState>(
      novelReaderControllerProvider(widget.args),
      (previous, next) {
        if (next.readingBucket != _bucket.value) {
          _bucket.value = next.readingBucket;
        }
        if (next.stale && !(previous?.stale ?? false)) _reportStaleAnchor();
      },
    );
    applyReadingSystemUiMode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyWakelock();
      _controller.beginRestore();
    });
  }

  @override
  void dispose() {
    _sub?.close();
    _controller
      ..detach(this)
      ..locationReplacer = null;
    _scrollController.dispose();
    _bucket.dispose();
    _follower.range.removeListener(_onSpeakingChanged);
    _follower.voicing.removeListener(_onVoicingChanged);
    _follower.dispose();
    // Symmetric with initState: leaving a chapter restores exactly what the
    // app launched with rather than permanently changing its shape.
    applyRestingSystemUiMode();
    _wakelock.disable();
    super.dispose();
  }

  void _applyWakelock() {
    final keepAwake = ref.read(readerDefaultsProvider).keepScreenAwake;
    keepAwake ? _wakelock.enable() : _wakelock.disable();
  }

  // ── NovelReadingSurface ──────────────────────────────────────────────────

  RenderBox? _boxFor(int paragraphIndex) {
    if (paragraphIndex < 0 || paragraphIndex >= _paragraphKeys.length) {
      return null;
    }
    final context = _paragraphKeys[paragraphIndex].currentContext;
    final box = context?.findRenderObject();
    return box is RenderBox && box.hasSize ? box : null;
  }

  double _viewportTop() {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return 0;
    return box.localToGlobal(Offset.zero).dy;
  }

  /// The line a reader is actually reading on — a quarter of the way down,
  /// not the top edge, where the paragraph is half clipped.
  double _readingLine() =>
      _viewportTop() + MediaQuery.sizeOf(context).height * widget.args.readingLineFraction;

  @override
  bool get atEnd {
    if (!_scrollController.hasClients) return false;
    final position = _scrollController.position;
    return position.pixels >= position.maxScrollExtent - 8;
  }

  @override
  double get maxExtent =>
      _scrollController.hasClients ? _scrollController.position.maxScrollExtent : 0;

  @override
  void jumpEstimate(double fraction) {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    _scrollController.jumpTo((max * fraction).clamp(0.0, max));
  }

  @override
  bool landOn(int index, double fraction, {required bool toReadingLine}) {
    if (!mounted || !_scrollController.hasClients) return true; // nothing to aim at
    final box = _boxFor(index);
    if (box == null) return false;
    final position = _scrollController.position;
    final anchorPoint =
        box.localToGlobal(Offset.zero).dy + fraction * box.size.height;
    final reference = toReadingLine ? _readingLine() : _viewportTop();
    _scrollController.jumpTo(
      (position.pixels + anchorPoint - reference).clamp(0.0, position.maxScrollExtent),
    );
    return true;
  }

  /// The exact reading position: which paragraph is under the reading line,
  /// and how far into it that line falls.
  ///
  /// Only the paragraphs the list has actually built have offsets to measure
  /// — the handful on screen — which is exactly the set the reading line can
  /// be in. `null` when nothing is laid out yet.
  ///
  /// The fraction is of the paragraph's own height and is not pixels: the
  /// same paragraph is three lines on a tablet and nine on a phone, so a
  /// pixel offset would name a different sentence on each.
  @override
  ({int index, double fraction})? anchorAtReadingLine() {
    if (!mounted || !_scrollController.hasClients) return null;
    final readingLine = _readingLine();
    final attached = <int>[];
    final offsets = <double>[];
    for (var i = 0; i < _paragraphKeys.length; i++) {
      final box = _boxFor(i);
      if (box == null) continue;
      attached.add(i);
      offsets.add(box.localToGlobal(Offset.zero).dy);
    }
    if (attached.isEmpty) return null;
    final pick = activeParagraphIndex(offsets, readingLine);
    final index = attached[pick];
    final height = _boxFor(index)?.size.height ?? 0;
    final fraction = height <= 0
        ? 0.0
        : ((readingLine - offsets[pick]) / height).clamp(0.0, 1.0);
    return (index: index, fraction: fraction);
  }

  /// Tell the reader, once and quietly, that the paragraph the bookmark named
  /// no longer exists and they have been put on the last one that does.
  ///
  /// Never a failure: the chapter opened and is readable. What would be wrong
  /// is landing somewhere else in silence, which reads as the app having lost
  /// their place.
  void _reportStaleAnchor() {
    final requested = widget.args.initialParagraph;
    final available = _chapter.paragraphs.length;
    if (requested == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This chapter changed — opened at paragraph $available '
            'instead of $requested.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  // ── Bookmark ─────────────────────────────────────────────────────────────

  /// Save the exact spot being read, in ONE action.
  ///
  /// Nothing is asked for — the paragraph, the point within it and the
  /// chapter's paragraph count are all things the controller already knows.
  Future<void> _handleBookmark() async {
    if (_bookmarkPending) return;
    final percent = _controller.bookmarkPercent();
    setState(() => _bookmarkPending = true);
    try {
      final result = await _controller.bookmark();
      if (!mounted || result != NovelBookmarkResult.saved || !context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            percent == null
                ? 'Bookmark saved'
                : 'Bookmarked at $percent% of this chapter',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _bookmarkPending = false);
    }
  }

  // ── Seamless continuation ────────────────────────────────────────────────

  /// Continue into the next chapter, saying first that this one is finished.
  ///
  /// Every way forward comes through here — the foot's button, the chrome's
  /// and auto-next — and nothing else: Previous and a jump from Contents are
  /// not the reader finishing this chapter, so they use [_openChapter]
  /// directly and leave its progress as the scroll left it.
  void _openNextChapter() => _controller.next();

  void _openChapter(String chapterKey) {
    // `go`, not `push`: continuing a book replaces the chapter rather than
    // stacking one on top of the last, so Back always leaves the reader
    // instead of walking backwards through everything just read.
    context.go(
      RoutePaths.novelReader(
        _chapter.sourceId,
        _chapter.seriesKey,
        chapterKey,
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  NovelSurfaceColors _surface(BuildContext context) {
    final stored = ref.watch(novelPaletteControllerProvider);
    final choice = NovelPalettes.resolveChoice(
      stored,
      appIsDark: Theme.of(context).brightness == Brightness.dark,
    );
    final palette = NovelPalettes.byId(choice);
    if (palette != null) return NovelSurfaceColors.fromPalette(palette);
    // "Follow app theme": inherit the app's own tokens rather than painting a
    // surface, so one rendering path covers both cases.
    final colors = context.colors;
    return NovelSurfaceColors(
      bg: colors.bg,
      ink: colors.fg,
      muted: colors.muted,
      isDark: Theme.of(context).brightness == Brightness.dark,
    );
  }

  /// The player, in the chrome rather than at the foot of the prose.
  ///
  /// It used to be a sliver after the last paragraph, which is where the
  /// reported bug lived: chapters run to eighty-odd paragraphs, so a reader
  /// who had not scrolled to the very end had no way to know a voice existed
  /// at all. The chrome is the one surface this screen already teaches a
  /// reader to reveal.
  ///
  /// Taking it out of the scroll view also removes a latent bug: the bar
  /// arrived after first paint and grew `maxScrollExtent` under a reader
  /// already sitting at the chapter end, which perturbed [_atEnd] and so
  /// auto-next's timing.
  ///
  /// A separate request from the prose and never awaited in front of it:
  /// almost nothing in the library is rendered, so a reader must not wait on
  /// a lookup that usually answers "no".
  Widget _audioBar(NovelSurfaceColors surface) {
    final chapter = widget.chapter;
    return Consumer(
      builder: (context, ref, _) {
        final key = (
          sourceId: chapter.sourceId,
          seriesKey: chapter.seriesKey,
          chapterKey: chapter.chapterKey,
        );
        // The phone's copy first: it plays with no network, and the timing
        // map saved with it is the one those exact bytes were rendered with.
        final playable = ref.watch(playableNovelAudioProvider(key)).valueOrNull;
        if (playable == null) return const SizedBox.shrink();
        final audio = playable.audio;
        final target = NarrationTarget(
          key: key,
          audio: audio,
          file: playable.file?.path,
          paragraphs: chapter.paragraphs,
          bookTitle: chapter.title,
          chapterNumber: chapter.chapterNumber,
          chapterTitle: chapter.title,
        );
        return ColoredBox(
          // Opaque for the same reason the chrome's own bars are: prose has to
          // stop showing through a control for it to read as one.
          color: surface.bg,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
            child: Row(
              children: [
                Expanded(
                  child: NovelAudioPlayerBar(
                    target: target,
                    muted: surface.muted,
                    rule: surface.rule,
                    onPosition: (ms) => _follower.onPosition(ms, audio),
                  ),
                ),
                NarrationSaveButton(
                  chapter: key,
                  color: surface.muted,
                  chapterNumber: chapter.chapterNumber,
                  title: chapter.title,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// The voice started or stopped, lit or not. Stopping is where a chapter
  /// listened to WITHOUT follow-along gets to continue: its range never
  /// moves, so [_onSpeakingChanged] never hears of it.
  void _onVoicingChanged() {
    if (!_follower.voicing.value) _controller.maybeScheduleAutoNext();
  }

  /// The voice moved to another paragraph, or stopped.
  void _onSpeakingChanged() {
    final range = _follower.range.value;
    if (range == null) {
      _followedParagraph = -1;
      // The voice stopped. [_maybeScheduleAutoNext] refuses to fire while it
      // is reading, so this is where a chapter finished by LISTENING rather
      // than by scrolling gets to continue.
      _controller.maybeScheduleAutoNext();
      return;
    }
    if (range.paragraph == _followedParagraph) return;
    // -1 means nothing has been followed since the voice last stopped, so
    // this is the first sentence of a fresh press of play.
    final starting = _followedParagraph < 0;
    _followedParagraph = range.paragraph;
    _followScroll(range.paragraph, starting: starting);
  }

  /// Bring the spoken paragraph into view, and otherwise leave the scroll
  /// alone.
  ///
  /// Two behaviours, because starting playback and continuing it are different
  /// requests. Pressing play means "read me THIS", wherever the reader happens
  /// to be sitting — a listener who resumes a chapter at 60% and hears the
  /// voice start from the top needs the page to go with it. After that it is
  /// the web's `block: "nearest"`: a reader who has scrolled ahead to see what
  /// happens must not be yanked back on every sentence.
  ///
  /// When it does move it aims at the reading line — the same reference
  /// [_anchorAtReadingLine] measures against — so listening and reading agree
  /// about where "here" is, and a bookmark taken while listening round-trips.
  void _followScroll(int paragraph, {required bool starting}) {
    if (_controller.restoring) return;
    if (!mounted || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    // Never fight a finger, or our own in-flight animation.
    if (!starting && position.isScrollingNotifier.value) return;

    final box = _boxFor(paragraph);
    if (box == null) {
      // Far enough off screen that the list has not built it. Only worth
      // crossing that distance on a deliberate press of play; mid-chapter it
      // would mean the reader had scrolled away on purpose.
      if (!starting) return;
      // The restore machinery already knows how to reach an unbuilt paragraph:
      // jump to where it is estimated to be, let the list build, measure, and
      // land exactly. Reusing it beats a second, less-tested guess.
      _controller.jumpToParagraph(paragraph);
      return;
    }

    final top = box.localToGlobal(Offset.zero).dy;
    final bottom = top + box.size.height;
    final line = _readingLine();
    // A paragraph taller than the screen never "fits", so being ON it means
    // the reading line is inside it — which is what progress means by it too.
    if (top <= line && bottom > line) return;
    if (!starting) {
      final viewportTop = _viewportTop();
      if (top >= viewportTop &&
          bottom <= viewportTop + MediaQuery.sizeOf(context).height) {
        return;
      }
    }
    _scrollController.animateTo(
      (position.pixels + top - line).clamp(0.0, position.maxScrollExtent),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final chapter = widget.chapter;
    _controller.autoNext = ref.watch(readerDefaultsProvider).autoNextChapter;
    final surface = _surface(context);
    final prefsKey = novelSeriesPrefsKey(chapter.sourceId, chapter.seriesKey);
    final prefs = ref.watch(novelPreferencesControllerProvider(prefsKey));
    final width = MediaQuery.sizeOf(context).width;
    final column = novelColumnWidth(
      measure: prefs.measure,
      fontSize: prefs.fontSize,
      available: width - 40,
    );

    return Scaffold(
      backgroundColor: surface.bg,
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => setState(() => _chromeVisible = !_chromeVisible),
            child: Scrollbar(
              controller: _scrollController,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: (width - column) / 2,
                    ),
                    sliver: SliverList.list(
                      children: [
                        SizedBox(height: MediaQuery.paddingOf(context).top + 72),
                        _ChapterHeading(
                          chapter: chapter,
                          surface: surface,
                          preferences: prefs,
                          onListen: () {
                            if (!_chromeVisible) {
                              setState(() => _chromeVisible = true);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: (width - column) / 2,
                    ),
                    sliver: NovelChapterView(
                      paragraphs: chapter.paragraphs,
                      palette: surface,
                      preferences: prefs,
                      paragraphKeys: _paragraphKeys,
                      speaking: _follower.range,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _ChapterFoot(
                      chapter: chapter,
                      surface: surface,
                      onNext: _nextKey == null ? null : _openNextChapter,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Only the percent depends on the bucket, so only this subtree
          // rebuilds when it moves — the paragraph list underneath does not.
          ValueListenableBuilder<int>(
            valueListenable: _bucket,
            // The player goes through `child`, not the builder: this fires on
            // nearly every progress tick, and rebuilding a slider and a speed
            // menu because a percent moved is the cost [_bucket] exists to
            // avoid in the first place.
            child: _audioBar(surface),
            builder: (context, bucket, child) => NovelReaderChrome(
              audio: child,
              visible: _chromeVisible,
              surface: surface,
              title: chapter.title,
              percent: chapterPercent(bucket, chapter.buckets),
              isOffline: chapter.isOffline,
              onBack: () => leaveReader(
                context,
                sourceId: chapter.sourceId,
                seriesKey: chapter.seriesKey,
              ),
              onPrevious: _previousKey == null
                  ? null
                  : () => _openChapter(_previousKey!),
              onNext: _nextKey == null ? null : _openNextChapter,
              onContents: () => NovelContentsSheet.show(
                context,
                sourceId: chapter.sourceId,
                seriesKey: chapter.seriesKey,
                currentChapterKey: chapter.chapterKey,
                surface: surface,
                onOpen: _openChapter,
              ),
              onBookmark: _bookmarkPending ? null : _handleBookmark,
              onCast: () => NovelCastPanel.show(
                context,
                chapter: (
                  sourceId: chapter.sourceId,
                  seriesKey: chapter.seriesKey,
                  chapterKey: chapter.chapterKey,
                ),
                surface: surface,
              ),
              onType: () => NovelTypePanel.show(
                context,
                seriesPrefsKey: prefsKey,
                surface: surface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The chapter's own front matter: number, title, length. Set as a book sets a
/// chapter opening — centred, with real air under it, so the first paragraph
/// starts on a clean page rather than immediately under a heading.
class _ChapterHeading extends StatelessWidget {
  const _ChapterHeading({
    required this.chapter,
    required this.surface,
    required this.preferences,
    required this.onListen,
  });

  final NovelChapter chapter;
  final NovelSurfaceColors surface;
  final NovelPreferences preferences;

  /// Reveal the controls, where the player is. Deliberately not a second
  /// player: [NovelAudioPlayerBar] owns the platform handle and must not be
  /// mounted twice.
  final VoidCallback onListen;

  @override
  Widget build(BuildContext context) {
    final stack = novelFontStack(preferences.fontFamily);
    final number = chapter.chapterNumber;
    return Padding(
      padding: const EdgeInsets.only(bottom: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (number != null)
            Text(
              'Chapter ${formatChapterNumber(number)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 2.4,
                fontWeight: FontWeight.w600,
                color: surface.muted,
              ),
            ),
          const SizedBox(height: 10),
          Text(
            chapter.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: stack.first,
              fontFamilyFallback: stack.sublist(1),
              fontSize: preferences.fontSize * 1.55,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: surface.ink,
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Container(width: 48, height: 1, color: surface.rule),
          ),
          const SizedBox(height: 14),
          Text(
            formatChapterLength(chapter.wordCount) ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: surface.muted),
          ),
          // Listening is offered at the TOP of the chapter, where somebody
          // deciding how to read it actually is. The player lives in the
          // chrome behind a tap, which is fine once you know it is there and
          // useless before: a chapter with a voice looked identical to one
          // without.
          //
          // Its own Consumer rather than a callback threaded down from the
          // body — the heading rebuilds only when the chapter changes, and
          // this lookup answers "no" for almost the whole library.
          Consumer(
            builder: (context, ref, _) {
              final key = (
                sourceId: chapter.sourceId,
                seriesKey: chapter.seriesKey,
                chapterKey: chapter.chapterKey,
              );
              final playable =
                  ref.watch(playableNovelAudioProvider(key)).valueOrNull;
              if (playable == null) return const SizedBox.shrink();
              final note =
                  novelFollowAlongNote(playable.audio, chapter.paragraphs);
              return Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Column(
                  children: [
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: onListen,
                        icon: const Icon(Icons.headphones_rounded, size: 18),
                        // "saved" so a chapter says it will play with the
                        // network off before anybody tries it on a plane.
                        label: Text(
                          'Listen to this chapter'
                          '${_spoken(playable.audio.totalMs)}'
                          '${playable.file != null ? ' · saved' : ''}',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: surface.ink,
                          side: BorderSide(color: surface.rule),
                        ),
                      ),
                    ),
                    if (note != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          note,
                          key: const Key('novel-audio-only-note'),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: surface.muted),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// " · 13 min", or nothing when the render carried no timing map.
  String _spoken(int totalMs) {
    if (totalMs <= 0) return '';
    final minutes = (totalMs / 60000).round();
    return minutes <= 0 ? '' : ' · $minutes min';
  }
}

class _ChapterFoot extends StatelessWidget {
  const _ChapterFoot({
    required this.chapter,
    required this.surface,
    required this.onNext,
  });

  final NovelChapter chapter;
  final NovelSurfaceColors surface;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        48,
        24,
        MediaQuery.paddingOf(context).bottom + 72,
      ),
      child: Column(
        children: [
          Container(width: 48, height: 1, color: surface.rule),
          const SizedBox(height: 24),
          if (onNext != null)
            OutlinedButton(
              onPressed: onNext,
              style: OutlinedButton.styleFrom(
                foregroundColor: surface.ink,
                side: BorderSide(color: surface.rule),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
              child: const Text('Next chapter'),
            )
          else
            Text(
              chapter.isOffline
                  ? 'End of the downloaded copy'
                  : 'End of the book, for now',
              style: TextStyle(fontSize: 13, color: surface.muted),
            ),
        ],
      ),
    );
  }
}

class _NovelReaderSkeleton extends StatelessWidget {
  const _NovelReaderSkeleton();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: NovelPalettes.dusk.bg,
        body: Center(
          child: CircularProgressIndicator(color: NovelPalettes.dusk.muted),
        ),
      );

}
