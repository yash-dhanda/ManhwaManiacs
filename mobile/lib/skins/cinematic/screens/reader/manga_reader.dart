import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/ocr/providers/ocr_providers.dart';
import 'package:manhwamaniacs/features/reader/engine/next_chapter_auto_queue.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_options.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_state.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_view.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_frames.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_surface_slots.dart';
import 'package:manhwamaniacs/features/reader/engine/tap_classifier.dart';
import 'package:manhwamaniacs/features/reader/engine/zoom_math.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/models/reader_prefs.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_prefs_provider.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_profile_settings.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_ui_provider.dart';
import 'package:manhwamaniacs/features/reader/utils/auto_scroll_speed.dart';
import 'package:manhwamaniacs/features/reader/utils/time_left.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/navigation.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_rating_card.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toast_host.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/chapter_download_control.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/cine_reader_route.dart' show cineReaderOwnsToastsProvider;
import 'package:manhwamaniacs/skins/cinematic/screens/reader/contents_list.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/contents_panel.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/contents_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/credits.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/edge_hud.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/end_states.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/folio_bar.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/image_layers.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/jump_to_page_field.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/micro_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/page_states.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_chrome.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_entry.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_gestures.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_keys.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_series.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_system_ui.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_taps.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/running_head.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/side_panel_layout.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/strip_bands.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/zoom_chip.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

/// A chapter title typed at the top-left after a committed pull to continue, carried across the
/// route change (`CH 143 — The Return`).
final pendingChapterCaptionProvider = StateProvider<String?>((ref) => null, name: 'pendingChapterCaption');

/// The Cinematic manga reader (cinematic 8.14): chrome on the shared reader engine. It takes the
/// resolved reader body of `ReaderScreen` or `SourceReaderScreen` (the same feed, the same
/// callbacks) and renders the running head, the folio bar with the ruler, the strip's bands and
/// credits, the Contents, the gestures and the keys.
class CineMangaReader extends ConsumerStatefulWidget {
  const CineMangaReader({super.key, required this.body});

  final ReaderFrameBody body;

  @override
  ConsumerState<CineMangaReader> createState() => _CineMangaReaderState();
}

class _CineMangaReaderState extends ConsumerState<CineMangaReader> {
  final ReaderEngine _engine = ReaderEngine();
  final FocusScopeNode _chromeScope = FocusScopeNode(debugLabel: 'reader chrome');
  final FocusNode _surface = FocusNode(debugLabel: 'reader surface');
  final GlobalKey<PageCounterFieldState> _counter = GlobalKey();
  final LockCounter _lock = LockCounter();
  final PaceTracker _pace = PaceTracker();
  final ValueNotifier<double> _swipeDx = ValueNotifier<double>(0);
  final DateTime _openedAt = DateTime.now();
  late final NextChapterAutoQueue _autoQueue = NextChapterAutoQueue();
  late final HudHold _brightnessHud = HudHold(_repaint);
  late final HudHold _speedHud = HudHold(_repaint);

  Timer? _chipTimer, _retryTimer;
  bool _chipVisible = false;
  bool _cinema = false;
  bool _resumeAuto = false;
  int _retryStep = 0;
  int? _brightnessDraft;
  double? _speedDraft;
  String? _lastChapterId;
  double _lastZoom = 1;
  bool _lastChrome = true;
  bool _lastAuto = false;
  ({ReaderNextState next, bool hasNext, int loaded}) _footerKey = (next: ReaderNextState.none, hasNext: false, loaded: 0);
  FurtherElsewhere? _shownFurther;
  ReaderSystemUi? _appliedUi;
  String? _caption;
  bool _ratingShown = false;

  ReaderFrameBody get _body => widget.body;
  ({String sourceId, String seriesKey, String chapterKey, ReaderOrigin origin}) get _id => _body.identity!;
  String get _seriesRef => '${_id.sourceId}:${_id.seriesKey}';
  ReaderSeriesKey get _seriesKey => (sourceId: _id.sourceId, seriesKey: _id.seriesKey);
  TargetPlatform get _platform => Theme.of(context).platform;
  bool get _reduced => CineMotion.reduced(context);

  /// A rebuild the engine asked for: never inside the frame's own build (the engine publishes from
  /// its `initState`).
  void _repaint() {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  late final StateController<bool> _toastOwner = ref.read(cineReaderOwnsToastsProvider.notifier);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      try {
        _toastOwner.state = true;
      } catch (_) {}
    });
    _engine.addListener(_onEngine);
    _engine.chapterCompleted.listen(_onCompleted);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final prefs = ref.read(readerPrefsProvider(_seriesRef));
      _cinema = prefs.cinema;
      ref.read(readerUiProvider.notifier).setZoom(prefs.zoom);
      if (_reduced) ref.read(readerUiProvider.notifier).stopAutoScroll();
      unawaited(ref.read(readerPrefsMigrationProvider.future));
      _applyUi(ReaderUiPhase.enter);
      if (_cinema) _engine.hideChrome();
      _surface.requestFocus();
      _announce(_engine.value);
      final caption = ref.read(pendingChapterCaptionProvider);
      if (caption != null) {
        ref.read(pendingChapterCaptionProvider.notifier).state = null;
        setState(() => _caption = caption);
        Timer(context.cine.durHoldBrief, () {
          if (mounted) setState(() => _caption = null);
        });
      }
    });
    _chromeScope.addListener(() {
      if (_chromeScope.hasFocus) {
        _engine.holdChrome();
      } else {
        _engine.scheduleHideChrome();
      }
    });
  }

  @override
  void dispose() {
    _chipTimer?.cancel();
    _retryTimer?.cancel();
    _brightnessHud.dispose();
    _speedHud.dispose();
    _swipeDx.dispose();
    _chromeScope.dispose();
    _surface.dispose();
    _engine.removeListener(_onEngine);
    _engine.dispose();
    Future.microtask(() {
      try {
        _toastOwner.state = false;
      } catch (_) {}
    });
    unawaited(applyReaderSystemUi(readerSystemUi(defaultTargetPlatform, ReaderUiPhase.exit)));
    super.dispose();
  }

  // ── Engine signals ────────────────────────────────────────────────────────

  void _applyUi(ReaderUiPhase phase) {
    final ui = readerSystemUi(_platform, phase);
    if (ui == _appliedUi) return;
    _appliedUi = ui;
    unawaited(applyReaderSystemUi(ui));
  }

  void _onEngine() {
    final s = _engine.value;
    if (s.chapterId.isNotEmpty && s.chapterId != _lastChapterId) {
      _lastChapterId = s.chapterId;
      _announce(s);
    }
    if (s.chromeVisible != _lastChrome) {
      _lastChrome = s.chromeVisible;
      _applyUi(s.chromeVisible ? ReaderUiPhase.chromeShown : ReaderUiPhase.chromeHidden);
      if (!s.chromeVisible && _chromeScope.hasFocus) _surface.requestFocus();
    }
    if (s.zoom != _lastZoom) {
      _lastZoom = s.zoom;
      _showChip();
    }
    if (s.page > 0 && s.pageCount > 0) _pace.sample(s.page, DateTime.now());
    final key = (next: s.nextState, hasNext: s.hasNext, loaded: s.loadedChapterIds.length);
    if (key != _footerKey) {
      _footerKey = key;
      _onNextState(s);
      _repaint();
    }
    if (s.furtherElsewhere != null && s.furtherElsewhere != _shownFurther) {
      _shownFurther = s.furtherElsewhere;
      _offerJump(s.furtherElsewhere!);
    }
    if (_lastAuto && !s.autoScrolling && s.atEnd && s.nextState != ReaderNextState.loading) {
      _engine.showChrome();
      cineFeedback(context, HapticEvent.autoscrollEnd);
    }
    _lastAuto = s.autoScrolling;
  }

  void _onCompleted(ChapterRef done) {
    if (!mounted) return;
    cineFeedback(context, HapticEvent.chapterComplete, sound: SoundEvent.chapterComplete);
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (mounted) cineFeedback(context, HapticEvent.tapSecondary);
    });
  }

  void _onNextState(ReaderEngineState s) {
    _retryTimer?.cancel();
    if (s.nextState == ReaderNextState.failed) {
      const backoff = [2, 4, 8, 16, 30];
      final wait = backoff[math.min(_retryStep, backoff.length - 1)];
      _retryStep++;
      _retryTimer = Timer(Duration(seconds: wait), () {
        if (mounted) unawaited(_body.onReachedFeedEnd?.call());
      });
    } else {
      _retryStep = 0;
    }
    if (s.autoScrolling && s.nextState == ReaderNextState.loading) {
      _resumeAuto = true;
      _engine.toggleAutoScroll();
    } else if (_resumeAuto && s.nextState != ReaderNextState.loading) {
      _resumeAuto = false;
      _engine.toggleAutoScroll();
    }
  }

  void _announce(ReaderEngineState s) {
    if (s.chapterId.isEmpty) return;
    final series = ref.read(readerSeriesProvider(_seriesKey));
    final chapter = series?.chapterOf(s.chapterId);
    final number = chapter?.number;
    final head = number == null ? 'Chapter' : 'Chapter ${chapterNumberText(number)}';
    final title = s.chapterTitle.isNotEmpty && !s.chapterTitle.toLowerCase().startsWith('chapter') ? ', ${s.chapterTitle}' : '';
    final tail = series == null ? '' : ' · ${series.title}';
    // ignore: deprecated_member_use
    unawaited(SemanticsService.announce('$head$title$tail', Directionality.of(context)));
  }

  void _showChip() {
    _chipTimer?.cancel();
    setState(() => _chipVisible = true);
    _chipTimer = Timer(context.cine.durHoldChip, () {
      if (mounted) setState(() => _chipVisible = false);
    });
  }

  void _offerJump(FurtherElsewhere f) {
    final series = ref.read(readerSeriesProvider(_seriesKey));
    final ch = series?.chapterOf(f.chapterKey);
    final label = chapterFolio(f.chapterNumber ?? ch?.number);
    ref.read(cineToastsProvider.notifier).action(
      "You're further ahead on another device ($label, p.${f.lastPage}). Jump there?",
      label: 'Jump',
      onAction: () => _goToChapter(f.chapterKey, page: f.lastPage),
    );
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  String _location(String chapterKey, {int? page}) => switch (_id.origin) {
        ReaderOrigin.manifest => ReaderTarget.manifest(_id.sourceId, _id.seriesKey, chapterKey, page: page).location,
        ReaderOrigin.source => ReaderTarget.source(_id.sourceId, _id.seriesKey, chapterKey, page: page).location,
      };

  /// Between chapters is a Dip, never a wipe.
  void _goToChapter(String chapterKey, {int? page}) {
    if (!mounted) return;
    context.go(_location(chapterKey, page: page), extra: <String, String>{'entry': ReaderEntry.dip.name});
  }

  void _leave() => leaveReaderByDip(context, sourceId: _id.sourceId, seriesKey: _id.seriesKey);

  void _openSeries() => _body.onOpenSeries();

  void _stepChapter({required bool forward}) {
    final s = _engine.value;
    final target = s.chapterIndex + (forward ? 1 : -1);
    if (target >= 0 && target < s.loadedChapterIds.length) {
      cineFeedback(context, forward ? HapticEvent.chapterNext : HapticEvent.tapSecondary, sound: forward ? SoundEvent.chapterNext : null);
      _engine.seekToChapter(target);
      return;
    }
    if (forward) {
      cineFeedback(context, HapticEvent.chapterNext, sound: SoundEvent.chapterNext);
      final next = ref.read(readerSeriesProvider(_seriesKey))?.nextOf(s.chapterId);
      if (_body.onNextChapter != null) {
        _body.onNextChapter!();
      } else if (next != null) {
        _goToChapter(next.id);
      }
    } else {
      final prev = ref.read(readerSeriesProvider(_seriesKey))?.previousOf(s.chapterId);
      if (_body.onPreviousChapter != null) {
        _body.onPreviousChapter!();
      } else if (prev != null) {
        _goToChapter(prev.id);
      }
    }
  }

  // ── Taps ──────────────────────────────────────────────────────────────────

  void _onTap(ReaderTapInfo info) {
    final s = _engine.value;
    final prefs = ref.read(readerPrefsProvider(_seriesRef));
    if (s.locked) {
      if (_lock.tap(info.position, info.size, DateTime.now()) == LockResult.unlocked) {
        ref.read(readerUiProvider.notifier).setLocked(false);
        cineFeedback(context, HapticEvent.readerUnlock, sound: SoundEvent.toggleOn);
        ref.read(cineToastsProvider.notifier).info('Controls unlocked');
      }
      return;
    }
    if (info.kind == TapKind.double) {
      cineFeedback(context, HapticEvent.zoomSnap);
      _engine.zoomAt(
        info.position,
        doubleTapZoomTarget(s.zoom, prefs.zoom),
        duration: _reduced ? Duration.zero : context.cine.durLine,
        curve: CineCurves.settle,
      );
      return;
    }
    if (s.autoScrolling) _engine.toggleAutoScroll();
    switch (stripTap(info.position, info.size, tapToScroll: prefs.stripTaps == 'scroll', rtl: prefs.rtl)) {
      case StripTap.toggleChrome:
        s.chromeVisible ? _engine.hideChrome() : _engine.showChrome();
      case StripTap.scrollBack:
        _scrollBy(forward: false);
      case StripTap.scrollForward:
        _scrollBy(forward: true);
    }
  }

  void _scrollBy({required bool forward}) => _engine.scrollByViewport(
        tapScrollFraction(forward: forward),
        duration: _reduced ? Duration.zero : context.cine.durTapscroll,
        curve: CineCurves.scroll,
      );

  // ── Keys and commands ─────────────────────────────────────────────────────

  void _pageStep({required bool forward}) {
    final s = _engine.value;
    cineFeedback(context, HapticEvent.pageTurn);
    _engine.jumpToPage((s.page + (forward ? 1 : -1)).clamp(1, math.max(1, s.pageCount)), glide: !_reduced);
  }

  void _toggleChrome() {
    final s = _engine.value;
    if (s.chromeVisible) {
      if (_chromeScope.hasFocus) _surface.requestFocus();
      _engine.hideChrome();
    } else {
      _engine.showChrome();
    }
  }

  void _toggleCinema() {
    setState(() => _cinema = !_cinema);
    cineFeedback(context, HapticEvent.toggleOn, sound: SoundEvent.toggleOn);
    unawaited(ref.read(readerSettingsProvider.notifier).put({'cinema': _cinema}));
    if (_cinema) {
      if (_chromeScope.hasFocus) _surface.requestFocus();
      _engine.hideChrome();
    } else {
      _engine.showChrome();
    }
  }

  void _toggleAutoScroll() {
    final prefs = ref.read(readerPrefsProvider(_seriesRef));
    if (!_engine.value.autoScrolling) _engine.setAutoScrollSpeedX(_speedDraft ?? prefs.autoScrollSpeedX);
    cineFeedback(context, HapticEvent.autoscrollToggle);
    _engine.toggleAutoScroll();
  }

  void _stepSpeed(double delta) {
    final prefs = ref.read(readerPrefsProvider(_seriesRef));
    final next = stepAutoScrollSpeed(_speedDraft ?? prefs.autoScrollSpeedX, delta);
    cineFeedback(context, HapticEvent.autoscrollStep);
    _setSpeed(next, persist: true);
  }

  void _setSpeed(double x, {required bool persist}) {
    setState(() => _speedDraft = x);
    _engine.setAutoScrollSpeedX(x);
    _speedHud.show();
    if (persist) {
      unawaited(ref.read(readerSeriesPrefsProvider.notifier).setFor(_seriesRef, {'autoScrollSpeed': x}));
      _speedHud.releaseSoon();
    }
  }

  void _zoomBy(double delta, {double? to}) {
    final size = MediaQuery.sizeOf(context);
    final resting = ref.read(readerPrefsProvider(_seriesRef)).zoom;
    final target = to ?? clampZoom(snapZoom(_engine.value.zoom + delta));
    _engine.zoomAt(size.center(Offset.zero), to == 0 ? resting : target, duration: Duration.zero, curve: Curves.linear);
  }

  Future<void> _bookmark() async {
    final ok = await _engine.bookmark();
    if (!ok && mounted) ref.read(cineToastsProvider.notifier).error("Couldn't save that spot.");
  }

  void _escape() {
    final tablet = MediaQuery.sizeOf(context).width >= 600;
    final panels = ref.read(readerPrefsProvider(_seriesRef)).panels;
    switch (escapeStep(sheetOpen: false, panelOpen: tablet && panels.left, cinema: _cinema)) {
      case ReaderEscape.closeSheet:
        break;
      case ReaderEscape.closePanel:
        _setLeftPanel(false);
      case ReaderEscape.leaveCinema:
        _toggleCinema();
      case ReaderEscape.exitReader:
        _leave();
    }
  }

  void _setLeftPanel(bool open) {
    final prefs = ref.read(readerPrefsProvider(_seriesRef));
    final p = prefs.panels;
    unawaited(
      ref.read(readerSettingsProvider.notifier).put({
        'panels': ReaderPanels(left: open, right: open ? false : p.right, lastOpened: open ? 'left' : p.lastOpened).toJson(),
      }),
    );
  }

  void _openContents() {
    _engine.showChrome();
    if (MediaQuery.sizeOf(context).width >= 600) {
      _setLeftPanel(!ref.read(readerPrefsProvider(_seriesRef)).panels.left);
      return;
    }
    _engine.holdChrome();
    unawaited(
      showContentsSheet(
        context,
        content: (sheetContext) => _contentsList(onPicked: () => Navigator.of(sheetContext).pop()),
      ).whenComplete(() {
        if (mounted) _engine.scheduleHideChrome();
      }),
    );
  }

  Widget _contentsList({required VoidCallback onPicked}) => Consumer(
        builder: (context, ref, _) {
          final series = ref.watch(readerSeriesProvider(_seriesKey));
          final progress = ref.watch(sourceSeriesProgressProvider((sourceId: _id.sourceId, seriesId: _id.seriesKey)));
          final downloads = ref.watch(seriesChapterDownloadStatusProvider(_seriesKey)).valueOrNull ?? const {};
          final active = ref.watch(seriesActiveChapterProgressProvider(_seriesKey));
          final current = _engine.value.chapterId.isEmpty ? _id.chapterKey : _engine.value.chapterId;
          return ContentsList(
            chapters: series?.chapters ?? const <SourceChapterSummary>[],
            currentKey: current,
            progress: progress,
            downloads: downloads,
            activeKey: active?.chapterKey,
            activeProgress: active == null || active.progress.pageTotal == 0 ? 0 : active.progress.pagesDone / active.progress.pageTotal,
            onPick: (chapter) {
              onPicked();
              if (chapter.id != current) _goToChapter(chapter.id);
            },
            onMarkTap: (chapter, mark) {},
          );
        },
      );

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final body = _body;
    final prefs = ref.watch(readerPrefsProvider(_seriesRef));
    final series = ref.watch(readerSeriesProvider(_seriesKey));
    final size = MediaQuery.sizeOf(context);
    final tablet = size.width >= 600;
    final landscape = size.height < 500 && size.width > size.height;
    final accessible = MediaQuery.accessibleNavigationOf(context);
    final reduced = CineMotion.reduced(context);
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final ground = readerGround(context, prefs.ground);
    final userStrip = ref.watch(sharedPrefsProvider).getInt('mm.reader.device.stripWidth');
    final feedLast = body.feed.chapters.isEmpty ? null : body.feed.chapters.last;
    final lastChapterSummary = feedLast == null ? null : series?.chapterOf(feedLast.id);
    final nextSummary = feedLast == null ? null : series?.nextOf(feedLast.id);
    final nextExists = body.onNextChapter != null || nextSummary != null || (feedLast?.nextChapterId != null);
    final autoNext = prefs.autoNextChapter;
    final offline = body.feed.chapters.isNotEmpty && body.feed.pages.isNotEmpty && body.feed.pages.first.localFile != null;
    final footerMode = nextExists && !autoNext ? CreditsMode.full : (nextExists ? CreditsMode.compact : CreditsMode.full);
    final footerExtent = (nextExists ? (autoNext ? 260.0 : 980.0) : 1300.0) * math.max(1.0, scale);

    // The engine also owns the next-chapter auto-queue for the manifest reader (the source
    // reader screen already queues its own).
    if (_id.origin == ReaderOrigin.manifest) {
      _autoQueue.maybeQueue(
        ref,
        sourceId: _id.sourceId,
        seriesKey: _id.seriesKey,
        routeChapterId: _id.chapterKey,
        nextChapterId: nextSummary?.id ?? feedLast?.nextChapterId,
      );
    }
    _syncSwipeable(prefs);

    final options = ReaderEngineOptions(
      ground: ground,
      gapPx: prefs.gap ? 8 : 0,
      columnWidth: landscape ? size.width * 0.7 : (tablet ? (userStrip ?? 720).toDouble().clamp(480, 860) : null),
      sideMarginPct: tablet || landscape ? 0 : prefs.sideMarginPct,
      colourFilter: switch (prefs.colour) {
        'sepia' => ReaderColourFilter.sepia,
        'grey' => ReaderColourFilter.grey,
        _ => ReaderColourFilter.none,
      },
      doubleTapSlop: 24,
      doubleTapWindow: const Duration(milliseconds: 300),
      tapSlop: 8,
      tapHandler: _onTap,
      autoHide: ReaderAutoHide(onScroll: !accessible),
      pinch: true,
      pageStateBuilder: cinePageState,
      bandBuilder: _band,
      creditsBuilder: _credits,
      creditsMode: footerMode,
      topBandExtent: 96,
      footerExtent: footerExtent,
      offline: offline,
      pageLayerBuilder: (context, pages) => _pageLayer(context, pages, prefs),
      pageSemantics: accessible ? _pageSemantics : (context, chapter, n, page) => Semantics(label: 'Page $n of ${chapter.pages.length}', child: page),
      slotSignature: (series?.chapters.length, prefs.autoNextChapter),
      lifecycleVolumeKeys: true,
    );

    final view = ReaderEngineView(
      controller: _engine,
      slots: ReaderSurfaceSlots(
        chapterSeam: (context, chapter, axis) => const SizedBox.shrink(),
        brokenPage: (context, retry) => const SizedBox.shrink(),
        pagedCornerRadius: 0,
      ),
      autoHideAfter: accessible ? const Duration(days: 1) : const Duration(milliseconds: 3000),
      chromeBuilder: (context, state) => _chrome(context, state, prefs, series, tablet: tablet, landscape: landscape, reduced: reduced),
      onEvent: _onEvent,
      feed: body.feed,
      scrollStorageKey: body.scrollStorageKey,
      onBack: _leave,
      onOpenSeries: _openSeries,
      initialPage: body.initialPage,
      initialAnchor: body.initialAnchor,
      showBookmark: body.showBookmark,
      onSaveProgress: body.onSaveProgress,
      onAddBookmark: body.onAddBookmark,
      onPreviousChapter: body.onPreviousChapter,
      onNextChapter: body.onNextChapter,
      onReachedFeedEnd: body.onReachedFeedEnd,
      onReachedFeedStart: body.onReachedFeedStart,
      pageExtents: body.pageExtents,
      bookmarkAnchors: body.bookmarkAnchors,
      options: options,
    );

    final leftPanel = tablet && prefs.panels.left;
    final canPop = GoRouter.of(context).canPop();
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: CineToastHost(
        frame: CineToastFrame.reader,
        readerBottomInset: _engine.value.chromeVisible ? 64 + MediaQuery.viewPaddingOf(context).bottom + 40 : 0,
        child: Material(
          color: ground,
          child: RegisteredShortcuts(
            group: 'Reader',
            entries: _entries(prefs),
            child: Focus(
              focusNode: _surface,
              autofocus: true,
              child: Semantics(
                container: true,
                label: 'Chapter ${chapterNumberText(lastChapterSummary?.number)}, page ${_engine.value.page} of ${_engine.value.pageCount}',
                child: Stack(
                  children: [
                    Positioned.fill(child: view),
                    if (tablet)
                      Positioned.fill(
                        child: SidePanelLayout(
                          leftOpen: leftPanel,
                          rightOpen: false,
                          left: ContentsPanel(
                            list: _contentsListPanel(),
                            onClose: () => _setLeftPanel(false),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  ContentsList _contentsListPanel() {
    final series = ref.watch(readerSeriesProvider(_seriesKey));
    final progress = ref.watch(sourceSeriesProgressProvider((sourceId: _id.sourceId, seriesId: _id.seriesKey)));
    final downloads = ref.watch(seriesChapterDownloadStatusProvider(_seriesKey)).valueOrNull ?? const {};
    final current = _engine.value.chapterId.isEmpty ? _id.chapterKey : _engine.value.chapterId;
    return ContentsList(
      chapters: series?.chapters ?? const <SourceChapterSummary>[],
      currentKey: current,
      progress: progress,
      downloads: downloads,
      onPick: (chapter) {
        if (chapter.id != current) _goToChapter(chapter.id);
      },
      onMarkTap: (chapter, mark) {},
    );
  }

  void _syncSwipeable(ReaderPrefs prefs) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final route = context.getSwipeablePageRoute<void>();
      if (route == null) return;
      final s = _engine.value;
      route.canSwipe = _platform == TargetPlatform.iOS && prefs.layout == 'strip' && s.zoom <= 1.0 && !s.guidedActive && GoRouter.of(context).canPop();
    });
  }

  void _onEvent(ReaderEngineEvent e) {
    final toasts = ref.read(cineToastsProvider.notifier);
    switch (e) {
      case ReaderUnlocked():
        break;
      case ReaderBookmarkSaved(:final page, :final percent):
        cineFeedback(context, HapticEvent.bookmarkAdd, sound: SoundEvent.bookmarkAdd);
        toasts.info(percent == null ? 'Marked page $page.' : 'Marked page $page — $percent% of the chapter.');
      case ReaderStaleAnchor():
        toasts.info('That page moved. Opened at the nearest one.');
    }
  }

  // ── Slots ─────────────────────────────────────────────────────────────────

  Widget _pageLayer(BuildContext context, Widget pages, ReaderPrefs prefs) {
    final warmed = readerWarmth(context, pages, prefs.warmthPct);
    if (!prefs.swipeChapter) return warmed;
    final size = MediaQuery.sizeOf(context);
    final gi = MediaQuery.systemGestureInsetsOf(context);
    return ValueListenableBuilder<double>(
      valueListenable: _swipeDx,
      child: warmed,
      builder: (context, dx, child) => Transform.translate(offset: Offset(dx, 0), child: child),
    ).wrapSwipe(
      RawGestureDetector(
        behavior: HitTestBehavior.translucent,
        gestures: {
          ChapterSwipeRecognizer: GestureRecognizerFactoryWithHandlers<ChapterSwipeRecognizer>(
            () => ChapterSwipeRecognizer(screenWidth: size.width),
            (r) {
              r
                ..screenWidth = size.width
                ..leftInset = gi.left
                ..rightInset = gi.right
                ..zoom = _engine.value.zoom
                ..onUpdate = (d) {
                  final x = d.primaryDelta == null ? _swipeDx.value : _swipeDx.value + d.primaryDelta!;
                  _swipeDx.value = x.sign * rubberBand(x.abs(), 160);
                }
                ..onEnd = (d) {
                  final verdict = classifySwipe(dx: _swipeDx.value / 0.35, vx: d.primaryVelocity ?? 0, zoom: _engine.value.zoom, rtl: prefs.rtl);
                  _swipeDx.value = 0;
                  if (verdict != SwipeVerdict.none) _stepChapter(forward: verdict == SwipeVerdict.toward);
                }
                ..onCancel = () => _swipeDx.value = 0;
            },
          ),
        },
      ),
    );
  }

  Widget _pageSemantics(BuildContext context, ReaderChapter chapter, int n, Widget page) => Consumer(
        builder: (context, ref, _) {
          final texts = ref
              .watch(ocrChapterTextProvider((sourceId: _id.sourceId, seriesKey: _id.seriesKey, chapterKey: chapter.id)))
              .valueOrNull;
          final text = texts?.where((p) => p.page == n).map((p) => p.text.trim()).where((t) => t.isNotEmpty).join(' ');
          return Semantics(label: 'Page $n of ${chapter.pages.length}', hint: text, child: page);
        },
      );

  Widget _band(BuildContext context, BandKind kind, {String? from, String? to, Duration? retryIn}) {
    final series = ref.read(readerSeriesProvider(_seriesKey));
    final fromCh = from == null ? null : series?.chapterTitled(from);
    final toCh = to == null ? null : series?.chapterTitled(to);
    final last = _body.feed.chapters.isEmpty ? null : _body.feed.chapters.last;
    final firstId = _body.feed.chapters.isEmpty ? null : _body.feed.chapters.first.id;
    final prev = firstId == null ? null : series?.previousOf(firstId);
    final next = last == null ? null : series?.nextOf(last.id);
    final entering = toCh == null
        ? (to == null ? '' : to.toUpperCase())
        : (toCh.title.toLowerCase().startsWith('chapter') ? chapterFolio(toCh.number) : '${chapterFolio(toCh.number)} · ${toCh.title.toUpperCase()}');
    return cineBand(
      context,
      kind,
      endLine: 'End of chapter ${chapterNumberText(fromCh?.number)}',
      entering: entering,
      previousLabel: chapterFolio(prev?.number),
      nextLabel: chapterFolio(next?.number),
      loadingPrevious: false,
      retryIn: retryIn,
      nextFailed: (ctx) => NextFailedNotice(
        label: 'Chapter ${chapterNumberText(next?.number)}',
        onRetry: () => unawaited(_body.onReachedFeedEnd?.call()),
        onOpen: () {
          if (next != null) _goToChapter(next.id);
        },
      ),
      offlineEnd: (ctx) => OfflineEndNotice(onBackToDownloads: () => context.go(Routes.downloads())),
    );
  }

  Widget _credits(BuildContext context, ReaderChapter chapter, String? nextId, CreditsMode mode) {
    final series = ref.read(readerSeriesProvider(_seriesKey));
    final summary = series?.chapterOf(chapter.id);
    final next = series?.nextOf(chapter.id);
    final nextKey = nextId ?? next?.id;
    final minutes = math.max(1, DateTime.now().difference(_openedAt).inMinutes);
    final number = chapterNumberText(summary?.number);
    final credits = ReaderCredits(
      engine: _engine,
      sourceId: _id.sourceId,
      seriesKey: _id.seriesKey,
      chapter: chapter,
      chapterNumber: number,
      seriesTitle: series?.title ?? chapter.seriesTitle ?? '',
      mode: mode,
      readMinutes: minutes,
      nextChapterKey: nextKey,
      nextNumber: next?.number,
      nextTitle: next?.title,
      onContinue: () {
        if (nextKey == null) return;
        cineFeedback(context, HapticEvent.chapterNext, sound: SoundEvent.chapterNext);
        final n = next?.number;
        ref.read(pendingChapterCaptionProvider.notifier).state = n == null ? null : 'CH ${chapterNumberText(n)} — ${next!.title}';
        _goToChapter(nextKey);
      },
    );
    if (nextKey != null || series == null) return credits;
    final sources = ref.read(sourcesListProvider).valueOrNull;
    final sourceName = sources?.where((s) => s.id == _id.sourceId).firstOrNull?.name ?? _id.sourceId;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        credits,
        ReaderEndNotice(
          sourceId: _id.sourceId,
          seriesKey: _id.seriesKey,
          title: series.title,
          sourceName: sourceName,
          chapterCount: series.chapters.length,
          completed: series.completed,
          latestChapter: number,
          readHours: math.max(1, (series.chapters.length * 0.2).ceil()),
          onBackToSeries: _leave,
        ),
      ],
    );
  }

  // ── Chrome ────────────────────────────────────────────────────────────────

  Widget _chrome(
    BuildContext context,
    ReaderEngineState s,
    ReaderPrefs prefs,
    ReaderSeries? series, {
    required bool tablet,
    required bool landscape,
    required bool reduced,
  }) {
    final chapter = series?.chapterOf(s.chapterId);
    final prev = series?.previousOf(s.chapterId);
    final next = series?.nextOf(s.chapterId);
    final loadingChapter = s.chapterId.isEmpty;
    final brightness = _brightnessDraft ?? prefs.brightness;
    final speedX = _speedDraft ?? prefs.autoScrollSpeedX;
    final offline = _body.feed.pages.isNotEmpty && _body.feed.pages.first.localFile != null;
    final bookmarked = s.bookmarks.any((a) => a.page == s.page);
    final minutes = minutesLeft(page: s.page, pageCount: s.pageCount, pagesPerMinute: _pace.pagesPerMinute);
    final showChrome = s.chromeVisible && !s.locked;
    final trailing = <Widget>[
      ChapterDownloadControl(sourceId: _id.sourceId, seriesKey: _id.seriesKey, chapterKey: s.chapterId.isEmpty ? _id.chapterKey : s.chapterId),
      CineIconButton(
        label: bookmarked ? 'Remove bookmark' : 'Bookmark this page',
        codepoint: 0xe0ea,
        selected: bookmarked,
        onPressed: _body.onAddBookmark == null ? null : _bookmark,
      ),
      if (tablet) CineIconButton(label: 'Contents', role: CineIconRole.contents, selected: prefs.panels.left, onPressed: _openContents),
    ];
    return Stack(
      children: [
        ReaderDimmer(brightness: brightness),
        Positioned.fill(
          child: FocusScope(
            node: _chromeScope,
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ReaderChromeMotion(
                    visible: showChrome && !(landscape && !s.chromeVisible),
                    fromTop: true,
                    child: ReaderRunningHead(
                      seriesTitle: series?.title ?? _body.feed.chapters.firstOrNull?.seriesTitle ?? '',
                      folio: chapterFolio(chapter?.number),
                      loading: loadingChapter,
                      offlineEdition: offline,
                      onBack: _leave,
                      onOpenSeries: _openSeries,
                      onOpenContents: _openContents,
                      trailing: trailing,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ReaderChromeMotion(
                    visible: showChrome,
                    fromTop: false,
                    child: ReaderFolioBar(
                      page: s.page,
                      pageCount: s.pageCount,
                      rtl: prefs.rtl,
                      bookmarkPages: [for (final a in s.bookmarks) a.page],
                      previousLabel: prev == null ? null : chapterNumberText(prev.number),
                      nextLabel: next == null ? null : chapterNumberText(next.number),
                      onPrevious: prev == null && !s.hasPrevious ? null : () => _stepChapter(forward: false),
                      onNext: next == null && !s.hasNext ? null : () => _stepChapter(forward: true),
                      onSeek: _engine.jumpToPage,
                      onJump: _engine.jumpToPage,
                      counterKey: _counter,
                      autoScrolling: s.autoScrolling,
                      speedLabel: '${speedX.toStringAsFixed(1)}×',
                      onToggleAutoScroll: _toggleAutoScroll,
                      minutesLeft: minutes,
                      returnFocus: _surface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ReaderMicroProgress(progress: s.progress, rtl: prefs.rtl, visible: !s.chromeVisible && !_cinema),
        ReaderZoomChip(zoom: s.zoom, visible: _chipVisible),
        EdgeDragZone(
          left: true,
          value: (brightness + 75) / 75,
          onChanged: (v) {
            setState(() => _brightnessDraft = (v * 75).round() - 75);
            _brightnessHud.show();
          },
          onEnd: () {
            final v = _brightnessDraft;
            if (v != null) unawaited(ref.read(readerSettingsProvider.notifier).put({'brightness': v}));
            _brightnessHud.releaseSoon();
          },
        ),
        EdgeDragZone(
          left: false,
          enabled: s.autoScrolling,
          value: (speedX - 0.5) / 2.5,
          onChanged: (v) => _setSpeed((0.5 + v * 2.5 * 20).round() / 20, persist: false),
          onEnd: () {
            final x = _speedDraft;
            if (x != null) unawaited(ref.read(readerSeriesPrefsProvider.notifier).setFor(_seriesRef, {'autoScrollSpeed': x}));
            _speedHud.releaseSoon();
          },
        ),
        EdgeHud(
          left: true,
          visible: _brightnessHud.visible,
          fill: (brightness + 75) / 75,
          label: brightness < 0 ? 'NIGHT $brightness' : '0',
        ),
        EdgeHud(left: false, visible: _speedHud.visible, fill: (speedX - 0.5) / 2.5, label: '${speedX.toStringAsFixed(1)}×'),
        if (_caption != null) _CaptionTyped(text: _caption!),
        if (!_ratingShown && series != null) _RatingOnce(series: series, sourceId: _id.sourceId, onShown: () => _ratingShown = true),
      ],
    );
  }

  // ── Keys ──────────────────────────────────────────────────────────────────

  List<ShortcutEntry> _entries(ReaderPrefs prefs) {
    ShortcutEntry e(LogicalKeyboardKey key, String desc, VoidCallback run, {bool shift = false, bool ctrl = false, bool single = true, List<String>? keys}) =>
        ShortcutEntry(
          group: 'Reader',
          activator: SingleActivator(key, shift: shift, control: ctrl),
          description: desc,
          singleKey: single && !shift && !ctrl,
          keys: keys,
          onInvoke: run,
        );
    final rtl = prefs.rtl;
    return [
      e(LogicalKeyboardKey.arrowRight, 'Next page', () => _pageStep(forward: arrowGoesForward(rightArrow: true, rtl: rtl))),
      e(LogicalKeyboardKey.keyD, 'Next page', () => _pageStep(forward: arrowGoesForward(rightArrow: true, rtl: rtl))),
      e(LogicalKeyboardKey.arrowLeft, 'Previous page', () => _pageStep(forward: arrowGoesForward(rightArrow: false, rtl: rtl))),
      e(LogicalKeyboardKey.keyA, 'Previous page', () => _pageStep(forward: arrowGoesForward(rightArrow: false, rtl: rtl))),
      e(LogicalKeyboardKey.keyJ, 'Next page', () => _pageStep(forward: true)),
      e(LogicalKeyboardKey.keyK, 'Previous page', () => _pageStep(forward: false)),
      e(LogicalKeyboardKey.space, 'One screen forward', () => _engine.pageBy(forward: true)),
      e(LogicalKeyboardKey.space, 'One screen back', () => _engine.pageBy(forward: false), shift: true, single: false),
      e(LogicalKeyboardKey.home, 'Start of the chapter', () => _engine.jumpToPage(1)),
      e(LogicalKeyboardKey.end, 'End of the chapter', () => _engine.jumpToPage(_engine.value.pageCount)),
      e(LogicalKeyboardKey.keyL, 'Next chapter', () => _stepChapter(forward: true)),
      e(LogicalKeyboardKey.keyH, 'Previous chapter', () => _stepChapter(forward: false)),
      e(LogicalKeyboardKey.arrowRight, 'Next chapter', () => _stepChapter(forward: true), shift: true, ctrl: true, single: false),
      e(LogicalKeyboardKey.arrowLeft, 'Previous chapter', () => _stepChapter(forward: false), shift: true, ctrl: true, single: false),
      e(LogicalKeyboardKey.keyG, 'Go to page', () {
        _engine.showChrome();
        WidgetsBinding.instance.addPostFrameCallback((_) => _counter.currentState?.beginEdit());
      }),
      e(LogicalKeyboardKey.keyC, 'Cinema mode', _toggleCinema),
      e(LogicalKeyboardKey.keyM, 'Show or hide the controls', _toggleChrome),
      e(LogicalKeyboardKey.keyP, 'Auto-scroll', _toggleAutoScroll),
      e(LogicalKeyboardKey.comma, 'Slower', () => _stepSpeed(-0.25), keys: const ['<']),
      e(LogicalKeyboardKey.period, 'Faster', () => _stepSpeed(0.25), keys: const ['>']),
      e(LogicalKeyboardKey.keyB, 'Bookmark this page', () => unawaited(_bookmark())),
      e(LogicalKeyboardKey.keyS, 'Back to the series', _leave),
      e(LogicalKeyboardKey.bracketLeft, 'Contents', () {
        _engine.showChrome();
        _openContents();
      }),
      e(LogicalKeyboardKey.equal, 'Zoom in', () => _zoomBy(0.1)),
      e(LogicalKeyboardKey.add, 'Zoom in', () => _zoomBy(0.1)),
      e(LogicalKeyboardKey.minus, 'Zoom out', () => _zoomBy(-0.1)),
      e(LogicalKeyboardKey.digit0, 'Reset zoom', () => _zoomBy(0, to: 0)),
      e(LogicalKeyboardKey.escape, 'Close, then leave', _escape, single: false),
    ];
  }
}

extension on Widget {
  /// Puts [detector] over this widget, in a `Stack`: the swipe recogniser sits translucent above
  /// the pages.
  Widget wrapSwipe(Widget detector) => Stack(fit: StackFit.passthrough, children: [this, Positioned.fill(child: detector)]);
}

/// The chapter title typed at the top-left after a pull to continue.
class _CaptionTyped extends StatelessWidget {
  const _CaptionTyped({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final top = MediaQuery.viewPaddingOf(context).top + 12;
    return Positioned(
      top: top,
      left: MediaQuery.viewPaddingOf(context).left + 16,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          color: const Color(0xFF000000),
          child: TypedHeadline(text, style: CineText.style(context, c.typeFolio), cap: c.typeFolio.cap),
        ),
      ),
    );
  }
}

/// The 18+ rating card at the start of a series flagged mature (cinematic 7.24), shown once.
class _RatingOnce extends ConsumerStatefulWidget {
  const _RatingOnce({required this.series, required this.sourceId, required this.onShown});
  final ReaderSeries series;
  final String sourceId;
  final VoidCallback onShown;

  @override
  ConsumerState<_RatingOnce> createState() => _RatingOnceState();
}

class _RatingOnceState extends ConsumerState<_RatingOnce> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    if (_done) return const SizedBox.shrink();
    final sources = ref.watch(sourcesListProvider).valueOrNull;
    final mature = sources?.where((s) => s.id == widget.sourceId).firstOrNull?.mature ?? false;
    if (!mature) return const SizedBox.shrink();
    widget.onShown();
    return Positioned(
      top: MediaQuery.viewPaddingOf(context).top + 56,
      left: 16,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: CineRatingCard(genres: widget.series.summary.genres, onDone: () => setState(() => _done = true)),
      ),
    );
  }
}
