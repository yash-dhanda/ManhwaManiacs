import 'package:flutter/foundation.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_state.dart';

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

  /// Cancel the chrome's auto-hide (a sheet is open over the reader).
  void holdChrome();

  /// Re-arm the chrome's auto-hide.
  void scheduleHideChrome();
}

/// The side of the engine that `ReaderEngineView`'s state implements.
abstract interface class ReaderEngineHost implements ReaderEngineCommands {
  /// A bookmark save is in flight.
  bool get bookmarkPending;
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

  bool get isAttached => _host != null;

  void attach(ReaderEngineHost host) {
    assert(_host == null, 'A ReaderEngine drives one ReaderEngineView.');
    _host = host;
  }

  void detach(ReaderEngineHost host) {
    if (identical(_host, host)) _host = null;
  }

  bool get bookmarkPending => _host?.bookmarkPending ?? false;

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
  void showChrome() => _host?.showChrome();

  @override
  void hideChrome() => _host?.hideChrome();

  @override
  void holdChrome() => _host?.holdChrome();

  @override
  void scheduleHideChrome() => _host?.scheduleHideChrome();
}
