import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/features/circle/utils/spoiler_guard.dart';
import 'package:manhwamaniacs/features/downloads/providers/progress_outbox_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/ocr/models/page_text.dart';
import 'package:manhwamaniacs/features/ocr/providers/dialogue_jump_provider.dart';
import 'package:manhwamaniacs/features/ocr/providers/ocr_providers.dart';
import 'package:manhwamaniacs/features/reader/engine/page_turn.dart';
import 'package:manhwamaniacs/features/reader/engine/paged_reader_view.dart';
import 'package:manhwamaniacs/features/reader/engine/read_all_window.dart' show locateGlobalPage, chapterStarts, readAllFlag;
import 'package:manhwamaniacs/features/reader/engine/reader_ambient.dart' show PanelsFound;
import 'package:manhwamaniacs/features/reader/engine/reader_engine.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_options.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_state.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_view.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_frames.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_layout.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_surface_slots.dart';
import 'package:manhwamaniacs/features/reader/engine/tap_classifier.dart';
import 'package:manhwamaniacs/features/reader/engine/zoom_math.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/models/reader_feed.dart' show kChapterSeamExtent;
import 'package:manhwamaniacs/features/reader/models/reader_prefs.dart';
import 'package:manhwamaniacs/features/reader/models/reading_progress.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_prefs_provider.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_profile_settings.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_signals_provider.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_ui_provider.dart';
import 'package:manhwamaniacs/features/reader/providers/series_reading_order_provider.dart';
import 'package:manhwamaniacs/features/reader/utils/auto_scroll_speed.dart';
import 'package:manhwamaniacs/features/reader/utils/read_all_feed.dart' show isFailedChapter;
import 'package:manhwamaniacs/features/reader/utils/reader_feed_factory.dart' show readAllControllerProvider;
import 'package:manhwamaniacs/features/reader/utils/reader_prefs_migration.dart' show LegacyReaderKeys;
import 'package:manhwamaniacs/features/reader/utils/time_left.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/navigation.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_rating_card.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toast_host.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/ambient_bridge.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/auto_scroll_chip.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/auto_scroll_speed_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/bubble_pulse.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/chapter_download_control.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/cine_page_physics.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/cine_reader_route.dart' show cineReaderOwnsToastsProvider;
import 'package:manhwamaniacs/skins/cinematic/screens/reader/contents_list.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/contents_panel.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/contents_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/credits.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/edge_hud.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/end_states.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/folio_bar.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/guided_view.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/image_layers.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/jump_to_page_field.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/margins_panel.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/micro_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/ocr_overlay.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/page_actions_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/page_states.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/paged_rules.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/previously_on_chip.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/read_all_divider.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_chrome.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_entry.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_gestures.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_keys.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_series.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_system_ui.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_taps.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_tint.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reading_setup_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/running_head.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/side_panel_layout.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/strip_bands.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/tap_zone_bands.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/zoom_chip.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/sections/ambient_section.dart' show kSoundscapeLoops;
import 'package:manhwamaniacs/skins/cinematic/soundscape/house_sound.dart';
import 'package:manhwamaniacs/skins/cinematic/soundscape/house_sound_binding.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

/// The over-scroll at the top of the strip that loads the previous chapter (J3).
const double kTopPullLoadPx = 140;

/// A chapter title typed at the top-left after a committed pull to continue, carried across the
/// route change (`CH 143 — The Return`).
final pendingChapterCaptionProvider = StateProvider<String?>((ref) => null, name: 'pendingChapterCaption');

/// The Cinematic manga reader (cinematic 8.14): chrome on the shared reader engine. It takes the
/// resolved reader body of `ReaderScreen` or `SourceReaderScreen` (the same feed, the same
/// callbacks) and renders the running head, the folio bar with the ruler, the strip's bands and
/// credits, the Contents, the gestures and the keys.
class CineMangaReader extends ConsumerStatefulWidget {
  const CineMangaReader({super.key, required this.body, this.readAll = false});

  final ReaderFrameBody body;

  /// The read-all route's reader (ScreenId `readAll`): one strip across the series, no layouts.
  final bool readAll;

  @override
  ConsumerState<CineMangaReader> createState() => _CineMangaReaderState();
}

class _CineMangaReaderState extends ConsumerState<CineMangaReader> with WidgetsBindingObserver {
  final ReaderEngine _engine = ReaderEngine();
  late final CineAmbientBridge _ambient = CineAmbientBridge(ref: ref, engine: _engine, sourceId: _id.sourceId, seriesKey: _id.seriesKey);
  final FocusScopeNode _chromeScope = FocusScopeNode(debugLabel: 'reader chrome');
  final FocusNode _surface = FocusNode(debugLabel: 'reader surface');
  final GlobalKey<PageCounterFieldState> _counter = GlobalKey();
  final LockCounter _lock = LockCounter();
  final PaceTracker _pace = PaceTracker();
  final ValueNotifier<double> _swipeDx = ValueNotifier<double>(0);
  final DateTime _openedAt = DateTime.now();
  late final HudHold _brightnessHud = HudHold(_repaint);
  late final HudHold _speedHud = HudHold(_repaint);

  Timer? _chipTimer, _retryTimer;
  bool _chipVisible = false;
  bool _cinema = false;
  bool _resumeAuto = false;
  int _retryStep = 0;
  int? _brightnessDraft;
  double? _speedDraft;
  String? _lastChapterId, _announcedChapter;
  double _lastZoom = 1;
  bool _lastChrome = true;
  bool _lastAuto = false;
  ({ReaderNextState next, bool hasNext, int loaded}) _footerKey = (next: ReaderNextState.none, hasNext: false, loaded: 0);
  FurtherElsewhere? _shownFurther;
  StreamSubscription<({String sourceId, String seriesKey})>? _progressSub;
  ReaderSystemUi? _appliedUi;
  String? _caption;
  bool _ratingShown = false;
  bool _fadeBlack = false;

  // Paged layouts, panels and page actions (mobile/13).
  final OcrOverlayController _ocr = OcrOverlayController();
  final Map<String, int> _retryEpoch = {};
  ({String chapter, int page})? _heroFor;
  ReaderLayout _lastLayout = ReaderLayout.strip;
  String? _carryChapterId;
  int? _carryPage;
  int _zonesReplay = 0;
  bool _bandsOn = false;
  String? _lastZonesKey;
  bool _completedOpen = false;

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

  DateTime? _lastReadAt;

  /// A Dialogue-screen hit for this chapter: jump to its page, tell the reader, pulse the bubble.
  Future<void> _landDialogue() async {
    final jump = ref.read(dialogueJumpProvider.notifier).take(_id.sourceId, _id.seriesKey, _id.chapterKey);
    if (jump == null) return;
    final id = (sourceId: _id.sourceId, seriesKey: _id.seriesKey, chapterKey: _id.chapterKey);
    final landing = await resolveDialogueLanding(jump, () => ref.read(ocrChapterTextProvider(id).future).catchError((Object _) => <PageText>[]));
    if (!mounted) return;
    final page = landing.page;
    if (page != null) {
      _engine.jumpToPage(page);
      final b = landing.box;
      if (b != null) _ocr.pulse(_id.chapterKey, page, OcrTextBox(text: '', x: b.x, y: b.y, width: b.w, height: b.h));
    }
    ref.read(cineToastsProvider.notifier).info(landing.toast);
  }

  @override
  void initState() {
    super.initState();
    // Held for the reader's lifetime: the chip's gap is measured before this session's progress.
    ref.listenManual(readerLastReadAtProvider((sourceId: _id.sourceId, seriesKey: _id.seriesKey)), (_, v) {
      if (mounted) setState(() => _lastReadAt = v.valueOrNull);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_landDialogue()));
    Future.microtask(() {
      try {
        _toastOwner.state = true;
      } catch (_) {}
    });
    _lastLayout = _layoutOf(ref.read(readerPrefsProvider(_seriesRef)));
    WidgetsBinding.instance.addObserver(this);
    _engine.addListener(_onEngine);
    _engine.topPull.addListener(_onTopPull);
    _progressSub = ref.read(progressOutboxControllerProvider).notAdvanced.listen((k) => unawaited(_checkFurther(k)));
    _engine.chapterCompleted.listen(_onCompleted);
    _ocr.addListener(_repaint);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final prefs = ref.read(readerPrefsProvider(_seriesRef));
      _cinema = prefs.cinema;
      _maybeK01Toast();
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The exit reports also go out when the app is backgrounded.
    if (state == AppLifecycleState.paused) unawaited(_ambient.flush(_engine.value.chapterId));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_ambient.flush(_engine.value.chapterId));
    _chipTimer?.cancel();
    _retryTimer?.cancel();
    unawaited(_progressSub?.cancel());
    _brightnessHud.dispose();
    _speedHud.dispose();
    _ocr
      ..removeListener(_repaint)
      ..dispose();
    _swipeDx.dispose();
    _chromeScope.dispose();
    _surface.dispose();
    _engine.removeListener(_onEngine);
    _engine.topPull.removeListener(_onTopPull);
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
      final crossed = _lastChapterId != null && _isReadAll;
      // Leaving a chapter inside the reader posts its new tint and panel samples once.
      if (_lastChapterId != null) unawaited(_ambient.flush(_lastChapterId!));
      _lastChapterId = s.chapterId;
      unawaited(_ambient.loadOcr(s.chapterId, wanted: true));
      _completedOpen = false;
      if (crossed) cineFeedback(context, HapticEvent.scrubBoundary, sound: SoundEvent.scrubBoundary);
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
    if (_lastAuto != s.autoScrolling) {
      _ambient.syncWords(running: s.autoScrolling, paceByDialogue: ref.read(readerSettingsProvider).paceByDialogue);
    }
    _lastAuto = s.autoScrolling;
  }

  void _onCompleted(ChapterRef done) {
    if (!mounted) return;
    if (done.chapterKey == _engine.value.chapterId || _engine.value.chapterId.isEmpty) setState(() => _completedOpen = true);
    // Unseals every guarded Circle row for this chapter without a refetch (cinematic 9.3.3).
    ref.read(completedThisSessionProvider.notifier).markCompleted(done.sourceId, done.seriesKey, done.chapterKey);
    cineFeedback(context, HapticEvent.chapterComplete, sound: SoundEvent.chapterComplete);
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (mounted) cineFeedback(context, HapticEvent.tapSecondary);
    });
  }

  void _onNextState(ReaderEngineState s) {
    _retryTimer?.cancel();
    if (s.nextState == ReaderNextState.failed) {
      const backoff = [2, 4, 8, 16, 30];
      var wait = backoff[math.min(_retryStep, backoff.length - 1)];
      final limited = ref.read(readerRateLimitedUntilProvider)?.difference(DateTime.now()).inSeconds;
      if (limited != null && limited > wait) wait = limited + 1;
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
      // Reduced motion: auto-scroll never starts by itself.
      if (!_reduced) _engine.toggleAutoScroll();
    }
  }

  void _announce(ReaderEngineState s) {
    if (s.chapterId.isEmpty || s.chapterId == _announcedChapter) return;
    _announcedChapter = s.chapterId;
    final series = ref.read(readerSeriesProvider(_seriesKey));
    final number = series?.chapterOf(s.chapterId)?.number;
    // The series may not have resolved yet: the engine's own chapter title carries the number.
    final head = number != null ? 'Chapter ${chapterNumberText(number)}' : (s.chapterTitle.toLowerCase().startsWith('chapter') ? s.chapterTitle : 'Chapter');
    final title = s.chapterTitle.isNotEmpty && !s.chapterTitle.toLowerCase().startsWith('chapter') ? ', ${s.chapterTitle}' : '';
    final seriesTitle = series?.title ?? _body.feed.chapters.firstOrNull?.seriesTitle ?? '';
    final tail = seriesTitle.isEmpty ? '' : ' · $seriesTitle';
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

  /// The outbox says the server did not advance for this series: read its rows and, when one is
  /// past the chapter being read, hand it to the engine (which raises `furtherElsewhere`).
  Future<void> _checkFurther(({String sourceId, String seriesKey}) k) async {
    if (k.sourceId != _id.sourceId || k.seriesKey != _id.seriesKey) return;
    final rows = await ref.read(readerRepositoryProvider).seriesProgress(sourceId: k.sourceId, seriesKey: k.seriesKey);
    if (!mounted || rows.isErr) return;
    final s = _engine.value;
    final here = ref.read(readerSeriesProvider(_seriesKey))?.chapterOf(s.chapterId)?.number;
    ReadingProgress? far;
    for (final r in rows.value) {
      if ((r.chapterNumber ?? -1) > (far?.chapterNumber ?? -1)) far = r;
    }
    if (far == null || far.chapterKey == s.chapterId) return;
    final ahead = (far.chapterNumber ?? -1) > (here ?? -1);
    if (!ahead) return;
    _engine.reportServerProgress(chapterKey: far.chapterKey, chapterNumber: far.chapterNumber, lastPage: far.lastPage, advanced: false);
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

  bool _topArmed = true;

  /// J3: over-scrolling up 140 px at the top of the strip loads the previous chapter the feed
  /// could not absorb itself (`scrub.boundary`), once per pull.
  void _onTopPull() {
    final pull = _engine.topPull.value;
    if (pull <= 0) {
      _topArmed = true;
      return;
    }
    if (!_topArmed || pull < kTopPullLoadPx || _body.onPreviousChapter == null) return;
    _topArmed = false;
    cineFeedback(context, HapticEvent.scrubBoundary, sound: SoundEvent.scrubBoundary);
    _body.onPreviousChapter!();
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

  /// A chapter picked in Contents: in read-all it scrolls to it when it is loaded (no Dip), else
  /// the strip restarts there; elsewhere it opens by Dip.
  void _pickChapter(String chapterKey) {
    if (!_isReadAll) {
      _goToChapter(chapterKey);
      return;
    }
    final i = _body.feed.indexOfChapter(chapterKey);
    if (i >= 0) {
      _engine.seekToChapter(i);
    } else {
      context.go(ReadAllTarget(_id.sourceId, _id.seriesKey, from: chapterKey).location, extra: <String, String>{'entry': ReaderEntry.dip.name});
    }
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

  // ── Paged layouts ─────────────────────────────────────────────────────────

  ReaderLayout _layoutOf(ReaderPrefs p) => switch (p.layout) {
        'single' => ReaderLayout.single,
        'double' => ReaderLayout.double,
        'guided' => ReaderLayout.guided,
        _ => ReaderLayout.strip,
      };

  bool get _isReadAll => widget.readAll;

  bool get _locked => _engine.value.locked;

  bool get _paged => _lastLayout != ReaderLayout.strip;

  bool get _guided => _lastLayout == ReaderLayout.guided;

  /// The layout `u` returns to when guided view is switched off.
  String _layoutBeforeGuided = 'strip';

  /// The one-time K01 toast: a sideways strip of the old reader is a page layout now.
  void _maybeK01Toast() {
    final sp = ref.read(sharedPrefsProvider);
    final show = shouldShowK01Toast(legacyDirection: sp.getString(LegacyReaderKeys.direction), seen: sp.getBool(kK01ToastSeenKey) ?? false);
    if (!show) return;
    unawaited(sp.setBool(kK01ToastSeenKey, true));
    ref.read(cineToastsProvider.notifier).info(kK01ToastText);
  }

  /// The tap-zone bands: the first time this layout of zones is used on the device, and again
  /// whenever the layout of zones changes.
  void _syncBands(ReaderPrefs prefs, ReaderLayout layout) {
    if (layout == ReaderLayout.strip || layout == ReaderLayout.guided) return;
    final zones = resolveZones(prefs.tapZones, rtl: prefs.rtl);
    final key = zoneLayoutKey(layout.name, zones);
    if (key == _lastZonesKey) return;
    final firstBuild = _lastZonesKey == null;
    _lastZonesKey = key;
    final sp = ref.read(sharedPrefsProvider);
    final seen = sp.getStringList(kZonesSeenKey) ?? const <String>[];
    if (!shouldShowBands(seen, layout.name, zones)) {
      if (!firstBuild) _showZones();
      return;
    }
    unawaited(sp.setStringList(kZonesSeenKey, markZonesSeen(seen, layout.name, zones)));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showZones();
    });
  }

  void _showZones() => setState(() {
        _bandsOn = true;
        _zonesReplay++;
      });

  void _onPagedTap(ReaderTapInfo info, ReaderPrefs prefs) {
    final s = _engine.value;
    if (_ocr.active) {
      _ocr.hideOutlines();
      return;
    }
    final zones = resolveZones(prefs.tapZones, rtl: prefs.rtl);
    final step = zoneStep(zoneAction(info.position.dx, info.size.width, zones));
    // The menu zone takes a double tap to open or close the chrome; a single tap there does nothing.
    // Pinch zooms.
    if (step == null) {
      if (info.kind == TapKind.double) s.chromeVisible ? _engine.hideChrome() : _engine.showChrome();
      return;
    }
    if (s.chromeVisible) _engine.hideChrome();
    _pagedStep(forward: step > 0);
  }

  void _pagedStep({required bool forward}) {
    // Guided view gives its own page-turn feedback per move.
    if (!_guided) cineFeedback(context, HapticEvent.pageTurn, sound: SoundEvent.pageTurn);
    _engine.pageBy(forward: forward);
  }

  void _setLayoutByKey(String key) {
    if (_isReadAll) return;
    final l = layoutForKey(key);
    if (l == null) return;
    cineFeedback(context, HapticEvent.select);
    unawaited(ref.read(readerSeriesPrefsProvider.notifier).setFor(_seriesRef, {'layout': l.layout, if (l.direction != null) 'direction': l.direction}));
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
    if (_paged) {
      _onPagedTap(info, prefs);
      return;
    }
    // Auto-scroll keeps running through a tap: the touch pauses it and the release resumes it
    // (the chrome stays hidden).
    if (s.autoScrolling) return;
    switch (stripTap(info.position, info.size, tapToScroll: prefs.stripTaps == 'scroll', rtl: prefs.rtl)) {
      // A double tap opens or closes the chrome; a single touch here is too often the end of a
      // scroll. Pinch zooms.
      case StripTap.toggleChrome:
        if (info.kind == TapKind.double) s.chromeVisible ? _engine.hideChrome() : _engine.showChrome();
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
    if (_paged) {
      _pagedStep(forward: forward);
      return;
    }
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
    if (_paged && !_guided) return;
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

  /// `u` and the `panel-focus` button: guided view on, or back to the layout it came from.
  void _toggleGuided() {
    if (_isReadAll) return;
    final prefs = ref.read(readerPrefsProvider(_seriesRef));
    final next = prefs.layout == 'guided' ? _layoutBeforeGuided : 'guided';
    if (prefs.layout != 'guided') _layoutBeforeGuided = prefs.layout;
    cineFeedback(context, HapticEvent.select);
    unawaited(ref.read(readerSeriesPrefsProvider.notifier).setFor(_seriesRef, {'layout': next}));
  }

  String? _houseLabel() {
    final h = ref.read(houseSoundProvider);
    if (!h.playing || h.loopId == null) return null;
    return kSoundscapeLoops.where((l) => l.$1 == h.loopId).firstOrNull?.$2;
  }

  String _guidedChipLabel() {
    final g = ref.read(readerSettingsProvider).guidedAutoAdvance;
    final paced = g.mode != 'FIXED' && _engine.ambient.hasDialogueText;
    return paced ? 'AUTO · PACED' : 'AUTO · ${(g.fixedMs / 1000).toStringAsFixed(1)} S';
  }

  /// The chip's tap: running <-> paused (from off the folio bar button starts it).
  void _chipToggle() {
    cineFeedback(context, HapticEvent.autoscrollToggle, sound: SoundEvent.autoscrollToggle);
    if (!_engine.value.autoScrolling) {
      _toggleAutoScroll();
      return;
    }
    _engine.autoScroll.togglePause();
  }

  /// The chip's long-press: the projection-speed sheet.
  void _openSpeedSheet() {
    cineFeedback(context, HapticEvent.longpressOpen);
    final prefs = ref.read(readerPrefsProvider(_seriesRef));
    final h = MediaQuery.sizeOf(context).height;
    _engine.holdChrome();
    unawaited(
      showAutoScrollSpeedSheet(
        context,
        value: _speedDraft ?? prefs.autoScrollSpeedX,
        onChanged: (x) => _setSpeed(x, persist: false),
        onCommit: (x) => _setSpeed(x, persist: true),
        equivalent: (x) => '≈ ${autoScrollPxPerSecondX(x, h).round()} PX/S',
      ).whenComplete(() {
        if (mounted) _engine.scheduleHideChrome();
      }),
    );
  }

  /// The running head's `waveform`: Reading setup at AMBIENT.
  void _openHouseSound() {
    _engine
      ..showChrome()
      ..holdChrome();
    unawaited(
      showReadingSetup(
        context,
        seriesRef: _seriesRef,
        seriesTitle: _seriesTitle,
        engine: _engine,
        readAll: _isReadAll,
        onShowZones: _showZones,
        initialTab: 3,
        topRule: _tintLight,
      ).whenComplete(() {
        if (mounted) _engine.hideChrome();
      }),
    );
  }

  Color? _tintLight;

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
    if (_ocr.active) {
      _ocr.hideOutlines();
      return;
    }
    switch (escapeStep(sheetOpen: false, panelOpen: tablet && (panels.left || panels.right), cinema: _cinema)) {
      case ReaderEscape.closeSheet:
        break;
      case ReaderEscape.closePanel:
        if (panels.right) {
          _setRightPanel(false);
        } else {
          _setLeftPanel(false);
        }
      case ReaderEscape.leaveCinema:
        _toggleCinema();
      case ReaderEscape.exitReader:
        _leave();
    }
  }

  void _setRightPanel(bool open) {
    final p = ref.read(readerPrefsProvider(_seriesRef)).panels;
    unawaited(
      ref.read(readerSettingsProvider.notifier).put({
        'panels': ReaderPanels(left: open ? false : p.left, right: open, lastOpened: open ? 'right' : p.lastOpened).toJson(),
      }),
    );
  }

  /// `note-pencil` and `]`: the Margins panel on tablets (one side panel at a time, the last
  /// opened wins). Phones have no panel: their path is the page actions.
  void _openMargins() {
    _engine.showChrome();
    if (MediaQuery.sizeOf(context).width < 600) return;
    _setRightPanel(!ref.read(readerPrefsProvider(_seriesRef)).panels.right);
  }

  String get _seriesTitle => ref.read(readerSeriesProvider(_seriesKey))?.title ?? _body.feed.chapters.firstOrNull?.seriesTitle ?? '';

  /// The comma key and the running head's sliders button: Reading setup over the live page.
  void _openSetup() {
    _engine
      ..showChrome()
      ..holdChrome();
    final page = _engine.pageAtReadingLine();
    unawaited(
      showReadingSetup(
        context,
        seriesRef: _seriesRef,
        seriesTitle: _seriesTitle,
        engine: _engine,
        readAll: _isReadAll,
        onShowZones: _showZones,
        pageActionsLabel: 'Page actions for p. $page',
        onPageActions: _openPageActions,
        topRule: _tintLight,
      ).whenComplete(() {
        // Closing the sheet also hides the chrome.
        if (mounted) _engine.hideChrome();
      }),
    );
  }

  ReaderChapter? _chapterById(String? id) {
    final chapters = _body.feed.chapters;
    return chapters.where((c) => c.id == id).firstOrNull ?? chapters.firstOrNull;
  }

  /// Page actions for [page] of [chapterId] (default: the page at the reading line).
  Future<void> _openPageActions({String? chapterId, int? page}) async {
    final chapter = _chapterById(chapterId ?? _engine.value.chapterId);
    if (chapter == null) return;
    final n = (page ?? _engine.pageAtReadingLine()).clamp(1, math.max(1, chapter.pages.length)).toInt();
    final id = (sourceId: _id.sourceId, seriesKey: _id.seriesKey, chapterKey: chapter.id);
    // The transcript decides whether `Show dialogue on this page` is offered: ask for it, briefly.
    final text = await ref.read(ocrChapterTextProvider(id).future).timeout(const Duration(milliseconds: 400), onTimeout: () => null).catchError((Object _) => null);
    if (!mounted) return;
    final hasText = text?.any((t) => t.page == n && !t.isEmpty) ?? false;
    final summary = ref.read(readerSeriesProvider(_seriesKey))?.chapterOf(chapter.id);
    _engine.holdChrome();
    unawaited(
      showPageActions(
        context,
        PageActionsTarget(
          sourceId: _id.sourceId,
          seriesKey: _id.seriesKey,
          chapter: chapter,
          page: n,
          chapterNumber: summary?.number,
          saved: chapter.pages.isNotEmpty && chapter.pages.first.localFile != null,
          hasDialogue: hasText,
          onShowDialogue: () => _ocr.showOutlines(chapter.id, n),
          onRetry: () => _retryPage(chapter, n),
          onOpenImage: () => _openImage(chapter, n),
        ),
      ).whenComplete(() {
        if (mounted) _engine.scheduleHideChrome();
      }),
    );
  }

  /// The per-page overlay slot: a failed read-all chapter's notice, else the OCR overlay.
  Widget _overlayFor(BuildContext context, int page, String chapterKey, Size box) {
    final chapter = _chapterById(chapterKey);
    if (_isReadAll && chapter != null && chapter.id == chapterKey && isFailedChapter(chapter)) {
      final series = ref.read(readerSeriesProvider(_seriesKey));
      final n = series?.chapterOf(chapterKey)?.number;
      return ColoredBox(
        color: context.cine.colorPaper0,
        child: Center(
          child: NextFailedNotice(
            label: 'Chapter ${chapterNumberText(n)}',
            onRetry: () => unawaited(ref.read(readAllControllerProvider)?.retry(chapterKey) ?? Future<void>.value()),
            onOpen: () => _goToChapter(chapterKey),
          ),
        ),
      );
    }
    return OcrPageOverlay(controller: _ocr, sourceId: _id.sourceId, seriesKey: _id.seriesKey, chapterKey: chapterKey, page: page, size: box);
  }

  /// The ruler's position in the loaded read-all window: the page counted from the start of the
  /// first loaded chapter, and the pages loaded in all.
  ({int page, int count})? _readAllGlobal(ReaderEngineState s) {
    if (s.readAll == null) return null;
    final counts = [for (final c in _body.feed.chapters) c.pages.length];
    if (counts.isEmpty || s.chapterIndex >= counts.length) return null;
    final starts = chapterStarts(counts);
    return (page: starts[s.chapterIndex] + s.page, count: counts.fold<int>(0, (a, b) => a + b));
  }

  String _readAllFlag(int global) {
    final counts = [for (final c in _body.feed.chapters) c.pages.length];
    final loc = locateGlobalPage(counts, global - 1);
    final id = _body.feed.chapters[loc.chapter].id;
    final n = ref.read(readerSeriesProvider(_seriesKey))?.chapterOf(id)?.number;
    return readAllFlag(chapterFolio(n), loc.page);
  }

  /// Dragging the read-all ruler: the chapter under the finger, then the page in it.
  void _readAllSeek(int global) {
    final counts = [for (final c in _body.feed.chapters) c.pages.length];
    final loc = locateGlobalPage(counts, global - 1);
    if (loc.chapter != _engine.value.chapterIndex) _engine.seekToChapter(loc.chapter);
    _engine.jumpToPage(loc.page);
  }

  void _retryPage(ReaderChapter chapter, int n) {
    final p = chapter.pages[n - 1];
    if (p.imageUrl.isNotEmpty) unawaited(CachedNetworkImage.evictFromCache(p.imageUrl));
    setState(() => _retryEpoch['${chapter.id}:$n'] = (_retryEpoch['${chapter.id}:$n'] ?? 0) + 1);
  }

  void _openImage(ReaderChapter chapter, int n) {
    setState(() => _heroFor = (chapter: chapter.id, page: n));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        openPageImage(context, ref, chapter: chapter, page: chapter.pages[n - 1], heroTag: 'reader-page-${chapter.id}-$n').whenComplete(() {
          if (mounted) setState(() => _heroFor = null);
        }),
      );
    });
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
              if (chapter.id != current) _pickChapter(chapter.id);
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
    final userStrip = ref.watch(sharedPrefsProvider).getInt('mm.reader.device.stripWidthPx');
    final feedLast = body.feed.chapters.isEmpty ? null : body.feed.chapters.last;
    final lastChapterSummary = feedLast == null ? null : series?.chapterOf(feedLast.id);
    final nextSummary = feedLast == null ? null : series?.nextOf(feedLast.id);
    final nextExists = body.onNextChapter != null || nextSummary != null || (feedLast?.nextChapterId != null);
    final autoNext = prefs.autoNextChapter;
    final offline = body.feed.chapters.isNotEmpty && body.feed.pages.isNotEmpty && body.feed.pages.first.localFile != null;
    final footerMode = nextExists && !autoNext ? CreditsMode.full : (nextExists ? CreditsMode.compact : CreditsMode.full);
    final footerExtent = (nextExists ? (autoNext ? 260.0 : 980.0) : 920.0) * math.max(1.0, scale);

    // The next-chapter auto-queue lives in the reader screens (library and source), not here.
    _syncSwipeable(prefs);
    final settings = ref.watch(readerSettingsProvider);
    _ambient.sync(
      context,
      chapters: body.feed.chapters,
      tintOn: settings.pageTint,
      paceByDialogue: settings.paceByDialogue,
      resumeAfterRelease: prefs.resumeAfterRelease,
      rtl: prefs.rtl,
      panelsWanted: true,
    );

    final readAllKeys = _isReadAll ? ref.watch(seriesReadingOrderProvider((sourceId: _id.sourceId, seriesId: _id.seriesKey))).valueOrNull : null;
    final layout = _isReadAll ? ReaderLayout.strip : _layoutOf(prefs);
    if (layout != _lastLayout) {
      // Switching layout keeps the page: the view being replaced still holds the state.
      final s = _engine.value;
      _carryChapterId = s.chapterId.isEmpty ? null : s.chapterId;
      _carryPage = s.page;
      _lastLayout = layout;
      _lastZonesKey = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _carryPage = null;
        _carryChapterId = null;
      });
    }
    final paged = layout != ReaderLayout.strip;
    _syncBands(prefs, layout);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _engine.setLayout(layout, rtl: prefs.rtl, pagePhysics: paged ? const CinePagePhysics() : null);
    });

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
      pageLayerBuilder: (context, pages) => paged ? readerWarmth(context, pages, prefs.warmthPct) : _pageLayer(context, pages, prefs),
      pageSemantics: accessible ? _pageSemantics : (context, chapter, n, page) => Semantics(label: 'Page $n of ${chapter.pages.length}', child: page),
      slotSignature: (series?.chapters.length, prefs.autoNextChapter, _heroFor, Object.hashAll(_retryEpoch.values)),
      seamExtent: _isReadAll ? ReadAllDivider.extent : kChapterSeamExtent,
      readAllKeys: readAllKeys,
      pageOverlayBuilder: _overlayFor,
      onPageLongPress: (chapterId, page) {
        if (_locked) return;
        cineFeedback(context, HapticEvent.longpressOpen);
        unawaited(_openPageActions(chapterId: chapterId, page: page));
      },
      pageHeroTag: (chapterId, page) => _heroFor?.chapter == chapterId && _heroFor?.page == page ? 'reader-page-$chapterId-$page' : null,
      pageEpoch: (chapterId, page) => _retryEpoch['$chapterId:$page'] ?? 0,
      lifecycleVolumeKeys: true,
    );

    Widget chrome(BuildContext context, ReaderEngineState state) =>
        _chrome(context, state, prefs, series, tablet: tablet, landscape: landscape, reduced: reduced, paged: paged);
    final autoHideAfter = accessible ? const Duration(days: 1) : const Duration(milliseconds: 3000);
    final Widget view;
    if (layout == ReaderLayout.guided) {
      final chapter = _chapterById(_carryChapterId ?? _id.chapterKey) ?? body.feed.chapters.first;
      view = CineGuidedView(
        key: const ValueKey('guided'),
        engine: _engine,
        chapter: chapter,
        rtl: prefs.rtl,
        ground: ground,
        chromeBuilder: chrome,
        initialPage: _carryPage ?? body.initialPage,
        autoAdvance: settings.guidedAutoAdvance,
        autoHideAfter: autoHideAfter,
        onSaveProgress: body.onSaveProgress,
        onPreviousChapter: body.onPreviousChapter,
        onNextChapter: body.onNextChapter,
        creditsBuilder: (context) => ColoredBox(color: ground, child: SingleChildScrollView(child: _credits(context, chapter, null, CreditsMode.compact))),
      );
    } else if (paged) {
      final chapter = _chapterById(_carryChapterId ?? _id.chapterKey) ?? body.feed.chapters.first;
      view = PagedReaderView(
        key: const ValueKey('paged'),
        controller: _engine,
        chapter: chapter,
        spec: ReaderLayoutSpec(layout: layout, rtl: prefs.rtl, pagePhysics: const CinePagePhysics()),
        chromeBuilder: chrome,
        autoHideAfter: autoHideAfter,
        fit: switch (prefs.fit) {
          'width' => ReaderPageFit.width,
          'original' => ReaderPageFit.original,
          _ => ReaderPageFit.height,
        },
        ground: ground,
        turn: PageTurn.values.firstWhere((t) => t.name == prefs.pageTurn, orElse: () => PageTurn.cut),
        slideDuration: context.cine.durPageturn,
        slideCurve: CineCurves.settle,
        fadeDuration: context.cine.durBeat,
        reducedMotion: reduced,
        reducedDuration: context.cine.durReduced,
        initialPage: _carryPage ?? body.initialPage,
        onEvent: _onEvent,
        bookmarkAnchors: body.bookmarkAnchors,
        onSaveProgress: body.onSaveProgress,
        onAddBookmark: body.onAddBookmark,
        onPreviousChapter: body.onPreviousChapter,
        onNextChapter: body.onNextChapter,
        options: options,
        style: PagedStageStyle(centreLine: context.cine.colorRule1),
      );
    } else {
      view = ReaderEngineView(
        key: const ValueKey('strip'),
        controller: _engine,
        slots: ReaderSurfaceSlots(
          chapterSeam: (context, chapter, axis) => const SizedBox.shrink(),
          brokenPage: (context, retry) => const SizedBox.shrink(),
          pagedCornerRadius: 0,
        ),
        autoHideAfter: autoHideAfter,
        chromeBuilder: chrome,
        onEvent: _onEvent,
        feed: body.feed,
        scrollStorageKey: body.scrollStorageKey,
        onBack: _leave,
        onOpenSeries: _openSeries,
        initialPage: _carryPage ?? body.initialPage,
        initialAnchor: _carryPage != null ? (page: _carryPage!, fraction: 0.0) : body.initialAnchor,
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
    }

    final leftPanel = tablet && prefs.panels.left;
    final rightPanel = tablet && prefs.panels.right;
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
                          rightOpen: rightPanel,
                          left: ContentsPanel(
                            list: _contentsListPanel(),
                            onClose: () => _setLeftPanel(false),
                          ),
                          right: MarginsPanel(
                            engine: _engine,
                            overlay: _ocr,
                            sourceId: _id.sourceId,
                            seriesKey: _id.seriesKey,
                            chapterKey: _engine.value.chapterId.isEmpty ? _id.chapterKey : _engine.value.chapterId,
                            chapterNumber: series?.chapterOf(_engine.value.chapterId.isEmpty ? _id.chapterKey : _engine.value.chapterId)?.number,
                            chapterSaved: offline,
                            completedOpen: _completedOpen,
                            seriesTitle: series?.title,
                            onClose: () => _setRightPanel(false),
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
        if (chapter.id != current) _pickChapter(chapter.id);
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
      case ReaderPageSwiped():
        cineFeedback(context, HapticEvent.pageTurn, sound: SoundEvent.pageTurn);
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
                  final verdict = classifySwipe(dx: r.totalDx, vx: d.primaryVelocity ?? 0, zoom: _engine.value.zoom, rtl: prefs.rtl);
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
    if (_isReadAll && kind == BandKind.seam) {
      // The feed's own titles rarely equal the series list's: find the chapters by id through the feed.
      double? numberOf(String? title) {
        final c = _body.feed.chapters.where((c) => c.title == title).firstOrNull;
        return (c == null ? null : series?.chapterOf(c.id)?.number) ?? series?.chapterTitled(title ?? '')?.number;
      }

      return ReadAllDivider(from: chapterNumberText(numberOf(from)), to: chapterNumberText(numberOf(to)));
    }
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
    void goNext() {
      if (nextKey == null) return;
      cineFeedback(context, HapticEvent.chapterNext, sound: SoundEvent.chapterNext);
      final n = next?.number;
      ref.read(pendingChapterCaptionProvider.notifier).state = n == null ? null : 'CH ${chapterNumberText(n)} — ${next!.title}';
      _goToChapter(nextKey);
    }

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
      onContinue: goNext,
      // K5: a committed pull fades through black for durFadeCut, then opens the chapter.
      onPull: () {
        if (nextKey == null) return;
        setState(() => _fadeBlack = true);
        Timer(_reduced ? Duration.zero : context.cine.durFadeCut, () {
          if (mounted) goNext();
        });
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

  /// The chrome root: the page-tint colour animation around the chrome, rebuilt when the panels,
  /// the auto-scroll behaviour or the house sound change.
  Widget _chrome(
    BuildContext context,
    ReaderEngineState s,
    ReaderPrefs prefs,
    ReaderSeries? series, {
    required bool tablet,
    required bool landscape,
    required bool reduced,
    required bool paged,
  }) {
    final house = ref.read(houseSoundProvider);
    return ReaderTintHost(
      source: _engine.pageTint,
      enabled: ref.read(readerSettingsProvider).pageTint,
      coverDuo: series?.summary.ambient?.duo ?? const Color(0xFFB8B2A4),
      child: Builder(
        builder: (context) {
          _tintLight = ReaderTintScope.of(context).light;
          return ListenableBuilder(
            listenable: Listenable.merge([_engine.panels, _engine.autoScroll, _engine.wordsOnScreen, house]),
            builder: (context, _) => _chromeBody(context, s, prefs, series, tablet: tablet, landscape: landscape, reduced: reduced, paged: paged),
          );
        },
      ),
    );
  }

  Widget _chromeBody(
    BuildContext context,
    ReaderEngineState s,
    ReaderPrefs prefs,
    ReaderSeries? series, {
    required bool tablet,
    required bool landscape,
    required bool reduced,
    required bool paged,
  }) {
    final chapter = series?.chapterOf(s.chapterId);
    final prev = series?.previousOf(s.chapterId);
    final next = series?.nextOf(s.chapterId);
    final loadingChapter = s.chapterId.isEmpty;
    final brightness = _brightnessDraft ?? prefs.brightness;
    final speedX = _speedDraft ?? prefs.autoScrollSpeedX;
    // The chapter being read, not the first stitched one: a saved chapter between two remote ones is still an offline edition.
    final current = _body.feed.chapters.where((ch) => ch.id == s.chapterId).firstOrNull;
    final offline = current != null && current.pages.isNotEmpty && current.pages.first.localFile != null;
    final bookmarked = s.bookmarks.any((a) => a.page == s.page);
    final minutes = minutesLeft(page: s.page, pageCount: s.pageCount, pagesPerMinute: _pace.pagesPerMinute);
    final showChrome = s.chromeVisible && !s.locked;
    final raGlobal = _readAllGlobal(s);
    final trailing = <Widget>[
      ChapterDownloadControl(sourceId: _id.sourceId, seriesKey: _id.seriesKey, chapterKey: s.chapterId.isEmpty ? _id.chapterKey : s.chapterId),
      CineIconButton(
        label: bookmarked ? 'Remove bookmark' : 'Bookmark this page',
        codepoint: 0xe0ea,
        selected: bookmarked,
        onPressed: _body.onAddBookmark == null ? null : _bookmark,
      ),
      if (!_isReadAll && (_guided || _engine.panels.value[s.page] is PanelsFound))
        CineIconButton(label: 'Guided view', role: CineIconRole.guidedView, selected: _guided, onPressed: _toggleGuided),
      if (tablet) CineIconButton(label: 'Contents', role: CineIconRole.contents, selected: prefs.panels.left, onPressed: _openContents),
      if (tablet) CineIconButton(label: 'Margins', codepoint: ReaderCp.notePencil, selected: prefs.panels.right, onPressed: _openMargins),
      CineIconButton(label: 'Reading setup', role: CineIconRole.readerSettings, onPressed: _openSetup),
      if (tablet) CineIconButton(label: 'Page actions', role: CineIconRole.overflow, onPressed: _openPageActions),
    ];
    return Stack(
      children: [
        if (paged && _bandsOn)
          Positioned.fill(
            child: TapZoneBands(
              labels: bandLabels(resolveZones(prefs.tapZones, rtl: prefs.rtl)),
              replay: _zonesReplay,
              onDone: () {
                if (mounted) setState(() => _bandsOn = false);
              },
            ),
          ),
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
                      folio: s.readAll == null ? chapterFolio(chapter?.number) : '${chapterFolio(chapter?.number)} · ${s.readAll!.index} OF ${s.readAll!.total}',
                      loading: loadingChapter,
                      offlineEdition: offline,
                      onBack: _leave,
                      onOpenSeries: _openSeries,
                      onOpenContents: _openContents,
                      trailing: trailing,
                      houseSoundLabel: _houseLabel(),
                      onOpenHouseSound: _openHouseSound,
                    ),
                  ),
                ),
                if (s.page == 1 && !loadingChapter)
                  Positioned(
                    top: MediaQuery.viewPaddingOf(context).top + cineHitMin(context) + 8,
                    left: MediaQuery.sizeOf(context).width >= 600 ? context.cine.space8 : context.cine.space4,
                    child: ReaderChromeMotion(
                      visible: showChrome && !(landscape && !s.chromeVisible),
                      fromTop: true,
                      child: PreviouslyOnChip(
                        sourceId: _id.sourceId,
                        seriesKey: _id.seriesKey,
                        chapterKey: s.chapterId,
                        lastReadAt: _lastReadAt,
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
                      showAutoScroll: !paged || _guided,
                      rulerPage: raGlobal?.page,
                      rulerCount: raGlobal?.count,
                      rulerBoundaries: s.readAll?.boundaries ?? const [],
                      rulerFlag: raGlobal == null ? null : _readAllFlag,
                      onRulerSeek: raGlobal == null ? null : _readAllSeek,
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
        HouseSoundBinding(genres: series?.summary.genres ?? const <String>[]),
        if (s.autoScrolling && !s.locked)
          positionAutoScrollChip(
            context,
            chromeVisible: showChrome,
            child: CineAutoScrollChip(
              speedX: speedX,
              running: _engine.autoScroll.moving,
              paced: _engine.autoScroll.paced,
              autoLabel: _guided ? _guidedChipLabel() : null,
              progress: s.progress,
              onToggle: _chipToggle,
              onOpenRuler: _openSpeedSheet,
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
          label: brightness < 0 ? 'NIGHT \u2212${-brightness}' : '0',
        ),
        EdgeHud(left: false, visible: _speedHud.visible, fill: (speedX - 0.5) / 2.5, label: '${speedX.toStringAsFixed(1)}×'),
        if (_caption != null) _CaptionTyped(text: _caption!),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              key: const ValueKey('pull-fade'),
              opacity: _fadeBlack ? 1 : 0,
              duration: _reduced ? Duration.zero : context.cine.durFadeCut,
              child: const ColoredBox(color: Colors.black),
            ),
          ),
        ),
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
      e(LogicalKeyboardKey.keyU, 'Guided view', _toggleGuided),
      e(LogicalKeyboardKey.keyP, 'Auto-scroll', _toggleAutoScroll),
      e(LogicalKeyboardKey.comma, 'Slower', () => _stepSpeed(-0.25), shift: true, single: false, keys: const ['<']),
      e(LogicalKeyboardKey.period, 'Faster', () => _stepSpeed(0.25), shift: true, single: false, keys: const ['>']),
      e(LogicalKeyboardKey.keyB, 'Bookmark this page', () => unawaited(_bookmark())),
      e(LogicalKeyboardKey.keyS, 'Back to the series', _leave),
      e(LogicalKeyboardKey.bracketLeft, 'Contents', () {
        _engine.showChrome();
        _openContents();
      }),
      e(LogicalKeyboardKey.comma, 'Reading setup', _openSetup),
      e(LogicalKeyboardKey.bracketRight, 'Margins', _openMargins),
      e(LogicalKeyboardKey.keyW, 'Strip', () => _setLayoutByKey('w')),
      e(LogicalKeyboardKey.keyV, 'Single page', () => _setLayoutByKey('v')),
      e(LogicalKeyboardKey.keyR, 'Right-to-left single page', () => _setLayoutByKey('r')),
      e(LogicalKeyboardKey.contextMenu, 'Page actions', _openPageActions, single: false),
      e(LogicalKeyboardKey.f10, 'Page actions', _openPageActions, shift: true, single: false),
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
