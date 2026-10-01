import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show PointerScrollEvent;
import 'package:flutter/material.dart' show Material, MaterialType, TextField, InputDecoration, InputBorder;
import 'package:flutter/scheduler.dart' show SchedulerBinding, SchedulerPhase;
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart' show singleKeyShortcutsProvider;
import 'package:manhwamaniacs/core/platform/mm_platform.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/providers/bookmark_outbox_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/downloads/store/bookmarks_dao.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/ocr/controllers/ocr_run_controller.dart';
import 'package:manhwamaniacs/features/ocr/models/page_text.dart';
import 'package:manhwamaniacs/features/ocr/providers/ocr_providers.dart';
import 'package:manhwamaniacs/features/reader/engine/lens_layout.dart';
import 'package:manhwamaniacs/features/reader/engine/neighbour.dart';
import 'package:manhwamaniacs/features/reader/engine/page_sample.dart' show PageSample;
import 'package:manhwamaniacs/features/reader/engine/page_turn.dart';
import 'package:manhwamaniacs/features/reader/engine/paged_reader_view.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_options.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_state.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_view.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_frames.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_layout.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_surface_slots.dart';
import 'package:manhwamaniacs/features/reader/engine/seam.dart';
import 'package:manhwamaniacs/features/reader/engine/swipe_neighbour.dart' show ReadingDirection, SwipeRelease;
import 'package:manhwamaniacs/features/reader/engine/tap_classifier.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/models/reader_feed.dart' show kChapterSeamExtent;
import 'package:manhwamaniacs/features/reader/models/reader_page.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_chapter_provider.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_prefs_provider.dart';
import 'package:manhwamaniacs/features/reader/providers/series_reading_order_provider.dart';
import 'package:manhwamaniacs/features/reader/utils/glass_reader_values.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_wakelock.dart';
import 'package:manhwamaniacs/features/sources/providers/source_reader_provider.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/ambient/cruise_controller.dart';
import 'package:manhwamaniacs/skins/glass/ambient/glass_ambient_bridge.dart';
import 'package:manhwamaniacs/skins/glass/ambient/guided_view.dart';
import 'package:manhwamaniacs/skins/glass/ambient/page_tint.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/light_angle.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_page_physics.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';
import 'package:manhwamaniacs/skins/glass/routes/sheet_registry.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_common.dart' show paletteOf;
import 'package:manhwamaniacs/skins/glass/screens/reader/band_lb.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/brightness_band.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/chapter_list.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/chapter_seam.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/dialogue_overlay.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/light_layers.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/neighbour_card.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/panel_fit.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/reader_chrome.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/reader_exclusion_rects.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/reader_gestures.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/reader_host.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/reader_keys.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/reader_settings_sheet.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/reader_system_ui.dart' show GlassReaderInsets;
import 'package:manhwamaniacs/skins/glass/screens/reader/side_panels.dart';
import 'package:manhwamaniacs/skins/glass/shell/purge.dart' show registerMatureStop, registerPlaybackStop;
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/soundscape/mixer.dart' show MixLevels;
import 'package:manhwamaniacs/skins/glass/soundscape/recipes.dart';
import 'package:manhwamaniacs/skins/glass/soundscape/soundscape_controller.dart';
import 'package:manhwamaniacs/skins/glass/soundscape/soundscape_sheet.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';
import 'package:share_plus/share_plus.dart';

/// The most `BackdropFilter.grouped` members the reader's one `BackdropGroup` may hold on the frost path (glass 2.5, 15.7).
const int kReaderBackdropBudget = 8;

/// The names of the backdrop members under [root] (debug: the assertion names every member when a ninth mounts).
List<String> readerBackdropMembers(Element root) {
  final out = <String>[];
  void visit(Element e) {
    // The side panels' material is a plain content-layer blur, not a member of the group.
    if (e.widget is ReaderPanelSurface) return;
    if (e.widget is BackdropFilter) {
      String? label;
      e.visitAncestorElements((a) {
        final w = a.widget;
        if (w is SkinGlass) {
          label = w.debugLabel;
          return false;
        }
        return true;
      });
      out.add(label ?? 'BackdropFilter');
    }
    e.visitChildElements(visit);
  }

  root.visitChildElements(visit);
  return out;
}

/// The Glass manga reader (glass 8.14): chrome over the shared reader engine. It never moves the page layer itself: every
/// page movement is an engine command.
class GlassMangaReader extends ConsumerStatefulWidget {
  const GlassMangaReader({super.key, required this.body, this.readAll = false, this.q, this.onReplace});

  final ReaderFrameBody body;
  final bool readAll;

  /// The dialogue-search query of `?q=` (the hit lens).
  final String? q;

  /// Replaces the route with another chapter of the same series (under a constant page key, so this `State` stays). Null uses
  /// `GoRouter.replace` with the route's own path family.
  final void Function(String chapterKey)? onReplace;

  @override
  ConsumerState<GlassMangaReader> createState() => GlassMangaReaderState();
}

class GlassMangaReaderState extends ConsumerState<GlassMangaReader> with TickerProviderStateMixin, WidgetsBindingObserver implements GlassReaderHost {
  @override
  final ReaderEngine engine = ReaderEngine();
  final FocusNode _focus = FocusNode(debugLabel: 'glass reader');
  final UnlockCounter _unlock = UnlockCounter();
  late final MmPlatform _platform = ref.read(mmPlatformProvider);
  late final ReaderWakelock _wakelock = ref.read(readerWakelockProvider);
  late final ReaderExclusionSync _exclusion = ReaderExclusionSync((r) => _platform.setExclusionRects(r));
  late final AnimationController _zoom = AnimationController(vsync: this);

  /// The hit lens's step (glass 8.14.9): slides to the next match and re-magnifies 1.0 -> 1.12 (`hitLens`, springCamera).
  late final AnimationController _lensMotion = AnimationController(vsync: this);
  Rect? _lensFrom, _lensTo;
  Offset? _centreFrom, _centreTo;
  final List<StreamSubscription<Object>> _subs = [];
  final List<ProviderSubscription<Object?>> _keepAlive = [];

  bool? _locked;
  bool _goTo = false;
  bool _menuOpen = false;
  bool _dialogue = false;
  bool _leftPanel = false, _rightPanel = false;
  RightPanelTab _rightTab = RightPanelTab.settings;
  int? _zoomChip;
  String? _seamChip;
  int _lockPulse = 0;
  Color? _tint;
  double? _liveBrightness;
  Timer? _zoomChipTimer, _seamChipTimer, _wakeRelease, _autoNext;
  bool _wakeHeld = false;
  bool _foreground = true;
  ({NeighbourDirection direction, NeighbourInfo? info})? _card;
  NeighbourPhase _phase = NeighbourPhase.idle;
  List<DialogueBox> _matches = const [];
  int _match = 0;
  bool _hitShown = false;
  List<Offset> _lights = const [];
  int _lightSerial = 0;
  double? _swipeDx;
  bool _scrubbing = false;
  double _thumbY = 0;
  String? _openSheet;
  VoidCallback? _releaseClaims;
  final List<VoidCallback> _stops = [];
  SoundscapeController? _soundscape;
  String? _pendingSheet;
  bool _guided = false;
  final TintFollower _tintFollower = TintFollower();
  PageSample? _lbSample, _lbShown;
  late final GlassAmbientBridge _ambientBridge = GlassAmbientBridge(ref: ref, engine: engine, sourceId: sourceId, seriesKey: seriesKey);

  ReaderFrameBody get _body => widget.body;
  ({String sourceId, String seriesKey, String chapterKey, ReaderOrigin origin}) get _id =>
      _body.identity ?? (sourceId: '', seriesKey: '', chapterKey: _body.feed.chapters.firstOrNull?.id ?? '', origin: ReaderOrigin.manifest);

  @override
  String get sourceId => _id.sourceId;
  @override
  String get seriesKey => _id.seriesKey;
  String get _seriesRef => '$sourceId:$seriesKey';

  GlassReaderSettingsView get _settings => ref.read(glassReaderSettingsProvider(_seriesRef));

  @override
  void initState() {
    super.initState();
    _platform;
    _wakelock;
    // Eager: a late controller first touched in dispose() would look up a deactivated ancestor.
    _zoom.value;
    _lensMotion.addListener(_applyLens);
    WidgetsBinding.instance.addObserver(this);
    _releaseClaims = _claimSheets();
    _subs
      ..add(engine.seamEvents.listen(_onSeam))
      ..add(engine.neighbourEvents.listen(_onNeighbour));
    engine.addListener(_onEngine);
    _attachCruise();
    if (widget.q != null) unawaited(_prepareHitLens(widget.q!));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      glassFire(ref, HapticEvent.readerEnter);
      _syncWake();
      final sheet = _sheetParam();
      _lastParam = sheet;
      if (sheet != null) _pushSheet(sheet);
    });
  }

  // ── Cruise (glass 9.4.1): the controller owns the speed, the engine owns the ramp and the touch pauses ──

  CruiseController get _cruise => ref.read(cruiseControllerProvider.notifier);

  void _attachCruise() {
    // Keeps the auto-dispose controller alive for as long as this reader is, and repaints the pill on every change.
    _keepAlive.add(ref.listenManual(cruiseControllerProvider, (_, __) {
      if (mounted && !_disposed) setState(() {});
    }),);
    // Binding changes the provider's state, which is not allowed while the tree builds: after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _cruise.attach(
        EngineCruiseSource(engine),
        speed: _settings.cruiseSpeed,
        persist: (v) => unawaited(GlassReaderSettingsWriter(ref, _seriesRef).series({GlassReaderKeys.cruiseSpeed: v})),
        reduced: () => ref.read(glassMotionPrefsProvider).reduced,
      );
    });
    _keepAlive.add(ref.listenManual(soundscapeControllerProvider.select((v) => (v.scene, v.state)), (_, __) {
      if (mounted && !_disposed) setState(() {});
    }),);
    _keepAlive.add(ref.listenManual(glassReaderSettingsProvider(_seriesRef), (p, n) => _cruise.follow(_settings.cruiseSpeed)));
    _stops.add(registerPlaybackStop('cruise', _cruise.stop));
    // The soundscape follows the reader: what it should play on open, and a fade-out and pause on leaving.
    final soundscape = ref.read(soundscapeControllerProvider.notifier);
    _soundscape = soundscape;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final own = ref.read(readerPrefsProvider(_seriesRef)).soundscape;
      final genres = ref.read(sourceSeriesDetailProvider((sourceId: sourceId, seriesId: seriesKey))).valueOrNull?.series.genres ?? const <String>[];
      final mature = ref.read(sourcesListProvider).valueOrNull?.where((x) => x.id == sourceId).firstOrNull?.mature ?? false;
      unawaited(soundscape.enterReader(SoundscapeReaderContext(
        seriesRef: _seriesRef,
        genres: genres,
        rememberedScene: SoundScene.byName(own?.scene),
        rememberedMix: own == null ? null : MixLevels(bed: own.bed, detail: own.detail, tone: own.tone),
        mature: mature,
      ),),);
    });
    final mature = ref.read(sourcesListProvider).valueOrNull?.where((x) => x.id == sourceId).firstOrNull?.mature ?? false;
    if (mature) _stops.add(registerMatureStop('cruise', _cruise.stop));
  }

  /// `?sheet=settings|chapters|note` is this reader's own: the global sheet host steps aside.
  VoidCallback _claimSheets() {
    final r = [
      for (final id in const ['settings', 'chapters', 'note', 'soundscape']) glassClaimSheet(id),
    ];
    return () {
      for (final f in r) {
        f();
      }
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final r = _router;
    if (!identical(r, _listened)) {
      _listened?.routerDelegate.removeListener(_onRoute);
      _listened = r?..routerDelegate.addListener(_onRoute);
    }
  }

  @override
  void didUpdateWidget(GlassMangaReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.body.identity?.chapterKey != widget.body.identity?.chapterKey) {
      _card = null;
      _phase = NeighbourPhase.idle;
      _zoom.value = 0;
      for (final s in _keepAlive) {
        s.close();
      }
      _keepAlive.clear();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_disposed) return;
    _syncWake();
  }

  bool _disposed = false;

  @override
  void deactivate() {
    _disposed = true;
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _disposed = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _listened?.routerDelegate.removeListener(_onRoute);
    _releaseClaims?.call();
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    for (final s in _keepAlive) {
      s.close();
    }
    for (final stop in _stops) {
      stop();
    }
    _soundscape?.leaveReader();
    engine.removeListener(_onEngine);
    _zoomChipTimer?.cancel();
    _seamChipTimer?.cancel();
    _wakeRelease?.cancel();
    _autoNext?.cancel();
    _idleHide?.cancel();
    _tapsTimer?.cancel();
    _exclusion.clear();
    if (_wakeHeld) unawaited(_wakelock.disable());
    _zoom.dispose();
    _lensMotion.dispose();
    _focus.dispose();
    engine.dispose();
    super.dispose();
  }

  // ── Host ────────────────────────────────────────────────────────────────

  ReaderChapter? _chapter(String id) => _body.feed.chapters.where((c) => c.id == id).firstOrNull;

  @override
  ReaderChapter? chapterById(String id) => _chapter(id);

  @override
  ReaderPage? pageOf(String chapterId, int page) {
    final c = _chapter(chapterId) ?? _body.feed.chapters.firstOrNull;
    if (c == null || page < 1 || page > c.pages.length) return null;
    return c.pages[page - 1];
  }

  @override
  String get seriesTitle {
    final d = ref.read(sourceSeriesDetailProvider((sourceId: sourceId, seriesId: seriesKey))).valueOrNull;
    return d?.series.title ?? _body.feed.chapters.firstOrNull?.seriesTitle ?? '';
  }

  String _chapterTitle(String id) {
    final c = _chapter(id);
    if (c != null) return c.title;
    final d = ref.read(sourceSeriesDetailProvider((sourceId: sourceId, seriesId: seriesKey))).valueOrNull;
    return d?.chapters.where((x) => x.id == id).firstOrNull?.title ?? id;
  }

  /// "Chapter 144" for a chapter id.
  String chapterLabel(String id) {
    final t = _chapterTitle(id);
    final n = chapterNumberOf(t);
    if (n == null) return t;
    return 'Chapter ${n == n.roundToDouble() ? n.round() : n}';
  }

  @override
  String chapterShort(String chapterId) {
    final n = chapterNumberOf(_chapterTitle(chapterId));
    if (n == null) return _chapterTitle(chapterId);
    return 'Ch ${n == n.roundToDouble() ? n.round() : n}';
  }

  String? get _nextId => _body.feed.chapters.lastOrNull?.nextChapterId ?? _neighbourInList(_body.feed.chapters.lastOrNull?.id, 1);
  String? get _previousId => _body.feed.chapters.firstOrNull?.previousChapterId ?? _neighbourInList(_body.feed.chapters.firstOrNull?.id, -1);

  /// The series list's neighbour of [id] (oldest first) when the manifest did not name one.
  String? _neighbourInList(String? id, int by) {
    if (id == null) return null;
    final list = ref.read(sourceSeriesDetailProvider((sourceId: sourceId, seriesId: seriesKey))).valueOrNull?.chapters;
    if (list == null) return null;
    final i = list.indexWhere((c) => c.id == id);
    final j = i + by;
    return i < 0 || j < 0 || j >= list.length ? null : list[j].id;
  }

  @override
  String? get nextChapterLabel => _nextId == null ? null : chapterLabel(_nextId!);

  @override
  bool get readAll => widget.readAll;

  @override
  bool get paged => !widget.readAll && (_settings.prefs.layout == 'single' || _settings.prefs.layout == 'double');

  @override
  bool get cinema => _settings.prefs.cinema;

  @override
  bool get hideCinemaProgress => _settings.values.hideCinemaProgress;

  @override
  bool get locked => _locked ?? _settings.values.lockControls;

  @override
  bool get offline => ref.read(deviceOnlineProvider).valueOrNull == false;

  @override
  bool get accessible => MediaQuery.accessibleNavigationOf(context);

  @override
  bool get reducedMotion => ref.read(glassMotionPrefsProvider).reduced;

  @override
  bool get pageTinted => _settings.values.pageTinted && !ref.read(glassA11yProvider).solid;

  @override
  bool get rainOn {
    final v = ref.read(soundscapeControllerProvider);
    final playing = v.scene == SoundScene.rain && (v.state == SoundscapeState.starting || v.state == SoundscapeState.playingBuiltin || v.state == SoundscapeState.playingRecorded || v.state == SoundscapeState.ducked);
    return playing && !reducedMotion && !ref.read(glassA11yProvider).solid;
  }

  @override
  Color? get tint => _tint;

  @override
  PageSample? get lbSample => _lbSample ?? engine.value.currentPageSample;

  Color? get _coverTint {
    final a = paletteOf(null, ref.read(sourceSeriesDetailProvider((sourceId: sourceId, seriesId: seriesKey))).valueOrNull?.series.ambient)?.a;
    return a == null || a.isEmpty ? null : a.first;
  }

  @override
  bool get goToOpen => _goTo;

  @override
  int? get zoomChipPercent => _zoomChip;

  @override
  String? get seamChip => _seamChip;

  @override
  int get lockPulse => _lockPulse;

  @override
  bool get matchesShown => _hitShown && _matches.isNotEmpty;

  // ── Engine events ──────────────────────────────────────────────────────

  void _onEngine() {
    if (_disposed) return;
    final s = engine.value;
    final sample = s.currentPageSample;
    // Glass 9.4.4: the clamped tint, moved only past a Delta E of 0.04 and never during a fling above 3000 px/s; a greyscale page keeps
    // it and six in a row fall back to the cover. The legibility sample is held through a fling the same way.
    _tintFollower.cover = _coverTint;
    final fling = s.scrollVelocity.abs() > kTintFlingHold;
    if (!fling) _lbSample = sample;
    final next = _tintFollower.feed(sample?.tint, s.scrollVelocity);
    if ((next != _tint || (!fling && _lbSample != _lbShown)) && mounted) {
      _lbShown = _lbSample;
      void apply() {
        if (mounted && !_disposed) setState(() => _tint = next);
      }

      // The engine publishes from inside its own build: never rebuild this reader in that phase.
      SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks ? WidgetsBinding.instance.addPostFrameCallback((_) => apply()) : apply();
    }
    _maybeAutoNext(s);
    _syncWake();
    final f = s.furtherElsewhere;
    if (f != null && f != _furtherShown) {
      _furtherShown = f;
      final n = f.chapterNumber;
      final ch = n == null ? chapterShort(f.chapterKey) : 'Ch ${n == n.roundToDouble() ? n.round() : n}';
      showGlassToast(
        ref,
        GlassToastSpec("You're further ahead on another device: $ch, p. ${f.lastPage}",
            actionLabel: 'Jump there', onAction: () => _switchTo(f.chapterKey),),
      );
    }
  }

  FurtherElsewhere? _furtherShown;

  /// Fingers on the strip: auto next never fires under a held pull.
  int _down = 0;

  void _onSeam(SeamEvent e) {
    if (e.kind == SeamEventKind.readingLine) {
      glassFire(ref, HapticEvent.chapterSeam);
      return;
    }
    if (widget.readAll) return;
    _seamChipTimer?.cancel();
    setState(() => _seamChip = chapterLabel(e.chapterId));
    _seamChipTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _seamChip = null);
    });
  }

  Future<void> _onNeighbour(NeighbourEvent e) async {
    final prev = _phase;
    _phase = e.phase;
    switch (e.phase) {
      case NeighbourPhase.idle:
        if (_zoom.value == 0 && mounted) setState(() => _card = null);
      case NeighbourPhase.armed:
        if (_card == null || prev == NeighbourPhase.idle) {
          glassFire(ref, HapticEvent.chapterArm);
          setState(() => _card = (direction: e.direction, info: null));
          try {
            final info = await engine.armNeighbour(e.direction);
            if (mounted && _card?.direction == e.direction) setState(() => _card = (direction: e.direction, info: info));
          } catch (_) {}
        }
      case NeighbourPhase.locked:
        // A fast pull can reach the lock without an armed event in between.
        if (_card == null) {
          setState(() => _card = (direction: e.direction, info: null));
          unawaited(
            engine.armNeighbour(e.direction).then(
              (info) {
                if (mounted && _card?.direction == e.direction) setState(() => _card = (direction: e.direction, info: info));
              },
              onError: (_) {},
            ),
          );
        }
        glassFire(ref, HapticEvent.chapterNext);
        if (e.via == NeighbourVia.wheel) unawaited(_commit(e.direction, 0));
    }
  }

  /// Releasing past the lock zooms the card to full screen on `springZoom` carrying the release velocity, then commits.
  Future<void> _commit(NeighbourDirection d, double velocity) async {
    if (_card == null) setState(() => _card = (direction: d, info: null));
    if (reducedMotion) {
      engine.commitNeighbour(d);
      return;
    }
    await GlassMotion.play(MotionName.zoom, controller: _zoom, target: 1, velocityPxPerS: velocity, travelPx: MediaQuery.sizeOf(context).height);
    if (!mounted) return;
    engine.commitNeighbour(d, velocity: velocity);
    engine.continueFling(velocity);
  }

  void _onPointerUp() {
    if (_phase == NeighbourPhase.locked && _card != null) unawaited(_commit(_card!.direction, engine.live.scrollVelocity.value));
  }

  /// One at a time with Auto next on: reaching the end with the chrome hidden commits the next chapter after 900 ms unless the
  /// reader scrolls back.
  void _maybeAutoNext(ReaderEngineState s) {
    final want = _settings.values.oneAtATime && _settings.prefs.autoNextChapter && s.atEnd && !s.chromeVisible && s.hasNext && _down == 0;
    if (!want) {
      _autoNext?.cancel();
      _autoNext = null;
      return;
    }
    _autoNext ??= Timer(const Duration(milliseconds: 900), () {
      _autoNext = null;
      if (mounted && engine.value.atEnd) unawaited(_commit(NeighbourDirection.next, 0));
    });
  }

  void _onEvent(ReaderEngineEvent e) {
    switch (e) {
      case ReaderUnlocked():
        _doUnlock();
      case ReaderBookmarkSaved():
        glassFire(ref, HapticEvent.bookmarkAdd);
        showGlassToast(ref, GlassToastSpec('Saved this spot', actionLabel: 'Add note', onAction: () => _presentSheet('note')));
      case ReaderStaleAnchor(:final openedPage, :final requestedPage):
        showGlassToast(ref, GlassToastSpec('This chapter changed. Opened at page $openedPage instead of $requestedPage.'));
      case ReaderPageSwiped():
        glassFire(ref, HapticEvent.pageTurn);
    }
  }

  // ── Keep awake (glass 8.14.5): on with the switch in the foreground, always while cruising, released 2 s after cruise stops ──

  void _syncWake() {
    if (!mounted || _disposed) return;
    final cruising = engine.value.autoScrolling || _guided;
    final want = _foreground && (_settings.values.keepAwake || cruising);
    final wl = _wakelock;
    if (want) {
      _wakeRelease?.cancel();
      _wakeRelease = null;
      if (!_wakeHeld) {
        _wakeHeld = true;
        unawaited(wl.enable());
      }
      return;
    }
    if (!_wakeHeld) return;
    if (!_foreground) {
      _wakeRelease?.cancel();
      _wakeHeld = false;
      unawaited(wl.disable());
      return;
    }
    _wakeRelease ??= Timer(const Duration(seconds: 2), () {
      _wakeRelease = null;
      if (_wakeHeld) {
        _wakeHeld = false;
        unawaited(wl.disable());
      }
    });
  }

  // ── Commands the chrome issues ─────────────────────────────────────────

  @override
  void back() => _leave();

  @override
  void openSeries() {
    final router = _router;
    if (router == null) return;
    unawaited(router.push<void>(Routes.feature(sourceId, seriesKey)));
  }

  @override
  void openChapterList({bool byKey = false}) {
    if (isReaderDesktopFrame(MediaQuery.sizeOf(context))) {
      _togglePanel(left: true, byKey: byKey);
      return;
    }
    _presentSheet('chapters');
  }

  @override
  void openSettings({bool byKey = false}) {
    if (isReaderDesktopFrame(MediaQuery.sizeOf(context))) {
      _rightTab = RightPanelTab.settings;
      _togglePanel(left: false, byKey: byKey);
      return;
    }
    _presentSheet('settings');
  }

  @override
  void toggleBookmark() {
    unawaited(
      engine.bookmark().then((ok) {
        if (!ok && mounted && _body.onAddBookmark != null) {
          showGlassToast(ref, const GlassToastSpec("Couldn't save that spot", kind: GlassToastKind.error));
        }
      }),
    );
  }

  @override
  void setGoTo(bool open) {
    if (open == _goTo) return;
    setState(() => _goTo = open);
    open ? engine.holdChrome() : engine.scheduleHideChrome();
  }

  /// Up to 5 pages glide on `springPage`; longer jumps cut (the engine's 120 ms cross-fade for paged).
  @override
  void jumpTo(int page) {
    final s = engine.value;
    final glide = (page - s.page).abs() <= 5;
    if (paged) {
      engine.turnTo(page,
          kind: glide ? PageTurn.slide : PageTurn.fade,
          slideDuration: _pageSettle,
          slideCurve: const Cubic(0.2, 0.9, 0.3, 1),
          fadeDuration: const Duration(milliseconds: 120),);
    } else {
      engine.jumpToPage(page, glide: glide);
    }
  }

  Duration get _pageSettle => springOf(gt.springPage).duration;

  @override
  void previousChapter() => _switchTo(_previousId);

  @override
  void nextChapter() {
    if (_settings.values.oneAtATime && !widget.readAll) {
      unawaited(_commit(NeighbourDirection.next, 0));
      return;
    }
    _switchTo(_nextId);
  }

  @override
  void toggleCruise() {
    if (!cruiseAvailable) return;
    glassFire(ref, HapticEvent.autoscrollToggle);
    _cruise.toggle();
  }

  @override
  CruiseState get cruise => ref.read(cruiseControllerProvider);

  @override
  bool get cruiseAvailable => !paged;

  @override
  void cruisePreview(double v) => _cruise.preview(v);

  @override
  void cruiseCommit(double v) => _cruise.commit(v);

  @override
  void cruiseStep(double by) => _cruise.step(by);

  @override
  void cruiseResume() => _cruise.resume();

  // ── Guided view (glass 9.4.3): `shift+p`, the page menu, the settings row, the landscape menu and the panel-focus button ──

  @override
  bool get guidedOn => _guided;

  @override
  bool get guidedAvailable => !paged && engine.value.panelBoxes != null;

  @override
  void toggleGuided() {
    if (paged || locked) return;
    if (_guided) {
      setState(() => _guided = false);
      engine.scheduleHideChrome();
    } else {
      engine.holdChrome();
      setState(() => _guided = true);
    }
    _syncWake();
  }

  /// Leaves guided view onto the strip with the framed panel's top at the top content inset (`inset.top + 60`).
  void _closeGuided(int page, double? panelTop) {
    if (!mounted) return;
    setState(() => _guided = false);
    engine.scheduleHideChrome();
    engine.jumpToPage(page);
    _syncWake();
  }

  void _stepCruise(double by) {
    if (!cruiseAvailable) return;
    _cruise.step(by);
  }

  @override
  void scrubbing(bool active, {double? thumbY}) {
    if (active != _scrubbing) {
      _scrubbing = active;
      active ? engine.holdChrome() : engine.scheduleHideChrome();
    }
    if (thumbY != null) _thumbY = thumbY;
    _syncExclusion();
  }

  // ── Chapters ───────────────────────────────────────────────────────────

  GoRouter? get _router {
    try {
      return GoRouter.of(context);
    } catch (_) {
      return null;
    }
  }

  /// Switches chapters in place: the next route resolves while this one stays, then the route is replaced under the constant
  /// page key so the `State` and the engine survive (the pages cross-fade, no route animation).
  void _switchTo(String? chapterKey) {
    if (chapterKey == null) return;
    if (widget.readAll) {
      final i = _body.feed.chapters.indexWhere((c) => c.id == chapterKey);
      if (i >= 0) {
        engine.seekToChapter(i);
        return;
      }
    }
    _keepResolved(chapterKey);
    _replace(chapterKey);
  }

  void _keepResolved(String chapterKey) {
    if (_id.origin == ReaderOrigin.source) {
      _keepAlive.add(ref.listenManual(sourceReaderChapterProvider((sourceId: sourceId, seriesId: seriesKey, chapterId: chapterKey)), (_, __) {}));
    } else {
      _keepAlive.add(ref.listenManual(resolvedReaderChapterProvider((sourceId: sourceId, seriesKey: seriesKey, chapterKey: chapterKey)), (_, __) {}));
    }
  }

  void _replace(String chapterKey) {
    final custom = widget.onReplace;
    if (custom != null) {
      custom(chapterKey);
      return;
    }
    final router = _router;
    if (router == null) return;
    final path = _id.origin == ReaderOrigin.source
        ? Routes.readerAliases[1]
            .replaceFirst(':sourceId', Uri.encodeComponent(sourceId))
            .replaceFirst(':seriesKey', Uri.encodeComponent(seriesKey))
            .replaceFirst(':chapterKey', Uri.encodeComponent(chapterKey))
        : Routes.reader(sourceId, seriesKey, chapterKey);
    router.replace<void>(path);
  }

  /// `loadNeighbour` for one-at-a-time mode: the neighbour's manifest, kept alive so the replace lands on resolved data.
  Future<ReaderChapter?> _loadNeighbour(NeighbourDirection d) async {
    final key = d == NeighbourDirection.next ? _nextId : _previousId;
    if (key == null) return null;
    _keepResolved(key);
    if (_id.origin == ReaderOrigin.source) {
      return ref.read(sourceReaderChapterProvider((sourceId: sourceId, seriesId: seriesKey, chapterId: key)).future);
    }
    final r = await ref.read(resolvedReaderChapterProvider((sourceId: sourceId, seriesKey: seriesKey, chapterKey: key)).future);
    return r.chapter;
  }

  // ── Leaving ────────────────────────────────────────────────────────────

  /// Back: pop when something is beneath; otherwise (a cold deep link, a notification, the skin-switch return) the series page in
  /// its full-page form with a 200 ms cross-fade.
  void _leave() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
      return;
    }
    _router?.go(Routes.feature(sourceId, seriesKey));
  }

  ReaderLayers get _layers => ReaderLayers(
        menu: _menuOpen || _goTo,
        dialogue: _dialogue || _hitShown,
        panel: _leftPanel || _rightPanel,
        cinema: cinema && !engine.value.chromeVisible,
      );

  void _apply(ReaderEscape step) {
    switch (step) {
      case ReaderEscape.closeMenu:
        if (_goTo) setGoTo(false);
        if (_menuOpen) Navigator.of(context, rootNavigator: true).maybePop();
      case ReaderEscape.closeDialogue:
        _closeDialogue();
      case ReaderEscape.closePanel:
        setState(() => _leftPanel = _rightPanel = false);
        _focus.requestFocus();
      case ReaderEscape.exitCinema:
        engine.showChrome();
      case ReaderEscape.closeSheet:
      case ReaderEscape.leave:
        _leave();
    }
  }

  void _onBack() => _apply(backStep(_layers));

  // ── Sheets (`?sheet=`), panels, the page menu ──────────────────────────

  /// The location's `?sheet=`, read from the router (the reader's own route is the top one while it shows).
  Uri? get _location {
    final r = _router;
    if (r == null) return null;
    final cfg = r.routerDelegate.currentConfiguration;
    if (cfg.isEmpty) return null;
    // A pushed reader is an imperative match on top of the base location: its own uri is the reader's.
    final last = cfg.last;
    return last is ImperativeRouteMatch ? last.matches.uri : cfg.uri;
  }

  String? _sheetParam() => _location?.queryParameters['sheet'];

  void _setSheetParam(String? id) {
    final router = _router;
    final uri = _location;
    if (router == null || uri == null) return;
    final q = {...uri.queryParameters};
    if (id == null) {
      if (!q.containsKey('sheet')) return;
      q.remove('sheet');
    } else {
      if (q['sheet'] == id) return;
      q['sheet'] = id;
    }
    router.replace<void>(Uri(path: uri.path, queryParameters: q.isEmpty ? null : q).toString());
  }

  /// Opens sheet [id]: with a router the location gains `?sheet=id` and the route listener pushes the sheet once the replace
  /// has landed (a replace would drop a sheet pushed before it); without one it is pushed at once.
  void _presentSheet(String id) {
    if (_openSheet != null) return;
    // Desktop frame: the Soundscape section lives at the top of the right panel's Settings tab.
    if (id == 'soundscape' && isReaderDesktopFrame(MediaQuery.sizeOf(context))) {
      _rightTab = RightPanelTab.settings;
      if (!_rightPanel) {
        _togglePanel(left: false);
      } else {
        setState(() {});
      }
      return;
    }
    if (_router != null && _location != null) {
      _setSheetParam(id);
      return;
    }
    _pushSheet(id);
  }

  GoRouter? _listened;

  String? _lastParam;

  /// Pushes a sheet when `?sheet=` appears (a transition from none or another id), never again for the same value: a sheet
  /// that just closed must not reopen before its parameter is removed.
  void _onRoute() {
    if (!mounted || _disposed) return;
    final id = _sheetParam();
    final appeared = id != _lastParam;
    _lastParam = id;
    if (appeared && id != null && _openSheet == null && const {'settings', 'chapters', 'note', 'soundscape'}.contains(id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _openSheet == null && _sheetParam() == id) _pushSheet(id);
      });
    }
  }

  void _pushSheet(String id) {
    if (_openSheet != null) return;
    final landscapePhone = MediaQuery.sizeOf(context).shortestSide < 600 && MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;
    final GlassSheetPage<void> page = switch (id) {
      'chapters' => GlassSheetPage<void>(
          key: const ValueKey('reader-sheet-chapters'),
          title: 'Chapters',
          detents: const [GlassDetent.large],
          opening: GlassDetent.large,
          builder: (c) => ReaderChapterList(
            sourceId: sourceId,
            seriesKey: seriesKey,
            currentChapterId: engine.value.chapterId,
            offline: offline,
            onOpen: (k) {
              Navigator.of(c).maybePop();
              _switchTo(k);
            },
          ),
        ),
      'note' => GlassSheetPage<void>(
          key: const ValueKey('reader-sheet-note'),
          title: 'Add note',
          detents: const [GlassDetent.medium],
          builder: (c) => _NoteSheet(
            onSave: (text) async {
              unawaited(Navigator.of(c).maybePop());
              await _saveNote(text);
            },
          ),
        ),
      'soundscape' => soundscapeSheetPage(seriesRef: _seriesRef, landscapePhone: landscapePhone),
      _ => GlassSheetPage<void>(
          key: const ValueKey('reader-sheet-settings'),
          title: 'Reader settings',
          detents: landscapePhone ? const [GlassDetent.large] : const [GlassDetent.medium, GlassDetent.large],
          opening: landscapePhone ? GlassDetent.large : GlassDetent.medium,
          builder: (c) => SingleChildScrollView(
            child: ReaderSettingsBody(
              seriesRef: _seriesRef,
              readAll: widget.readAll,
              onOpenSheet: (id) {
                _pendingSheet = id;
                unawaited(Navigator.of(c).maybePop());
              },
            ),
          ),
        ),
    };
    _openSheet = id;
    engine.holdChrome();
    unawaited(
      Navigator.of(context, rootNavigator: true).push<void>(page.createRoute(context)).whenComplete(() {
        _openSheet = null;
        if (!mounted) return;
        engine.scheduleHideChrome();
        _setSheetParam(null);
        final next = _pendingSheet;
        _pendingSheet = null;
        if (next != null) _openNext(next);
      }),
    );
  }

  /// What an Ambient row asked for once the settings sheet has left.
  void _openNext(String id) {
    if (id == 'guided') {
      toggleGuided();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _presentSheet(id);
      });
    }
  }

  void _openFromPanel(String id) => id == 'guided' ? toggleGuided() : _presentSheet(id);

  Future<void> _saveNote(String text) async {
    final outbox = ref.read(bookmarkOutboxControllerProvider);
    final all = await outbox.store?.listBookmarks() ?? const [];
    final mine = all.where((b) => b.sourceId == sourceId && b.seriesKey == seriesKey && b.chapterKey == engine.value.chapterId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (mine.isEmpty) return;
    try {
      await outbox.setNote(mine.first, text);
    } catch (_) {
      if (mounted) showGlassToast(ref, const GlassToastSpec("Couldn't save that note", kind: GlassToastKind.error));
    }
  }

  /// Desktop frame: opening a panel by key moves focus into it; opening a second that does not fit closes the first.
  void _togglePanel({required bool left, bool byKey = false}) {
    final w = MediaQuery.sizeOf(context).width;
    setState(() {
      if (left) {
        _leftPanel = !_leftPanel;
        if (_leftPanel && _rightPanel && !bothPanelsFit(w)) {
          _rightPanel = false;
          showGlassToast(ref, const GlassToastSpec('One panel at a time at this window size'));
        }
      } else {
        _rightPanel = !_rightPanel;
        if (_rightPanel && _leftPanel && !bothPanelsFit(w)) {
          _leftPanel = false;
          showGlassToast(ref, const GlassToastSpec('One panel at a time at this window size'));
        }
      }
    });
  }

  Future<void> _pageMenu(String chapterId, int page, Offset at) async {
    if (locked) return;
    _menuOpen = true;
    engine.holdChrome();
    final anchor = Rect.fromCenter(center: at, width: 1, height: 1);
    await showGlassMenu(
      context,
      anchor: anchor,
      atPointer: true,
      title: 'Page $page',
      entries: [
        GlassMenuEntry(label: 'Save page image', onSelected: () => unawaited(_savePage(chapterId, page, anchor))),
        GlassMenuEntry(label: 'Bookmark this spot', onSelected: toggleBookmark),
        GlassMenuEntry(label: 'Show dialogue', onSelected: _openDialogue),
        if (!paged) GlassMenuEntry(label: 'Guided view', onSelected: toggleGuided),
        GlassMenuEntry(label: 'Report broken page', onSelected: () => _retryPage(chapterId, page)),
      ],
    );
    _menuOpen = false;
    if (mounted) engine.scheduleHideChrome();
  }

  final Map<String, int> _epochs = {};

  void _retryPage(String chapterId, int page) => setState(() => _epochs['$chapterId:$page'] = (_epochs['$chapterId:$page'] ?? 0) + 1);

  /// The phone share flow (glass 9.2.4): the page file through the share sheet; Android saves into Pictures/ManhwaManiacs.
  Future<void> _savePage(String chapterId, int page, Rect anchor) async {
    final p = pageOf(chapterId, page);
    final file = p?.localFile;
    if (file == null) {
      showGlassToast(ref, const GlassToastSpec('Save this chapter to keep its pages'));
      return;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await const MethodChannel('mm/media').invokeMethod<void>('saveImage', {'path': file.path, 'album': 'ManhwaManiacs'});
        showGlassToast(ref, const GlassToastSpec('Saved to Pictures/ManhwaManiacs'));
      } catch (_) {
        showGlassToast(ref, const GlassToastSpec("Couldn't save that page", kind: GlassToastKind.error));
      }
      return;
    }
    await shareReaderPage(file.path, anchor, onResult: (saved) => showGlassToast(ref, GlassToastSpec(saved ? 'Saved to Photos' : 'Shared')));
  }

  // ── Dialogue overlay and hit lens ──────────────────────────────────────

  ({String sourceId, String seriesKey, String chapterKey}) get _chapterIdentity =>
      (sourceId: sourceId, seriesKey: seriesKey, chapterKey: engine.value.chapterId.isEmpty ? _id.chapterKey : engine.value.chapterId);

  void _openDialogue() {
    setState(() => _dialogue = true);
    engine.holdChrome();
  }

  void _closeDialogue() {
    setState(() {
      _dialogue = false;
      _hitShown = false;
    });
    _lensMotion.stop();
    _lensFrom = _lensTo = null;
    _centreFrom = _centreTo = null;
    engine.pageLayerTransform(null, null);
    engine.scheduleHideChrome();
  }

  Future<void> _prepareHitLens(String q) async {
    List<PageText>? pages;
    try {
      pages = await ref.read(ocrChapterTextProvider((sourceId: sourceId, seriesKey: seriesKey, chapterKey: _id.chapterKey)).future);
    } catch (_) {}
    if (!mounted) return;
    final m = dialogueMatches(pages ?? const [], q);
    if (m.isEmpty) {
      showGlassToast(ref, const GlassToastSpec('Opened at the chapter start: the match moved.'));
      return;
    }
    setState(() {
      _matches = m;
      _match = 0;
      _hitShown = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _showMatch(jump: true));
  }

  void _stepMatch(int by) {
    if (_matches.isEmpty) return;
    setState(() => _match = (_match + by) % _matches.length);
    glassFire(ref, HapticEvent.ocrHit);
    _showMatch(jump: true);
  }

  void _showMatch({bool jump = false}) {
    if (!mounted || _matches.isEmpty) return;
    final m = _matches[_match];
    var r = boxInViewport(engine, m);
    final vp = engine.viewportRect;
    if (jump && (r == null || !vp.inflate(-40).contains(r.center))) {
      engine.jumpToPage(m.page, glide: true);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      r = boxInViewport(engine, m);
      if (r == null) return;
      final lens = hitLensRect(r!);
      _lensFrom = _lensTo ?? lens;
      _lensTo = lens;
      _centreFrom = _centreTo ?? r!.center;
      _centreTo = r!.center;
      _lensMotion.value = 0;
      unawaited(GlassMotion.play(MotionName.hitLens, controller: _lensMotion, target: 1));
    });
  }

  /// One frame of the lens step, through the engine's page-layer command. Reduced motion: the lens sits on the new bubble at
  /// full magnification and only fades in (the 120 ms fade is the overlay's opacity).
  void _applyLens() {
    final to = _lensTo, c = _centreTo;
    if (to == null || c == null || !_hitShown || !mounted) return;
    final v = _lensMotion.value.clamp(0.0, 1.0);
    final reduced = reducedMotion;
    final rect = reduced ? to : Rect.lerp(_lensFrom, to, v)!;
    final centre = reduced ? c : Offset.lerp(_centreFrom, c, v)!;
    engine.pageLayerTransform(LensTransform(reduced ? 1.12 : 1 + 0.12 * v, centre), LensClip(rect, 6));
    setState(() {});
  }

  // ── Taps, keys, gestures ───────────────────────────────────────────────

  void _onTap(ReaderTapInfo info) {
    final s = engine.value;
    if (locked) {
      if (inUnlockRegion(info.position, info.size)) {
        final n = _unlock.tap(DateTime.now());
        setState(() => _lockPulse++);
        if (n >= 5) _doUnlock();
      }
      if (!paged) return;
    }
    _light(info.position);
    final doubleOk = doubleTapAllowedAt(info.position, info.size, paged: paged, tapToScroll: _settings.values.tapToScroll);
    if (info.kind == TapKind.double && doubleOk) {
      // A double tap never changes chrome visibility: the first tap's toggle is reverted at once.
      s.chromeVisible ? engine.hideChrome() : engine.showChrome();
      final target = s.zoom > 1.05 ? 1.0 : 2.0;
      engine.zoomAt(info.position, target,
          duration: const Duration(milliseconds: 380), curve: const Cubic(0.2, 0.9, 0.3, 1), spring: springOf(gt.springCamera),);
      glassFire(ref, HapticEvent.zoomSnap);
      _showZoomChip((target * 100).round());
      return;
    }
    if (paged) {
      final band = tapBandOf(info.position.dx, info.size.width);
      final zones = _settings.prefs.tapZones?.map((z) => TapZoneAction.values.byName(z)).toList();
      switch (pagedTapAction(band, rtl: _settings.prefs.rtl, zones: zones)) {
        case TapZoneAction.previous:
          _turn(-1);
        case TapZoneAction.next:
          _turn(1);
        case TapZoneAction.menu:
          _toggleChrome();
      }
      return;
    }
    if (_settings.values.tapToScroll) {
      switch (stripScrollTapAction(info.position, info.size)) {
        case TapZoneAction.previous:
          engine.scrollByViewport(-0.75, duration: springOf(gt.springSettle).duration, curve: const Cubic(0.2, 0.9, 0.3, 1));
        case TapZoneAction.next:
          engine.scrollByViewport(0.75, duration: springOf(gt.springSettle).duration, curve: const Cubic(0.2, 0.9, 0.3, 1));
        case TapZoneAction.menu:
          _toggleChrome();
      }
      return;
    }
    _toggleChrome();
  }

  Timer? _idleHide;

  void _toggleChrome() {
    _idleHide?.cancel();
    if (engine.value.chromeVisible) {
      engine.hideChrome();
      return;
    }
    engine.showChrome();
    if (MediaQuery.accessibleNavigationOf(context)) return;
    _idleHide = Timer(const Duration(milliseconds: 3000), () {
      // Never while a sheet, menu, popover, scrub or overlay holds the chrome.
      if (mounted && _openSheet == null && !_menuOpen && !_goTo && !_scrubbing && !_dialogue && !_hitShown) engine.hideChrome();
    });
  }

  void _turn(int by) {
    final s = engine.value;
    if (s.zoom > 1.0) return;
    final to = (s.page + by).clamp(1, s.pageCount);
    if (to == s.page) return;
    final kind = switch (_settings.values.pageTransition) { 'slide' => PageTurn.slide, 'fade' => PageTurn.fade, _ => PageTurn.cut };
    engine.turnTo(to,
        kind: reducedMotion && kind == PageTurn.slide ? PageTurn.fade : kind,
        slideDuration: _pageSettle,
        slideCurve: const Cubic(0.2, 0.9, 0.3, 1),
        fadeDuration: const Duration(milliseconds: 160),);
    glassFire(ref, HapticEvent.pageTurn);
  }

  void _doUnlock() {
    setState(() => _locked = false);
    glassFire(ref, HapticEvent.readerUnlock);
    showGlassToast(ref, const GlassToastSpec('Reader unlocked'));
  }

  void _light(Offset p) {
    final serial = ++_lightSerial;
    setState(() => _lights = [p]);
    Timer(const Duration(milliseconds: 300), () {
      if (mounted && serial == _lightSerial) setState(() => _lights = const []);
    });
  }

  void _showZoomChip(int percent) {
    _zoomChipTimer?.cancel();
    setState(() => _zoomChip = percent);
    _zoomChipTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _zoomChip = null);
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    // Typing in a field (the go-to well, the note) is never a reader binding.
    final typing = FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<EditableText>() != null;
    if (typing && e.logicalKey != LogicalKeyboardKey.escape) return KeyEventResult.ignored;
    final hw = HardwareKeyboard.instance;
    final action = readerKeyAction(e.logicalKey, e.character,
        shift: hw.isShiftPressed, ctrl: hw.isControlPressed || hw.isMetaPressed, singleKeys: ref.read(singleKeyShortcutsProvider),);
    final s = engine.value;
    if (action == null) {
      // A key that is not a reader binding, or Tab, restores hidden chrome first.
      if (!s.chromeVisible) {
        engine.showChrome();
        return e.logicalKey == LogicalKeyboardKey.tab ? KeyEventResult.handled : KeyEventResult.ignored;
      }
      return KeyEventResult.ignored;
    }
    if (locked && action != ReaderKeyAction.unlock && action != ReaderKeyAction.escape) return KeyEventResult.handled;
    final rtl = _settings.prefs.rtl;
    switch (action) {
      case ReaderKeyAction.pageForward:
        paged ? _turn(rtl ? -1 : 1) : engine.pageBy(forward: true);
      case ReaderKeyAction.pageBack:
        paged ? _turn(rtl ? 1 : -1) : engine.pageBy(forward: false);
      case ReaderKeyAction.nextPage:
        paged ? _turn(1) : jumpTo(math.min(s.pageCount, s.page + 1));
      case ReaderKeyAction.previousPage:
        paged ? _turn(-1) : jumpTo(math.max(1, s.page - 1));
      case ReaderKeyAction.screenDown:
        engine.pageBy(forward: true);
      case ReaderKeyAction.screenUp:
        engine.pageBy(forward: false);
      case ReaderKeyAction.firstPage:
        engine.jumpToPage(1);
      case ReaderKeyAction.lastPage:
        engine.jumpToPage(s.pageCount);
      case ReaderKeyAction.previousChapter:
        previousChapter();
      case ReaderKeyAction.nextChapter:
        nextChapter();
      case ReaderKeyAction.goToPage:
        engine.showChrome();
        setGoTo(true);
      case ReaderKeyAction.unlock:
        if (locked) _doUnlock();
      case ReaderKeyAction.cinema:
        unawaited(GlassReaderSettingsWriter(ref, _seriesRef).profile({'cinema': !cinema}));
      case ReaderKeyAction.toggleChrome:
        _toggleChrome();
      case ReaderKeyAction.cruise:
        toggleCruise();
      case ReaderKeyAction.cruiseSlower:
        _stepCruise(-0.25);
      case ReaderKeyAction.cruiseFaster:
        _stepCruise(0.25);
      case ReaderKeyAction.soundscape:
        _presentSheet('soundscape');
      case ReaderKeyAction.guided:
        toggleGuided();
      case ReaderKeyAction.bookmark:
        toggleBookmark();
      case ReaderKeyAction.chapterList:
        openChapterList(byKey: true);
      case ReaderKeyAction.settings:
        openSettings(byKey: true);
      case ReaderKeyAction.series:
        openSeries();
      case ReaderKeyAction.zoomIn:
        engine.zoomIn();
        _showZoomChip(((s.zoom + 0.1) * 100).round());
      case ReaderKeyAction.zoomOut:
        engine.zoomOut();
        _showZoomChip(((s.zoom - 0.1) * 100).round());
      case ReaderKeyAction.zoomReset:
        engine.resetZoom();
        _showZoomChip(100);
      case ReaderKeyAction.layoutStrip:
        unawaited(GlassReaderSettingsWriter(ref, _seriesRef).series({'layout': 'strip'}));
      case ReaderKeyAction.layoutSingle:
        unawaited(GlassReaderSettingsWriter(ref, _seriesRef).series({'layout': 'single'}));
      case ReaderKeyAction.layoutRtl:
        unawaited(GlassReaderSettingsWriter(ref, _seriesRef).series({'layout': 'single', 'direction': 'rtl'}));
      case ReaderKeyAction.dialogue:
        if (_rightPanel) setState(() => _rightTab = RightPanelTab.dialogue);
        _dialogue ? _closeDialogue() : _openDialogue();
      case ReaderKeyAction.dialoguePanel:
        if (isReaderDesktopFrame(MediaQuery.sizeOf(context))) {
          setState(() {
            _rightTab = RightPanelTab.dialogue;
            _rightPanel = true;
          });
        }
      case ReaderKeyAction.shortcuts:
        unawaited(Navigator.of(context, rootNavigator: true).push<void>(_shortcutsPage().createRoute(context)));
      case ReaderKeyAction.nextMatch:
        _stepMatch(1);
      case ReaderKeyAction.previousMatch:
        _stepMatch(-1);
      case ReaderKeyAction.stackOverview:
        return KeyEventResult.ignored; // The shell's global key opens it.
      case ReaderKeyAction.panelsNext:
      case ReaderKeyAction.panelsPrevious:
        FocusScope.of(context).nextFocus();
      case ReaderKeyAction.pageMenu:
        final at = Offset(MediaQuery.sizeOf(context).width / 2, MediaQuery.sizeOf(context).height * 0.38);
        unawaited(_pageMenu(s.chapterId, engine.pageAtReadingLine(), at));
      case ReaderKeyAction.escape:
        _apply(escapeStep(_layers));
    }
    return KeyEventResult.handled;
  }

  GlassSheetPage<void> _shortcutsPage() {
    final spec = glassSheetSpec('shortcuts');
    return GlassSheetPage<void>(title: spec?.title ?? 'Keyboard shortcuts', builder: spec?.builder ?? (_) => const SizedBox.shrink());
  }

  // ── Exclusion rects (Android) ──────────────────────────────────────────

  void _syncExclusion() {
    if (!mounted || _disposed) return;
    final size = MediaQuery.sizeOf(context);
    final shown = engine.value.chromeVisible;
    if (!shown) {
      _exclusion.clear();
      return;
    }
    final phonePortrait = size.shortestSide < 600 && size.height >= size.width;
    final landscapePhone = size.shortestSide < 600 && size.width > size.height;
    _exclusion.apply(
      readerExclusionRects(
        size: size,
        thumbY: _thumbY == 0 ? size.height / 2 : _thumbY,
        railWidth: GlassFrame.hitMin(context),
        portraitPhone: phonePortrait,
        railShown: engine.value.pageCount > 1 && !landscapePhone,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────

  Color get _ground => _settings.values.background == 'graphite' ? gt.colorG50 : const Color(0xFF000000);

  ReaderEngineOptions _options(GlassReaderSettingsView v, {required double? column, required bool accessibleNav}) => ReaderEngineOptions(
        ground: _ground,
        gapPx: v.prefs.gap ? 8 : 0,
        columnWidth: column,
        colourFilter: switch (v.prefs.colour) {
          'sepia' => ReaderColourFilter.sepia,
          'grey' => ReaderColourFilter.grey,
          _ => ReaderColourFilter.none
        },
        doubleTapSlop: kGlassDoubleTapSlop,
        tapSlop: 8,
        tapHandler: _onTap,
        autoHide: ReaderAutoHide(onScroll: !accessibleNav),
        pinch: true,
        pinchMin: 1,
        pinchMax: 3,
        rubberBandMax: 0.18,
        legacyWakeAndLock: false,
        lifecycleVolumeKeys: true,
        pageStateBuilder: glassPageState,
        bandBuilder: GlassReaderBands(
          nextLabel: _nextId == null ? 'The next chapter' : chapterLabel(_nextId!),
          previousLabel: _previousId == null ? 'The previous chapter' : chapterLabel(_previousId!),
          onRetryNeighbour: () => _body.onReachedFeedEnd?.call(),
          onOpenNext: () => _switchTo(_nextId),
          onDownloadNext: _downloadNextTen,
          readAll: widget.readAll,
        ).build,
        creditsBuilder: (context, chapter, next, mode) => next != null ? const SizedBox(height: 24) : _caughtUp(chapter),
        topBandExtent: widget.readAll ? 0 : 96,
        footerExtent: 220,
        seamExtent: widget.readAll ? 48 : kChapterSeamExtent,
        offline: offline,
        pageLayerBuilder: (context, pages) =>
            ReaderLightLayers(brightness: _liveBrightness ?? v.values.brightness, warmth: v.values.warmth, child: pages),
        pageSemantics: (context, chapter, n, page) => Semantics(label: _pageLabel(chapter, n), image: true, child: page),
        slotSignature: (_nextId, _previousId, v.values.brightness, v.values.warmth, _liveBrightness, Object.hashAll(_epochs.values)),
        onPageLongPress: (chapterId, page) {
          final size = MediaQuery.sizeOf(context);
          unawaited(_pageMenu(chapterId, page, Offset(size.width / 2, size.height * 0.4)));
        },
        pageEpoch: (chapterId, page) => _epochs['$chapterId:$page'] ?? 0,
        readAllKeys: widget.readAll ? ref.read(seriesReadingOrderProvider((sourceId: sourceId, seriesId: seriesKey))).valueOrNull : null,
      );

  Map<int, String> _ocrText = const {};

  String _pageLabel(ReaderChapter chapter, int n) {
    final t = _ocrText[n];
    return t != null && t.trim().isNotEmpty ? t : 'Page $n of ${chapter.pages.length}';
  }

  Widget _caughtUp(ReaderChapter chapter) {
    final n = chapterNumberOf(chapter.title);
    final followed = ref.read(updatesProvider.notifier).followedFor(sourceId: sourceId, seriesKey: seriesKey) != null;
    return CaughtUpCard(
      nextNumber: n == null ? 'the next one' : '${(n + 1).floor()}',
      inLibrary: followed,
      onFollow: () async {
        final err = await ref.read(updatesProvider.notifier).followSeries(sourceId: sourceId, seriesKey: seriesKey);
        if (err == null) glassFire(ref, HapticEvent.followAdd);
      },
    );
  }

  void _downloadNextTen() {
    final d = ref.read(sourceSeriesDetailProvider((sourceId: sourceId, seriesId: seriesKey))).valueOrNull;
    if (d == null) return;
    final i = d.chapters.indexWhere((c) => c.id == engine.value.chapterId);
    final queue = ref.read(downloadQueueControllerProvider.notifier);
    for (final c in d.chapters.skip(i + 1).take(10)) {
      unawaited(queue.enqueueChapter(id: (sourceId: sourceId, seriesKey: seriesKey, chapterKey: c.id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = ref.watch(glassReaderSettingsProvider(_seriesRef));
    ref.watch(sourceSeriesDetailProvider((sourceId: sourceId, seriesId: seriesKey)));
    ref
      ..watch(glassMotionPrefsProvider)
      ..watch(deviceOnlineProvider);
    final ocr = ref.watch(ocrChapterTextProvider(_chapterIdentity)).valueOrNull;
    _ocrText = {for (final p in ocr ?? const <PageText>[]) p.page: p.text};
    _ambientBridge.sync(chapters: _body.feed.chapters, rtl: v.prefs.rtl);
    final size = MediaQuery.sizeOf(context);
    final accessibleNav = MediaQuery.accessibleNavigationOf(context);
    final desktop = isReaderDesktopFrame(size);
    final portraitPhone = size.shortestSide < 600 && size.height >= size.width;
    final layout = widget.readAll ? 'strip' : v.prefs.layout;
    final isPaged = layout == 'single' || layout == 'double';
    if (_lastLayout != null && _lastLayout != layout) _showTapsOverlay();
    _lastLayout = layout;
    final column = desktop ? stripWithPanels(size.width, left: _leftPanel, right: _rightPanel) : null;
    final options = _options(v, column: column, accessibleNav: accessibleNav);
    // Idle hide after 3,000 ms only when a tap opened the chrome (glass 8.14.2): the skin's timer, not the engine's.
    const autoHideAfter = Duration(days: 1);

    Widget chromeFor(BuildContext context, ReaderEngineState state) => LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final cw = column == null ? w : math.min(w, column);
            return GlassReaderChrome(host: this, state: state, column: Rect.fromLTWH((w - cw) / 2, 0, cw, c.maxHeight));
          },
        );
    // While guided view is open the chrome is drawn above it (the engine's copy steps aside): the top groups stay as they are.
    Widget chrome(BuildContext context, ReaderEngineState state) => _guided ? const SizedBox.shrink() : chromeFor(context, state);

    final Widget view;
    if (isPaged) {
      final chapter = _chapter(engine.value.chapterId) ?? _body.feed.chapters.first;
      view = PagedReaderView(
        key: const ValueKey('glass-paged'),
        controller: engine,
        chapter: chapter,
        spec: ReaderLayoutSpec(
            layout: layout == 'double' ? ReaderLayout.double : ReaderLayout.single, rtl: v.prefs.rtl, pagePhysics: const GlassPagePhysics(),),
        chromeBuilder: chrome,
        autoHideAfter: autoHideAfter,
        fit: switch (v.prefs.fit) { 'height' => ReaderPageFit.height, 'original' => ReaderPageFit.original, _ => ReaderPageFit.width },
        ground: _ground,
        turn: switch (v.values.pageTransition) { 'slide' => PageTurn.slide, 'fade' => PageTurn.fade, _ => PageTurn.cut },
        slideDuration: _pageSettle,
        slideCurve: const Cubic(0.2, 0.9, 0.3, 1),
        reducedMotion: reducedMotion,
        reducedDuration: const Duration(milliseconds: 160),
        initialPage: _body.initialPage,
        onEvent: _onEvent,
        bookmarkAnchors: _body.bookmarkAnchors,
        onSaveProgress: _body.onSaveProgress,
        onAddBookmark: _body.onAddBookmark,
        onPreviousChapter: _previousId == null ? null : previousChapter,
        onNextChapter: _nextId == null ? null : nextChapter,
        options: options,
        style: const PagedStageStyle(centreLine: Color(0x00000000)),
      );
    } else {
      view = ReaderEngineView(
        key: const ValueKey('glass-strip'),
        controller: engine,
        slots: ReaderSurfaceSlots(
          chapterSeam: (context, chapter, axis) => GlassChapterSeam(from: null, to: chapter.title, slim: widget.readAll),
          brokenPage: (context, retry) => glassPageState(context, 0, PageStatus.broken, null, retry),
          pagedCornerRadius: 0,
        ),
        autoHideAfter: autoHideAfter,
        chromeBuilder: chrome,
        onEvent: _onEvent,
        feed: _body.feed,
        scrollStorageKey: _body.scrollStorageKey,
        onBack: _leave,
        onOpenSeries: openSeries,
        initialPage: _body.initialPage,
        initialAnchor: _body.initialAnchor,
        showBookmark: _body.showBookmark,
        onSaveProgress: _body.onSaveProgress,
        onAddBookmark: _body.onAddBookmark,
        // Chapter switches go through the reader (a replace under the constant page key), never the entry screen's own push.
        onPreviousChapter: _body.onPreviousChapter == null ? null : previousChapter,
        onNextChapter: _body.onNextChapter == null ? null : () => _switchTo(_nextId),
        onReachedFeedEnd: v.values.oneAtATime && !widget.readAll ? null : _body.onReachedFeedEnd,
        onReachedFeedStart: v.values.oneAtATime && !widget.readAll ? null : _body.onReachedFeedStart,
        pageExtents: _body.pageExtents,
        bookmarkAnchors: _body.bookmarkAnchors,
        options: options,
        chapterMode: v.values.oneAtATime && !widget.readAll ? ReaderChapterMode.single : ReaderChapterMode.continuous,
        overscrollReturn: springOf(gt.springSettle),
        onReplaceChapter: (c) => _replace(c.chapterKey),
        loadNeighbour: _loadNeighbour,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _disposed) return;
      _syncExclusion();
      if (!kReleaseMode) {
        final members = readerBackdropMembers(context as Element);
        assert(
          members.length <= kReaderBackdropBudget || !_frostPath,
          'The reader BackdropGroup holds ${members.length} members (budget $kReaderBackdropBudget): ${members.join(', ')}',
        );
      }
    });

    final stripArea = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _down++,
      onPointerCancel: (_) => _down = math.max(0, _down - 1),
      onPointerUp: (_) {
        _down = math.max(0, _down - 1);
        _onPointerUp();
        _maybeAutoNext(engine.value);
      },
      onPointerSignal: (e) {
        if (e is PointerScrollEvent && (HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed)) {
          final z = (engine.value.zoom * (e.scrollDelta.dy < 0 ? 1.1 : 1 / 1.1)).clamp(1.0, isPaged ? 4.0 : 3.0);
          engine.zoomAt(e.localPosition, z, duration: const Duration(milliseconds: 160), curve: const Cubic(0.2, 0.9, 0.3, 1));
          _showZoomChip((z * 100).round());
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate:
            v.values.swipeChapter && !isPaged && engine.value.zoom <= 1 ? (d) => setState(() => _swipeDx = (_swipeDx ?? 0) + d.delta.dx) : null,
        onHorizontalDragEnd: v.values.swipeChapter && !isPaged
            ? (d) {
                final dx = _swipeDx ?? 0;
                setState(() => _swipeDx = null);
                final dir = v.prefs.rtl ? ReadingDirection.rtl : ReadingDirection.ltr;
                final toNext = engine.swipeNeighbour(dx, viewportWidth: size.width, direction: dir).direction == NeighbourDirection.next;
                final r = engine.releaseSwipeNeighbour(dx, d.velocity.pixelsPerSecond.dx,
                    viewportWidth: size.width, direction: dir, hasNeighbour: toNext ? _nextId != null : _previousId != null,);
                if (r == SwipeRelease.committed) glassFire(ref, HapticEvent.chapterNext);
              }
            : null,
        child: BrightnessBand(
          enabled: portraitPhone && !locked,
          brightness: _liveBrightness ?? v.values.brightness,
          onChanged: (b) => setState(() => _liveBrightness = b),
          onCommit: (b) {
            unawaited(GlassReaderSettingsWriter(ref, _seriesRef).glass({GlassReaderKeys.brightness: b}));
            setState(() => _liveBrightness = null);
          },
          child: view,
        ),
      ),
    );

    final stack = Stack(
      children: [
        if (desktop)
          Positioned.fill(
            child: PageLitGutters(
              strip: Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: column ?? size.width, height: size.height),
              top: engine.value.currentPageSample?.top,
              bottom: engine.value.currentPageSample?.bottom,
              lit: !_leftPanel && !_rightPanel && v.values.pageTinted && !ref.read(glassA11yProvider).solid,
            ),
          ),
        Positioned.fill(
          child: desktop
              ? ReaderPanelLayout(
                  leftOpen: _leftPanel && !cinemaHidden,
                  rightOpen: _rightPanel && !cinemaHidden,
                  duration: springOf(gt.springSheet).duration,
                  tint: pageTinted ? _tint : null,
                  strip: stripArea,
                  left: ReaderChapterList(
                    panel: true,
                    sourceId: sourceId,
                    seriesKey: seriesKey,
                    currentChapterId: engine.value.chapterId,
                    offline: offline,
                    onOpen: _switchTo,
                    onReadAll: () => _router?.go(Routes.readAll(sourceId, seriesKey, {'from': engine.value.chapterId})),
                  ),
                  right: ReaderRightPanel(
                    tab: _rightTab,
                    onTab: (t) => setState(() => _rightTab = t),
                    settings: ReaderSettingsBody(seriesRef: _seriesRef, readAll: widget.readAll, inPanel: true, onOpenSheet: _openFromPanel),
                    pageText: (ocr ?? const <PageText>[]).where((p) => p.page == engine.value.page).firstOrNull,
                  ),
                )
              : stripArea,
        ),
        for (final p in _lights) Positioned(left: p.dx - 60, top: p.dy - 60, child: const _TapLight()),
        if (_swipeDx != null && _swipeDx!.abs() > 4)
          SwipeNeighbourCard(
            displayed: engine
                .swipeNeighbour(_swipeDx!, viewportWidth: size.width, direction: v.prefs.rtl ? ReadingDirection.rtl : ReadingDirection.ltr)
                .displayed,
            label: _swipeDx! < 0 ? (nextChapterLabel ?? '') : (_previousId == null ? '' : chapterLabel(_previousId!)),
            fromRight: _swipeDx! < 0,
          ),
        if (_card != null)
          Positioned.fill(
            child: NeighbourCard(
              direction: _card!.direction,
              label: chapterLabel((_card!.direction == NeighbourDirection.next ? _nextId : _previousId) ?? ''),
              info: _card!.info,
              firstPage: _card!.info == null || _card!.info!.firstPageUrl.isEmpty
                  ? null
                  : ReaderPage(id: 'neighbour-first', number: 1, imageUrl: _card!.info!.firstPageUrl),
              // Device tilt +-4 degrees through the light angle (pinned at rest under reduced motion).
              tilt: ((ref.watch(glassLightAngleProvider).valueOrNull ?? kLightAngleRest) - kLightAngleRest) / (25 * math.pi / 180),
              overscroll: engine.live.overscrollExtent,
              zoom: _zoom,
              reduced: reducedMotion,
              onRead: () => unawaited(_commit(_card!.direction, 0)),
            ),
          ),
        if (_dialogue)
          Positioned.fill(
            child: DialogueOverlayLayer(
              engine: engine,
              pages: ocr ?? const [],
              onCopy: (t) {
                unawaited(Clipboard.setData(ClipboardData(text: t)));
                showGlassToast(ref, const GlassToastSpec('Copied'));
              },
              onClose: _closeDialogue,
              canExtract: _chapterSaved && (ref.watch(ocrAvailableProvider).valueOrNull ?? false),
              onExtract: () => unawaited(ref.read(ocrRunControllerProvider.notifier).runChapter(id: _chapterIdentity)),
              extracting: _extractProgress(),
            ),
          ),
        if (_hitShown && _matches.isNotEmpty) ..._hitLayer(size),
        if (_guided && _chapter(engine.value.chapterId) != null)
          Positioned.fill(
            child: GlassGuidedView(
              key: const ValueKey('glass-guided'),
              engine: engine,
              chapter: _chapter(engine.value.chapterId)!,
              rtl: v.prefs.rtl,
              initialPage: engine.value.page,
              onClose: _closeGuided,
              onNextChapter: _nextId == null ? null : () {
                setState(() => _guided = false);
                nextChapter();
              },
              onPreviousChapter: _previousId == null ? null : () {
                setState(() => _guided = false);
                previousChapter();
              },
              lb: bandLb(Rect.fromLTWH(0, 0, size.width, size.height), size, engine.value.currentPageSample),
              tint: pageTinted ? _tint : null,
              bottomInset: math.max(GlassReaderInsets.of(context).bottom, MediaQuery.systemGestureInsetsOf(context).bottom) + 16,
            ),
          ),
        if (_guided)
          Positioned.fill(
            child: ValueListenableBuilder<ReaderEngineState>(valueListenable: engine, builder: (context, state, _) => chromeFor(context, state)),
          ),
        if (_tapsMounted)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _taps ? 1 : 0,
                duration: Duration(milliseconds: _taps ? 150 : 1000),
                child: _TapPanes(rtl: v.prefs.rtl, zones: v.prefs.tapZones),
              ),
            ),
          ),
      ],
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: Semantics(
          container: true,
          customSemanticsActions: locked ? {const CustomSemanticsAction(label: 'Unlock controls'): _doUnlock} : const {},
          child: Material(
            type: MaterialType.transparency,
            child: ColoredBox(
              color: _ground,
              child: BackdropGroup(
                child: Stack(
                  children: [
                    Positioned.fill(child: stack),
                    Positioned(
                      left: 0,
                      top: 0,
                      width: 1,
                      height: 1,
                      child: Semantics(
                          header: true, label: '$seriesTitle, ${chapterLabel(engine.value.chapterId).toLowerCase()}', child: const SizedBox.shrink(),),
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

  /// The desktop frame's panels.
  ({bool left, bool right}) get panelsOpen => (left: _leftPanel, right: _rightPanel);

  String? _lastLayout;
  bool _taps = false, _tapsMounted = false;
  Timer? _tapsTimer;

  /// The first-run overlay of three panes (Back, Menu, Next) whenever the layout changes: 1.5 s, then a 1,000 ms fade.
  void _showTapsOverlay() {
    _tapsTimer?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _taps = _tapsMounted = true);
      _tapsTimer = Timer(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        setState(() => _taps = false);
        // The panes leave the tree after the fade, so they never count against the budget while invisible.
        _tapsTimer = Timer(const Duration(milliseconds: 1000), () {
          if (mounted && !_taps) setState(() => _tapsMounted = false);
        });
      });
    });
  }

  bool get cinemaHidden => cinema && !engine.value.chromeVisible;

  bool get _frostPath => ref.read(glassRendererProvider) == GlassRenderer.frosted;

  bool get _chapterSaved {
    final s = ref.watch(seriesChapterDownloadStatusProvider((sourceId: sourceId, seriesKey: seriesKey))).valueOrNull;
    return s?[engine.value.chapterId]?.state == DownloadChapterState.complete;
  }

  (int, int)? _extractProgress() {
    final r = ref.watch(ocrRunControllerProvider);
    if (r.phase != OcrRunPhase.recognizing && r.phase != OcrRunPhase.uploading) return null;
    return (r.completedPages, r.totalPages);
  }

  List<Widget> _hitLayer(Size size) {
    final m = _matches[_match];
    final r = boxInViewport(engine, m);
    final g = ReaderChromeGeometry.of(context, column: Offset.zero & size);
    return [
      if (r != null)
        HitLens(
          rect: _lensMotion.value >= 1 || _lensFrom == null || reducedMotion ? hitLensRect(r) : Rect.lerp(_lensFrom, hitLensRect(r), _lensMotion.value)!,
          opacity: reducedMotion ? _lensMotion.value.clamp(0.0, 1.0) : 1,
        ),
      Positioned(
        left: 0,
        right: 0,
        bottom: g.bottom,
        child: Center(
          child: MatchCapsule(index: _match, count: _matches.length, onStep: _stepMatch, onClose: _closeDialogue, tint: pageTinted ? _tint : null),
        ),
      ),
    ];
  }
}

/// Three glass panes labelled Back, Menu and Next over the 30 / 40 / 30 bands.
class _TapPanes extends StatelessWidget {
  const _TapPanes({required this.rtl, this.zones});
  final bool rtl;
  final List<String>? zones;

  static String _label(String z) => switch (z) { 'previous' => 'Back', 'next' => 'Next', _ => 'Menu' };

  @override
  Widget build(BuildContext context) {
    final z = zones ?? (rtl ? const ['next', 'menu', 'previous'] : const ['previous', 'menu', 'next']);
    Widget pane(int i, int flex) => Expanded(
          flex: flex,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: LayoutBuilder(
              builder: (context, c) => SkinGlass(
                size: c.biggest,
                tier: GlassTierId.t2,
                shape: const GlassShape.superellipse(22),
                layer: GlassLayerKind.overlays,
                debugLabel: 'reader tap pane',
                child: Center(child: GlassText(_label(z[i]), role: gt.typeHeadline, onGlass: true)),
              ),
            ),
          ),
        );
    return SafeArea(child: Row(children: [pane(0, 3), pane(1, 4), pane(2, 3)]));
  }
}

/// The 120 px tap light: 10 % white blooming at the tap point and fading over 300 ms (opacity only, also under reduced motion).
class _TapLight extends StatefulWidget {
  const _TapLight();

  @override
  State<_TapLight> createState() => _TapLightState();
}

class _TapLightState extends State<_TapLight> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 300))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: FadeTransition(
          opacity: ReverseAnimation(_c),
          child: Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0x1AFFFFFF), Color(0x00FFFFFF)])),
          ),
        ),
      );
}

/// The one-line note sheet of "Saved this spot · Add note" (`?sheet=note`).
class _NoteSheet extends StatefulWidget {
  const _NoteSheet({required this.onSave});
  final Future<void> Function(String text) onSave;

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  final TextEditingController _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(color: gt.colorWellOnGlass, borderRadius: BorderRadius.circular(12)),
              child: Material(
                type: MaterialType.transparency,
                child: TextField(
                  controller: _c,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  style: roleStyle(context, gt.typeBody, onGlass: true),
                  decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'A note for this spot',
                      hintStyle: roleStyle(context, gt.typeBody, onGlass: true).copyWith(color: gt.colorLabel3),),
                  onSubmitted: (t) => unawaited(widget.onSave(t)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GlassButton(label: 'Save', variant: GlassButtonVariant.primary, onPressed: () => unawaited(widget.onSave(_c.text))),
          ],
        ),
      );
}

/// iOS: the share sheet from the menu's anchor; "Saved to Photos" when the activity was Save Image. The `share_plus` call lives
/// behind this seam so tests can stand in for it.
Future<void> Function(String path, Rect anchor, {required void Function(bool saved) onResult}) shareReaderPage = _sharePage;

Future<void> _sharePage(String path, Rect anchor, {required void Function(bool saved) onResult}) async {
  try {
    final r = await SharePlus.instance.share(ShareParams(files: [XFile(path)], sharePositionOrigin: anchor));
    // A dismissal is silent.
    if (r.status != ShareResultStatus.success) return;
    onResult(r.raw == 'com.apple.UIKit.activity.SaveToCameraRoll');
  } catch (_) {}
}
