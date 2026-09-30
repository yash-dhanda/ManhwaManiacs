import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart' show SpringDescription;
import 'package:flutter/widgets.dart' show Curve, Offset, Rect, ScrollPhysics;
import 'package:manhwamaniacs/features/downloads/models/chapter_identity.dart';
import 'package:manhwamaniacs/features/reader/engine/auto_scroll_controller.dart';
import 'package:manhwamaniacs/features/reader/engine/camera.dart';
import 'package:manhwamaniacs/features/reader/engine/page_tint.dart';
import 'package:manhwamaniacs/features/reader/engine/page_turn.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_ambient.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_state.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_layout.dart';

/// The chapter a [ReaderEngine.chapterCompleted] event names.
typedef ChapterRef = ChapterIdentity;

/// What a reader chrome can ask the reader to do.
abstract interface class ReaderEngineCommands {
  /// Jump to the start of [page] of the chapter being read (1-based).
  void seekToPage(int page);

  /// Animate ~85 % of the viewport forwards or backwards.
  void pageBy({required bool forward});

  /// Light haptic, then the next / previous chapter route.
  void nextChapter();
  void previousChapter();

  void toggleAutoScroll();
  void setAutoScrollSpeed(double pxPerSecond);

  void zoomIn();
  void zoomOut();
  void resetZoom();
  void toggleDoubleTapZoom();

  /// Bookmark the exact spot on screen; `true` when it was stored.
  Future<bool> bookmark();

  void showChrome();
  void hideChrome();

  /// Two-finger zoom: the content point under [focal] stays fixed while the scale follows
  /// [scale] (the absolute zoom the pinch asks for), clamped to [min]..[max] (rubber-banded past
  /// them when [rubberBand], settling back on release) and snapped to [snapStep] on release.
  /// [velocity] is the scale velocity at release, 0 while the fingers are down.
  void pinchZoom(
    Offset focal,
    double scale,
    double velocity, {
    required double min,
    required double max,
    double? snapStep,
    bool rubberBand = true,
    bool released = false,
  });

  /// Animates the zoom to the absolute level [scale] keeping the content point under [point]
  /// fixed. Cinematic passes a duration and a curve, Glass a [spring].
  void zoomAt(
    Offset point,
    double scale, {
    required Duration duration,
    required Curve curve,
    SpringDescription? spring,
  });

  /// Auto-scroll speed as the x multiplier (0.50-3.00), converted with `autoScrollPxPerSecondX`.
  void setAutoScrollSpeedX(double speedX);

  /// Jump to the start of [page] of the chapter being read; [glide] animates it (240 ms).
  void jumpToPage(int page, {bool glide = false});

  /// Scroll by [fraction] of the viewport (negative goes back), animated over [duration].
  void scrollByViewport(double fraction,
      {required Duration duration, required Curve curve,});

  /// Scroll to the start of the loaded chapter at [chapterIndex] of the feed.
  void seekToChapter(int chapterIndex);

  /// Turn to [page] of the chapter (paged layouts): Cut jumps, Slide animates over [slideDuration]
  /// along [slideCurve], Fade cross-fades over [fadeDuration]. The strip jumps.
  void turnTo(
    int page, {
    PageTurn kind = PageTurn.cut,
    required Duration slideDuration,
    required Curve slideCurve,
    required Duration fadeDuration,
  });

  /// The page under 38 % of the viewport in the strip, the current page in paged layouts.
  int pageAtReadingLine();

  /// Cancel the chrome's auto-hide (a sheet is open over the reader).
  void holdChrome();

  /// Re-arm the chrome's auto-hide.
  void scheduleHideChrome();
}

/// The side of the engine that `ReaderEngineView`'s state implements.
abstract interface class ReaderEngineHost implements ReaderEngineCommands {
  /// A bookmark save is in flight.
  bool get bookmarkPending;

  /// A `POST /reader/progress` answer: [advanced] false means the server holds the row given
  /// here, later than the one saved; true clears it.
  void reportServerProgress({
    required String chapterKey,
    required double? chapterNumber,
    required int lastPage,
    required bool advanced,
  });
}

/// Geometry a host can answer: page fractions to viewport px (the strip's scroll offset and page
/// extents, current every frame). Implemented by the strip view.
abstract interface class ReaderGeometryHost {
  /// Viewport px of the point ([x], [y]) in page fractions of chapter-local [page]; null when the
  /// page is not laid out.
  Offset? pageToViewport(int page, double x, double y);

  /// The viewport rectangle in logical px.
  Rect get viewportRect;
}

/// Something the chrome should tell the reader about; the engine draws
/// nothing itself.
sealed class ReaderEngineEvent {
  const ReaderEngineEvent();
}

/// Five centre taps lifted lock mode.
final class ReaderUnlocked extends ReaderEngineEvent {
  const ReaderUnlocked();
}

/// A bookmark was stored at [page], [percent] of the way through the chapter
/// (null when the chapter has no page count to measure against).
final class ReaderBookmarkSaved extends ReaderEngineEvent {
  const ReaderBookmarkSaved({required this.page, required this.percent});
  final int page;
  final int? percent;
}

/// The bookmark the reader was opened at points past the chapter's end; it
/// opened at [openedPage] instead of [requestedPage].
final class ReaderStaleAnchor extends ReaderEngineEvent {
  const ReaderStaleAnchor({
    required this.openedPage,
    required this.requestedPage,
  });
  final int openedPage;
  final int requestedPage;
}

/// A page was turned by a finger in a paged layout (taps, keys and the ruler go through
/// [ReaderEngine.turnTo] and are the skin's own feedback): the skin plays its `page.turn` cue.
final class ReaderPageSwiped extends ReaderEngineEvent {
  const ReaderPageSwiped({required this.page});
  final int page;
}

/// The reader's controller: publishes [ReaderEngineState] and forwards every
/// command to the `ReaderEngineView` it is attached to, the way a
/// `ScrollController` forwards to its `ScrollPosition`. With no view attached
/// every command is a no-op.
///
/// Owned — created and disposed — by whoever builds the view.
class ReaderEngine extends ValueNotifier<ReaderEngineState>
    implements ReaderEngineCommands {
  ReaderEngine() : super(ReaderEngineState.initial);

  ReaderEngineHost? _host;

  final StreamController<ChapterRef> _completed =
      StreamController<ChapterRef>.broadcast();

  /// Fires once per chapter per open, when the engine marks the chapter complete: its last page
  /// scrolled up past 60 % of the viewport, or the ruler dragged to the end.
  Stream<ChapterRef> get chapterCompleted => _completed.stream;

  /// Called by the view.
  void emitChapterCompleted(ChapterRef chapter) {
    if (!_completed.isClosed) _completed.add(chapter);
  }

  /// Pixels the reader has pulled past the top of the strip (a drag at offset 0), 0 at rest.
  final ValueNotifier<double> topPull = ValueNotifier<double>(0);

  /// Pixels pulled past the end of the strip, 0 at rest.
  final ValueNotifier<double> endPull = ValueNotifier<double>(0);

  /// Page tint, panel detection, words on screen and the exit reports (mobile/23 A4).
  final ReaderAmbient ambient = ReaderAmbient();

  /// The 400 ms speed ramp, pace by dialogue and touch interruption of auto-scroll (A6).
  final AutoScrollController autoScroll = AutoScrollController();

  /// The guided layout's camera (A5).
  final ReaderCamera camera = ReaderCamera();

  /// The chrome's tint source: `PageTintSource.page(seed)`, `PageTintSource.cover` or null.
  ValueNotifier<PageTintSource?> get pageTint => ambient.pageTint;

  /// Panels of the chapter on screen by 1-based page.
  ValueNotifier<Map<int, PanelsState>> get panels => ambient.panels;

  /// Words in the viewport while pace by dialogue has text; null otherwise.
  ValueNotifier<int?> get wordsOnScreen => ambient.wordsOnScreen;

  /// Words in panel [panelIndex] of [page] (null without dialogue text).
  int? wordsInPanel(int page, int panelIndex) => ambient.wordsInPanel(page, panelIndex);

  /// The rect the guided camera is fitted on (null: whole page).
  CameraTarget? get cameraRect => camera.cameraRect;

  /// Fits [rect] (page fractions of [rect.page]) in the viewport within 24 px margins at up to 3x,
  /// dollying over [duration] along [curve] (or springing), or cutting when neither is given.
  /// The guided stage listens to [camera] and runs the animation with its ticker.
  void setCamera(CameraTarget rect, {Duration? duration, Curve? curve, SpringDescription? spring, Offset? velocity}) {
    _cameraCommand.value = (rect: rect, duration: duration, curve: curve, spring: spring, velocity: velocity, serial: ++_cameraSerial);
  }

  int _cameraSerial = 0;

  /// The latest [setCamera] request, for the stage that owns the ticker.
  final ValueNotifier<({CameraTarget rect, Duration? duration, Curve? curve, SpringDescription? spring, Offset? velocity, int serial})?> _cameraCommand =
      ValueNotifier(null);
  ValueListenable<({CameraTarget rect, Duration? duration, Curve? curve, SpringDescription? spring, Offset? velocity, int serial})?> get cameraCommand => _cameraCommand;

  /// Viewport px of the point ([x], [y]) in page fractions of chapter-local [page], current every
  /// frame while scrolling, zooming or moving the camera.
  Offset pageToViewport(int page, double x, double y) {
    if (camera.active) return camera.pageToViewport(page, x, y);
    final h = _host;
    if (h is ReaderGeometryHost) return (h as ReaderGeometryHost).pageToViewport(page, x, y) ?? Offset.zero;
    return Offset.zero;
  }

  /// The page and page fractions under a viewport [point] (the guided camera's page).
  (int, Offset) viewportToPage(Offset point) => camera.viewportToPage(point);

  /// The viewport rect (strip host) or the camera's viewport.
  Rect get viewportRect {
    final h = _host;
    if (!camera.active && h is ReaderGeometryHost) return (h as ReaderGeometryHost).viewportRect;
    return Offset.zero & camera.viewport;
  }

  /// Guided view is on: read by mobile/12's iOS back-swipe rule.
  void setGuidedActive(bool on) {
    camera.active = on;
    if (value.guidedActive != on) value = value.copyWith(guidedActive: on);
  }

  @override
  void dispose() {
    ambient.dispose();
    autoScroll.dispose();
    camera.dispose();
    _cameraCommand.dispose();
    unawaited(_completed.close());
    topPull.dispose();
    endPull.dispose();
    layoutSpec.dispose();
    super.dispose();
  }

  bool get isAttached => _host != null;

  /// The layout the skin asked for (glass 15.4 `setLayout`): the strip until told otherwise. A
  /// skin's reader frame builds the strip view or the paged view from it.
  final ValueNotifier<ReaderLayoutSpec> layoutSpec = ValueNotifier<ReaderLayoutSpec>(const ReaderLayoutSpec());

  /// Switch between the strip and the paged layouts, keeping the current page. [pagePhysics] is the
  /// skin's finger physics for a paged layout.
  void setLayout(ReaderLayout layout, {bool rtl = false, ScrollPhysics? pagePhysics}) {
    layoutSpec.value = ReaderLayoutSpec(layout: layout, rtl: rtl, pagePhysics: pagePhysics);
  }

  /// A view replacing another (a layout switch) attaches before the old one is disposed: the newest
  /// host wins and the old one's detach is then a no-op.
  void attach(ReaderEngineHost host) {
    _host = host;
  }

  void detach(ReaderEngineHost host) {
    if (identical(_host, host)) _host = null;
  }

  bool get bookmarkPending => _host?.bookmarkPending ?? false;

  /// Tells the engine what the server answered to a progress save (cinematic 8.14.11): with
  /// `advanced: false` the state's `furtherElsewhere` carries the server's row until the next
  /// advancing save.
  void reportServerProgress({
    required String chapterKey,
    required double? chapterNumber,
    required int lastPage,
    required bool advanced,
  }) =>
      _host?.reportServerProgress(
          chapterKey: chapterKey,
          chapterNumber: chapterNumber,
          lastPage: lastPage,
          advanced: advanced,);

  @override
  void seekToPage(int page) => _host?.seekToPage(page);

  @override
  void pageBy({required bool forward}) => _host?.pageBy(forward: forward);

  @override
  void nextChapter() => _host?.nextChapter();

  @override
  void previousChapter() => _host?.previousChapter();

  @override
  void toggleAutoScroll() => _host?.toggleAutoScroll();

  @override
  void setAutoScrollSpeed(double pxPerSecond) =>
      _host?.setAutoScrollSpeed(pxPerSecond);

  @override
  void zoomIn() => _host?.zoomIn();

  @override
  void zoomOut() => _host?.zoomOut();

  @override
  void resetZoom() => _host?.resetZoom();

  @override
  void toggleDoubleTapZoom() => _host?.toggleDoubleTapZoom();

  @override
  Future<bool> bookmark() => _host?.bookmark() ?? Future.value(false);

  @override
  void pinchZoom(
    Offset focal,
    double scale,
    double velocity, {
    required double min,
    required double max,
    double? snapStep,
    bool rubberBand = true,
    bool released = false,
  }) =>
      _host?.pinchZoom(focal, scale, velocity,
          min: min,
          max: max,
          snapStep: snapStep,
          rubberBand: rubberBand,
          released: released,);

  @override
  void zoomAt(Offset point, double scale,
          {required Duration duration,
          required Curve curve,
          SpringDescription? spring,}) =>
      _host?.zoomAt(point, scale,
          duration: duration, curve: curve, spring: spring,);

  @override
  void setAutoScrollSpeedX(double speedX) => _host?.setAutoScrollSpeedX(speedX);

  @override
  void jumpToPage(int page, {bool glide = false}) =>
      _host?.jumpToPage(page, glide: glide);

  @override
  void scrollByViewport(double fraction,
          {required Duration duration, required Curve curve,}) =>
      _host?.scrollByViewport(fraction, duration: duration, curve: curve);

  @override
  void seekToChapter(int chapterIndex) => _host?.seekToChapter(chapterIndex);

  @override
  void turnTo(
    int page, {
    PageTurn kind = PageTurn.cut,
    required Duration slideDuration,
    required Curve slideCurve,
    required Duration fadeDuration,
  }) =>
      _host?.turnTo(page, kind: kind, slideDuration: slideDuration, slideCurve: slideCurve, fadeDuration: fadeDuration);

  @override
  int pageAtReadingLine() => _host?.pageAtReadingLine() ?? value.page;

  @override
  void showChrome() => _host?.showChrome();

  @override
  void hideChrome() => _host?.hideChrome();

  @override
  void holdChrome() => _host?.holdChrome();

  @override
  void scheduleHideChrome() => _host?.scheduleHideChrome();
}
