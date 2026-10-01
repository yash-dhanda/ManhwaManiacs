import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Material, MaterialType, SelectionArea, SelectionAreaState, TextMagnifier;
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/color/cover_palette.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/circle/utils/spoiler_guard.dart' show completedThisSessionProvider;
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart' show DownloadKind;
import 'package:manhwamaniacs/features/downloads/providers/open_chapter_scope.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/controllers/novel_auto_scroll.dart';
import 'package:manhwamaniacs/features/novels/controllers/novel_reader_controller.dart';
import 'package:manhwamaniacs/features/novels/engine/novel_paginator.dart';
import 'package:manhwamaniacs/features/novels/engine/novel_paragraph_layout.dart' show kNovelSceneBreakExtent, novelParagraphIndents;
import 'package:manhwamaniacs/features/novels/models/glass_novel_prefs.dart';
import 'package:manhwamaniacs/features/novels/models/novel_chapter.dart';
import 'package:manhwamaniacs/features/novels/models/novel_typography.dart';
import 'package:manhwamaniacs/features/novels/providers/glass_novel_prefs_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_audio_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_cast_provider.dart' show novelAttributionProvider;
import 'package:manhwamaniacs/features/novels/providers/novel_chapter_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_preferences_provider.dart' show novelPaceStoreProvider;
import 'package:manhwamaniacs/features/novels/providers/saved_audio_provider.dart' show SavedAudioState, savedAudioStateProvider;
import 'package:manhwamaniacs/features/novels/providers/series_audio_provider.dart' show seriesAudioProvider;
import 'package:manhwamaniacs/features/novels/utils/narration_timing.dart' show FollowKind, followDecision;
import 'package:manhwamaniacs/features/novels/utils/novel_book.dart';
import 'package:manhwamaniacs/features/novels/utils/novel_pace.dart' show avgWordsPerLine;
import 'package:manhwamaniacs/features/novels/utils/novel_progress.dart';
import 'package:manhwamaniacs/features/novels/utils/speaker_slots.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_prefs_provider.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_profile_settings.dart';
import 'package:manhwamaniacs/features/reader/utils/glass_reader_values.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_wakelock.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart' show matureContentProvider;
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/ambient/cruise.dart';
import 'package:manhwamaniacs/skins/glass/ambient/cruise_controller.dart';
import 'package:manhwamaniacs/skins/glass/ambient/cruise_pill.dart';
import 'package:manhwamaniacs/skins/glass/ambient/novel_cruise.dart';
import 'package:manhwamaniacs/skins/glass/ambient/rain_on_glass.dart';
import 'package:manhwamaniacs/skins/glass/glass/light_angle.dart';
import 'package:manhwamaniacs/skins/glass/glass/registry.dart' show GlassLayerKind;
import 'package:manhwamaniacs/skins/glass/glass/shape.dart' show GlassShape;
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/glass/listen/cast_sheet.dart' show GlassCastBody;
import 'package:manhwamaniacs/skins/glass/listen/glass_narration_host.dart';
import 'package:manhwamaniacs/skins/glass/listen/highlight_layer.dart';
import 'package:manhwamaniacs/skins/glass/listen/listen_row.dart';
import 'package:manhwamaniacs/skins/glass/listen/paged_follow.dart';
import 'package:manhwamaniacs/skins/glass/listen/player_column.dart' show GlassPlayerColumn, PlayerForm;
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/parts/reactions/chapter_reactions.dart' show GlassChapterReactions;
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart' show glassA11yProvider;
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart' show GlassButton, GlassButtonIcon, GlassButtonVariant;
import 'package:manhwamaniacs/skins/glass/primitives/press.dart' show GlassMaterial, GlassPressable;
import 'package:manhwamaniacs/skins/glass/primitives/reactions/glass_reactions.dart';
import 'package:manhwamaniacs/skins/glass/primitives/reactions/reaction_flight.dart';
import 'package:manhwamaniacs/skins/glass/primitives/tab_pager.dart' show GlassTabPagerController;
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_swipe_route.dart';
import 'package:manhwamaniacs/skins/glass/routes/route_frame.dart';
import 'package:manhwamaniacs/skins/glass/routes/sheet_param_host.dart';
import 'package:manhwamaniacs/skins/glass/routes/sheet_registry.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_common.dart' show paletteOf;
import 'package:manhwamaniacs/skins/glass/screens/library/library_common.dart' show roleIcon;
import 'package:manhwamaniacs/skins/glass/screens/novel/bottom_capsule.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/chapter_end_pull.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/chapter_header.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/chrome_top.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/contents_sheet.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/drop_cap_paragraph.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/end_matter.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/glass_paragraph.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/go_to_percent.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/line_guide.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/listen_bridge.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/novel_keys.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/novel_states.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/page_turn.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/paged_view.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/paper_frame.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/paper_ripple.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/papers.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/pinch_size.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/pinch_steps.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/progress_hairline.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/selection_menu.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/side_panels.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/speaker_bands.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/tinted_run_chip.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/type_rows.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/type_sheet.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/reader_system_ui.dart';
import 'package:manhwamaniacs/skins/glass/shell/purge.dart' show registerMatureStop, registerPlaybackStop;
import 'package:manhwamaniacs/skins/glass/skin_glass.dart' show SkinGlass;
import 'package:manhwamaniacs/skins/glass/soundscape/mixer.dart' show MixLevels;
import 'package:manhwamaniacs/skins/glass/soundscape/recipes.dart';
import 'package:manhwamaniacs/skins/glass/soundscape/soundscape_controller.dart';
import 'package:manhwamaniacs/skins/glass/soundscape/soundscape_sheet.dart';
import 'package:manhwamaniacs/skins/glass/type.dart' show GlassText;

/// The reading line: 38 % from the top (G1).
const double kNovelReadingLine = 0.38;

/// Thresholds of E1: 24 px down hides, 56 px up shows, 3000 ms idle hides after a tap opened it, never in the first 800 ms of a
/// chapter, never within 30 s of a hardware key.
const double kChromeHideDown = 24, kChromeShowUp = 56;
const Duration kChromeIdle = Duration(milliseconds: 3000), kChromeChapterGrace = Duration(milliseconds: 800), kChromeKeyGrace = Duration(seconds: 30);

/// A tap: down and up within 400 ms and 18 px (F1's `press.lift` uses the same 18 px; it fires at 150 ms).
const Duration kTapMax = Duration(milliseconds: 400), kPressLift = Duration(milliseconds: 150);
const double kTapSlop = 18;

/// The `nonce` extra: a different chapter opened by Dive is a new page; the seamless next keeps the page it is on.
String novelNonce(GoRouterState state) {
  final e = state.extra;
  return e is Map ? '${e['nonce'] ?? ''}' : '';
}

/// The page key of a novel route: the book plus the nonce, never the chapter, so the seamless next chapter replaces the location
/// without a new page (D12).
ValueKey<String> novelPageKey(GoRouterState state) {
  final p = state.pathParameters;
  return ValueKey<String>('glass-novel:${p['sourceId']}:${p['seriesKey']}:${novelNonce(state)}');
}

/// The novel route's page (B1, B3): a reader page (instant enter, the 20 px iOS strip) keyed by [novelPageKey].
Page<void> glassNovelPage(GoRouterState state) {
  final key = novelPageKey(state);
  final body = GlassRouteFrame(routeKey: key.value, sheetHost: (c) => GlassSheetParamHost(child: c), child: GlassNovelReaderScreen.of(state));
  if (defaultTargetPlatform == TargetPlatform.android) {
    return GlassMaterialPage<void>(key: key, name: state.name, builder: (_) => body, instantEnter: true);
  }
  // Book open (`extra: {'entry': 'book', ...}`) is routed to mobile/33's `GlassBookOpenPage` in `router.dart`.
  return GlassSwipePage<void>(key: key, name: state.name, builder: (_) => body, edgeOnly: 20, instantEnter: true);
}

/// ScreenId `novel` (`/novels/:sourceId/:seriesKey/:chapterKey?page&para&at&listen=1`): the Glass novel reader (glass 8.15).
class GlassNovelReaderScreen extends StatelessWidget {
  const GlassNovelReaderScreen({super.key, required this.sourceId, required this.seriesKey, required this.chapterKey, this.bucket = 1, this.paragraph, this.fraction, this.nonce = '', this.listen = false});

  factory GlassNovelReaderScreen.of(GoRouterState s) {
    final p = s.pathParameters;
    final q = s.uri.queryParameters;
    final at = double.tryParse(q['at'] ?? '');
    return GlassNovelReaderScreen(
      sourceId: p['sourceId'] ?? '',
      seriesKey: p['seriesKey'] ?? '',
      chapterKey: p['chapterKey'] ?? '',
      bucket: (int.tryParse(q['page'] ?? '') ?? 1).clamp(1, 100),
      paragraph: int.tryParse(q['para'] ?? ''),
      fraction: at == null || at.isNaN ? null : at.clamp(0.0, 1.0),
      nonce: novelNonce(s),
      listen: q['listen'] == '1',
    );
  }

  final String sourceId, seriesKey, chapterKey;
  final int bucket;
  final int? paragraph;
  final double? fraction;
  final String nonce;
  final bool listen;

  @override
  Widget build(BuildContext context) => GlassReaderSystemUi(
        child: GlassNovelReader(
          key: ValueKey('glass-novel-reader:$sourceId:$seriesKey:$nonce'),
          sourceId: sourceId,
          seriesKey: seriesKey,
          chapterKey: chapterKey,
          bucket: bucket,
          paragraph: paragraph,
          fraction: fraction,
          nonce: nonce,
          listen: listen,
        ),
      );
}

/// The reader's body. It renders `NovelReaderController`'s state (`mobile/14`) and owns no reading logic of its own.
class GlassNovelReader extends ConsumerStatefulWidget {
  const GlassNovelReader({super.key, required this.sourceId, required this.seriesKey, required this.chapterKey, this.bucket = 1, this.paragraph, this.fraction, this.nonce = '', this.listen = false, this.chromeSlots = const [], this.topCentreSlots = const []});
  final String sourceId, seriesKey, chapterKey;
  final int bucket;
  final int? paragraph;
  final double? fraction;
  final String nonce;

  /// `?listen=1`: start reading aloud at the resume point once the first frame is laid out (glass 8.15.2).
  final bool listen;

  /// Extra top-right buttons from later steps (`mobile/37`'s own listen and voices buttons are added here).
  final List<NovelChromeSlot> chromeSlots;

  /// `mobile/41`'s "Previously · 20 s" pill (E9); the newest capsule wins the slot.
  final List<Widget> topCentreSlots;

  @override
  ConsumerState<GlassNovelReader> createState() => GlassNovelReaderState();
}

class GlassNovelReaderState extends ConsumerState<GlassNovelReader> with TickerProviderStateMixin, WidgetsBindingObserver implements NovelReadingSurface {
  late final NovelReaderArgs _args = NovelReaderArgs(
    sourceId: widget.sourceId,
    seriesKey: widget.seriesKey,
    chapterKey: widget.chapterKey,
    readingLineFraction: kNovelReadingLine,
    initialBucket: widget.bucket,
    initialParagraph: widget.paragraph,
    initialFraction: widget.fraction,
    attribution: true,
  );
  late final NovelReaderController _ctl = ref.read(novelReaderControllerProvider(_args).notifier);
  late final ReaderWakelock _wakelock = ref.read(readerWakelockProvider);
  late final AnimationController _chromeAnim;
  late final AnimationController _nextAnim;
  late final AnimationController _pulse;
  late final AnimationController _flag;
  late final AnimationController _leftAnim;
  late final AnimationController _rightAnim;

  final ScrollController _scroll = ScrollController();
  late final NovelAutoScroll _cruiseAuto = NovelAutoScroll(scroll: _scroll, vsync: this, basePxPerSecond: _cruiseBase, onEnd: _cruiseEnded);
  final List<VoidCallback> _ambientStops = [];
  SoundscapeController? _soundscape;
  final FocusNode _surfaceFocus = FocusNode(debugLabel: 'novel reading surface');
  final FocusScopeNode _chromeScope = FocusScopeNode(debugLabel: 'novel chrome');
  final FocusScopeNode _leftScope = FocusScopeNode(debugLabel: 'novel contents panel');
  final FocusScopeNode _rightScope = FocusScopeNode(debugLabel: 'novel type panel');
  final GlobalKey<NovelPagedViewState> _pagedView = GlobalKey();
  final GlobalKey<SelectionAreaState> _selection = GlobalKey();
  final GlobalKey _titleKey = GlobalKey(debugLabel: 'novel title capsule');
  final GlobalKey _nextCardKey = GlobalKey(debugLabel: 'novel next card');
  final GlobalKey _viewportKey = GlobalKey(debugLabel: 'novel viewport');
  final GlobalKey _headerKey = GlobalKey(debugLabel: 'novel header measure');
  final ChapterEndPull _pull = ChapterEndPull();
  final PinchTracker _pinch = PinchTracker();
  final List<VoidCallback> _releases = [];

  List<GlobalKey> _keys = const [];
  bool _chrome = false;
  bool _restored = false;
  bool _leftPanel = false, _rightPanel = false;
  bool _goTo = false;
  int _sheets = 0;
  bool _selectionActive = false;
  String _selectedText = '';
  OverlayEntry? _keyboardMenu;
  ({String text, Rect anchor})? _chip;
  double? _pinchSize;
  int _pinchSteps = 0;
  double _overAccum = 0;
  double _lastPixels = 0, _downAccum = 0, _upAccum = 0;
  Duration _chapterStart = Duration.zero;
  Duration? _lastKey;
  Timer? _idle, _pressLift, _rateTimer;
  int? _rateLeft;
  Offset? _downAt;
  Duration? _downTime;
  bool _runTapped = false;
  int? _pulseParagraph;
  Offset? _rippleOrigin;
  int _revision = 0;
  String? _announced;

  // -- Listen mode (mobile/37) --
  late final GlassListenBand _band = GlassListenBand(vsync: this, reduced: () => _reduced, onSentence: _onBandSentence);
  final PagedFollow _pagedFollow = PagedFollow();
  late final AnimationController _jumpFade = AnimationController(vsync: this, duration: const Duration(milliseconds: 120), value: 1);
  bool _voiceDecoupled = false, _programmaticTurn = false, _listenBooted = false;

  Object? _pageKey;
  ProviderSubscription<NovelReaderState>? _sub;
  int _semanticsPercent = 0;
  bool _programmatic = false;

  // -- Lifecycle --------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _chapterStart = _now;
    _chromeAnim = AnimationController(vsync: this, value: 0);
    _nextAnim = AnimationController(vsync: this, value: 1);
    _pulse = AnimationController(vsync: this, value: 1);
    _flag = AnimationController(vsync: this, value: 0);
    _leftAnim = AnimationController(vsync: this, value: 0);
    _rightAnim = AnimationController(vsync: this, value: 0);
    WidgetsBinding.instance.addObserver(this);
    for (final id in const [kNovelSheetContents, kNovelSheetType, kNovelSheetNote, kNovelSheetSoundscape]) {
      _releases.add(glassClaimSheet(id));
    }
    _ctl
      ..attach(this)
      ..seamless = true
      ..locationReplacer = _replaceLocation
      ..narrationBusy = _narrationBusy;
    _scroll.addListener(_onScroll);
    _attachAmbient();
    _sub = ref.listenManual<NovelReaderState>(novelReaderControllerProvider(_args), _onState);
    ref.listenManual<NarrationState>(narrationControllerProvider, _onNarration);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _surfaceFocus.requestFocus();
      _syncWakelock();
      _openSheetFromLocation();
      _bootListen();
      glassFire(ref, HapticEvent.readerEnter);
      glassSound(ref, SoundEvent.readerEnter);
    });
  }

  @override
  void didUpdateWidget(GlassNovelReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chapterKey != oldWidget.chapterKey && widget.chapterKey != ref.read(novelReaderControllerProvider(_args)).chapter?.chapterKey) {
      _ctl.swapTo(widget.chapterKey);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      unawaited(_wakelock.disable());
    } else if (state == AppLifecycleState.resumed) {
      _syncWakelock();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final r in _releases) {
      r();
    }
    _sub?.close();
    _idle?.cancel();
    _pressLift?.cancel();
    _rateTimer?.cancel();
    _keyboardMenu?.remove();
    _ctl
      ..detach(this)
      ..locationReplacer = null;
    for (final stop in _ambientStops) {
      stop();
    }
    _soundscape?.leaveReader();
    _cruiseAuto.dispose();
    _scroll.dispose();
    _band.dispose();
    _jumpFade.dispose();
    for (final c in [_chromeAnim, _nextAnim, _pulse, _flag, _leftAnim, _rightAnim]) {
      c.dispose();
    }
    _surfaceFocus.dispose();
    _chromeScope.dispose();
    _leftScope.dispose();
    _rightScope.dispose();
    unawaited(_wakelock.disable());
    super.dispose();
  }

  // -- Derived values ---------------------------------------------------------

  /// Monotonic time from the frame clock (the test clock under `flutter test`).
  Duration get _now => SchedulerBinding.instance.currentSystemFrameTimeStamp;

  GlassBookRef get _book => (sourceId: widget.sourceId, seriesKey: widget.seriesKey);
  bool get _reduced => GlassMotion.isReduced() || ref.read(glassReducedProvider);
  bool get _desktop => novelDesktopFrame(MediaQuery.sizeOf(context));
  bool get _phone => MediaQuery.sizeOf(context).shortestSide < 600;

  GlassNovelValues _values() {
    final v = ref.read(glassNovelPrefsProvider(_book)).values(desktopFrame: _desktop, scale: MediaQuery.textScalerOf(context).scale);
    final p = _pinchSize;
    return p == null ? v : v.copyWith(fontSize: p);
  }

  bool get _paged => _values().paged;

  NovelReaderState get _state => ref.read(novelReaderControllerProvider(_args));

  SourceSeriesDetailData? get _series => ref.read(sourceSeriesDetailProvider((sourceId: widget.sourceId, seriesId: widget.seriesKey))).valueOrNull;

  String get _seriesTitle => _series?.series.title ?? '';

  NovelChapterKey get _chapterKey => (sourceId: widget.sourceId, seriesKey: widget.seriesKey, chapterKey: _state.chapter?.chapterKey ?? widget.chapterKey);

  GlassListenBridge? _bridge() {
    final c = _state.chapter;
    if (c == null) return null;
    return ref.read(glassListenBridgeProvider(GlassListenContext(key: _chapterKey, paragraphs: c.paragraphs, bookTitle: _seriesTitle, chapterNumber: c.chapterNumber, chapterTitle: c.title)));
  }

  bool _narrationBusy() {
    final n = ref.read(narrationControllerProvider);
    return n.active && n.key == _chapterKey;
  }

  String _numberText(double? n) => n == null ? '·' : formatChapterNumber(n);

  /// "Ch 12" for the title capsule.
  String _short(NovelChapter c) => 'Ch ${_numberText(c.chapterNumber)}';

  SourceChapterSummary? _summary(String? key) {
    if (key == null) return null;
    for (final c in _series?.chapters ?? const <SourceChapterSummary>[]) {
      if (c.id == key) return c;
    }
    return null;
  }

  /// "Chapter 13 · The Tower".
  String? _nextLabel() {
    final key = _ctl.nextKey;
    if (key == null) return null;
    final s = _summary(key);
    final number = s?.number == null ? null : formatChapterNumber(s!.number!);
    final title = s?.title ?? '';
    return [if (number != null) 'Chapter $number' else 'Next chapter', if (title.isNotEmpty && title != 'Chapter $number') title].join(' · ');
  }

  ({bool ready, double wpm}) _pace() {
    final store = ref.read(novelPaceStoreProvider);
    return (ready: store.samples().length >= 3, wpm: store.paceWpm);
  }

  // -- Listen mode (mobile/37, glass 8.16) -------------------------------------------

  GlassNarrationActions get _actions => ref.read(glassNarrationActionsProvider);

  bool get _narratingHere {
    final n = ref.read(narrationControllerProvider);
    return n.key == _chapterKey && n.target != null && n.active;
  }

  /// `?listen=1`: reads aloud from the resume point once the first frame is laid out; a start that cannot happen (audio focus
  /// refused, still preparing) leaves the listen row up, paused.
  void _bootListen() {
    if (_listenBooted || !widget.listen || _state.chapter == null) return;
    _listenBooted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_listenStart());
    });
  }

  /// The narration moved: when it went on to the neighbouring chapter the text swaps in place (the post-play card, the lock screen),
  /// and on the desktop frame starting narration opens the Listen tab.
  void _onNarration(NarrationState? prev, NarrationState next) {
    final k = next.key;
    if (k == null || !mounted) return;
    final mine = _chapterKey;
    if (k != prev?.key) {
      _voiceDecoupled = false;
      _pagedFollow.backToTheVoice();
      if (prev?.key == mine && k.sourceId == mine.sourceId && k.seriesKey == mine.seriesKey && k.chapterKey != mine.chapterKey) {
        if (k.chapterKey == _ctl.nextKey) {
          _next();
        } else if (k.chapterKey == _ctl.previousKey) {
          _previous();
        }
      }
    }
    if (_desktop && !(prev?.active ?? false) && next.active && k == mine) _showRightTab(2);
  }

  /// Starts reading aloud at the reading line's paragraph (the header capsule, the listen button, `p`).
  Future<void> _listenStart({bool fromReadingLine = true}) async {
    final b = _bridge();
    if (b == null) return;
    // The audio answer may still be on its way (a deep link starts narration at the first frame).
    if (await ref.read(playableNovelAudioProvider(_chapterKey).future) == null || !mounted) return;
    glassFire(ref, HapticEvent.listenToggle);
    final para = fromReadingLine ? (anchorAtReadingLine()?.index ?? (_paged ? paragraphOfPage(_ctl.pages, _pagedView.currentState?.page ?? 0) : 0)) : 0;
    _voiceDecoupled = false;
    _pagedFollow.backToTheVoice();
    await b.playFrom(para);
  }

  /// The listen button (glass 8.15.3): the owner on an un-narrated chapter lands in the Audiobook sheet (Narrate, this chapter selected);
  /// everyone else starts narration, or opens the player when it is already reading this chapter.
  void _onListenButton() {
    final key = _chapterKey;
    if (_narratingHere) {
      _openListenSurface();
      return;
    }
    final playable = ref.read(playableNovelAudioProvider(key)).valueOrNull;
    if (playable != null) {
      unawaited(_listenStart());
      return;
    }
    if (ref.read(glassIsOwnerProvider)) {
      _holdChrome();
      _actions.openSheet('audiobook', extra: {'series': '${key.sourceId}:${key.seriesKey}', 'chapter': key.chapterKey, 'mode': 'narrate'});
    }
  }

  /// The full player: a sheet over the page, or the Listen tab on the desktop frame.
  void _openListenSurface([Rect? from]) {
    _holdChrome();
    if (_desktop) {
      _showRightTab(2);
    } else {
      _actions.openPlayer(from);
    }
  }

  void _openVoices() {
    _holdChrome();
    if (_desktop) {
      _showRightTab(1);
    } else {
      _actions.openSheet('cast');
    }
  }

  final GlassTabPagerController _panelTabs = GlassTabPagerController();

  /// Opens the right panel on tab [i] (0 Aa, 1 Voices, 2 Listen).
  void _showRightTab(int i) {
    if (!_desktop) return;
    if (!_rightPanel) _togglePanel(right: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_panelTabs.pages.hasClients) _panelTabs.pages.jumpToPage(i);
    });
  }

  List<NovelChromeSlot> _listenSlots() {
    final key = _chapterKey;
    final playable = ref.read(playableNovelAudioProvider(key)).valueOrNull;
    final owner = ref.read(glassIsOwnerProvider);
    final canRender = ref.read(seriesAudioProvider((sourceId: key.sourceId, seriesKey: key.seriesKey))).valueOrNull?.canRender ?? false;
    if (playable == null && !(owner && canRender)) return const [];
    return [
      NovelChromeSlot(icon: GlassButtonIcon(roleIcon(GlassIconRole.listen), fill: roleIcon(GlassIconRole.listen, GlassIconWeight.fill)), label: 'Listen', onPressed: _onListenButton, inMoreMenu: true),
      NovelChromeSlot(icon: GlassButtonIcon(roleIcon(GlassIconRole.voiceCast), fill: roleIcon(GlassIconRole.voiceCast, GlassIconWeight.fill)), label: 'Voices', onPressed: _openVoices, inMoreMenu: true),
    ];
  }

  Widget _voicesTab(BuildContext c) => GlassCastBody(chapter: _chapterKey, onGlass: false);

  Widget _listenTab(BuildContext c) => Consumer(
        builder: (context, ref, _) {
          final n = ref.watch(narrationControllerProvider);
          if (n.target != null) return const GlassPlayerColumn(form: PlayerForm.tab);
          final has = ref.watch(playableNovelAudioProvider(_chapterKey)).valueOrNull != null;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GlassText(has ? 'Read this chapter aloud' : 'This chapter has no audio yet', role: gt.typeCallout, textAlign: TextAlign.center),
                  if (has) ...[const SizedBox(height: 12), GlassButton(label: 'Listen', variant: GlassButtonVariant.primary, onPressed: () => unawaited(_listenStart()))],
                ],
              ),
            ),
          );
        },
      );

  /// "Listen · 14 min" under the chapter facts (glass 8.15.2) and, when the audio cannot follow along, the quiet line saying so.
  List<Widget> _headerListen(NovelChapter chapter, PaperColors colors) {
    final playable = ref.read(playableNovelAudioProvider(_chapterKey)).valueOrNull;
    if (playable == null) return const [];
    final minutes = math.max(1, (playable.audio.totalMs / 60000).round());
    final saved = ref.read(savedAudioStateProvider(_chapterKey)) == SavedAudioState.saved;
    final label = 'Listen · $minutes min${saved ? ' · saved' : ''}';
    final follows = playable.audio.followsText(chapter.paragraphs);
    final style = roleStyle(context, gt.typeSubhead, wght: 600, maxScale: 1.5).copyWith(color: colors.ink);
    return [
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerLeft,
        child: GlassPressable(
          material: GlassMaterial.content,
          sink: 0.96,
          onTap: () => unawaited(_listenStart()),
          semanticsLabel: label,
          builder: (context, info) => ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Center(
              widthFactor: 1,
              child: DecoratedBox(
                decoration: ShapeDecoration(color: colors.ink.withValues(alpha: 0.12), shape: const GlassShape.capsule().border(const Size(180, 32))),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(roleIcon(GlassIconRole.listen, GlassIconWeight.fill), size: 16, color: colors.ink), const SizedBox(width: 8), Text(label, style: style, textScaler: TextScaler.noScaling)]),
                ),
              ),
            ),
          ),
        ),
      ),
      if (!follows)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('Audio plays without follow-along for this chapter', style: roleStyle(context, gt.typeCaption1, maxScale: 1.3).copyWith(color: colors.muted), textScaler: TextScaler.noScaling),
        ),
    ];
  }

  // Follow the voice (glass 8.16.7, J2 and J4).

  void _onBandSentence(BandTarget? t) {
    if (t == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _followVoice(t);
    });
  }

  void _followVoice(BandTarget t) {
    if (!_band.enabled) return;
    if (_paged) {
      _followPaged(t);
    } else {
      _followScroll(t);
    }
  }

  /// Paged mode: the page turns, with the chosen transition (Fade under reduced motion), the moment the voice reaches a sentence that is
  /// not on the page; a manual turn decouples until "Back to the voice".
  void _followPaged(BandTarget t) {
    final view = _pagedView.currentState;
    if (view == null || _ctl.pages.isEmpty) return;
    var target = -1;
    for (var i = 0; i < _ctl.pages.length && target < 0; i++) {
      for (final sl in _ctl.pages[i]) {
        if (sl.paragraphIndex == t.paragraph && sl.startChar <= t.start && t.start < sl.endChar) {
          target = i;
          break;
        }
      }
    }
    if (target < 0) target = pageOfParagraph(_ctl.pages, t.paragraph);
    final here = view.page;
    if (target == here || _pagedFollow.decoupled) return;
    _programmaticTurn = true;
    final delta = target - here;
    (delta.abs() == 1 ? view.turnBy(delta) : Future<void>(() => view.jumpTo(target))).whenComplete(() => _programmaticTurn = false);
  }

  /// Scroll mode: keeps the sentence at 38 % of the viewport and scrolls on `springSettle` only when it leaves 20-70 %; beyond two
  /// viewports it jumps with a 120 ms cross-fade; a manual scroll decouples (no automatic return).
  void _followScroll(BandTarget t) {
    if (_voiceDecoupled || !_scrollOk) return;
    final box = _boxFor(t.paragraph);
    final viewport = _viewportHeight();
    if (box == null) {
      // The paragraph is not built: land it at the top band through the controller's own path.
      _ctl.jumpToParagraph(t.paragraph, toReadingLine: false);
      return;
    }
    final text = _readerParagraphLength(t.paragraph);
    final fraction = text <= 0 ? 0.0 : (t.start / text).clamp(0.0, 1.0);
    final top = box.localToGlobal(Offset.zero).dy + fraction * box.size.height - _viewportTop();
    final d = followDecision(top, viewport);
    if (d.kind == FollowKind.none) return;
    final to = (_scroll.position.pixels + d.delta).clamp(_scroll.position.minScrollExtent, _scroll.position.maxScrollExtent);
    _programmatic = true;
    if (_reduced) {
      _jump(to);
      _programmatic = false;
    } else if (d.kind == FollowKind.jump) {
      unawaited(_jumpFade.animateTo(0.2, duration: const Duration(milliseconds: 60)).then((_) {
        if (mounted) _jump(to);
        return mounted ? _jumpFade.animateTo(1, duration: const Duration(milliseconds: 60)) : null;
      }).whenComplete(() => _programmatic = false),);
    } else {
      unawaited(_scroll.animateTo(to, duration: Duration(milliseconds: gt.springSettle.ms), curve: SpringCurve(gt.springSettle)).whenComplete(() => _programmatic = false));
    }
  }

  int _readerParagraphLength(int i) {
    final c = _state.chapter;
    return c == null || i < 0 || i >= c.paragraphs.length ? 0 : c.paragraphs[i].length;
  }

  /// A manual scroll or turn while narrating decouples the page from the voice.
  void _decoupleFromVoice() {
    if (!_band.enabled || _programmatic || _programmaticTurn) return;
    if (_paged) {
      if (_pagedFollow.decoupled) return;
      _pagedFollow.manualTurn();
    } else {
      if (_voiceDecoupled) return;
      _voiceDecoupled = true;
    }
    setState(() {});
  }

  bool get _decoupled => _band.enabled && (_paged ? _pagedFollow.decoupled : _voiceDecoupled);

  /// "Back to the voice": re-couples and brings the page to the spoken sentence.
  void _backToTheVoice() {
    _voiceDecoupled = false;
    _pagedFollow.backToTheVoice();
    setState(() {});
    final n = _band.next;
    if (n != null) _followVoice(n);
  }

  // -- Controller state -------------------------------------------------------

  void _onState(NovelReaderState? prev, NovelReaderState next) {
    if (next.stale && !(prev?.stale ?? false)) showGlassToast(ref, const GlassToastSpec('The text here changed. Opened at the nearest paragraph.'));
    final far = next.furtherElsewhere;
    if (far != null && far != prev?.furtherElsewhere) {
      final ch = far.chapterNumber == null ? 'a later chapter' : 'Ch ${formatChapterNumber(far.chapterNumber!)}';
      showGlassToast(
        ref,
        GlassToastSpec("You're further ahead on another device: $ch, ${far.percent} %", actionLabel: 'Jump there', onAction: () {
          _ctl.clearFurther();
          _openChapter(far.chapterKey, bucket: far.bucket);
        },),
      );
    }
    if (next.revision != prev?.revision) {
      _revision = next.revision;
      _restored = true;
      _keys = const [];
      _pageKey = null;
      _pull.reset();
      _chapterStart = _now;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollOk) _scroll.jumpTo(0);
      });
    }
    if (next.chapter != null && next.chapter?.chapterKey != prev?.chapter?.chapterKey) {
      _chapterStart = _now;
      _announce(next);
    }
    if (next.nextState != prev?.nextState) _checkRateLimit(next);
    if (next.chapter != null && prev?.chapter == null) _bootListen();
  }

  void _announce(NovelReaderState s) {
    final ch = s.chapter;
    if (ch == null || !mounted) return;
    final number = ch.chapterNumber == null ? 'Chapter' : 'Chapter ${formatChapterNumber(ch.chapterNumber!)}';
    final hasTitle = ch.title.isNotEmpty && ch.title != number;
    final series = _seriesTitle;
    final text = [number, if (hasTitle) ch.title].join(', ') + (series.isEmpty ? '' : ' · $series');
    if (_announced == text) return;
    _announced = text;
    try {
      unawaited(SemanticsService.sendAnnouncement(View.of(context), text, Directionality.of(context)));
    } catch (_) {}
  }

  /// The next chapter answered `rate_limited`: the capsule counts the `Retry-After` down and asks again at zero (J).
  void _checkRateLimit(NovelReaderState s) {
    final next = _ctl.nextKey;
    if (s.nextState != NovelNextState.failed || next == null) return;
    final err = ref.read(resolvedNovelChapterProvider((sourceId: widget.sourceId, seriesKey: widget.seriesKey, chapterKey: next))).error;
    if (err is! ApiError || err.code != 'rate_limited') return;
    _rateTimer?.cancel();
    setState(() => _rateLeft = math.max(1, (err.retryAfter?.inSeconds ?? 10)));
    _rateTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      final left = (_rateLeft ?? 1) - 1;
      if (left <= 0) {
        t.cancel();
        setState(() => _rateLeft = null);
        ref.invalidate(resolvedNovelChapterProvider((sourceId: widget.sourceId, seriesKey: widget.seriesKey, chapterKey: next)));
      } else {
        setState(() => _rateLeft = left);
      }
    });
  }

  // -- System and keep awake --------------------------------------------------

  void _syncWakelock() {
    if (!mounted) return;
    final on = _phone && ref.read(readerSettingsProvider).glassKeepAwake;
    unawaited(on ? _wakelock.enable() : _wakelock.disable());
  }

  Future<void> _setReaderGlass(Map<String, dynamic> fields) async {
    final record = ref.read(readerSettingsProvider);
    await ref.read(readerSettingsProvider.notifier).put(glassPatch(record, fields));
    _syncWakelock();
  }

  // -- Chrome -----------------------------------------------------------------

  bool get _menuOrPopover => _goTo || _keyboardMenu != null || _chip != null;

  bool get _canHide {
    if (!mounted) return false;
    if (_sheets > 0 || _menuOrPopover || _selectionActive) return false;
    if (_chromeScope.hasFocus) return false;
    if (MediaQuery.accessibleNavigationOf(context)) return false;
    final now = _now;
    if (now - _chapterStart < kChromeChapterGrace) return false;
    final k = _lastKey;
    if (k != null && now - k < kChromeKeyGrace) return false;
    return true;
  }

  void _setChrome(bool visible, {bool force = false}) {
    if (visible == _chrome) return;
    if (!visible && !force && !_canHide) return;
    if (!visible && _chromeScope.hasFocus) _surfaceFocus.requestFocus();
    setState(() => _chrome = visible);
    unawaited(GlassMotion.play(visible ? MotionName.materialise : MotionName.dematerialise, controller: _chromeAnim, target: visible ? 1 : 0));
    _idle?.cancel();
  }

  /// A tap on the column toggles; after a tap opened it, 3000 ms idle hides it again.
  void _toggleChrome() {
    if (_chrome) {
      _setChrome(false, force: _canHide);
      return;
    }
    _setChrome(true);
    _idle?.cancel();
    _idle = Timer(kChromeIdle, () {
      if (mounted && _chrome) _setChrome(false);
    });
  }

  void _holdChrome() {
    _idle?.cancel();
    if (!_chrome) _setChrome(true);
  }

  void _onScroll() {
    _ctl.onScrolled();
    if (_scrollOk && _scroll.position.extentAfter < 1) _markFinished();
    if (!_scrollOk) return;
    final p = _scroll.position.pixels;
    final delta = _programmatic || (_cruiseAuto.running && _cruiseAuto.controller.moving) ? 0.0 : p - _lastPixels;
    _lastPixels = p;
    if (delta > 0) {
      _upAccum = 0;
      _downAccum += delta;
      if (_downAccum >= kChromeHideDown && _chrome) _setChrome(false);
    } else if (delta < 0) {
      _downAccum = 0;
      _upAccum += -delta;
      if (_upAccum >= kChromeShowUp && !_chrome) _setChrome(true);
    }
    final percent = _state.chapterPercent ~/ 5 * 5;
    if (percent != _semanticsPercent) setState(() => _semanticsPercent = percent);
  }

  // -- Navigation -------------------------------------------------------------

  bool get _nothingBeneath => !(Navigator.maybeOf(context)?.canPop() ?? false);

  /// Back to the book: pop to the entry beneath, or (nothing beneath) the book page in its full-page form with a 200 ms cross-fade.
  void _leave() {
    if (!mounted) return;
    _ctl.autoNext = false;
    if (_nothingBeneath) {
      GoRouter.maybeOf(context)?.go(Routes.feature(widget.sourceId, widget.seriesKey));
    } else {
      Navigator.of(context).pop();
    }
  }

  /// Seamless: the same page, the location replaced (the page key is the reading session).
  void _replaceLocation(String chapterKey) {
    // A timer (auto next) can fire while the reader is leaving: never navigate back into it.
    if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? true)) return;
    GoRouter.maybeOf(context)?.go(Routes.novel(widget.sourceId, widget.seriesKey, chapterKey), extra: <String, String>{'nonce': widget.nonce});
  }

  /// Contents, Jump there: a different chapter opens by Dive (a new reader page).
  void _openChapter(String chapterKey, {int? bucket}) {
    if (!mounted) return;
    GoRouter.maybeOf(context)?.go(
      Routes.novel(widget.sourceId, widget.seriesKey, chapterKey, {if (bucket != null) 'page': bucket}),
      extra: <String, String>{'nonce': '${DateTime.now().microsecondsSinceEpoch}'},
    );
  }

  /// Novel next (D12): `l`, the Next card, the locked pull. The next chapter slides up in place on `springPage`.
  void _next() {
    if (_ctl.nextKey == null) return;
    glassFire(ref, HapticEvent.chapterNext);
    glassSound(ref, SoundEvent.chapterNext);
    _nextAnim.value = 0;
    _markFinished();
    _ctl.next();
    unawaited(GlassMotion.play(MotionName.novelNext, controller: _nextAnim, target: 1));
  }

  void _previous() {
    if (_ctl.previousKey == null) return;
    glassFire(ref, HapticEvent.chapterNext);
    _ctl.previous();
  }

  // -- Surface (scroll) -------------------------------------------------------

  bool get _scrollOk => _scroll.hasClients && _scroll.positions.length == 1;

  RenderBox? _boxFor(int i) {
    if (i < 0 || i >= _keys.length) return null;
    final box = _keys[i].currentContext?.findRenderObject();
    return box is RenderBox && box.hasSize && box.attached ? box : null;
  }

  double _viewportTop() {
    final box = _viewportKey.currentContext?.findRenderObject();
    return box is RenderBox && box.hasSize ? box.localToGlobal(Offset.zero).dy : 0;
  }

  double _viewportHeight() {
    final box = _viewportKey.currentContext?.findRenderObject();
    return box is RenderBox && box.hasSize ? box.size.height : MediaQuery.sizeOf(context).height;
  }

  double _line() => _viewportTop() + _viewportHeight() * kNovelReadingLine;

  @override
  bool get atEnd {
    if (_paged) {
      final s = _pagedView.currentState;
      return s != null && s.page >= _ctl.pages.length;
    }
    if (!_scrollOk) return false;
    return _scroll.position.pixels >= _scroll.position.maxScrollExtent - 8;
  }

  @override
  double get maxExtent => _scrollOk ? _scroll.position.maxScrollExtent : 0;

  @override
  void jumpEstimate(double fraction) {
    if (!_scrollOk) return;
    final max = _scroll.position.maxScrollExtent;
    _jump((max * fraction).clamp(0.0, max));
  }

  /// A jump the reader makes itself (restore, Contents, keys): it never shows or hides the chrome.
  void _jump(double to) {
    _programmatic = true;
    _scroll.jumpTo(to);
    _programmatic = false;
  }

  @override
  bool landOn(int index, double fraction, {required bool toReadingLine}) {
    if (_paged) {
      final paged = _pagedView.currentState;
      if (paged == null) return false;
      paged.jumpTo(pageOfParagraph(_ctl.pages, index));
      return true;
    }
    if (!mounted || !_scrollOk) return true;
    final box = _boxFor(index);
    if (box == null) return false;
    final anchor = box.localToGlobal(Offset.zero).dy + fraction * box.size.height;
    final target = toReadingLine ? _line() : _viewportTop() + NovelChromeGeometry.of(context).topBand;
    _jump((_scroll.position.pixels + anchor - target).clamp(0.0, _scroll.position.maxScrollExtent));
    return true;
  }

  @override
  ({int index, double fraction})? anchorAtReadingLine() {
    if (!mounted || !_scrollOk) return null;
    final line = _line();
    final attached = <int>[];
    final offsets = <double>[];
    for (var i = 0; i < _keys.length; i++) {
      final box = _boxFor(i);
      if (box == null) continue;
      attached.add(i);
      offsets.add(box.localToGlobal(Offset.zero).dy);
    }
    if (attached.isEmpty) return null;
    final pick = activeParagraphIndex(offsets, line);
    final index = attached[pick];
    final h = _boxFor(index)?.size.height ?? 0;
    return (index: index, fraction: h <= 0 ? 0.0 : ((line - offsets[pick]) / h).clamp(0.0, 1.0));
  }

  /// Lands paragraph [index] at the top band (the proof captures; Contents uses the same controller path).
  @visibleForTesting
  void jumpToParagraph(int index) => _ctl.jumpToParagraph(index, toReadingLine: false);

  // -- Commands ---------------------------------------------------------------

  Future<void> _bookmarkResult(Future<NovelBookmarkResult> run) async {
    final r = await run;
    if (!mounted) return;
    switch (r) {
      case NovelBookmarkResult.saved:
        glassFire(ref, HapticEvent.bookmarkAdd);
        glassSound(ref, SoundEvent.bookmarkAdd);
        _flag.value = 1;
        unawaited(_flag.springTo(0, gt.springTick));
        showGlassToast(ref, GlassToastSpec('Saved this spot', actionLabel: 'Add note', onAction: _openNote));
      case NovelBookmarkResult.failed:
        showGlassToast(ref, const GlassToastSpec("Couldn't save that spot", kind: GlassToastKind.error));
      case NovelBookmarkResult.nothing:
        break;
    }
  }

  void _bookmarkReadingLine() => unawaited(_bookmarkResult(_ctl.bookmark()));

  /// "The paragraph under the press" (F2): the first visible paragraph whose `RenderParagraph.selections` is not empty.
  int? _selectedParagraph() {
    for (var i = 0; i < _keys.length; i++) {
      final ctx = _keys[i].currentContext;
      if (ctx == null) continue;
      var found = false;
      void visit(RenderObject r) {
        if (found) return;
        // ignore: invalid_use_of_visible_for_testing_member
        if (r is RenderParagraph && r.selections.isNotEmpty) {
          found = true;
          return;
        }
        r.visitChildren(visit);
      }

      final ro = ctx.findRenderObject();
      if (ro != null) visit(ro);
      if (found) return i;
    }
    return anchorAtReadingLine()?.index ?? (_paged ? paragraphOfPage(_ctl.pages, _pagedView.currentState?.page ?? 0) : null);
  }

  void _clearSelection() {
    _keyboardMenu?.remove();
    _keyboardMenu = null;
    final region = _selection.currentState?.selectableRegion;
    region?.clearSelection();
    region?.hideToolbar();
    if (_selectionActive) setState(() => _selectionActive = false);
  }

  NovelSelectionActions _selectionActions() {
    final bridge = _bridge();
    final para = _selectedParagraph();
    final recommend = glassSheetRegistered(kNovelSheetRecommend);
    return NovelSelectionActions(
      onCopy: () {
        unawaited(Clipboard.setData(ClipboardData(text: _selectedText)));
        showGlassToast(ref, const GlassToastSpec('Copied'));
        _clearSelection();
      },
      onBookmark: () {
        if (para != null) unawaited(_bookmarkResult(_ctl.bookmarkAt(para)));
        _clearSelection();
      },
      onPlayFrom: bridge != null && bridge.available && para != null
          ? () {
              runBridge(() => bridge.playFrom(para));
              _clearSelection();
            }
          : null,
      onReact: (kind, from) {
        _clearSelection();
        unawaited(_react(kind, from));
      },
      onRecommend: recommend
          ? () {
              _clearSelection();
              final uri = GoRouterState.of(context).uri;
              GoRouter.of(context).go(uri.replace(queryParameters: {...uri.queryParameters, 'sheet': kNovelSheetRecommend, 'series': '${widget.sourceId}:${widget.seriesKey}'}).toString(), extra: <String, String>{'nonce': widget.nonce});
            }
          : null,
    );
  }

  /// React to this chapter (F6): the shared reactions mutation; the glyph flies on a ballistic arc to the end-matter strip when it is
  /// on screen, else to the title capsule.
  Future<void> _react(ReactionKind kind, Offset from) async {
    final c = _state.chapter;
    if (c == null) return;
    glassFire(ref, HapticEvent.reactionSend);
    glassSound(ref, SoundEvent.reactionSend);
    final strip = ref.read(glassReactionTargetsProvider).centerOf(kind);
    final title = _titleKey.currentContext?.findRenderObject();
    final to = strip ?? (title is RenderBox && title.hasSize ? title.localToGlobal(title.size.center(Offset.zero)) : MediaQuery.sizeOf(context).topCenter(Offset.zero));
    unawaited(_fly(kind, from, to));
    final key = (sourceId: widget.sourceId, seriesKey: widget.seriesKey);
    final notifier = ref.read(chapterReactionsProvider(key).notifier);
    await notifier.press(c.chapterKey, kind, chapterNumber: c.chapterNumber, mature: _sourceMature);
    if (!mounted) return;
    final mine = notifier.reactionsOf(c.chapterKey)?.mine;
    if (mine != kind) {
      showGlassToast(ref, const GlassToastSpec("Couldn't send your reaction", kind: GlassToastKind.error));
      return;
    }
    final profile = ref.read(activeProfileProvider)?.id;
    final sharing = profile == null ? null : ref.read(sharingProvider(profile)).valueOrNull;
    if (sharing != null && !sharing.reactions) {
      showGlassToast(ref, const GlassToastSpec('Only you see this. Turn on Circle sharing to show others.'));
    }
  }

  Future<void> _fly(ReactionKind kind, Offset from, Offset to) async {
    final r = glassReaction(kind);
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    final reduced = _reduced;
    final v = flightVelocity(from, to);
    final c = AnimationController(vsync: this, duration: reduced ? const Duration(milliseconds: 150) : Duration(milliseconds: (v.t * 1000).round()) + kBurst);
    final entry = OverlayEntry(
      builder: (_) => AnimatedBuilder(
        animation: c,
        builder: (context, _) {
          if (reduced) {
            return Positioned(left: to.dx - 18, top: to.dy - 18, width: 36, height: 36, child: IgnorePointer(child: Opacity(opacity: c.value, child: Icon(r.fill, size: 36, color: gt.colorBloom))));
          }
          final t = c.value * c.duration!.inMicroseconds / 1e6;
          if (t <= v.t) {
            final p = flightAt(from, to, t);
            return Positioned(left: p.dx - 18, top: p.dy - 18, width: 36, height: 36, child: IgnorePointer(child: Icon(r.fill, size: 36, color: gt.colorBloom)));
          }
          final burst = burstParticles(to, (t - v.t) / (kBurst.inMicroseconds / 1e6));
          return IgnorePointer(
            child: Stack(children: [
              for (final b in burst)
                Positioned(left: b.at.dx - 2, top: b.at.dy - 2, width: 4, height: 4, child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: gt.colorBloom.withValues(alpha: b.opacity)))),
            ],),
          );
        },
      ),
    );
    overlay.insert(entry);
    final e = GlassMotion.recorder.begin(MotionName.reactionBloomAndArc.label, c.duration!.inMilliseconds);
    try {
      await c.forward().orCancel;
      glassFire(ref, HapticEvent.select);
    } catch (_) {
    } finally {
      GlassMotion.recorder.end(e);
      entry.remove();
      c.dispose();
    }
  }

  void _openNote() => unawaited(_present(kNovelSheetNote));

  bool get _sourceMature => ref.read(sourcesListProvider).valueOrNull?.where((x) => x.id == widget.sourceId).firstOrNull?.mature ?? false;

  /// The chapter is finished here: the spoiler guard unseals its reactions (glass 9.3, mobile/43).
  void _markFinished() {
    final c = _state.chapter;
    if (c == null || c.chapterKey == _finishedKey) return;
    _finishedKey = c.chapterKey;
    ref.read(completedThisSessionProvider.notifier).markCompleted(widget.sourceId, widget.seriesKey, c.chapterKey);
  }

  String? _finishedKey;

  /// `?sheet=` on the reader's own location at mount (a deep link) opens that sheet.
  void _openSheetFromLocation() {
    String? id;
    try {
      id = GoRouterState.of(context).uri.queryParameters['sheet'];
    } catch (_) {}
    if (id == kNovelSheetType || id == kNovelSheetContents || id == kNovelSheetNote || id == kNovelSheetSoundscape) unawaited(_present(id!));
  }

  /// Presents one of the reader's sheets (the reader claims their ids, `mobile/29`'s registry).
  Future<void> _present(String id, {bool byKey = false}) async {
    if (!mounted) return;
    final paper = _values().paper;
    final page = switch (id) {
      kNovelSheetType => novelTypeSheetPage(_typeBody),
      kNovelSheetSoundscape => soundscapeSheetPage(seriesRef: '${widget.sourceId}:${widget.seriesKey}', landscapePhone: _phone && MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height),
      kNovelSheetContents => novelContentsSheetPage(paper, (c) => _contentsBody(c, autofocus: byKey && HardwareKeyboard.instance.logicalKeysPressed.isEmpty)),
      _ => novelNoteSheetPage((note) async {
          final ok = note.isEmpty || await _ctl.addNoteToLast(note);
          if (!ok && mounted) showGlassToast(ref, const GlassToastSpec("Couldn't save that note", kind: GlassToastKind.error));
          return ok;
        }),
    };
    _holdChrome();
    setState(() => _sheets++);
    try {
      await Navigator.of(context, rootNavigator: true).push<void>(page.createRoute(context));
    } finally {
      if (mounted) setState(() => _sheets = math.max(0, _sheets - 1));
    }
  }

  Widget _contentsBody(BuildContext c, {bool autofocus = false}) => NovelContentsBody(
        showTitle: false,
        sourceId: widget.sourceId,
        seriesKey: widget.seriesKey,
        currentChapterKey: _chapterKey.chapterKey,
        autofocus: autofocus,
        onOpen: (key) {
          Navigator.of(c).maybePop();
          if (key != _chapterKey.chapterKey) _openChapter(key);
        },
      );

  Widget _typeBody(BuildContext c, {ScrollController? controller}) => Consumer(
        builder: (context, ref, _) {
          final prefs = ref.watch(glassNovelPrefsProvider(_book));
          final record = ref.watch(readerSettingsProvider);
          final values = prefs.values(desktopFrame: _desktop, scale: MediaQuery.textScalerOf(context).scale);
          return NovelTypeBody(
            controller: controller,
            context0: NovelTypeContext(
              values: values,
              prefs: prefs,
              pageTinted: record.glassPageTinted,
              keepAwake: record.glassKeepAwake,
              setPageTinted: (v) => unawaited(_setReaderGlass({GlassReaderKeys.pageTinted: v})),
              setKeepAwake: (v) => unawaited(_setReaderGlass({GlassReaderKeys.keepAwake: v})),
              onPaper: (paper, orb) {
                glassFire(ref, HapticEvent.select);
                setState(() => _rippleOrigin = orb);
                unawaited(prefs.setProfile({GlassNovelKeys.paper: paper.wire}));
              },
              onReset: () {
                unawaited(prefs.resetBook());
                showGlassToast(ref, const GlassToastSpec('Type reset for this book'));
              },
              palette: _palette(),
              phone: _phone,
              soundscapeSummary: ref.watch(soundscapeControllerProvider).summary,
              onSoundscape: () {
                Navigator.of(c).maybePop();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) unawaited(_present(kNovelSheetSoundscape));
                });
              },
              cruiseOffered: _cruiseInSheet,
              cruiseRunning: ref.watch(cruiseControllerProvider).running,
              onToggleCruise: _toggleCruise,
            ),
          );
        },
      );

  void _openType({bool byKey = false}) {
    if (_desktop) {
      _togglePanel(right: true, byKey: byKey);
      return;
    }
    unawaited(_present(kNovelSheetType));
  }

  void _openContents({bool byKey = false}) {
    if (_desktop) {
      _togglePanel(right: false, byKey: byKey);
      return;
    }
    unawaited(_present(kNovelSheetContents, byKey: byKey));
  }

  /// Desktop panels (D2-D4): opening one re-centres the column on `springSheet`; the second closes the first with the toast when the
  /// column would fall below 48 ch.
  void _togglePanel({required bool right, bool byKey = false}) {
    _holdChrome();
    final type = _type(_values());
    final adv = novelZeroAdvance(type);
    final w = MediaQuery.sizeOf(context).width;
    setState(() {
      if (right) {
        _rightPanel = !_rightPanel;
        if (_rightPanel && _leftPanel && !panelsFitTogether(viewport: w, zeroAdvance: adv)) {
          _leftPanel = false;
          showGlassToast(ref, const GlassToastSpec('One panel at a time at this window size'));
        }
      } else {
        _leftPanel = !_leftPanel;
        if (_leftPanel && _rightPanel && !panelsFitTogether(viewport: w, zeroAdvance: adv)) {
          _rightPanel = false;
          showGlassToast(ref, const GlassToastSpec('One panel at a time at this window size'));
        }
      }
    });
    unawaited(GlassMotion.play(MotionName.sheetPresent, controller: _leftAnim, target: _leftPanel ? 1 : 0));
    unawaited(GlassMotion.play(MotionName.sheetPresent, controller: _rightAnim, target: _rightPanel ? 1 : 0));
    if (byKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (right ? _rightPanel : _leftPanel) _focusFirstIn(right ? _rightScope : _leftScope);
      });
    }
  }

  /// Moves focus to the first focusable control inside [scope] (the current row or first control, D4; the chrome's first, E1).
  void _focusFirstIn(FocusScopeNode scope) {
    final first = scope.traversalDescendants.where((n) => n.canRequestFocus).firstOrNull;
    if (first != null) {
      first.requestFocus();
    } else if (scope.context != null) {
      scope.requestFocus();
    }
  }

  void _closePanels() {
    if (!_leftPanel && !_rightPanel) return;
    setState(() => _leftPanel = _rightPanel = false);
    unawaited(GlassMotion.play(MotionName.sheetPresent, controller: _leftAnim, target: 0));
    unawaited(GlassMotion.play(MotionName.sheetPresent, controller: _rightAnim, target: 0));
    _surfaceFocus.requestFocus();
  }

  void _cyclePanel(int dir) {
    final order = <FocusNode>[_surfaceFocus, if (_leftPanel) _leftScope, if (_rightPanel) _rightScope];
    if (order.length < 2) return;
    var at = order.indexWhere((n) => n.hasFocus);
    if (at < 0) at = 0;
    final next = order[(at + dir) % order.length];
    next is FocusScopeNode ? _focusFirstIn(next) : next.requestFocus();
  }

  void _setGoTo(bool open) {
    if (open == _goTo) return;
    if (open) _holdChrome();
    setState(() => _goTo = open);
  }

  void _goToValue(int v) {
    _setGoTo(false);
    if (_paged) {
      _pagedView.currentState?.jumpTo(v - 1);
    } else {
      _ctl.jumpToBucket(v.clamp(1, 100));
    }
  }

  void _size({int step = 0, bool reset = false}) {
    final v = _values();
    if (reset) {
      unawaited(ref.read(glassNovelPrefsProvider(_book)).setBook({GlassNovelKeys.size: null}));
      return;
    }
    final next = keySize(v.fontSize, step: step, defaultSize: v.defaultSize);
    glassFire(ref, next == v.fontSize ? HapticEvent.detentLimit : HapticEvent.detentTick);
    _reflowAround(() => ref.read(glassNovelPrefsProvider(_book)).setBook({GlassNovelKeys.size: next}));
  }

  /// Re-flows around the paragraph anchor (G8, D3): the paragraph under the reading line stays put.
  void _reflowAround(Future<void> Function() change) {
    final anchor = _paged ? null : anchorAtReadingLine();
    unawaited(change().then((_) {
      if (anchor == null || !mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) => _ctl.jumpToParagraph(anchor.index, fraction: anchor.fraction));
    }),);
  }

  void _step({required bool forward, bool screen = false}) {
    if (_paged) {
      final p = _pagedView.currentState;
      if (p == null) return;
      if (forward && p.page >= _ctl.pages.length) {
        _next();
        return;
      }
      unawaited(p.turnBy(forward ? 1 : -1));
      glassFire(ref, HapticEvent.pageTurn);
      glassSound(ref, SoundEvent.pageTurn);
      return;
    }
    if (!_scrollOk) return;
    final d = _scroll.position.viewportDimension * (screen ? 0.9 : 0.4);
    final to = (_scroll.position.pixels + (forward ? d : -d)).clamp(0.0, _scroll.position.maxScrollExtent);
    unawaited(_scroll.animateTo(to, duration: Duration(milliseconds: _reduced ? 1 : 431), curve: SpringCurve(gt.springSnappy, settleMs: 431)));
  }

  void _edge({required bool end}) {
    if (_paged) {
      _pagedView.currentState?.jumpTo(end ? _ctl.pages.length : 0);
    } else if (_scrollOk) {
      _scroll.jumpTo(end ? _scroll.position.maxScrollExtent : 0);
    }
  }

  void _escape() {
    switch (novelEscapeStep(menuOrPopover: _menuOrPopover || _selectionActive, sheetOrPanel: _leftPanel || _rightPanel)) {
      case NovelEscapeStep.closeMenu:
        if (_goTo) {
          _setGoTo(false);
        } else if (_chip != null) {
          setState(() => _chip = null);
        } else {
          _clearSelection();
        }
      case NovelEscapeStep.closeSheetOrPanel:
        _closePanels();
      case NovelEscapeStep.toBook:
        _leave();
    }
  }

  void _showKeyboardMenu() {
    final region = _selection.currentState?.selectableRegion;
    if (region == null || _selectedText.isEmpty || _keyboardMenu != null) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    final lb = paperLb(_values().paper);
    _keyboardMenu = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: GlassSelectionMenu(region: region, actions: _selectionActions(), lb: lb, onDismiss: () {
          _keyboardMenu?.remove();
          _keyboardMenu = null;
        },),
      ),
    );
    overlay.insert(_keyboardMenu!);
  }

  // -- Cruise (glass 9.4.1, 8.15.4) and the soundscape ----------------------------------------

  bool get _rainOn {
    final v = ref.read(soundscapeControllerProvider);
    final playing = v.scene == SoundScene.rain && (v.state == SoundscapeState.starting || v.state == SoundscapeState.playingBuiltin || v.state == SoundscapeState.playingRecorded || v.state == SoundscapeState.ducked);
    return playing && !_reduced && !ref.read(glassA11yProvider).solid;
  }

  String get _seriesRef => '${widget.sourceId}:${widget.seriesKey}';
  bool get _cruiseInSheet => MediaQuery.textScalerOf(context).scale(17) / 17 > 1.3;
  CruiseController get _cruise => ref.read(cruiseControllerProvider.notifier);

  /// px/s at 1.0x: `(wpm / 60) / wordsPerLine x lineHeightPx`, the words per line measured from the laid-out extent.
  double _cruiseBase() {
    final chapter = ref.read(novelReaderControllerProvider(_args)).chapter;
    if (chapter == null || !_scrollOk) return 0;
    final type = _type(_values());
    final lineH = type.fontSize * type.lineHeight;
    final lines = math.max(1, (_scroll.position.maxScrollExtent / lineH).round());
    return novelPxPerSecond(1, wpm: ref.read(novelPaceStoreProvider).paceWpm, wordsPerLine: avgWordsPerLine(chapter.wordCount, lines), lineHeightPx: lineH);
  }

  void _cruiseEnded() {
    glassFire(ref, HapticEvent.autoscrollEnd);
    _setChrome(true);
  }

  void _attachAmbient() {
    _ambientKeep.add(ref.listenManual(cruiseControllerProvider, (_, __) {
      if (mounted) setState(() {});
    }),);
    _ambientKeep.add(ref.listenManual(soundscapeControllerProvider.select((v) => (v.on, v.scene, v.state)), (_, __) {
      if (mounted) setState(() {});
    }),);
    final soundscape = ref.read(soundscapeControllerProvider.notifier);
    _soundscape = soundscape;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _cruise.attach(
        NovelCruiseSource(_cruiseAuto, _scroll),
        speed: ref.read(readerPrefsProvider(_seriesRef)).cruiseSpeed,
        persist: (v) => unawaited(ref.read(readerSeriesPrefsProvider.notifier).setFor(_seriesRef, {GlassReaderKeys.cruiseSpeed: v})),
        reduced: () => _reduced,
      );
      final own = ref.read(readerPrefsProvider(_seriesRef)).soundscape;
      final genres = _series?.series.genres ?? const <String>[];
      final mature = ref.read(sourcesListProvider).valueOrNull?.where((x) => x.id == widget.sourceId).firstOrNull?.mature ?? false;
      unawaited(soundscape.enterReader(SoundscapeReaderContext(
        seriesRef: _seriesRef,
        genres: genres,
        rememberedScene: SoundScene.byName(own?.scene),
        rememberedMix: own == null ? null : MixLevels(bed: own.bed, detail: own.detail, tone: own.tone),
        mature: mature,
      ),),);
    });
    _ambientStops.add(registerPlaybackStop('cruise', _cruise.stop));
    final mature = ref.read(sourcesListProvider).valueOrNull?.where((x) => x.id == widget.sourceId).firstOrNull?.mature ?? false;
    if (mature) _ambientStops.add(registerMatureStop('cruise', _cruise.stop));
  }

  final List<ProviderSubscription<Object?>> _ambientKeep = [];

  /// `a` and the bottom capsule's button (scroll mode only; narration plays through its own bar).
  void _toggleCruise() {
    if (_paged) {
      showGlassToast(ref, const GlassToastSpec('Cruise needs the scroll layout'));
      return;
    }
    glassFire(ref, HapticEvent.autoscrollToggle);
    _cruise.toggle();
  }

  /// `<` and `>` step cruise by 0.25x, only while narration is not playing (narration owns them then).
  void _stepCruise(double by) {
    if (ref.read(narrationControllerProvider).isPlaying) return;
    if (_paged) return;
    _cruise.step(by);
  }

  Widget _cruiseButton(Color? tint, double lb) {
    final c = ref.read(cruiseControllerProvider);
    return CruisePill(
      state: c,
      onToggle: _toggleCruise,
      onResume: _cruise.resume,
      onPreview: _cruise.preview,
      onCommit: _cruise.commit,
      onStep: _cruise.step,
      reduced: _reduced,
      lb: lb,
      tint: tint,
    );
  }

  bool _runKey(NovelKeyAction a) {
    _lastKey = _now;
    switch (a) {
      case NovelKeyAction.previousChapter:
        _previous();
      case NovelKeyAction.nextChapter:
        _next();
      case NovelKeyAction.forward:
        _step(forward: true);
      case NovelKeyAction.back:
        _step(forward: false);
      case NovelKeyAction.screenForward:
        _step(forward: true, screen: true);
      case NovelKeyAction.screenBack:
        _step(forward: false, screen: true);
      case NovelKeyAction.chapterStart:
        _edge(end: false);
      case NovelKeyAction.chapterEnd:
        _edge(end: true);
      case NovelKeyAction.larger:
        _size(step: 1);
      case NovelKeyAction.smaller:
        _size(step: -1);
      case NovelKeyAction.resetSize:
        _size(reset: true);
      case NovelKeyAction.typeSheet:
        _openType(byKey: true);
      case NovelKeyAction.contents:
        _openContents(byKey: true);
      case NovelKeyAction.bookmark:
        _bookmarkReadingLine();
      case NovelKeyAction.playPause:
        final b = _bridge();
        if (b != null) runBridge(b.toggle);
      case NovelKeyAction.previousSentence:
        if (_narratingHere) unawaited(ref.read(narrationControllerProvider.notifier).stepSentence(-1));
      case NovelKeyAction.nextSentence:
        if (_narratingHere) unawaited(ref.read(narrationControllerProvider.notifier).stepSentence(1));
      case NovelKeyAction.back15:
        if (_narratingHere) unawaited(ref.read(narrationControllerProvider.notifier).seekBy(const Duration(seconds: -15)));
      case NovelKeyAction.forward15:
        if (_narratingHere) unawaited(ref.read(narrationControllerProvider.notifier).seekBy(const Duration(seconds: 15)));
      case NovelKeyAction.slower:
      case NovelKeyAction.faster:
        // Cruise speed outside narration is `mobile/44`'s.
        if (_narratingHere) {
          glassFire(ref, HapticEvent.select);
          final n = ref.read(narrationControllerProvider);
          unawaited(ref.read(narrationControllerProvider.notifier).setSpeed(n.speed + (a == NovelKeyAction.faster ? 0.05 : -0.05)));
        }
      case NovelKeyAction.voices:
        _openVoices();
      case NovelKeyAction.goTo:
        _setGoTo(true);
      case NovelKeyAction.shortcuts:
        final spec = glassSheetSpec('shortcuts');
        if (spec != null) {
          unawaited(Navigator.of(context, rootNavigator: true).push<void>(GlassSheetPage<void>(title: spec.title, builder: spec.builder).createRoute(context)));
        }
      case NovelKeyAction.selectionMenu:
        _showKeyboardMenu();
      case NovelKeyAction.panelNext:
        _cyclePanel(1);
      case NovelKeyAction.panelPrevious:
        _cyclePanel(-1);
      case NovelKeyAction.cruise:
        _toggleCruise();
      case NovelKeyAction.cruiseSlower:
        _stepCruise(-Cruise.tick);
      case NovelKeyAction.cruiseFaster:
        _stepCruise(Cruise.tick);
      case NovelKeyAction.soundscape:
        unawaited(_present(kNovelSheetSoundscape));
      case NovelKeyAction.escape:
        _escape();
    }
    return true;
  }

  List<ShortcutEntry> _entries() => [
        for (final b in novelKeyBindings(desktopFrame: _desktop, singleKeys: true))
          ShortcutEntry(group: 'Novel reader', activator: b.activator, description: b.description, singleKey: b.printable, keys: b.keys, onInvoke: () => _runKey(b.action)),
      ];

  /// Keys the reader does not bind restore hidden chrome and focus its first control (E1).
  KeyEventResult _onOtherKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    _lastKey = _now;
    if (!_chrome && ![LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.shiftRight, LogicalKeyboardKey.tab].contains(e.logicalKey)) {
      _setChrome(true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusFirstIn(_chromeScope);
      });
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // -- Pointer: taps, press.lift, pinch, pull release --------------------------

  void _onPointerDown(PointerDownEvent e) {
    if (_pinch.down(e)) {
      _pressLift?.cancel();
      _downAt = null;
      setState(() {
        _pinchSize = _values().fontSize;
        _pinchSteps = 0;
      });
      return;
    }
    _downAt = e.position;
    _downTime = e.timeStamp;
    _runTapped = false;
    _pressLift?.cancel();
    _pressLift = Timer(kPressLift, () {
      if (_downAt != null) glassFire(ref, HapticEvent.pressLift);
    });
  }

  void _onPointerMove(PointerMoveEvent e) {
    final scale = _pinch.move(e);
    if (scale != null) {
      final start = ref.read(glassNovelPrefsProvider(_book)).values(desktopFrame: _desktop, scale: MediaQuery.textScalerOf(context).scale).fontSize;
      final steps = pinchSteps(scale);
      if (steps != _pinchSteps) {
        final size = pinchSize(start, scale);
        final atEnd = size == GlassNovelRange.sizeMin || size == GlassNovelRange.sizeMax;
        glassFire(ref, atEnd && size == _pinchSize ? HapticEvent.detentLimit : HapticEvent.detentTick);
        setState(() {
          _pinchSteps = steps;
          _pinchSize = size;
        });
      }
      return;
    }
    final d = _downAt;
    if (d != null && (e.position - d).distance > kTapSlop) {
      _downAt = null;
      _pressLift?.cancel();
    }
  }

  void _onPointerUp(PointerUpEvent e) {
    if (_pinch.up(e)) {
      final size = _pinchSize;
      setState(() => _pinchSize = null);
      if (size != null && size != ref.read(glassNovelPrefsProvider(_book)).values(desktopFrame: _desktop, scale: MediaQuery.textScalerOf(context).scale).fontSize) {
        _reflowAround(() => ref.read(glassNovelPrefsProvider(_book)).setBook({GlassNovelKeys.size: size}));
      }
      return;
    }
    _pressLift?.cancel();
    if (_pull.locked) {
      _pull.reset();
      _next();
      return;
    }
    final d = _downAt, t = _downTime;
    _downAt = null;
    if (d == null || t == null || e.timeStamp - t > kTapMax) return;
    // The arena (a tinted run's recognizer) resolves after this pointer up: decide in a microtask.
    scheduleMicrotask(() {
      if (!mounted || _runTapped) return;
      if (_selectionActive) {
        _clearSelection();
        return;
      }
      if (_paged) {
        final box = _viewportKey.currentContext?.findRenderObject();
        if (box is! RenderBox) return;
        switch (tapBand(_values().tapZones, box.globalToLocal(e.position), box.size)) {
          case PageTapAction.back:
            _step(forward: false);
          case PageTapAction.forward:
            _step(forward: true);
          case PageTapAction.menu:
            _toggleChrome();
        }
        return;
      }
      _toggleChrome();
    });
  }

  void _onPointerCancel(PointerCancelEvent e) {
    _pinch.up(e);
    _pressLift?.cancel();
    _downAt = null;
  }

  bool _onScrollNotification(ScrollNotification n) {
    if (n.depth != 0 || !_scrollOk) return false;
    // A finger drag pauses cruise until the momentum settles (glass 9.4.1).
    if (n is ScrollStartNotification && n.dragDetails != null && _cruiseAuto.running) _cruiseAuto.controller.manualDrag();
    if (n is ScrollStartNotification && n.dragDetails != null) _decoupleFromVoice();
    final m = n.metrics;
    double? displayed;
    if (_reduced) {
      if (n is OverscrollNotification && n.overscroll > 0 && n.dragDetails != null) {
        _overAccum += n.overscroll;
        displayed = _overAccum;
      } else if (n is ScrollEndNotification) {
        _overAccum = 0;
      }
    } else if (n is ScrollUpdateNotification && m.pixels > m.maxScrollExtent && n.dragDetails != null) {
      displayed = m.pixels - m.maxScrollExtent;
    } else if (n is ScrollUpdateNotification && m.pixels <= m.maxScrollExtent) {
      displayed = 0;
    }
    if (displayed != null && _ctl.nextKey != null) {
      final was = _pull.locked;
      for (final ev in _pull.update(displayed)) {
        switch (ev) {
          case ChapterPullEvent.arm:
            glassFire(ref, HapticEvent.chapterArm);
          case ChapterPullEvent.lock:
            glassFire(ref, HapticEvent.chapterNext);
            glassSound(ref, SoundEvent.chapterNext);
          case ChapterPullEvent.unlock:
            glassFire(ref, HapticEvent.thresholdBack);
        }
      }
      if (was != _pull.locked) setState(() {});
    }
    return false;
  }

  // -- Type and paper -----------------------------------------------------------

  NovelType _type(GlassNovelValues v) => glassNovelType(v, osBold: MediaQuery.boldTextOf(context));

  CoverPalette? _palette() => paletteOf(null, _series?.series.ambient);

  Mood get _mood => ref.read(activeProfileProvider)?.mood ?? Mood.neutral;

  double _lb(GlassPaper paper) => paperLb(paper, fieldL: _palette()?.l);

  // -- Build ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(novelReaderControllerProvider(_args));
    ref
      ..watch(glassNovelPrefsProvider(_book))
      ..watch(sourceSeriesDetailProvider((sourceId: widget.sourceId, seriesId: widget.seriesKey)))
      ..watch(playableNovelAudioProvider(_chapterKey))
      ..watch(seriesAudioProvider((sourceId: widget.sourceId, seriesKey: widget.seriesKey)))
      ..watch(glassIsOwnerProvider)
      ..watch(narrationControllerProvider.select((n) => (n.key, n.status)))
      ..watch(glassReducedProvider);
    final narration = ref.watch(narrationControllerProvider);
    final attribution = ref.watch(novelAttributionProvider(_chapterKey)).valueOrNull;
    final bodyChapter = s.chapter;
    if (bodyChapter != null) {
      _band.sync(narration: ref.read(narrationControllerProvider.notifier), state: narration, chapter: _chapterKey, paragraphs: bodyChapter.paragraphs, attribution: attribution);
    }
    final record = ref.watch(readerSettingsProvider);
    _ctl.autoNext = record.autoNextChapter;
    final v = _values();
    final paper = v.paper;
    final online = ref.watch(deviceOnlineProvider).valueOrNull ?? true;
    final chapter = s.chapter;

    // The 18+ gate (glass 8.0.8): a mature source on a closed profile.
    final mature = ref.watch(sourcesListProvider).valueOrNull?.where((x) => x.id == widget.sourceId).firstOrNull?.mature ?? false;
    final gateOpen = ref.watch(matureContentProvider).valueOrNull ?? true;
    final gated = mature && !gateOpen;

    _syncSwipe(v.paged);
    final canPop = !_nothingBeneath && !_selectionActive && !_menuOrPopover;
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        switch (novelBackStep(selection: _selectionActive, menuOrPopover: _menuOrPopover, overview: false)) {
          case NovelBackStep.clearSelection:
            _clearSelection();
          case NovelBackStep.closeMenu:
            _escape();
          case NovelBackStep.closeOverview:
            break;
          case NovelBackStep.pop:
            _leave();
        }
      },
      child: NovelPaperRipple(
        paper: paper,
        origin: _rippleOrigin,
        reduced: _reduced,
        builder: (context, p, ghost) => _frame(context, s, chapter, v.copyWith(paper: p), ghost: ghost, gated: gated, online: online),
      ),
    );
  }

  void _syncSwipe(bool paged) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      // The 20 px iOS edge strip is live only in scroll mode (glass 8.0.5).
      if (route is GlassSwipePageRoute) route.canSwipe = !paged && !_nothingBeneath;
    });
  }

  Widget _frame(BuildContext context, NovelReaderState s, NovelChapter? chapter, GlassNovelValues v, {required bool ghost, required bool gated, required bool online}) {
    final colors = paperColors(v.paper);
    final spec = glassPaperSpec(_palette(), _mood);
    final Widget body;
    if (gated) {
      body = NovelStateView(kind: NovelFailureKind.gated, onBack: _leave, onHome: () => GoRouter.maybeOf(context)?.go(Routes.tonight()));
    } else if (s.chapterValue.hasError && chapter == null) {
      final e = s.chapterValue.error;
      body = NovelStateView(
        kind: novelFailureKind(e, online: online),
        error: e,
        onBack: _leave,
        onRetry: () {
          ref.invalidate(novelChapterPayloadProvider(_args.key));
          ref.invalidate(resolvedNovelChapterProvider(_args.key));
        },
      );
    } else if (chapter == null) {
      final type = _type(v);
      body = NovelLoadingPage(lineHeight: type.fontSize * type.lineHeight, width: _columnWidth(v), top: NovelChromeGeometry.of(context).topBand + 24);
    } else if (chapter.paragraphs.isEmpty) {
      body = NovelStateView(kind: NovelFailureKind.empty, onBack: _leave);
    } else {
      body = _reading(context, s, chapter, v, ghost: ghost);
    }
    final showChrome = chapter != null && chapter.paragraphs.isNotEmpty && !gated && !ghost;
    final percent = _readoutPercent(s);
    final content = Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: body),
        if (showChrome) ..._chromeLayers(context, s, chapter, v),
        if (!ghost && chapter != null)
          Positioned(left: 0, right: 0, top: GlassReaderInsets.of(context).top, height: 2, child: NovelProgressHairline(progress: percent / 100, color: colors.muted)),
      ],
    );
    // A transparent Material gives the page its text defaults (no debug underline) and the selection toolbar its ancestor.
    final framed = Material(type: MaterialType.transparency, child: PaperFrame(paper: v.paper, colors: colors, spec: spec, child: content));
    if (ghost) return framed;
    final label = chapter == null ? 'Chapter loading' : 'Chapter ${_numberText(chapter.chapterNumber)}, $_semanticsPercent percent';
    final bridge = _bridge();
    final tree = Focus(
      onKeyEvent: _onOtherKey,
      child: RegisteredShortcuts(
        group: 'Novel reader',
        entries: _entries(),
        child: Focus(
          focusNode: _surfaceFocus,
          autofocus: true,
          child: Semantics(container: true, label: label, child: OpenChapterScope(chapterId: _chapterKey, child: framed)),
        ),
      ),
    );
    return GlassListenBridgeScope(bridge: bridge, child: tree);
  }

  int _readoutPercent(NovelReaderState s) {
    if (_paged && _ctl.pages.isNotEmpty) {
      final page = _pagedView.currentState?.page ?? s.pageIndex;
      return (page / _ctl.pages.length * 100).round().clamp(1, 100);
    }
    return s.chapterPercent;
  }

  /// The column (D1): measure x the advance of `0` in the body style, never wider than the viewport minus `2 x max(20, inset.left)`;
  /// with desktop panels open the measure fits the room left (D3) without changing the stored one.
  double _columnWidth(GlassNovelValues v) {
    final size = MediaQuery.sizeOf(context);
    final inset = GlassReaderInsets.of(context);
    final type = _type(v);
    final adv = novelZeroAdvance(type);
    final measure = _desktop ? fitMeasureCh(measure: v.measure, viewport: size.width, zeroAdvance: adv, left: _leftPanel, right: _rightPanel) : v.measure;
    return math.max(120, math.min(measure * adv, size.width - 2 * math.max(20.0, inset.left)));
  }

  double _measureCh(GlassNovelValues v) {
    final adv = novelZeroAdvance(_type(v));
    return adv <= 0 ? v.measure : _columnWidth(v) / adv;
  }

  // -- Reading body -----------------------------------------------------------

  Widget _reading(BuildContext context, NovelReaderState s, NovelChapter chapter, GlassNovelValues v, {required bool ghost}) {
    final width = _columnWidth(v);
    final reading = v.paged ? _pagedBody(context, s, chapter, v, width, ghost: ghost) : _scrollBody(context, s, chapter, v, width, ghost: ghost);
    final colors = paperColors(v.paper);
    final selectable = ghost
        ? reading
        : SelectionArea(
            key: _selection,
            magnifierConfiguration: TextMagnifier.adaptiveMagnifierConfiguration,
            onSelectionChanged: (c) {
              final text = c?.plainText ?? '';
              _selectedText = text;
              final active = text.isNotEmpty;
              if (active != _selectionActive) setState(() => _selectionActive = active);
            },
            contextMenuBuilder: (context, region) => GlassSelectionMenu(region: region, actions: _selectionActions(), lb: _lb(v.paper)),
            child: reading,
          );
    final listener = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: ghost ? null : _onPointerDown,
      onPointerMove: ghost ? null : _onPointerMove,
      onPointerUp: ghost ? null : _onPointerUp,
      onPointerCancel: ghost ? null : _onPointerCancel,
      child: selectable,
    );
    final desktop = _desktop;
    final panelled = !desktop
        ? listener
        : AnimatedBuilder(
            animation: Listenable.merge([_leftAnim, _rightAnim]),
            child: listener,
            builder: (context, child) => Padding(
              padding: EdgeInsets.only(left: _leftAnim.value * (kNovelLeftPanel + kNovelPanelGap), right: _rightAnim.value * (kNovelRightPanel + kNovelPanelGap)),
              child: child,
            ),
          );
    return KeyedSubtree(
      key: ghost ? null : _viewportKey,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _nextAnim,
            child: panelled,
            builder: (context, child) {
              final t = _nextAnim.value.clamp(0.0, 1.0);
              final faded = FadeTransition(opacity: _jumpFade, child: child);
              if (t >= 1) return faded;
              return Opacity(opacity: t, child: Transform.translate(offset: Offset(0, (1 - t) * MediaQuery.sizeOf(context).height * 0.3), child: faded));
            },
          ),
          if (v.lineGuide && !ghost) Positioned.fill(child: IgnorePointer(ignoring: false, child: NovelLineGuide(lineHeightPx: v.fontSize * v.lineHeight, paper: colors.bg))),
        ],
      ),
    );
  }

  TextStyle _bodyStyle(GlassNovelValues v, Color ink) => _type(v).style(ink);

  List<GlassParagraphDecoration> _decorations(NovelReaderState s, int i) {
    final runs = s.speakerRuns[i];
    return [
      if (runs != null && runs.isNotEmpty) SpeakerBandsDecoration(runs, hideBackground: _band.enabled ? (r) => _bandCovers(i, r) : null),
      if (_band.enabled) ListenBandDecoration(_band, i),
    ];
  }

  /// The listen band covers this run: the run drops its background under it (its underline stays).
  bool _bandCovers(int paragraph, SpeakerRun r) {
    final n = _band.next;
    return n != null && n.paragraph == paragraph && n.start < r.end && n.end > r.start;
  }

  void _onRunTap(SpeakerRun run, Rect rect) {
    _runTapped = true;
    final box = _viewportKey.currentContext?.findRenderObject();
    final local = box is RenderBox ? rect.shift(-box.localToGlobal(Offset.zero)) : rect;
    setState(() => _chip = (text: runChipText(run.name, null), anchor: local));
  }

  Widget _paragraph(BuildContext context, NovelReaderState s, NovelChapter chapter, GlassNovelValues v, double width, int i, {int start = 0, int? end, bool ghost = false}) {
    final colors = paperColors(v.paper);
    final text = chapter.paragraphs[i];
    final type = _type(v);
    final style = _bodyStyle(v, colors.ink);
    final runs = s.speakerRuns[i] ?? const <SpeakerRun>[];
    final align = v.justify ? TextAlign.justify : TextAlign.start;
    if (isSceneBreak(text)) return _sceneBreak(v, colors, paged: v.paged);
    final dc = i == 0 && start == 0 ? splitDropCap(text) : null;
    final Widget piece;
    if (dc != null && text.contains(dc.initial)) {
      piece = GlassDropCapParagraph(
        paragraph: text,
        dropCap: dc,
        type: type,
        style: style,
        ink: colors.ink,
        width: width,
        end: end,
        runs: runs,
        decorations: _decorations(s, i),
        onRunTap: ghost ? null : _onRunTap,
        semanticsLabel: semanticsWithSpeakers(text, runs),
        repaint: _band,
      );
    } else {
      piece = GlassTextPiece(
        paragraph: text,
        start: start,
        end: end,
        style: style,
        align: align,
        indent: start == 0 && v.paragraphSpacing == 0 && novelParagraphIndents(chapter.paragraphs, i),
        runs: runs,
        decorations: _decorations(s, i),
        onRunTap: ghost ? null : _onRunTap,
        repaint: _band,
      );
    }
    if (i + 1 != _pulseParagraph || ghost) return piece;
    return AnimatedBuilder(
      animation: _pulse,
      child: piece,
      builder: (context, child) => DecoratedBox(
        decoration: BoxDecoration(color: gt.colorIris600.withValues(alpha: 0.14 * (1 - _pulse.value))),
        child: child,
      ),
    );
  }

  /// "✦ ✦ ✦" (D8): centred in muted, 0.5 em tracking, 1.6 em above and below (paged: inside the paginator's fixed band), excluded from
  /// selection and read as "Scene break".
  Widget _sceneBreak(GlassNovelValues v, PaperColors colors, {required bool paged}) {
    // "✦ ✦ ✦" drawn as three four-point stars with 0.5 em tracking (not every bundled face carries U+2726).
    final em = v.fontSize * 0.8;
    final glyphs = SizedBox(width: 3 * em + 2 * (0.5 * em + em * 0.3), height: em, child: CustomPaint(painter: _SceneStars(colors.muted, em)));
    return SelectionContainer.disabled(
      child: Semantics(
        label: 'Scene break',
        excludeSemantics: true,
        child: paged
            ? SizedBox(height: kNovelSceneBreakExtent, child: Center(child: glyphs))
            : Padding(padding: EdgeInsets.symmetric(vertical: 1.6 * v.fontSize), child: Center(child: glyphs)),
      ),
    );
  }

  Widget _header(BuildContext context, NovelChapter chapter, GlassNovelValues v) {
    final pace = _pace();
    final minutes = math.max(1, (chapter.wordCount / (pace.ready ? pace.wpm : kWordsPerMinute)).ceil());
    return GlassChapterHeader(
      kicker: chapter.chapterNumber == null ? 'CHAPTER' : 'CHAPTER ${formatChapterNumber(chapter.chapterNumber!)}',
      title: chapter.title,
      lengthLine: glassLengthLine(chapter.wordCount, minutes),
      bodySize: v.fontSize,
      slots: _headerListen(chapter, paperColors(v.paper)),
    );
  }

  Widget _endMatter(BuildContext context, NovelReaderState s, NovelChapter chapter, {bool ghost = false}) {
    final pace = _pace();
    final minutes = math.max(1, (chapter.wordCount / (pace.ready ? pace.wpm : kWordsPerMinute)).ceil());
    final online = ref.read(deviceOnlineProvider).valueOrNull ?? true;
    final endOfDownload = chapter.isOffline && !online && _ctl.nextKey != null && s.nextState == NovelNextState.failed;
    return GlassEndMatter(
      cardKey: ghost ? null : _nextCardKey,
      endLabel: chapter.chapterNumber == null ? 'END OF CHAPTER' : 'END OF CHAPTER ${formatChapterNumber(chapter.chapterNumber!)}',
      lengthLine: glassLengthLine(chapter.wordCount, minutes),
      nextLabel: _nextLabel(),
      onNext: _next,
      locked: _pull.locked,
      onPrevious: _ctl.previousKey == null ? null : _previous,
      onBackToBook: _leave,
      endOfDownload: endOfDownload,
      onDownloadNext: _downloadNext10,
      // The finished chapter's reactions (mobile/43, glass 9.3.2); a reaction sent from the menu lands in this strip.
      reactionSlots: ghost
          ? const []
          : [
              const SizedBox(height: 24),
              GlassChapterReactions(sourceId: widget.sourceId, seriesKey: widget.seriesKey, chapterKey: chapter.chapterKey, chapterNumber: chapter.chapterNumber, mature: _sourceMature),
            ],
    );
  }

  /// "Download next 10 when online" (J): the next ten chapters through the shared download queue.
  void _downloadNext10() {
    final chapters = novelReadingOrder(_series?.chapters ?? const []);
    final at = chapters.indexWhere((c) => c.id == _chapterKey.chapterKey);
    final next = at < 0 ? const <SourceChapterSummary>[] : chapters.skip(at + 1).take(10);
    unawaited(ref.read(downloadQueueControllerProvider.notifier).enqueueChapters([
      for (final c in next)
        (id: (sourceId: widget.sourceId, seriesKey: widget.seriesKey, chapterKey: c.id), chapterNumber: c.number, title: c.title, seriesTitle: _seriesTitle, kind: DownloadKind.novel),
    ]),);
    showGlassToast(ref, const GlassToastSpec('The next 10 chapters will download when you are online'));
  }

  Widget _scrollBody(BuildContext context, NovelReaderState s, NovelChapter chapter, GlassNovelValues v, double width, {required bool ghost}) {
    final paragraphs = chapter.paragraphs;
    if (!ghost && _keys.length != paragraphs.length) _keys = List.generate(paragraphs.length, (_) => GlobalKey());
    if (!ghost && !_restored) {
      _restored = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _ctl.beginRestore();
        _flashParagraph();
      });
    }
    final g = NovelChromeGeometry.of(context);
    final gap = v.paragraphSpacing * v.fontSize;
    final list = ListView.builder(
      key: ValueKey('novel-scroll-$_revision'),
      controller: ghost ? ScrollController(initialScrollOffset: _scrollOk ? _scroll.position.pixels : 0) : _scroll,
      physics: _pinch.pinching ? const NeverScrollableScrollPhysics() : GlassChapterEndPhysics(reduced: _reduced),
      padding: EdgeInsets.only(top: g.topBand, bottom: g.bottomBand),
      itemCount: paragraphs.length + 2,
      itemBuilder: (context, i) {
        Widget column(Widget child) => Center(child: SizedBox(width: width, child: child));
        if (i == 0) return column(_header(context, chapter, v));
        if (i == paragraphs.length + 1) return column(_endMatter(context, s, chapter, ghost: ghost));
        final p = i - 1;
        final para = Padding(padding: EdgeInsets.only(bottom: isSceneBreak(paragraphs[p]) ? 0 : gap), child: _paragraph(context, s, chapter, v, width, p, ghost: ghost));
        return column(ghost ? para : KeyedSubtree(key: _keys[p], child: para));
      },
    );
    if (ghost) return list;
    return Listener(
      onPointerDown: (_) {
        if (_cruiseAuto.running) _cruiseAuto.controller.touchDown();
      },
      onPointerUp: (_) {
        if (_cruiseAuto.running) _cruiseAuto.controller.touchUp();
      },
      onPointerCancel: (_) {
        if (_cruiseAuto.running) _cruiseAuto.controller.touchUp();
      },
      child: NotificationListener<ScrollNotification>(onNotification: _onScrollNotification, child: list),
    );
  }

  /// `?para=` flashes the paragraph with the Row pulse: `iris600` at 14 % fading to 0 over 900 ms (reduced: shown 900 ms, removed).
  void _flashParagraph() {
    final para = widget.paragraph;
    if (para == null) return;
    setState(() => _pulseParagraph = para);
    _pulse.value = 0;
    if (_reduced) {
      Timer(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => _pulseParagraph = null);
      });
      return;
    }
    unawaited(GlassMotion.play(MotionName.rowPulse, controller: _pulse, target: 1).then((_) {
      if (mounted) setState(() => _pulseParagraph = null);
    }),);
  }

  Widget _pagedBody(BuildContext context, NovelReaderState s, NovelChapter chapter, GlassNovelValues v, double width, {required bool ghost}) {
    final size = MediaQuery.sizeOf(context);
    final g = NovelChromeGeometry.of(context);
    final type = _type(v).copyWith(measure: _measureCh(v));
    final header = _header(context, chapter, v);
    final key = Object.hash(size, type, chapter.chapterKey, _revision, width, v.paper);
    if (!ghost && _pageKey != key) {
      _pageKey = key;
      final estimate = glassHeaderHeight(
        context,
        kicker: chapter.chapterNumber == null ? 'CHAPTER' : 'CHAPTER ${formatChapterNumber(chapter.chapterNumber!)}',
        title: chapter.title,
        lengthLine: glassLengthLine(chapter.wordCount, 99),
        bodySize: v.fontSize,
        width: width,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // The header as laid out (the offstage copy below), so page one reserves exactly its height.
        final measured = _headerKey.currentContext?.size?.height;
        final opener = measured ?? estimate;
        _ctl.setViewport(size, margin: math.max(20, GlassReaderInsets.of(context).left), bandTop: g.topBand, bandBottom: g.bottomBand, openerHeight: opener);
        _ctl.paginateNovel(type.measure, type);
        if (!_restored) {
          _restored = true;
          _ctl.beginRestore();
        }
        setState(() {});
      });
    }
    final pages = _ctl.pages;
    final measure = Offstage(child: Center(child: SizedBox(width: width, child: KeyedSubtree(key: ghost ? null : _headerKey, child: header))));
    if (pages.isEmpty) return Stack(children: [if (!ghost) measure, NovelLoadingPage(lineHeight: type.fontSize * type.lineHeight, width: width, top: g.topBand)]);
    if (!ghost && _keys.length != chapter.paragraphs.length) _keys = List.generate(chapter.paragraphs.length, (_) => GlobalKey());
    final gap = v.paragraphSpacing * v.fontSize;
    Widget page(BuildContext context, int index, bool ghostPage) {
      if (index >= pages.length) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(top: g.topBand, bottom: g.bottomBand),
          child: Center(child: SizedBox(width: width, child: _endMatter(context, s, chapter, ghost: ghostPage))),
        );
      }
      final slices = pages[index];
      final children = <Widget>[if (index == 0) header];
      for (var k = 0; k < slices.length; k++) {
        final sl = slices[k];
        if (k > 0 && !sl.isContinuation && !sl.sceneBreak && gap > 0) children.add(SizedBox(height: gap));
        final w = _paragraph(context, s, chapter, v, width, sl.paragraphIndex, start: sl.startChar, end: sl.endChar, ghost: ghostPage);
        children.add(!ghostPage && sl.startChar == 0 ? KeyedSubtree(key: _keys[sl.paragraphIndex], child: w) : w);
      }
      return Padding(
        padding: EdgeInsets.only(top: g.topBand, bottom: g.bottomBand),
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            child: ClipRect(child: OverflowBox(alignment: Alignment.topCenter, maxHeight: double.infinity, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children))),
          ),
        ),
      );
    }

    final view = NovelPagedView(
      key: ghost ? null : _pagedView,
      count: pages.length + 1,
      initialPage: s.pageIndex.clamp(0, pages.length),
      turn: v.pageTurn,
      reduced: _reduced,
      paper: paperColors(v.paper).bg,
      builder: (context, i, ghostPage) => page(context, i, ghost || ghostPage),
      onPage: (i) {
        if (!_programmaticTurn) _decoupleFromVoice();
        _ctl.onPaged(i);
        glassFire(ref, HapticEvent.pageTurn);
        glassSound(ref, SoundEvent.pageTurn);
        if (i >= pages.length) {
          _ctl.markComplete();
          _markFinished();
        }
        setState(() {});
      },
    );
    return ghost ? view : Stack(fit: StackFit.expand, children: [measure, view]);
  }

  // -- Chrome layers ------------------------------------------------------------

  List<Widget> _chromeLayers(BuildContext context, NovelReaderState s, NovelChapter chapter, GlassNovelValues v) {
    final g = NovelChromeGeometry.of(context);
    final colors = paperColors(v.paper);
    final record = ref.read(readerSettingsProvider);
    final tinted = record.glassPageTinted;
    final lb = _lb(v.paper);
    final percent = _readoutPercent(s);
    final pace = _pace();
    final fraction = percent / 100;
    final minutes = pace.ready ? math.max(0, (chapter.wordCount * (1 - fraction) / pace.wpm).ceil()) : null;
    final paged = v.paged && _ctl.pages.isNotEmpty;
    final pageNo = paged ? (_pagedView.currentState?.page ?? s.pageIndex) + 1 : null;
    final readout = novelReadout(percent: percent, minutesLeft: paged ? null : minutes, page: pageNo == null ? null : math.min(pageNo, _ctl.pages.length), pages: paged ? _ctl.pages.length : null);
    Widget live(Widget child) => AnimatedBuilder(
          animation: _chromeAnim,
          child: child,
          builder: (context, child) {
            final a = _chromeAnim.value.clamp(0.0, 1.0);
            final hidden = !_chrome;
            return ExcludeFocus(
              excluding: hidden,
              child: ExcludeSemantics(
                excluding: hidden,
                child: IgnorePointer(
                  ignoring: hidden,
                  child: a <= 0 ? const SizedBox.shrink() : Opacity(opacity: a, child: Transform.scale(scale: 0.96 + 0.04 * a, child: child)),
                ),
              ),
            );
          },
        );
    final topCentre = _topCentre(lb);
    final landscape = g.landscapePhone;
    final rowOn = _narratingHere && !ref.watch(glassListenRowHiddenProvider) && !(_desktop && _rightPanel && _panelTabs.pages.hasClients && (_panelTabs.pages.page ?? 0).round() == 2);
    final rowW = listenRowWidth(novelCapsuleWidth(g.size.width), landscapePhone: landscape);
    final rowAlign = landscape ? Alignment.centerRight : Alignment.center;
    return [
      // The tint cross-fades over curveTintShift (900 ms; 200 ms reduced) when the paper changes.
      TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: tinted ? colors.ink.withValues(alpha: kPaperTintAlpha) : const Color(0x00000000)),
        duration: _reduced ? const Duration(milliseconds: 200) : gt.curveTintShift.duration,
        curve: gt.curveTintShift.curve,
        builder: (context, tint, _) {
          final t = tint == null || tint.a <= 0.001 ? null : tint;
          return RainOnGlassHost(
            active: _rainOn && _chrome,
            light: ref.watch(glassLightAngleProvider).valueOrNull ?? kLightAngleRest,
            child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: g.left,
                right: g.right,
                top: g.top,
                child: FocusScope(
                  node: _chromeScope,
                  child: live(
                    NovelChromeTop(
                      g: g,
                      title: [if (_seriesTitle.isNotEmpty) _seriesTitle, _short(chapter)].join(' · '),
                      bookmarked: s.saved,
                      onBookmark: _bookmarkReadingLine,
                      onContents: _openContents,
                      onType: _openType,
                      lb: lb,
                      tint: t,
                      savedCopy: chapter.isOffline,
                      staleAge: chapter.cacheStale ? novelCacheAge(chapter.cacheFetchedAt) : null,
                      slots: [...widget.chromeSlots, ..._listenSlots()],
                      aaBadge: ref.read(soundscapeControllerProvider).on,
                      titleKey: _titleKey,
                      bookmarkDrop: _flag,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: ListenRowLinger(
                  chromeShown: _chrome,
                  pinned: ref.watch(glassListenRowPinnedProvider),
                  builder: (context, visible) {
                    final showRow = rowOn && visible;
                    final inGroup = showRow && _chrome;
                    return Stack(
                      children: [
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: g.bottom,
                          height: inGroup ? 56 + 8 + kListenRowHeight : 56,
                          child: Center(
                            child: live(
                              NovelBottomCapsule(
                                width: novelCapsuleWidth(g.size.width),
                                readout: readout,
                                percent: percent,
                                onGoTo: () => _setGoTo(true),
                                lb: lb,
                                tint: t,
                                onPrevious: _ctl.previousKey == null ? null : _previous,
                                onNext: _ctl.nextKey == null ? null : _next,
                                nextLabel: _nextLabel(),
                                slots: [if (!_paged && !_cruiseInSheet) _cruiseButton(t, lb)],
                                listenRow: inGroup ? GlassListenRowBody(width: rowW) : null,
                                listenRowWidth: rowW,
                                listenRowAlign: rowAlign,
                              ),
                            ),
                          ),
                        ),
                        // The chrome is hidden and the row lingers (5000 ms): the row alone, where it sat.
                        if (showRow && !_chrome)
                          Positioned(
                            left: 0,
                            right: landscape ? g.right : 0,
                            bottom: g.bottom + 56 + 8,
                            height: kListenRowHeight,
                            child: Align(
                              alignment: rowAlign,
                              child: SkinGlass(size: Size(rowW, kListenRowHeight), tier: GlassTierId.t3, lb: lb, debugLabel: 'listen row', child: GlassListenRowBody(width: rowW)),
                            ),
                          ),
                        if (showRow && _decoupled)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: g.bottom + 56 + 8 + kListenRowHeight + 8,
                            child: Center(child: _BackToTheVoice(onTap: _backToTheVoice)),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          );
        },
      ),
      if (topCentre != null) Positioned(top: g.top, left: 0, right: 0, height: 32, child: Center(child: topCentre)),
      if (_chip != null)
        GlassRunChip(
          key: ValueKey(_chip),
          text: _chip!.text,
          anchor: _chip!.anchor,
          lb: lb,
          onGone: () => setState(() => _chip = null),
        ),
      if (_goTo)
        Positioned.fill(
          child: Stack(
            children: [
              Positioned.fill(child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => _setGoTo(false))),
              Positioned(
                left: 0,
                right: 0,
                bottom: g.bottom + 56 + 8,
                child: Center(
                  child: NovelGoToPopover(
                    value: paged ? (pageNo ?? 1) : percent,
                    pages: paged ? _ctl.pages.length : null,
                    onGo: _goToValue,
                    onClose: () => _setGoTo(false),
                    lb: lb,
                  ),
                ),
              ),
            ],
          ),
        ),
      if (_desktop) ..._panels(context, chapter, v),
    ];
  }

  /// The top-centre slot (E9): one capsule at a time, the newest wins: the pinch capsule, the rate-limited capsule, `mobile/41`'s pill.
  Widget? _topCentre(double lb) {
    final p = _pinchSize;
    if (p != null) return NovelTopCapsule(key: const ValueKey('pinch'), text: 'Text size ${p.round()}', lb: lb);
    final left = _rateLeft;
    if (left != null) return NovelTopCapsule(key: const ValueKey('rate'), text: 'The source is busy; the next chapter will load in $left s', warning: true, lb: lb);
    final n = ref.read(narrationControllerProvider);
    if (n.key == _chapterKey && n.target != null && n.active && !n.highlightSafe) return _HighlightPaused(key: const ValueKey('highlight-paused'), lb: lb);
    return widget.topCentreSlots.isEmpty ? null : widget.topCentreSlots.last;
  }

  List<Widget> _panels(BuildContext context, NovelChapter chapter, GlassNovelValues v) {
    final g = NovelChromeGeometry.of(context);
    final colors = paperColors(v.paper);
    Widget slide(Animation<double> a, bool left, Widget child) => AnimatedBuilder(
          animation: a,
          child: child,
          builder: (context, child) => a.value <= 0.001
              ? const SizedBox.shrink()
              : Opacity(opacity: a.value.clamp(0.0, 1.0), child: Transform.translate(offset: Offset((left ? -1 : 1) * 24 * (1 - a.value), 0), child: child)),
        );
    return [
      Positioned(
        left: kNovelPanelInset,
        top: g.top + g.side + 12,
        bottom: kNovelPanelInset + g.inset.bottom,
        width: kNovelLeftPanel,
        child: slide(
          _leftAnim,
          true,
          Focus(
            onKeyEvent: (n, e) {
              if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
                _closePanels();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: NovelSidePanel(
              label: 'Contents',
              paperBg: colors.bg,
              focus: _leftScope,
              child: PaperScope(paper: v.paper, colors: colors, child: _leftPanel ? NovelContentsBody(sourceId: widget.sourceId, seriesKey: widget.seriesKey, currentChapterKey: chapter.chapterKey, onOpen: (k) => k == chapter.chapterKey ? null : _openChapter(k)) : const SizedBox.shrink()),
            ),
          ),
        ),
      ),
      Positioned(
        right: kNovelPanelInset,
        top: g.top + g.side + 12,
        bottom: kNovelPanelInset + g.inset.bottom,
        width: kNovelRightPanel,
        child: slide(
          _rightAnim,
          false,
          Focus(
            onKeyEvent: (n, e) {
              if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
                _closePanels();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: NovelSidePanel(
              label: 'Type, voices and listen',
              paperBg: colors.bg,
              focus: _rightScope,
              child: Material(type: MaterialType.transparency, child: _rightPanel ? NovelRightPanelTabs(controller: _panelTabs, tabs: novelRightPanelTabs(_typeBody, voices: _voicesTab, listen: _listenTab)) : const SizedBox.shrink()),
            ),
          ),
        ),
      ),
    ];
  }
}

/// The right panel's tabs in order (D2, glass 8.15.1): Aa, then `mobile/37`'s Voices and Listen.
List<NovelPanelTab> novelRightPanelTabs(WidgetBuilder aa, {WidgetBuilder? voices, WidgetBuilder? listen}) => [
      NovelPanelTab('Aa', aa),
      if (voices != null) NovelPanelTab('Voices', voices),
      if (listen != null) NovelPanelTab('Listen', listen),
    ];

/// "Highlight paused: the text changed" (glass 8.16.7, J3): a quiet `glassThin` capsule in the top-centre slot.
class _HighlightPaused extends StatelessWidget {
  const _HighlightPaused({super.key, required this.lb});
  final double lb;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        label: 'Highlight paused: the text changed',
        excludeSemantics: true,
        child: SkinGlass(
          size: Size(math.min(MediaQuery.sizeOf(context).width - 48, 280), 32),
          tier: GlassTierId.t2,
          lb: lb,
          layer: GlassLayerKind.hud,
          debugLabel: 'highlight paused capsule',
          child: Center(child: GlassText('Highlight paused: the text changed', role: gt.typeFootnote, wght: 600, onGlass: true, maxScale: 1.3, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ),
      );
}

/// "Back to the voice": a `fill2` twin capsule above the listen row after a manual scroll or turn.
class _BackToTheVoice extends StatelessWidget {
  const _BackToTheVoice({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GlassPressable(
        material: GlassMaterial.content,
        sink: 0.96,
        onTap: onTap,
        semanticsLabel: 'Back to the voice',
        builder: (context, info) => ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Center(
            widthFactor: 1,
            child: DecoratedBox(
              decoration: ShapeDecoration(color: gt.colorFill2, shape: const GlassShape.capsule().border(const Size(160, 36))),
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: GlassText('Back to the voice', role: gt.typeSubhead, wght: 600, onGlass: true, maxLines: 1)),
            ),
          ),
        ),
      );
}

/// Three four-point stars (U+2726), [em] each, 0.5 em apart plus a word space.
class _SceneStars extends CustomPainter {
  _SceneStars(this.color, this.em);
  final Color color;
  final double em;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final step = em + 0.5 * em + em * 0.3;
    for (var i = 0; i < 3; i++) {
      final c = Offset(em / 2 + i * step, size.height / 2);
      final r = em * 0.42, w = em * 0.11;
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy - r)
          ..lineTo(c.dx + w, c.dy - w)
          ..lineTo(c.dx + r, c.dy)
          ..lineTo(c.dx + w, c.dy + w)
          ..lineTo(c.dx, c.dy + r)
          ..lineTo(c.dx - w, c.dy + w)
          ..lineTo(c.dx - r, c.dy)
          ..lineTo(c.dx - w, c.dy - w)
          ..close(),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_SceneStars old) => old.color != color || old.em != em;
}
