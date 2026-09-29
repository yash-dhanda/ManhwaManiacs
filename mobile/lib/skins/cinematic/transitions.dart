import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/diagnostics/motion_recorder.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

// Pages and transitions (cinematic 4.5, 8.0.4, 8.0.5). Every push and every button or
// programmatic pop plays Page; a series page opens on a match cut; takeovers and auth Dip; the
// readers own their route (screens/reader/reader_route_page.dart).

/// Which named move a route plays.
enum CineTransitionKind { page, match, dip, cut }

const kPageIn = Duration(milliseconds: 320);
const kPageOut = Duration(milliseconds: 224);
const kMatchCutIn = Duration(milliseconds: 480);
const kMatchCutOut = Duration(milliseconds: 336);
const kDipTotal = Duration(milliseconds: 440);
const kPredictiveCommit = Duration(milliseconds: 240);
const kPredictiveCancel = Duration(milliseconds: 160);
const kReducedPage = Duration(milliseconds: 150);
const kReducedMatch = Duration(milliseconds: 200);

/// Whether route durations should be the reduced ones. Routes read it when they are built
/// (a controller's duration is fixed then); the app frame keeps [appReduced] in step with
/// `appReduceMotionProvider`.
abstract final class CineRouteMotion {
  static bool appReduced = false;

  static bool get reduced =>
      appReduced || WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;

  static Duration forward(CineTransitionKind k) => switch (k) {
        CineTransitionKind.cut => Duration.zero,
        CineTransitionKind.page => reduced ? kReducedPage : kPageIn,
        CineTransitionKind.match => reduced ? kReducedMatch : kMatchCutIn,
        CineTransitionKind.dip => reduced ? kReducedPage : kDipTotal,
      };

  static Duration reverse(CineTransitionKind k) => switch (k) {
        CineTransitionKind.cut => Duration.zero,
        CineTransitionKind.page => reduced ? kReducedPage : kPageOut,
        CineTransitionKind.match => reduced ? kReducedMatch : kMatchCutOut,
        CineTransitionKind.dip => reduced ? kReducedPage : kDipTotal,
      };
}

// ---------------------------------------------------------------------------------------------
// Pure math

/// The Android fade-through, a pure function of gesture progress so a predictive back gesture
/// paints it too: the outgoing page's scale 1.00 -> 0.95 and opacity 1 -> 0 over progress
/// 0 - 0.6, the incoming page's opacity 0 -> 1 over 0.4 - 1.0.
({double outScale, double outOpacity, double inOpacity}) fadeThrough(double progress) {
  final p = progress.clamp(0.0, 1.0);
  final o = (p / 0.6).clamp(0.0, 1.0);
  return (outScale: 1 - 0.05 * o, outOpacity: 1 - o, inOpacity: ((p - 0.4) / 0.6).clamp(0.0, 1.0));
}

/// The Dip's black layer at [ms] on the 440 ms clock: out 160 ms `lift` to `#000000`, hold 40 ms,
/// in 240 ms `settle`.
double dipBlack(double ms) {
  if (ms <= 0) return 0;
  if (ms < 160) return CineCurves.lift.transform(ms / 160);
  if (ms < 200) return 1;
  if (ms < 440) return 1 - CineCurves.settle.transform((ms - 200) / 240);
  return 0;
}

/// The incoming page shows once the black holds (forward); the leaving page hides then (reverse).
bool dipChildVisible(double ms, {required bool reverse}) => reverse ? ms < 200 : ms >= 200;

/// Page's incoming half: x +24 -> 0, opacity 0 -> 1.
({double dx, double opacity}) pageIncoming(double t) => (dx: 24 * (1 - t), opacity: t);

/// Page's outgoing half: x 0 -> -24, opacity 1 -> 0.
({double dx, double opacity}) pageOutgoing(double t) => (dx: -24 * t, opacity: 1 - t);

/// Match cut: everything but the cover dissolves in over the first 240 ms of 480 (and out over
/// the first 240 ms of the 336 back).
double matchDissolve(double v, {required bool reverse}) {
  final span = reverse ? 240 / 336 : 0.5;
  return CineCurves.turn.transform((v / span).clamp(0.0, 1.0));
}

// ---------------------------------------------------------------------------------------------
// Painters

/// Logs the move to the motion recorder while the route's [animation] runs.
class CineMoveTracker extends StatefulWidget {
  const CineMoveTracker({super.key, required this.name, required this.animation, required this.plannedIn, required this.plannedOut, required this.child});
  final MotionName name;
  final Animation<double> animation;
  final int plannedIn, plannedOut;
  final Widget child;

  @override
  State<CineMoveTracker> createState() => _CineMoveTrackerState();
}

class _CineMoveTrackerState extends State<CineMoveTracker> {
  MotionHandle? _handle;

  @override
  void initState() {
    super.initState();
    widget.animation.addStatusListener(_status);
    _status(widget.animation.status);
  }

  void _status(AnimationStatus s) {
    switch (s) {
      case AnimationStatus.forward:
        _end();
        _handle = CineMotion.track(widget.name, widget.plannedIn);
      case AnimationStatus.reverse:
        _end();
        _handle = CineMotion.track(widget.name, widget.plannedOut);
      case AnimationStatus.completed || AnimationStatus.dismissed:
        _end();
    }
  }

  void _end() {
    _handle?.end();
    _handle = null;
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_status);
    _end();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

Widget _fadeSlide({required double dx, required double opacity, required Widget child}) =>
    Opacity(opacity: opacity.clamp(0.0, 1.0), child: Transform.translate(offset: Offset(dx, 0), child: child));

/// Page: the incoming page x +24 -> 0 and opacity 0 -> 1 over 320 ms `settle`; the outgoing page
/// (through [secondaryAnimation]) x 0 -> -24 and opacity 1 -> 0 over 224 ms `lift`; a pop reverses
/// both over 224 ms. Reduced: a 150 ms opacity cross-fade.
Widget cinePageTransition({
  required BuildContext context,
  required Animation<double> animation,
  required Animation<double> secondaryAnimation,
  required Widget child,
  bool incoming = true,
}) {
  final reduced = CineMotion.reduced(context);
  final body = AnimatedBuilder(
      animation: Listenable.merge([animation, secondaryAnimation]),
      child: child,
      builder: (context, child) {
        final inT = animation.status == AnimationStatus.reverse
            ? CineCurves.lift.flipped.transform(animation.value)
            : CineCurves.settle.transform(animation.value);
        // Forward the outgoing half runs over the first 224 of 320 ms; a pop over its own 224.
        final sv = secondaryAnimation.value;
        final outT = secondaryAnimation.status == AnimationStatus.reverse
            ? CineCurves.lift.flipped.transform(sv)
            : CineCurves.lift.transform((sv / (224 / 320)).clamp(0.0, 1.0));
        if (reduced) {
          return Opacity(opacity: ((incoming ? animation.value : 1) * (1 - secondaryAnimation.value)).clamp(0.0, 1.0), child: child);
        }
        final i = incoming ? pageIncoming(inT) : (dx: 0.0, opacity: 1.0);
        final o = pageOutgoing(outT);
        return _fadeSlide(dx: i.dx + o.dx, opacity: i.opacity * o.opacity, child: child!);
      },
  );
  if (!incoming) return body;
  return CineMoveTracker(
    name: MotionName.page,
    animation: animation,
    plannedIn: CineRouteMotion.forward(CineTransitionKind.page).inMilliseconds,
    plannedOut: CineRouteMotion.reverse(CineTransitionKind.page).inMilliseconds,
    child: body,
  );
}

/// Match cut: the cover is a `Hero`; everything else dissolves. Reduced: `HeroMode` off and a
/// 200 ms cross-fade.
Widget cineMatchCutTransition({
  required BuildContext context,
  required Animation<double> animation,
  required Widget child,
}) {
  final reduced = CineMotion.reduced(context);
  return CineMoveTracker(
    name: MotionName.matchCut,
    animation: animation,
    plannedIn: CineRouteMotion.forward(CineTransitionKind.match).inMilliseconds,
    plannedOut: CineRouteMotion.reverse(CineTransitionKind.match).inMilliseconds,
    child: HeroMode(
      enabled: !reduced,
      child: AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, child) => Opacity(
          opacity: reduced
              ? animation.value
              : matchDissolve(animation.value, reverse: animation.status == AnimationStatus.reverse),
          child: child,
        ),
      ),
    ),
  );
}

/// Dip: out to `#000000`, hold, in. The page itself is hidden until the black holds. Reduced: a
/// 150 ms fade.
Widget cineDipTransition({
  required BuildContext context,
  required Animation<double> animation,
  required Widget child,
}) {
  final reduced = CineMotion.reduced(context);
  return CineMoveTracker(
    name: MotionName.dip,
    animation: animation,
    plannedIn: CineRouteMotion.forward(CineTransitionKind.dip).inMilliseconds,
    plannedOut: CineRouteMotion.reverse(CineTransitionKind.dip).inMilliseconds,
    child: AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        if (reduced) return Opacity(opacity: animation.value, child: child);
        final rev = animation.status == AnimationStatus.reverse;
        final ms = (rev ? 1 - animation.value : animation.value) * kDipTotal.inMilliseconds;
        return Stack(fit: StackFit.passthrough, children: [
          Opacity(opacity: dipChildVisible(ms, reverse: rev) ? 1 : 0, child: child),
          Positioned.fill(
            child: IgnorePointer(child: ColoredBox(color: Color.fromRGBO(0, 0, 0, dipBlack(ms)))),
          ),
        ],);
      },
    ),
  );
}

Widget _transitionFor(CineTransitionKind kind, BuildContext context, Animation<double> a, Animation<double> s, Widget child) =>
    switch (kind) {
      CineTransitionKind.cut => cinePageTransition(context: context, animation: a, secondaryAnimation: s, child: child, incoming: false),
      CineTransitionKind.page => cinePageTransition(context: context, animation: a, secondaryAnimation: s, child: child),
      CineTransitionKind.match => cineMatchCutTransition(context: context, animation: a, child: child),
      CineTransitionKind.dip => cineDipTransition(context: context, animation: a, child: child),
    };

/// iOS finger-tracked slide (8.0.5 "Back"): on a linear curve the top page's x follows the finger
/// while the page beneath goes from -30 % to 0 under a `#000` dim falling from 0.6 to 0.
class CineSwipeSlide extends StatelessWidget {
  const CineSwipeSlide.top({super.key, required Animation<double> animation, required this.child})
      : _animation = animation,
        _beneath = false;
  const CineSwipeSlide.beneath({super.key, required Animation<double> secondaryAnimation, required this.child})
      : _animation = secondaryAnimation,
        _beneath = true;

  final Animation<double> _animation;
  final bool _beneath;
  final Widget child;

  /// The top page's fractional x at animation value [v]: 0 at rest, 1 fully off to the right.
  static double topOffset(double v) => 1 - v;

  /// The beneath page's fractional x at secondary value [v]: -0.3 while covered.
  static double beneathOffset(double v) => -0.3 * v;

  /// The beneath page's dim.
  static double beneathDim(double v) => 0.6 * v;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _animation,
        child: child,
        builder: (context, child) {
          final v = _animation.value;
          if (!_beneath) return FractionalTranslation(translation: Offset(topOffset(v), 0), child: child);
          return FractionalTranslation(
            translation: Offset(beneathOffset(v), 0),
            child: Stack(fit: StackFit.passthrough, children: [
              child!,
              Positioned.fill(child: IgnorePointer(child: ColoredBox(color: Color.fromRGBO(0, 0, 0, beneathDim(v))))),
            ],),
          );
        },
      );
}

// ---------------------------------------------------------------------------------------------
// iOS: SwipeablePage

Page<void> _swipeablePage(GoRouterState state, Widget child, CineTransitionKind kind) {
  return SwipeablePage<void>(
    key: state.pageKey,
    name: state.name,
    // A Cut page (a branch root or a shell) has nothing to swipe back to, but it stays a
    // Cupertino-family route so the page beneath a push still plays its own outgoing move.
    canSwipe: kind != CineTransitionKind.cut,
    canOnlySwipeFromEdge: true,
    backGestureDetectionWidth: 20,
    transitionDuration: CineRouteMotion.forward(kind),
    reverseTransitionDuration: CineRouteMotion.reverse(kind),
    transitionBuilder: cineSwipeBuilder(kind),
    builder: (_) => child,
  );
}

/// The `SwipeableTransitionBuilder` (0.4.8's shape) of a kind: the page's move, or the finger-tracked slide while
/// the finger is on it. The page beneath reads `Navigator.userGestureInProgress` because its own
/// `isSwipeGesture` is false.
typedef CineSwipeBuilder = Widget Function(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  bool isSwipeGesture,
  Widget child,
);

CineSwipeBuilder cineSwipeBuilder(CineTransitionKind kind) =>
    (context, animation, secondaryAnimation, isSwipeGesture, child) {
      // `isSwipeGesture` is the navigator's flag in 0.4.8, so the page beneath sees it true too: the
      // current route is the one under the finger.
      if (isSwipeGesture && (ModalRoute.of(context)?.isCurrent ?? true)) {
        return CineSwipeSlide.top(animation: animation, child: child);
      }
      return AnimatedBuilder(
        animation: Listenable.merge([animation, secondaryAnimation]),
        child: child,
        builder: (context, child) {
          final beneathSwipe = secondaryAnimation.status != AnimationStatus.dismissed &&
              !(ModalRoute.of(context)?.isCurrent ?? true) &&
              Navigator.of(context).userGestureInProgress;
          if (beneathSwipe) return CineSwipeSlide.beneath(secondaryAnimation: secondaryAnimation, child: child!);
          return _transitionFor(kind, context, animation, secondaryAnimation, child!);
        },
      );
    };

// ---------------------------------------------------------------------------------------------
// Android: predictive back

/// The progress the fade-through paints, shared by the top page and the page beneath: the raw
/// gesture progress while the finger moves, then a `settle` finish (240 ms commit, 160 ms cancel)
/// that runs on its own clock, because the route's controller restarts on commit.
final class CineBackGesture extends ChangeNotifier implements TickerProvider {
  CineBackGesture._();
  static final CineBackGesture instance = CineBackGesture._();

  double progress = 0;
  bool _finishing = false;
  late final AnimationController _c = AnimationController(vsync: this);
  double _from = 0, _to = 0;

  bool get finishing => _finishing;

  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);

  void update(double p) {
    _finishing = false;
    _c.stop();
    progress = p.clamp(0.0, 1.0);
    notifyListeners();
  }

  void commit() => _finish(1, kPredictiveCommit);
  void cancel() => _finish(0, kPredictiveCancel);

  void _finish(double to, Duration d) {
    _from = progress;
    _to = to;
    _finishing = true;
    _c
      ..removeListener(_tick)
      ..addListener(_tick)
      ..duration = d
      ..forward(from: 0).whenComplete(() {
        _finishing = false;
        notifyListeners();
      });
  }

  void _tick() {
    progress = _from + (_to - _from) * CineCurves.settle.transform(_c.value);
    notifyListeners();
  }

  @visibleForTesting
  void reset() {
    _c.stop();
    _finishing = false;
    progress = 0;
  }
}

/// A route that says which move it plays; the Android builder reads it.
abstract interface class CineKindRoute {
  CineTransitionKind get kind;
}

/// Android: registered in `PageTransitionsTheme` for `TargetPlatform.android` (and iOS, for the
/// `MaterialPageRoute`s a package pushes). Plays the route's kind for button and programmatic
/// navigation and the fade-through for predictive back. `ZoomPageTransitionsBuilder` and
/// `PredictiveBackFullscreenPageTransitionsBuilder` never ship: the latter falls back to Zoom's
/// 300 ms for every non-gesture navigation.
class CinePageTransitionsBuilder extends PageTransitionsBuilder {
  const CinePageTransitionsBuilder();

  @override
  Duration get transitionDuration => CineRouteMotion.forward(CineTransitionKind.page);

  @override
  Duration get reverseTransitionDuration => CineRouteMotion.reverse(CineTransitionKind.page);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final kind = route is CineKindRoute ? (route as CineKindRoute).kind : CineTransitionKind.page;
    return _CineBackDetector(
      route: route,
      builder: (context) => AnimatedBuilder(
        animation: Listenable.merge([animation, secondaryAnimation, CineBackGesture.instance]),
        child: child,
        builder: (context, child) {
          if (route.popGestureInProgress) {
            final p = CineBackGesture.instance.progress;
            final f = fadeThrough(p);
            if (route.isCurrent) {
              return Opacity(
                opacity: f.outOpacity,
                child: Transform.scale(scale: f.outScale, child: child),
              );
            }
            return Opacity(opacity: f.inOpacity, child: child);
          }
          return _transitionFor(kind, context, animation, secondaryAnimation, child!);
        },
      ),
    );
  }
}

/// Copy of Flutter's private `_PredictiveBackGestureDetector` (material/predictive_back_page_
/// transitions_builder.dart): a `WidgetsBindingObserver` that forwards the system back gesture to
/// the route while it is current and its pop gesture is enabled.
class _CineBackDetector extends StatefulWidget {
  const _CineBackDetector({required this.route, required this.builder});
  final PageRoute<dynamic> route;
  final WidgetBuilder builder;

  @override
  State<_CineBackDetector> createState() => _CineBackDetectorState();
}

class _CineBackDetectorState extends State<_CineBackDetector> with WidgetsBindingObserver {
  bool get _isEnabled => widget.route.isCurrent && widget.route.popGestureEnabled;

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    if (backEvent.isButtonEvent || !_isEnabled) return false;
    widget.route.handleStartBackGesture(progress: 1 - backEvent.progress);
    CineBackGesture.instance.update(backEvent.progress);
    return true;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    widget.route.handleUpdateBackGestureProgress(progress: 1 - backEvent.progress);
    CineBackGesture.instance.update(backEvent.progress);
  }

  @override
  void handleCancelBackGesture() {
    CineBackGesture.instance.cancel();
    widget.route.handleCancelBackGesture();
  }

  @override
  void handleCommitBackGesture() {
    CineBackGesture.instance.commit();
    widget.route.handleCommitBackGesture();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

/// Android match-cut and Dip pages: a Material route whose durations are the kind's, painted by
/// [CinePageTransitionsBuilder] (which reads [kind]). A plain page uses `MaterialPage`, whose
/// durations already come from the builder.
class CineAndroidPage<T> extends Page<T> {
  const CineAndroidPage({required this.child, required this.kind, super.key, super.name, super.arguments});
  final Widget child;
  final CineTransitionKind kind;

  /// The route's durations, by kind (reduced motion read when asked).
  Duration get transitionDuration => CineRouteMotion.forward(kind);
  Duration get reverseTransitionDuration => CineRouteMotion.reverse(kind);

  @override
  Route<T> createRoute(BuildContext context) => _CineRoute<T>(this);
}

class _CineRoute<T> extends PageRoute<T> with MaterialRouteTransitionMixin<T> implements CineKindRoute {
  _CineRoute(CineAndroidPage<T> page) : super(settings: page);

  CineAndroidPage<T> get _page => settings as CineAndroidPage<T>;

  @override
  CineTransitionKind get kind => _page.kind;

  @override
  Widget buildContent(BuildContext context) => _page.child;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => _page.transitionDuration;

  @override
  Duration get reverseTransitionDuration => _page.reverseTransitionDuration;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';
}

/// Android match cut: 480 / 336 ms, with the same builder.
class CineMatchCutPage<T> extends CineAndroidPage<T> {
  const CineMatchCutPage({required super.child, super.key, super.name}) : super(kind: CineTransitionKind.match);
}

// ---------------------------------------------------------------------------------------------
// Page selection

CineTransitionKind? cineKindFromName(String? name) => switch (name) {
      'page' => CineTransitionKind.page,
      'match' => CineTransitionKind.match,
      'dip' => CineTransitionKind.dip,
      _ => null,
    };

/// `extra` is a `Map<String, String>?` (so go_router's codec never chokes): `{'transition':
/// 'page' | 'match' | 'dip'}` picks the move; anything else falls back.
CineTransitionKind cineKindFromExtra(Object? extra, {required CineTransitionKind fallback}) {
  if (extra is Map) return cineKindFromName(extra['transition']?.toString()) ?? fallback;
  return fallback;
}

/// The page for a pushed route: `SwipeablePage` on iOS, `MaterialPage` (Page) or
/// [CineAndroidPage] elsewhere. Reads `extra['transition']`.
Page<void> cinePage(
  GoRouterState state,
  Widget child, {
  CineTransitionKind defaultKind = CineTransitionKind.page,
}) {
  final kind = cineKindFromExtra(state.extra, fallback: defaultKind);
  if (defaultTargetPlatform == TargetPlatform.iOS) return _swipeablePage(state, child, kind);
  if (kind == CineTransitionKind.page) return MaterialPage<void>(key: state.pageKey, name: state.name, child: child);
  if (kind == CineTransitionKind.match) return CineMatchCutPage<void>(key: state.pageKey, name: state.name, child: child);
  return CineAndroidPage<void>(key: state.pageKey, name: state.name, kind: kind, child: child);
}

/// The page a series opens on: a match cut (`SwipeablePage` 480 / 336 ms on iOS so the cover
/// `Hero` follows the finger; [CineMatchCutPage] elsewhere).
Page<void> cineMatchCutPage(GoRouterState state, Widget child) =>
    cinePage(state, child, defaultKind: CineTransitionKind.match);

/// Takeovers (onboarding, recap, annual) and auth: Dip in, Dip out.
Page<void> cineDipPage(GoRouterState state, Widget child) => cinePage(state, child, defaultKind: CineTransitionKind.dip);

/// A branch root or a shell: **Cut**, the new branch shows at once and its lists run Set. Still a
/// Material or Cupertino family route (zero duration), so the page beneath a push paints its own
/// outgoing move: Flutter's delegated transition only defers to a route of the same family.
Page<void> cineCutPage(GoRouterState state, Widget child) => defaultTargetPlatform == TargetPlatform.iOS
    ? _swipeablePage(state, child, CineTransitionKind.cut)
    : CineAndroidPage<void>(key: state.pageKey, name: state.name, kind: CineTransitionKind.cut, child: child);

/// A cover that flies from a poster into its series page. [tag] is the `(sourceId, seriesKey)`
/// record. iOS reverses the match cut with the finger; Android's predictive back fades through.
class CineHero extends StatelessWidget {
  const CineHero({super.key, required this.tag, required this.child});
  final (String, String) tag;
  final Widget child;

  @override
  Widget build(BuildContext context) => Hero(
        tag: tag,
        transitionOnUserGestures: defaultTargetPlatform == TargetPlatform.iOS,
        createRectTween: (a, b) => RectTween(begin: a, end: b),
        child: child,
      );
}
