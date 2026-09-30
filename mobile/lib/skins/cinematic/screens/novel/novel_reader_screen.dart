import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/core/network/api_image.dart';
import 'package:manhwamaniacs/features/downloads/providers/open_chapter_scope.dart';
import 'package:manhwamaniacs/features/library/utils/cover_url.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/controllers/novel_reader_controller.dart';
import 'package:manhwamaniacs/features/novels/engine/novel_paginator.dart' as pg show pageOfParagraph;
import 'package:manhwamaniacs/features/novels/engine/novel_paginator.dart';
import 'package:manhwamaniacs/features/novels/engine/novel_paragraph_layout.dart';
import 'package:manhwamaniacs/features/novels/models/novel_chapter.dart';
import 'package:manhwamaniacs/features/novels/models/novel_typography.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_audio_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_cast_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_chapter_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_preferences_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_profile_settings.dart';
import 'package:manhwamaniacs/features/novels/providers/series_audio_provider.dart';
import 'package:manhwamaniacs/features/novels/utils/novel_book.dart';
import 'package:manhwamaniacs/features/novels/utils/novel_progress.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_profile_settings.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_wakelock.dart';
import 'package:manhwamaniacs/features/settings/providers/a11y_prefs_provider.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/navigation.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_rating_card.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_text_field.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toast_host.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/audiobook_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/cast_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/follow_along.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/listen_button.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/listen_common.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/listen_layer.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/bottom_bar.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/chapter_opener.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/end_matter.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/in_page_head.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/novel_contents.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/novel_keys.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/novel_margins_panel.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/novel_paragraph.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/novel_states.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/page_frame.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/paged_columns.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/progress_folio.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/stocks.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/top_bar.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/type_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/cine_reader_route.dart' show cineReaderOwnsToastsProvider;
import 'package:manhwamaniacs/skins/cinematic/screens/reader/edge_hud.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/end_states.dart' show ReaderEndNotice;
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_entry.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_series.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_system_ui.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/side_panel_layout.dart';
import 'package:manhwamaniacs/skins/cinematic/tint.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

/// The Cinematic novel reader, "The page" (cinematic 8.15): a text column painted edge to edge in
/// one of seven dark paper stocks. It renders `NovelReaderController`'s state, owns no reading
/// logic of its own, and is `ScreenId.novel`.
class CineNovelReader extends ConsumerStatefulWidget {
  const CineNovelReader({
    super.key,
    required this.sourceId,
    required this.seriesKey,
    required this.chapterKey,
    this.bucket = 1,
    this.paragraph,
    this.fraction,
    this.nonce = '',
    this.listen = false,
  });

  final String sourceId, seriesKey, chapterKey;

  /// `?listen=1`: start the narrator when the first frame is laid out.
  final bool listen;

  /// `?page=` (a progress bucket), `?para=` and `?at=` (a bookmark's paragraph and fraction).
  final int bucket;
  final int? paragraph;
  final double? fraction;

  /// The route's `nonce` extra: kept on every seamless replacement so the route page is kept.
  final String nonce;

  @override
  ConsumerState<CineNovelReader> createState() => _CineNovelReaderState();
}

class _CineNovelReaderState extends ConsumerState<CineNovelReader> with TickerProviderStateMixin implements NovelReadingSurface, FollowSurface {
  /// The Cinematic reading line: 38 % from the top.
  static const double _readingLine = 0.38;

  late final NovelReaderArgs _args = NovelReaderArgs(
    sourceId: widget.sourceId,
    seriesKey: widget.seriesKey,
    chapterKey: widget.chapterKey,
    readingLineFraction: _readingLine,
    initialBucket: widget.bucket,
    initialParagraph: widget.paragraph,
    initialFraction: widget.fraction,
    attribution: true,
  );
  late final NovelReaderController _ctl = ref.read(novelReaderControllerProvider(_args).notifier);
  late final ReaderWakelock _wakelock = ref.read(readerWakelockProvider);
  late final StateController<bool> _toastOwner = ref.read(cineReaderOwnsToastsProvider.notifier);
  late final AnimationController _chromeAnim = AnimationController(vsync: this, value: 0);

  final ScrollController _scroll = ScrollController();
  final FocusScopeNode _chromeScope = FocusScopeNode(debugLabel: 'novel chrome');
  final FocusNode _surfaceFocus = FocusNode(debugLabel: 'novel surface');
  final GlobalKey<NovelProgressFolioState> _folio = GlobalKey();
  final GlobalKey<NovelPagedColumnsState> _paged = GlobalKey();
  final ValueNotifier<int> _bucket = ValueNotifier<int>(1);
  final ValueNotifier<({String name, Offset at})?> _speaker = ValueNotifier(null);
  late final HudHold _hud = HudHold(_repaint);
  late final NarrationController _narr = ref.read(narrationControllerProvider.notifier);
  final ListenUi _listenUi = ListenUi();
  late final ListenFollower _follower = ListenFollower(surface: this, narration: _narr, reduced: () => _reduced);
  ListenDecorator? _decorator;
  bool _programmatic = false, _programmaticPage = false;
  bool _pendingListen = false, _resumeAfterSwap = false;

  List<GlobalKey> _keys = const [];
  bool _chrome = false;
  bool _restored = false;
  bool _noteOpen = false;
  bool _leftPanel = false;
  bool _rightPanel = false;
  bool _editingProgress = false;
  int? _brightnessDraft;
  int _revision = 0;
  String? _announced;
  double _lastPixels = 0, _downAccum = 0, _upAccum = 0, _overscroll = 0;
  bool _overArmed = true;
  Timer? _speakerTimer;
  Object? _pageKey;
  bool _ratingShown = false;
  ReaderSystemUi? _appliedUi;
  ProviderSubscription<NovelReaderState>? _sub;

  TargetPlatform get _platform => Theme.of(context).platform;
  bool get _reduced => CineMotion.reduced(context);
  String get _prefsKey => novelSeriesPrefsKey(widget.sourceId, widget.seriesKey);

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

  @override
  void initState() {
    super.initState();
    _chromeAnim.value = 0;
    Future.microtask(() {
      try {
        _toastOwner.state = true;
      } catch (_) {}
    });
    _ctl
      ..attach(this)
      ..seamless = true
      ..locationReplacer = _replaceLocation
      ..narrationBusy = _narrationBusy;
    _narr
      ..onSkipNext = _skipNext
      ..onFeedback = _narrationFeedback;
    _pendingListen = widget.listen;
    _listenUi.addListener(_repaint);
    _scroll.addListener(_onScroll);
    _chromeScope.addListener(() {
      if (!_chromeScope.hasFocus && _chrome) _maybeAutoHide();
    });
    _sub = ref.listenManual<NovelReaderState>(novelReaderControllerProvider(_args), _onState);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyUi(ReaderUiPhase.enter);
      _surfaceFocus.requestFocus();
      final keepAwake = ref.read(readerDefaultsProvider).keepScreenAwake;
      keepAwake ? _wakelock.enable() : _wakelock.disable();
    });
  }

  @override
  void didUpdateWidget(CineNovelReader old) {
    super.didUpdateWidget(old);
    // An external navigation to another chapter of the same book (a seamless replacement has
    // already swapped it in).
    if (widget.chapterKey != old.chapterKey && widget.chapterKey != ref.read(novelReaderControllerProvider(_args)).chapter?.chapterKey) {
      _ctl.swapTo(widget.chapterKey);
    }
  }

  @override
  void dispose() {
    _sub?.close();
    _speakerTimer?.cancel();
    // Leaving the reader stops the narration and removes the notification.
    _narr
      ..onSkipNext = null
      ..onFeedback = null;
    Future<void>.microtask(() async {
      try {
        await _narr.stop();
      } catch (_) {}
    });
    _follower.dispose();
    _decorator?.dispose();
    _listenUi.dispose();
    _ctl
      ..detach(this)
      ..locationReplacer = null;
    _scroll.dispose();
    _chromeAnim.dispose();
    _chromeScope.dispose();
    _surfaceFocus.dispose();
    _bucket.dispose();
    _speaker.dispose();
    _hud.dispose();
    _wakelock.disable();
    Future.microtask(() {
      try {
        _toastOwner.state = false;
      } catch (_) {}
    });
    unawaited(applyReaderSystemUi(readerSystemUi(defaultTargetPlatform, ReaderUiPhase.exit)));
    super.dispose();
  }

  // ── State transitions ─────────────────────────────────────────────────────

  void _onState(NovelReaderState? prev, NovelReaderState next) {
    if (next.readingBucket != _bucket.value) _bucket.value = next.readingBucket;
    final toasts = ref.read(cineToastsProvider.notifier);
    if (next.stale && !(prev?.stale ?? false)) toasts.info('The text here changed. Opened at the nearest paragraph.');
    final far = next.furtherElsewhere;
    if (far != null && far != prev?.furtherElsewhere) {
      final n = far.chapterNumber;
      final label = n == null ? 'a later chapter' : 'CH ${chapterNumberText(n)}, ${chapterPercent(far.bucket, 100)}%';
      toasts.action(
        "You're further ahead on another device ($label). Jump there?",
        label: 'Jump',
        onAction: () {
          _ctl.clearFurther();
          _openByDip(far.chapterKey, bucket: far.bucket);
        },
      );
    }
    if (next.revision != prev?.revision) {
      // A different chapter swapped in at the top: a fresh list at offset 0.
      _revision = next.revision;
      _restored = true;
      _keys = const [];
      _pageKey = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollOk) _scroll.jumpTo(0);
      });
      _afterSwap();
    }
    if (prev?.chapter == null && next.chapter != null) {
      _announce(next);
      if (_pendingListen) {
        _pendingListen = false;
        // `?listen=1`: the narrator starts once the first frame is laid out.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_startListen(fromReadingLine: false));
        });
      }
    }
  }

  void _announce(NovelReaderState s) {
    final ch = s.chapter;
    if (ch == null) return;
    final series = ref.read(readerSeriesProvider((sourceId: widget.sourceId, seriesKey: widget.seriesKey)))?.title ?? '';
    final number = ch.chapterNumber == null ? 'Chapter' : 'Chapter ${chapterNumberText(ch.chapterNumber)}';
    final hasTitle = ch.title.isNotEmpty && ch.title != number;
    final text = [number, if (hasTitle) ch.title].join(', ') + (series.isEmpty ? '' : ' · $series');
    if (_announced == text) return;
    _announced = text;
    // ignore: deprecated_member_use
    unawaited(SemanticsService.announce(text, Directionality.of(context)));
  }

  // ── System bars and chrome ────────────────────────────────────────────────

  void _applyUi(ReaderUiPhase phase) {
    final ui = readerSystemUi(_platform, phase);
    if (ui == _appliedUi) return;
    _appliedUi = ui;
    unawaited(applyReaderSystemUi(ui));
  }

  void _setChrome(bool visible) {
    if (visible == _chrome) return;
    if (!visible && _chromeScope.hasFocus) _surfaceFocus.requestFocus();
    setState(() => _chrome = visible);
    // The status bar comes with the chrome (at the start of its fade in) and leaves at the start
    // of its fade out.
    _applyUi(visible ? ReaderUiPhase.chromeShown : ReaderUiPhase.chromeHidden);
    final cine = context.cine;
    if (visible) {
      unawaited(_chromeAnim.animateTo(1, duration: cine.durLine, curve: CineCurves.settle));
    } else {
      unawaited(_chromeAnim.animateTo(0, duration: cine.durBeat, curve: CineCurves.lift));
    }
  }

  void _toggleChrome() => _setChrome(!_chrome);

  bool get _canAutoHide => !_chromeScope.hasFocus && !MediaQuery.accessibleNavigationOf(context) && !_editingProgress;

  void _maybeAutoHide() {}

  void _onScroll() {
    _ctl.onScrolled();
    if (!_scrollOk) return;
    final p = _scroll.position.pixels;
    final delta = p - _lastPixels;
    _lastPixels = p;
    if (delta > 0) {
      _upAccum = 0;
      _downAccum += delta;
      if (_downAccum >= 24 && _chrome && _canAutoHide) _setChrome(false);
    } else if (delta < 0) {
      _downAccum = 0;
      _upAccum += -delta;
      if (_upAccum >= 56 && !_chrome) _setChrome(true);
    }
    if (atEnd && !_chrome) _setChrome(true);
  }

  // ── NovelReadingSurface (scroll layout) ───────────────────────────────────

  bool get _scrollOk => _scroll.hasClients && _scroll.positions.length == 1;

  bool get _isPaged => ref.read(novelSettingsProvider).novelLayout == 'paged';

  RenderBox? _boxFor(int i) {
    if (i < 0 || i >= _keys.length) return null;
    final box = _keys[i].currentContext?.findRenderObject();
    return box is RenderBox && box.hasSize ? box : null;
  }

  double _viewportTop() {
    final box = context.findRenderObject();
    return box is RenderBox && box.hasSize ? box.localToGlobal(Offset.zero).dy : 0;
  }

  double _line() => _viewportTop() + MediaQuery.sizeOf(context).height * _readingLine;

  @override
  bool get atEnd {
    if (_isPaged) {
      final s = _paged.currentState;
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
    _scroll.jumpTo((max * fraction).clamp(0.0, max));
  }

  @override
  bool landOn(int index, double fraction, {required bool toReadingLine}) {
    if (_isPaged) {
      final paged = _paged.currentState;
      if (paged == null) return false;
      paged.jumpTo(pg.pageOfParagraph(_ctl.pages, index));
      return true;
    }
    if (!mounted || !_scrollOk) return true;
    final box = _boxFor(index);
    if (box == null) return false;
    final anchor = box.localToGlobal(Offset.zero).dy + fraction * box.size.height;
    final ref = toReadingLine ? _line() : _viewportTop();
    _scroll.jumpTo((_scroll.position.pixels + anchor - ref).clamp(0.0, _scroll.position.maxScrollExtent));
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

  // ── Navigation ────────────────────────────────────────────────────────────

  void _leave() => leaveReaderByDip(context, sourceId: widget.sourceId, seriesKey: widget.seriesKey);

  /// Seamless: the same page, the location replaced (the page key is the reading session).
  void _replaceLocation(String chapterKey) {
    if (!mounted) return;
    context.go(
      Routes.novel(widget.sourceId, widget.seriesKey, chapterKey),
      extra: <String, String>{'entry': ReaderEntry.dip.name, 'nonce': widget.nonce},
    );
  }

  /// Contents, Jump: a different chapter opens by Dip.
  void _openByDip(String chapterKey, {int? bucket}) {
    if (!mounted) return;
    context.go(
      Routes.novel(widget.sourceId, widget.seriesKey, chapterKey, {if (bucket != null) 'page': bucket}),
      extra: <String, String>{'entry': ReaderEntry.dip.name, 'nonce': DateTime.now().microsecondsSinceEpoch.toString()},
    );
  }

  void _next() {
    cineFeedback(context, HapticEvent.chapterNext, sound: SoundEvent.chapterNext);
    _resumeAfterSwap = _narr.current.active;
    _ctl.next();
    _announceSoon();
  }

  void _previous() {
    cineFeedback(context, HapticEvent.chapterNext, sound: SoundEvent.chapterNext);
    _resumeAfterSwap = _narr.current.active;
    _ctl.previous();
    _announceSoon();
  }

  void _announceSoon() => Timer(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        _announced = null;
        _announce(ref.read(novelReaderControllerProvider(_args)));
      });

  // ── Commands ──────────────────────────────────────────────────────────────

  Future<void> _bookmark() async {
    final percent = _ctl.bookmarkPercent();
    final result = await _ctl.bookmark();
    if (!mounted) return;
    final toasts = ref.read(cineToastsProvider.notifier);
    switch (result) {
      case NovelBookmarkResult.saved:
        cineFeedback(context, HapticEvent.bookmarkAdd, sound: SoundEvent.bookmarkAdd);
        toasts.action(percent == null ? 'Bookmarked.' : 'Bookmarked at $percent% of this chapter.', label: 'Add a note', onAction: () => setState(() => _noteOpen = true));
      case NovelBookmarkResult.failed:
        toasts.error("Couldn't save that spot.");
      case NovelBookmarkResult.nothing:
        break;
    }
  }

  Future<Object?> _typeSheet() async {
    _setChromeHold();
    final stock = _stock();
    final series = ref.read(readerSeriesProvider((sourceId: widget.sourceId, seriesKey: widget.seriesKey)));
    final a = series?.summary.ambient;
    await showNovelTypeSheet(
      context,
      prefsKey: _prefsKey,
      stock: stock,
      ambient: a == null ? null : AmbientRoles(duo: a.duo, tint: a.tint, ink: a.ink),
    );
    if (mounted) _setChrome(false);
    return null;
  }

  void _setChromeHold() {
    if (!_chrome) _setChrome(true);
  }

  void _openContents() {
    _setChromeHold();
    final tablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    if (tablet) {
      setState(() {
        _leftPanel = !_leftPanel;
        if (_leftPanel) _rightPanel = false;
      });
      return;
    }
    final ch = ref.read(novelReaderControllerProvider(_args)).chapter;
    if (ch == null) return;
    unawaited(showNovelContentsSheet(
      context,
      sourceId: widget.sourceId,
      seriesKey: widget.seriesKey,
      currentChapterKey: ch.chapterKey,
      stock: _stock(),
      onOpen: _openByDip,
    ),);
  }

  void _openMargins() {
    _setChromeHold();
    if (MediaQuery.sizeOf(context).shortestSide < 600) return;
    setState(() {
      _rightPanel = !_rightPanel;
      if (_rightPanel) _leftPanel = false;
    });
  }

  void _goToPercent() {
    _setChromeHold();
    WidgetsBinding.instance.addPostFrameCallback((_) => _folio.currentState?.beginEdit());
  }

  void _escape() {
    final tablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    switch (novelEscapeStep(progressFieldOpen: _folio.currentState?.editing ?? false, sheetOpen: false, panelOpen: tablet && (_leftPanel || _rightPanel), playerOpen: _listenUi.roomOpen)) {
      case NovelEscape.cancelProgressField:
        _folio.currentState?.cancelEdit();
      case NovelEscape.closeSheet:
        break;
      case NovelEscape.collapsePlayer:
        _listenUi.handleBack();
      case NovelEscape.closePanel:
        setState(() => _leftPanel = _rightPanel = false);
      case NovelEscape.exitReader:
        _leave();
    }
  }

  void _step({required bool forward, bool small = false}) {
    if (_isPaged) {
      _paged.currentState?.turnBy(forward ? 1 : -1);
      return;
    }
    if (!_scrollOk) return;
    final v = _scroll.position.viewportDimension * (small ? 0.4 : 0.9);
    final to = (_scroll.position.pixels + (forward ? v : -v)).clamp(0.0, _scroll.position.maxScrollExtent);
    unawaited(_scroll.animateTo(to, duration: _reduced ? Duration.zero : context.cine.durLine, curve: CineCurves.settle));
  }

  void _edge({required bool end}) {
    if (_isPaged) {
      _paged.currentState?.jumpTo(end ? _ctl.pages.length : 0);
    } else if (_scrollOk) {
      _scroll.jumpTo(end ? _scroll.position.maxScrollExtent : 0);
    }
  }

  void _size({int step = 0, bool reset = false}) {
    final type = watchNovelTypeOnce();
    final target = novelKeySize(type.fontSize, step: step, reset: reset, faceDefault: faceDefaults(type.face, tablet: MediaQuery.sizeOf(context).shortestSide >= 600).size);
    unawaited(ref.read(novelPreferencesControllerProvider(_prefsKey).notifier).setSize(target));
  }

  NovelType watchNovelTypeOnce() {
    final book = ref.read(novelPreferencesControllerProvider(_prefsKey));
    return resolveNovelType(
      book: book,
      settings: ref.read(novelSettingsProvider),
      legible: ref.read(legibleTextProvider),
      systemScale: MediaQuery.textScalerOf(context).scale(1),
      tablet: MediaQuery.sizeOf(context).shortestSide >= 600,
      osBold: MediaQuery.boldTextOf(context),
    );
  }

  CineStockColors _stock() {
    final id = ref.read(novelStockIdProvider);
    final a = ref.read(readerSeriesProvider((sourceId: widget.sourceId, seriesKey: widget.seriesKey)))?.summary.ambient;
    return stockColorsFor(id, ambient: a == null ? null : AmbientRoles(duo: a.duo, tint: a.tint, ink: a.ink));
  }

  void _showSpeaker(String name, Offset at) {
    cineFeedback(context, HapticEvent.longpressOpen);
    _speaker.value = (name: name, at: at);
    _speakerTimer?.cancel();
    _speakerTimer = Timer(const Duration(milliseconds: 2500), () => _speaker.value = null);
  }


  // ── Listen ────────────────────────────────────────────────────────────────

  NovelChapterKey get _chapterKey => (
        sourceId: widget.sourceId,
        seriesKey: widget.seriesKey,
        chapterKey: ref.read(novelReaderControllerProvider(_args)).chapter?.chapterKey ?? widget.chapterKey,
      );

  /// Narration keeps the 900 ms auto-next off while it plays, is paused mid-chapter, or its
  /// post-play card is waiting.
  bool _narrationBusy() {
    final n = _narr.current;
    return (n.active && n.key == _chapterKey) || _listenUi.cardShowing;
  }

  void _skipNext() {
    if (_ctl.nextKey != null) _next();
  }

  void _narrationFeedback(NarrationFeedback f) {
    if (!mounted) return;
    switch (f) {
      case NarrationFeedback.sleepFade:
        cineFeedback(context, HapticEvent.sleepFade);
      case NarrationFeedback.shakeExtended:
        cineFeedback(context, HapticEvent.select);
        ref.read(cineToastsProvider.notifier).info('Sleep timer +5 min');
    }
  }

  /// Reads the chapter aloud from the reading line (or the start), when it has audio.
  Future<void> _startListen({bool fromReadingLine = true}) async {
    final s = ref.read(novelReaderControllerProvider(_args));
    final chapter = s.chapter;
    if (chapter == null) return;
    final key = _chapterKey;
    final playable = await ref.read(playableNovelAudioProvider(key).future);
    if (playable == null || !mounted) return;
    final series = ref.read(readerSeriesProvider((sourceId: widget.sourceId, seriesKey: widget.seriesKey)));
    String? narrator;
    try {
      final attr = await ref.read(novelAttributionProvider(key).future).timeout(const Duration(milliseconds: 400));
      final voices = await ref.read(novelVoicesProvider.future).timeout(const Duration(milliseconds: 400));
      narrator = attr.narratorVoiceId == null ? null : voices.where((v) => v.voiceId == attr.narratorVoiceId).firstOrNull?.name;
    } catch (_) {
      narrator = null;
    }
    final base = ref.read(apiBaseUrlProvider);
    final target = NarrationTarget(
      key: key,
      audio: playable.audio,
      file: playable.file?.path,
      paragraphs: chapter.paragraphs,
      bookTitle: series?.title ?? '',
      chapterNumber: chapter.chapterNumber,
      chapterTitle: chapter.title,
      narratorName: narrator,
      coverUrl: coverUrlAtWidth(sourceSeriesCoverUrl(base, widget.sourceId, widget.seriesKey), 512),
    );
    if (!mounted) return;
    var startMs = 0;
    final paragraph = fromReadingLine ? anchorAtReadingLine()?.index : null;
    if (paragraph != null && paragraph > 0) {
      final seg = playable.audio.segments.where((x) => x.paragraph >= paragraph).firstOrNull;
      startMs = seg?.startMs ?? 0;
    }
    cineFeedback(context, HapticEvent.listenToggle);
    _follower.refollow();
    await _narr.start(target, startMs: startMs);
  }

  /// `p`: play or pause this chapter's narration, starting it when nothing is playing here.
  Future<void> _listenToggle() async {
    final n = _narr.current;
    if (n.key == _chapterKey && n.target != null && n.status != NarrationStatus.failed) {
      cineFeedback(context, HapticEvent.listenToggle);
      await _narr.toggle();
    } else {
      await _startListen();
    }
  }

  void _listenKey(NovelListenKey k) {
    final n = _narr.current;
    final mine = n.key == _chapterKey && n.target != null;
    switch (k) {
      case NovelListenKey.toggle:
        unawaited(_listenToggle());
      case NovelListenKey.previousSentence:
        if (mine) unawaited(_narr.stepSentence(-1));
      case NovelListenKey.nextSentence:
        if (mine) unawaited(_narr.stepSentence(1));
      case NovelListenKey.back15:
        if (mine) unawaited(_narr.seekBy(const Duration(seconds: -15)));
      case NovelListenKey.forward15:
        if (mine) unawaited(_narr.seekBy(const Duration(seconds: 15)));
      case NovelListenKey.slower:
        if (mine) {
          cineFeedback(context, HapticEvent.select);
          unawaited(_narr.setSpeed(n.speed - 0.05));
        }
      case NovelListenKey.faster:
        if (mine) {
          cineFeedback(context, HapticEvent.select);
          unawaited(_narr.setSpeed(n.speed + 0.05));
        }
    }
  }

  /// The voices button, the voices line and the Margins VOICES tab.
  void _openVoices() {
    _setChromeHold();
    unawaited(showCastSheet(context, chapter: _chapterKey, stock: _stock(), onReNarrate: _reNarrate));
  }

  void _reNarrate() {
    Navigator.of(context).maybePop();
    unawaited(showAudiobookSheet(context, sourceId: widget.sourceId, seriesKey: widget.seriesKey, seriesTitle: ref.read(readerSeriesProvider((sourceId: widget.sourceId, seriesKey: widget.seriesKey)))?.title, currentChapterKey: _chapterKey.chapterKey, initialQuickPick: 'revoice', stock: _stock()));
  }

  /// The post-play card finished: the chapter swaps in place and the narration goes on.
  void _advanceListening() {
    if (_ctl.nextKey == null) return;
    _resumeAfterSwap = true;
    _ctl.next();
    _announceSoon();
  }

  /// A chapter swapped in: when the narrator was reading (or the card advanced), read the new one.
  void _afterSwap() {
    if (!_resumeAfterSwap) return;
    _resumeAfterSwap = false;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final key = _chapterKey;
      final playable = await ref.read(playableNovelAudioProvider(key).future);
      if (!mounted) return;
      if (playable == null) {
        await _narr.stop();
        return;
      }
      await _startListen(fromReadingLine: false);
    });
  }


  /// Whether the paged first page reserves room for the Listen row: the owner always (the
  /// `NOT NARRATED` row), everyone else once the book has any narrated chapter. Part of the page
  /// key, so a flip repaginates once instead of clipping a line.
  bool _reserveListen() =>
      ref.watch(isOwnerProvider) || (ref.watch(seriesAudioProvider((sourceId: widget.sourceId, seriesKey: widget.seriesKey))).valueOrNull?.rendered.isNotEmpty ?? false);

  /// The Listen row under the opener's facts line.
  Widget? _listenOpener(NovelChapter chapter, ReaderSeries? series) => ListenOpener(
        chapter: _chapterKey,
        chapterNumber: chapter.chapterNumber,
        title: chapter.title,
        seriesTitle: series?.title,
        fixedHeight: _isPaged ? (_reserveListen() ? kListenOpenerReserve - 20 : 0) : null,
        onListen: () => unawaited(_startListen()),
      );

  /// The voices line under the text, over the end matter.
  Widget _withVoicesLine(CineStockColors stock, Widget endMatter) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          VoicesLine(chapter: _chapterKey, muted: stock.muted, onOpen: _openVoices),
          endMatter,
        ],
      );

  // FollowSurface ------------------------------------------------------------

  @override
  bool get isPaged => _isPaged;

  @override
  double? paragraphTop(int index) {
    final box = _boxFor(index);
    return box == null ? null : box.localToGlobal(Offset.zero).dy - _viewportTop();
  }

  @override
  double get viewportHeight {
    final box = context.findRenderObject();
    return box is RenderBox && box.hasSize ? box.size.height : MediaQuery.sizeOf(context).height;
  }

  @override
  void scrollBy(double delta, {required bool animate}) {
    if (!_scrollOk) return;
    final to = (_scroll.position.pixels + delta).clamp(0.0, _scroll.position.maxScrollExtent);
    _programmatic = true;
    if (animate) {
      unawaited(_scroll.animateTo(to, duration: context.cine.durGlide, curve: CineCurves.settle).whenComplete(() => _programmatic = false));
    } else {
      _scroll.jumpTo(to);
      _programmatic = false;
    }
  }

  @override
  void jumpToParagraph(int index) {
    _programmatic = true;
    if (!landOn(index, 0, toReadingLine: true)) {
      final n = ref.read(novelReaderControllerProvider(_args)).paragraphs.length;
      if (n > 0) jumpEstimate(index / n);
    }
    _programmatic = false;
  }

  @override
  int? pageOfParagraph(int index) => _ctl.pages.isEmpty ? null : pg.pageOfParagraph(_ctl.pages, index);

  @override
  int get currentPage => _paged.currentState?.page ?? 0;

  @override
  void showPage(int page) {
    final paged = _paged.currentState;
    if (paged == null) return;
    _programmaticPage = true;
    final delta = page - paged.page;
    if (delta.abs() == 1) {
      paged.turnBy(delta);
    } else {
      paged.jumpTo(page);
    }
    Future<void>.delayed(const Duration(milliseconds: 600), () => _programmaticPage = false);
  }

  ListenDecorator _decoratorFor(BuildContext context, CineStockColors stock) {
    final c = context.cine;
    final d = _decorator ??= ListenDecorator(
      narration: _narr,
      chapterOf: () => _chapterKey,
      vsync: this,
      reduced: () => _reduced,
      wash: c.colorSpotWash,
      ink: stock.ink,
    );
    d
      ..wash = c.colorSpotWash
      ..ink = stock.ink;
    return d;
  }

  // ── Keys ──────────────────────────────────────────────────────────────────

  List<ShortcutEntry> _entries() {
    ShortcutEntry e(LogicalKeyboardKey key, String desc, VoidCallback run, {bool shift = false, bool single = true, List<String>? keys}) => ShortcutEntry(
          group: 'Novel reader',
          activator: SingleActivator(key, shift: shift),
          description: desc,
          singleKey: single && !shift,
          keys: keys,
          onInvoke: run,
        );
    return [
      e(LogicalKeyboardKey.keyH, 'Previous chapter', _previous),
      e(LogicalKeyboardKey.keyL, 'Next chapter', _next),
      e(LogicalKeyboardKey.keyJ, 'Scroll or page forward', () => _step(forward: true, small: true)),
      e(LogicalKeyboardKey.keyK, 'Scroll or page back', () => _step(forward: false, small: true)),
      e(LogicalKeyboardKey.space, 'One screen forward', () => _step(forward: true)),
      e(LogicalKeyboardKey.space, 'One screen back', () => _step(forward: false), shift: true, single: false),
      e(LogicalKeyboardKey.home, 'Start of the chapter', () => _edge(end: false)),
      e(LogicalKeyboardKey.end, 'End of the chapter', () => _edge(end: true)),
      e(LogicalKeyboardKey.equal, 'Larger text', () => _size(step: 1)),
      e(LogicalKeyboardKey.add, 'Larger text', () => _size(step: 1)),
      e(LogicalKeyboardKey.minus, 'Smaller text', () => _size(step: -1)),
      e(LogicalKeyboardKey.digit0, 'Reset text size', () => _size(reset: true)),
      e(LogicalKeyboardKey.keyT, 'Text and page', () => unawaited(_typeSheet())),
      e(LogicalKeyboardKey.comma, 'Text and page', () => unawaited(_typeSheet())),
      e(LogicalKeyboardKey.keyO, 'Contents', _openContents),
      e(LogicalKeyboardKey.keyB, 'Bookmark this spot', () => unawaited(_bookmark())),
      e(LogicalKeyboardKey.keyM, 'Margins', _openMargins),
      e(LogicalKeyboardKey.keyG, 'Go to a percent', _goToPercent),
      e(LogicalKeyboardKey.keyP, 'Play or pause the narrator', () => _listenKey(NovelListenKey.toggle)),
      e(LogicalKeyboardKey.bracketLeft, 'Previous sentence', () => _listenKey(NovelListenKey.previousSentence)),
      e(LogicalKeyboardKey.bracketRight, 'Next sentence', () => _listenKey(NovelListenKey.nextSentence)),
      e(LogicalKeyboardKey.bracketLeft, 'Back 15 seconds', () => _listenKey(NovelListenKey.back15), shift: true, single: false, keys: const ['Shift', '[']),
      e(LogicalKeyboardKey.bracketRight, 'Forward 15 seconds', () => _listenKey(NovelListenKey.forward15), shift: true, single: false, keys: const ['Shift', ']']),
      e(LogicalKeyboardKey.comma, 'Listen slower', () => _listenKey(NovelListenKey.slower), shift: true, single: false, keys: const ['<']),
      e(LogicalKeyboardKey.period, 'Listen faster', () => _listenKey(NovelListenKey.faster), shift: true, single: false, keys: const ['>']),
      e(LogicalKeyboardKey.escape, 'Close, then back to the book', _escape, single: false),
    ];
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(novelReaderControllerProvider(_args));
    final settings = ref.watch(novelSettingsProvider);
    final series = ref.watch(readerSeriesProvider((sourceId: widget.sourceId, seriesKey: widget.seriesKey)));
    final stockId = ref.watch(novelStockIdProvider);
    final ambient = series?.summary.ambient;
    final stock = stockColorsFor(stockId, ambient: ambient == null ? null : AmbientRoles(duo: ambient.duo, tint: ambient.tint, ink: ambient.ink));
    final type = watchNovelType(ref, context, _prefsKey);
    final size = MediaQuery.sizeOf(context);
    final tablet = size.shortestSide >= 600;
    final landscape = size.height < 500 && size.width > size.height;
    final paged = settings.novelLayout == 'paged';
    final margin = switch (settings.novelMargins) { 'narrow' => 16.0, 'wide' => 48.0, _ => 24.0 };
    final width = tablet || landscape ? novelColumnWidthCh(type, viewportWidth: size.width, margin: 24) : size.width - 2 * margin;
    final brightness = _brightnessDraft ?? settings.novelBrightness;
    _ctl.autoNext = ref.watch(readerSettingsProvider).autoNextChapter;
    _syncSwipeable(paged);

    final chapter = s.chapter;
    final Widget body;
    if (s.chapterValue.hasError && chapter == null) {
      final e = s.chapterValue.error;
      body = NovelFailureView(
        error: e is AppError ? e : UnknownError(message: '$e', cause: e),
        onRetry: () {
          ref.invalidate(novelChapterPayloadProvider(_args.key));
          ref.invalidate(resolvedNovelChapterProvider(_args.key));
        },
        onBack: _leave,
      );
    } else if (chapter == null) {
      body = NovelLoadingPage(lineHeight: type.fontSize * type.lineHeight, width: width);
    } else if (chapter.paragraphs.isEmpty) {
      body = NovelEmptyView(onBack: _leave);
    } else {
      body = paged ? _pagedBody(context, s, chapter, type, stock, width, size, margin) : _scrollBody(context, s, chapter, type, stock, width, series);
    }

    final showBars = chapter != null && chapter.paragraphs.isNotEmpty;
    final canPop = GoRouter.of(context).canPop() && !_leftPanel && !_rightPanel && !_editingProgress && !_listenUi.roomOpen;
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_listenUi.handleBack()) return;
        if (_folio.currentState?.editing ?? false) {
          _folio.currentState?.cancelEdit();
        } else if (_leftPanel || _rightPanel) {
          setState(() => _leftPanel = _rightPanel = false);
        } else {
          _leave();
        }
      },
      child: NovelPageFrame(
        colors: stock,
        brightness: brightness,
        child: CineToastHost(
          frame: CineToastFrame.reader,
          readerBottomInset: _chrome ? kNovelBarHeight + MediaQuery.viewPaddingOf(context).bottom + 40 : 0,
          stockColours: (page: stock.page, ink: stock.ink, muted: stock.muted),
          child: RegisteredShortcuts(
            group: 'Novel reader',
            entries: _entries(),
            child: Focus(
              focusNode: _surfaceFocus,
              autofocus: true,
              child: Semantics(
                container: true,
                label: chapter == null ? 'Chapter loading' : 'Chapter ${chapterNumberText(chapter.chapterNumber)}, ${s.chapterPercent} percent',
                child: OpenChapterScope(
                  chapterId: (sourceId: widget.sourceId, seriesKey: widget.seriesKey, chapterKey: chapter?.chapterKey ?? widget.chapterKey),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fill(child: body),
                      if (showBars) ..._chromeLayers(context, s, chapter, series, stock, tablet, paged),
                      if (showBars) _gestureZones(context, brightness),
                      if (showBars) _listenLayer(context, s, chapter, series, stock),
                      if (showBars && tablet) _panels(context, s, chapter, stock),
                      _speakerPopover(stock),
                      if (_noteOpen) _noteField(stock),
                      if (!_ratingShown && series != null) _rating(series),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _syncSwipeable(bool paged) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final route = context.getSwipeablePageRoute<void>();
      if (route == null) return;
      // The 20 pt iOS edge swipe is live only in the scroll layout and pops without a Dip.
      route.canSwipe = _platform == TargetPlatform.iOS && !paged && GoRouter.of(context).canPop();
    });
  }

  // ── The scroll layout ─────────────────────────────────────────────────────

  Widget _scrollBody(BuildContext context, NovelReaderState s, NovelChapter chapter, NovelType type, CineStockColors stock, double width, ReaderSeries? series) {
    final paragraphs = chapter.paragraphs;
    if (_keys.length != paragraphs.length) _keys = List.generate(paragraphs.length, (_) => GlobalKey());
    final c = context.cine;
    final decorator = _decoratorFor(context, stock);
    final number = chapter.chapterNumber == null ? null : chapterNumberText(chapter.chapterNumber);
    final next = _nextInfo(series, chapter, s);
    if (!_restored && paragraphs.isNotEmpty) {
      _restored = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ctl.beginRestore();
      });
    }
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _toggleChrome,
        child: _SwipeChapter(
          enabled: ref.watch(novelSettingsProvider).novelSwipeChapter,
          onSwipe: (forward) {
            forward ? _next() : _previous();
          },
          child: ListView.builder(
            controller: _scroll,
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: paragraphs.length + 2,
            itemBuilder: (context, i) {
              Widget column(Widget child) => Center(child: SizedBox(width: width, child: child));
              if (i == 0) {
                return column(
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        NovelInPageHead(
                          seriesTitle: series?.title ?? '',
                          kicker: number == null ? 'CHAPTER' : 'CHAPTER $number',
                          percent: _bucket.percentOf(chapter),
                          stock: stock,
                          scroll: _scroll,
                        ),
                        NovelChapterOpener(chapterNumberText: number, title: chapter.title, wordCount: chapter.wordCount, type: type, stock: stock, trailing: _listenOpener(chapter, series)),
                      ],
                    ),
                  ),
                );
              }
              if (i == paragraphs.length + 1) {
                return column(
                  _withVoicesLine(stock, NovelEndMatter(
                    chapterKey: chapter.chapterKey,
                    chapterNumberText: number,
                    wordCount: chapter.wordCount,
                    stock: stock,
                    next: next,
                    onNext: next == null ? null : _next,
                    onPrevious: _ctl.previousKey == null ? null : _previous,
                    onBackToBook: _leave,
                    offline: chapter.isOffline,
                    onBackToDownloads: () => context.go(Routes.downloads()),
                    theEnd: _theEnd(series, chapter),
                  ),),
                );
              }
              final p = i - 1;
              final text = paragraphs[p];
              if (isSceneBreak(text)) return column(KeyedSubtree(key: _keys[p], child: NovelSceneBreak(stock: stock)));
              return column(
                KeyedSubtree(
                  key: _keys[p],
                  child: ListenableBuilder(
                    listenable: decorator,
                    builder: (context, _) => NovelParagraph(
                      text: text,
                      type: type,
                      width: width,
                      stock: stock,
                      indent: novelParagraphIndents(paragraphs, p),
                      dropCap: p == 0,
                      decorations: decorator.decorate(p, speakerDecorations(c, s.speakerRuns[p] ?? const [])),
                      onSpeakerPress: _showSpeaker,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// The Completed book's end block: `THE END`, "You finished {title}.", the Up next rail.
  Widget? _theEnd(ReaderSeries? series, NovelChapter chapter) {
    if (series == null || _ctl.nextKey != null || !series.completed) return null;
    final name = ref.read(sourcesListProvider).valueOrNull?.where((x) => x.id == widget.sourceId).firstOrNull?.name ?? widget.sourceId;
    return ReaderEndNotice(
      sourceId: widget.sourceId,
      seriesKey: widget.seriesKey,
      title: series.title,
      sourceName: name,
      chapterCount: series.chapters.length,
      completed: true,
      latestChapter: chapterNumberText(chapter.chapterNumber),
      readHours: math.max(1, (series.chapters.length * 0.2).ceil()),
      onBackToSeries: _leave,
    );
  }

  ({String? number, String title})? _nextInfo(ReaderSeries? series, NovelChapter chapter, NovelReaderState s) {
    final key = _ctl.nextKey;
    if (key == null) return null;
    final summary = series?.chapterOf(key);
    return (number: summary?.number == null ? null : chapterNumberText(summary!.number), title: summary?.title ?? '');
  }

  bool _onScrollNotification(ScrollNotification n) {
    if (n.depth != 0) return false;
    // A manual scroll stops the page following the voice.
    if (!_programmatic && n is ScrollUpdateNotification && n.dragDetails != null) _follower.userMoved();
    if (n is OverscrollNotification && n.overscroll > 0 && n.dragDetails != null && _ctl.nextKey != null) {
      _overscroll += n.overscroll;
      if (_overArmed && _overscroll >= kNovelOverscrollNextPx) {
        _overArmed = false;
        cineFeedback(context, HapticEvent.scrubBoundary, sound: SoundEvent.scrubBoundary);
        _next();
      }
    } else if (n is ScrollEndNotification) {
      _overscroll = 0;
      _overArmed = true;
    }
    return false;
  }

  // ── The paged layout ──────────────────────────────────────────────────────

  Widget _pagedBody(BuildContext context, NovelReaderState s, NovelChapter chapter, NovelType type, CineStockColors stock, double width, Size size, double margin) {
    final c = context.cine;
    final number = chapter.chapterNumber == null ? null : chapterNumberText(chapter.chapterNumber);
    final series = ref.read(readerSeriesProvider((sourceId: widget.sourceId, seriesKey: widget.seriesKey)));
    final reserve = _reserveListen();
    final key = Object.hash(size, type, chapter.chapterKey, _revision, width, reserve);
    if (_pageKey != key) {
      _pageKey = key;
      final opener = novelOpenerHeight(context, hasNumber: number != null, title: chapter.title, wordCount: chapter.wordCount, type: type, width: width) + (reserve ? kListenOpenerReserve : 0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _ctl.setViewport(size, margin: margin, bandTop: kNovelPageTopPad, openerHeight: opener);
        _ctl.paginateNovel(type.measure, type);
        if (!_restored) {
          _restored = true;
          _ctl.beginRestore();
        }
        setState(() {});
      });
    }
    final pages = _ctl.pages;
    if (pages.isEmpty) return NovelLoadingPage(lineHeight: type.fontSize * type.lineHeight, width: width);
    final decorations = {for (final e in s.speakerRuns.entries) e.key: speakerDecorations(c, e.value)};
    final next = _nextInfo(series, chapter, s);
    return NovelPagedColumns(
      key: _paged,
      paragraphs: chapter.paragraphs,
      pages: pages,
      type: type,
      width: width,
      stock: stock,
      turn: ref.watch(novelSettingsProvider).novelPageTurn,
      tapZones: ref.watch(novelSettingsProvider).novelTapZones,
      initialPage: s.pageIndex,
      decorations: decorations,
      decorationsBuilder: _decoratorFor(context, stock).decorate,
      decorationsRepaint: _decorator,
      onSpeakerPress: _showSpeaker,
      opener: NovelChapterOpener(chapterNumberText: number, title: chapter.title, wordCount: chapter.wordCount, type: type, stock: stock, trailing: _listenOpener(chapter, series)),
      endMatter: _withVoicesLine(stock, NovelEndMatter(
        chapterKey: chapter.chapterKey,
        chapterNumberText: number,
        wordCount: chapter.wordCount,
        stock: stock,
        next: next,
        onNext: next == null ? null : _next,
        onPrevious: _ctl.previousKey == null ? null : _previous,
        onBackToBook: _leave,
        offline: chapter.isOffline,
        onBackToDownloads: () => context.go(Routes.downloads()),
        theEnd: _theEnd(series, chapter),
      ),),
      onPage: (i) {
        if (!_programmaticPage) _follower.userMoved();
        _ctl.onPaged(i);
        _bucket.value = ref.read(novelReaderControllerProvider(_args)).readingBucket;
        if (i >= pages.length) {
          _ctl.markComplete();
          cineFeedback(context, HapticEvent.chapterComplete, sound: SoundEvent.chapterComplete);
        }
      },
      onMenu: _toggleChrome,
    );
  }

  Widget _listenLayer(BuildContext context, NovelReaderState s, NovelChapter chapter, ReaderSeries? series, CineStockColors stock) {
    final number = chapter.chapterNumber == null ? null : chapterNumberText(chapter.chapterNumber);
    final next = _nextInfo(series, chapter, s);
    final base = ref.read(apiBaseUrlProvider);
    final insets = MediaQuery.viewPaddingOf(context);
    return Positioned.fill(
      child: ListenLayer(
        ui: _listenUi,
        chapter: _chapterKey,
        stock: stock,
        chromeVisible: _chrome,
        barBottom: kNovelBarHeight + insets.bottom,
        safeBottom: insets.bottom,
        seriesTitle: series?.title ?? '',
        chapterLabel: number == null ? 'CHAPTER' : 'CHAPTER $number',
        chapterNumber: chapter.chapterNumber,
        chapterTitle: chapter.title,
        coverUrl: coverUrlAtWidth(sourceSeriesCoverUrl(base, widget.sourceId, widget.seriesKey), 720),
        duo: series?.summary.ambient?.duo ?? CineColors.ambientFallbackDuo,
        hasNext: _ctl.nextKey != null,
        hasPrevious: _ctl.previousKey != null,
        nextLabel: next?.number == null ? null : 'Chapter ${next!.number}',
        onNext: _next,
        onPrevious: _previous,
        onAdvance: _advanceListening,
        followDecoupled: _follower.decoupled,
        onBackToVoice: _follower.refollow,
      ),
    );
  }

  // ── Chrome, gestures, panels ──────────────────────────────────────────────

  List<Widget> _chromeLayers(BuildContext context, NovelReaderState s, NovelChapter chapter, ReaderSeries? series, CineStockColors stock, bool tablet, bool paged) {
    final bookmarked = s.saved;
    final number = chapter.chapterNumber == null ? 'CHAPTER' : 'CHAPTER ${chapterNumberText(chapter.chapterNumber)}';
    final title = [if ((series?.title ?? '').isNotEmpty) series!.title.toUpperCase(), number].join(' · ');
    final fraction = s.chapterPercent / 100;
    final minutes = math.max(0, (readingMinutes(chapter.wordCount) * (1 - fraction)).ceil());
    final idx = series?.indexOf(chapter.chapterKey) ?? -1;
    final total = series?.chapters.length ?? 0;
    final bookPercent = idx < 0 || total == 0 ? null : (((idx + fraction) / total) * 100).round().clamp(0, 100);
    final cacheAge = _ago(chapter.cacheFetchedAt);
    return [
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: _ChromeFade(
          animation: _chromeAnim,
          visible: _chrome,
          child: FocusScope(
            node: _chromeScope,
            child: NovelTopBar(
              stock: stock,
              runningTitle: title,
              onBack: _leave,
              offline: chapter.isOffline,
              savedCopyAgo: chapter.cacheStale ? cacheAge : null,
              actions: novelTopActions(
                onContents: _openContents,
                onBookmark: () => unawaited(_bookmark()),
                bookmarked: bookmarked,
                onType: () => unawaited(_typeSheet()),
                onMargins: tablet ? _openMargins : null,
                marginsOpen: _rightPanel,
                afterBookmark: [
                  if (s.attribution.attributed || (ref.watch(seriesAudioProvider((sourceId: widget.sourceId, seriesKey: widget.seriesKey))).valueOrNull?.rendered.contains(chapter.chapterKey) ?? false))
                    CineIconButton(label: 'Voices', role: CineIconRole.voiceCast, onPressed: _openVoices),
                ],
              ),
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: _ChromeFade(
          animation: _chromeAnim,
          visible: _chrome,
          child: NovelBottomBar(
            stock: stock,
            progress: fraction,
            onPrevious: _ctl.previousKey == null ? null : _previous,
            onNext: _ctl.nextKey == null ? null : _next,
            folio: novelFolio(
              key: _folio,
              stock: stock,
              chapterPercent: s.chapterPercent,
              bookPercent: bookPercent,
              minutesLeft: minutes,
              onGoTo: (p) => _ctl.jumpToBucket(math.max(1, (p / 100 * chapter.buckets).round())),
              onEditingChanged: (v) => setState(() => _editingProgress = v),
            ),
          ),
        ),
      ),
    ];
  }

  String _ago(String? iso) {
    final t = iso == null ? null : DateTime.tryParse(iso);
    if (t == null) return '';
    final h = DateTime.now().toUtc().difference(t.toUtc()).inHours;
    return h < 1 ? '1 H' : (h < 48 ? '$h H' : '${h ~/ 24} D');
  }

  Widget _gestureZones(BuildContext context, int brightness) => Positioned.fill(
        child: Stack(
          children: [
            EdgeDragZone(
              left: true,
              value: (brightness + 75) / 75,
              onChanged: (v) {
                setState(() => _brightnessDraft = (v * 75).round() - 75);
                _hud.show();
              },
              onEnd: () {
                final v = _brightnessDraft;
                if (v != null) unawaited(ref.read(novelSettingsProvider.notifier).put({'brightness': v}));
                _hud.releaseSoon();
              },
            ),
            EdgeHud(left: true, visible: _hud.visible, fill: (brightness + 75) / 75, label: brightness < 0 ? 'NIGHT −${-brightness}' : '0'),
          ],
        ),
      );

  Widget _panels(BuildContext context, NovelReaderState s, NovelChapter chapter, CineStockColors stock) => Positioned.fill(
        child: SidePanelLayout(
          leftOpen: _leftPanel,
          rightOpen: _rightPanel,
          left: NovelContentsPanel(
            sourceId: widget.sourceId,
            seriesKey: widget.seriesKey,
            currentChapterKey: chapter.chapterKey,
            onOpen: _openByDip,
            onClose: () => setState(() => _leftPanel = false),
          ),
          right: NovelMarginsPanel(
            sourceId: widget.sourceId,
            seriesKey: widget.seriesKey,
            chapterKey: chapter.chapterKey,
            chapterNumber: chapter.chapterNumber,
            completedOpen: s.readingBucket >= chapter.buckets && chapter.buckets > 0,
            onClose: () => setState(() => _rightPanel = false),
            onAddNote: () async {
              final r = await _ctl.bookmark();
              return r == NovelBookmarkResult.saved ? _ctl.lastBookmark : null;
            },
            onJumpToParagraph: (p) => _ctl.jumpToParagraph(p - 1, toReadingLine: false),
            extraTabs: [
              NovelMarginsTab('VOICES', (context) => CastList(chapter: _chapterKey, stock: stock, onReNarrate: _reNarrate)),
            ],
          ),
        ),
      );

  Widget _speakerPopover(CineStockColors stock) => ValueListenableBuilder<({String name, Offset at})?>(
        valueListenable: _speaker,
        builder: (context, v, _) {
          if (v == null) return const SizedBox.shrink();
          final c = context.cine;
          final box = context.findRenderObject();
          final local = box is RenderBox ? box.globalToLocal(v.at) : v.at;
          return Positioned(
            left: local.dx.clamp(8.0, MediaQuery.sizeOf(context).width - 160),
            top: math.max(8, local.dy - 56),
            child: GestureDetector(
              onTap: () => _speaker.value = null,
              child: Semantics(
                liveRegion: true,
                label: v.name,
                child: Container(
                  key: const Key('novel-speaker-popover'),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: stock.page, border: Border.all(color: stock.muted)),
                  child: CineRoleText(v.name.toUpperCase(), c.typeKicker, color: stock.ink),
                ),
              ),
            ),
          );
        },
      );

  Widget _noteField(CineStockColors stock) => Positioned(
        left: 16,
        right: 16,
        bottom: 24,
        child: _InlineNote(
          onSave: (text) async {
            setState(() => _noteOpen = false);
            if (text.trim().isNotEmpty) await _ctl.addNoteToLast(text);
          },
          onCancel: () => setState(() => _noteOpen = false),
        ),
      );

  Widget _rating(ReaderSeries series) => Consumer(
        builder: (context, ref, _) {
          final mature = ref.watch(sourcesListProvider).valueOrNull?.where((x) => x.id == widget.sourceId).firstOrNull?.mature ?? false;
          if (!mature) return const SizedBox.shrink();
          _ratingShown = true;
          return Positioned(
            top: MediaQuery.viewPaddingOf(context).top + 56,
            left: 16,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: CineRatingCard(genres: series.summary.genres, onDone: () {}),
            ),
          );
        },
      );
}

/// The chrome's motion (cinematic 8.15.3): it fades in over 240 ms and out over 160 ms and never
/// slides. Hidden chrome is `Offstage`, so it leaves focus traversal and semantics.
class _ChromeFade extends StatelessWidget {
  const _ChromeFade({required this.animation, required this.visible, required this.child});
  final Animation<double> animation;
  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, child) => Offstage(
          offstage: animation.value == 0 && !visible,
          child: IgnorePointer(ignoring: !visible, child: Opacity(opacity: animation.value.clamp(0.0, 1.0), child: child)),
        ),
      );
}

/// A horizontal swipe changes chapter (scroll layout, `swipeChapter` on): >= 72 px or 600 px/s,
/// within 30 degrees of horizontal, starting at least `max(24 px, the system gesture inset)` from
/// both edges.
class _SwipeChapter extends StatefulWidget {
  const _SwipeChapter({required this.enabled, required this.onSwipe, required this.child});
  final bool enabled;
  final ValueChanged<bool> onSwipe;
  final Widget child;

  @override
  State<_SwipeChapter> createState() => _SwipeChapterState();
}

class _SwipeChapterState extends State<_SwipeChapter> {
  final VelocityTracker _tracker = VelocityTracker.withKind(PointerDeviceKind.touch);
  Offset? _down;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final inset = math.max(24.0, MediaQuery.systemGestureInsetsOf(context).left);
    final width = MediaQuery.sizeOf(context).width;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        _tracker.addPosition(e.timeStamp, e.position);
        _down = e.position.dx >= inset && e.position.dx <= width - inset ? e.position : null;
      },
      onPointerMove: (e) => _tracker.addPosition(e.timeStamp, e.position),
      onPointerUp: (e) {
        final start = _down;
        _down = null;
        if (start == null) return;
        final d = e.position - start;
        final v = _tracker.getVelocity().pixelsPerSecond.dx;
        if (d.dx == 0 && v == 0) return;
        final angle = math.atan2(d.dy.abs(), d.dx.abs()) * 180 / math.pi;
        if (angle > 30) return;
        if (d.dx.abs() >= 72 || v.abs() >= 600) widget.onSwipe(d.dx < 0);
      },
      onPointerCancel: (_) => _down = null,
      child: widget.child,
    );
  }
}

/// The note field that takes the toast's place after `Add a note`: IME done saves.
class _InlineNote extends StatefulWidget {
  const _InlineNote({required this.onSave, required this.onCancel});
  final ValueChanged<String> onSave;
  final VoidCallback onCancel;

  @override
  State<_InlineNote> createState() => _InlineNoteState();
}

class _InlineNoteState extends State<_InlineNote> {
  final _text = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Material(
        color: context.cine.colorPaper0,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: Focus(
            onKeyEvent: (n, e) {
              if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
                widget.onCancel();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: CineTextField(label: 'Note', controller: _text, focusNode: _focus, textInputAction: TextInputAction.done, onSubmitted: widget.onSave),
          ),
        ),
      );
}

extension on ValueNotifier<int> {
  /// A read-only view of the bucket as the chapter's percent.
  ValueListenable<int> percentOf(NovelChapter chapter) => _Percent(this, chapter.buckets);
}

class _Percent extends ValueNotifier<int> {
  _Percent(this._source, this._buckets) : super(_compute(_source.value, _buckets)) {
    _source.addListener(_sync);
  }
  final ValueNotifier<int> _source;
  final int _buckets;

  static int _compute(int bucket, int buckets) => chapterPercent(bucket, buckets);

  void _sync() => value = _compute(_source.value, _buckets);

  @override
  void dispose() {
    _source.removeListener(_sync);
    super.dispose();
  }
}
