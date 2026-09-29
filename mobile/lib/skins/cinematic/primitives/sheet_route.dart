import 'dart:async';

import 'package:flutter/material.dart';
import 'package:manhwamaniacs/core/diagnostics/motion_recorder.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/skin_audio.dart';

export 'package:manhwamaniacs/skins/cinematic/primitives/cine_sheet.dart' show CineSheet, CineSheetState;

/// A sheet is a `PageRoute` (cinematic 7.9): `showModalBottomSheet` cannot meet the detents,
/// rubber band, spring release and dismissal rules, and a `Hero` can fly into a page route (Quick
/// look). Rise in (360 ms `settle`), 240 ms `lift` out; reduced motion 150 ms fades.
class CineSheetRoute<T> extends PageRoute<T> {
  CineSheetRoute({
    required this.builder,
    required this.kicker,
    required this.title,
    this.livePreview = false,
    this.sheetState = CineSheetState.ready,
    this.errorHeadline = 'This didn’t load.',
    this.errorDeck,
    this.onRetry,
    this.reduced = false,
    this.restoreFocus,
    this.themes,
    super.settings,
  });

  final WidgetBuilder builder;
  final String kicker, title;
  final bool livePreview, reduced;
  final CineSheetState sheetState;
  final String errorHeadline;
  final String? errorDeck;
  final VoidCallback? onRetry;

  /// The trigger's focus node, refocused once the sheet is gone.
  final FocusNode? restoreFocus;

  /// The trigger's themes, so tokens resolve under a navigator whose own theme has none.
  final CapturedThemes? themes;

  @override
  bool get opaque => false;
  @override
  Color? get barrierColor => CineScrim.modal;
  @override
  bool get barrierDismissible => true;
  @override
  String? get barrierLabel => 'Close';
  @override
  bool get maintainState => true;
  @override
  Duration get transitionDuration => reduced ? CineDur.reduced : CineDur.rise;
  @override
  Duration get reverseTransitionDuration => reduced ? CineDur.reduced : CineDur.line;

  /// The barrier reaches 0.78 in 240 ms of the 360 ms rise.
  @override
  Curve get barrierCurve => reduced ? Curves.linear : Interval(0, CineDur.line.inMilliseconds / CineDur.rise.inMilliseconds);

  MotionHandle? _motion;

  @override
  TickerFuture didPush() {
    _motion = CineMotion.track(MotionName.rise, transitionDuration.inMilliseconds);
    try {
      unawaited(SkinAudio.instance.play(SoundEvent.sheetOpen).catchError((Object _) {}));
    } catch (_) {}
    return super.didPush()..whenCompleteOrCancel(() => _motion?.end());
  }

  @override
  void dispose() {
    final node = restoreFocus;
    if (node != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (node.context != null && node.canRequestFocus) node.requestFocus();
      });
    }
    super.dispose();
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) => _wrap(CineSheet(
        kicker: kicker,
        title: title,
        livePreview: livePreview,
        state: sheetState,
        errorHeadline: errorHeadline,
        errorDeck: errorDeck,
        onRetry: onRetry,
        reduced: reduced,
        onClose: () => Navigator.of(context).maybePop(),
        child: Builder(builder: builder),
      ),);

  Widget _wrap(Widget w) => themes?.wrap(w) ?? w;

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    if (reduced) return FadeTransition(opacity: animation, child: child);
    final t = CurvedAnimation(parent: animation, curve: CineCurves.settle, reverseCurve: CineCurves.lift.flipped);
    return AnimatedBuilder(
      animation: t,
      child: child,
      builder: (_, c) => Opacity(opacity: t.value.clamp(0.0, 1.0), child: Transform.translate(offset: Offset(0, 24 * (1 - t.value)), child: c)),
    );
  }
}

/// Opens a Cinematic sheet. Focus moves to its first control and returns to the trigger.
Future<T?> showCineSheet<T>(
  BuildContext context, {
  required String kicker,
  required String title,
  required WidgetBuilder builder,
  bool livePreview = false,
  CineSheetState state = CineSheetState.ready,
  String errorHeadline = 'This didn’t load.',
  String? errorDeck,
  VoidCallback? onRetry,
}) {
  final trigger = FocusManager.instance.primaryFocus;
  final navigator = Navigator.of(context);
  return navigator.push(CineSheetRoute<T>(
    themes: InheritedTheme.capture(from: context, to: navigator.context),
    builder: builder,
    kicker: kicker,
    title: title,
    livePreview: livePreview,
    sheetState: state,
    errorHeadline: errorHeadline,
    errorDeck: errorDeck,
    onRetry: onRetry,
    reduced: CineMotion.reduced(context),
    restoreFocus: trigger,
  ),);
}
