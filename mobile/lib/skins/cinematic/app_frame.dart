import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/app/app_restart.dart';
import 'package:manhwamaniacs/core/diagnostics/debug_overlays.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/error/fatal_error.dart';
import 'package:manhwamaniacs/core/logging/app_logger.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/auth/providers/offline_edition_controller.dart';
import 'package:manhwamaniacs/features/settings/providers/a11y_prefs_provider.dart';
import 'package:manhwamaniacs/features/updates/providers/unread_count_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/motion_timings.dart';
import 'package:manhwamaniacs/skins/cinematic/nav_map.dart';
import 'package:manhwamaniacs/skins/cinematic/navigation.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_lightbox.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid_overlay.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toast_host.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/cine_reader_route.dart' show cineReaderOwnsToastsProvider;
import 'package:manhwamaniacs/skins/cinematic/screens/system/cine_broken_part.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/system/cine_error_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/shell.dart' show cineArrivalProvider;
import 'package:manhwamaniacs/skins/cinematic/shell/cine_scaffold.dart' show cineRevealFocus;
import 'package:manhwamaniacs/skins/cinematic/shell/global_keys.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/rating_card_slot.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/stop_press_banner.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/thumb_index.dart';
import 'package:manhwamaniacs/skins/cinematic/shutter.dart';
import 'package:manhwamaniacs/skins/cinematic/splash/cine_splash.dart';
import 'package:manhwamaniacs/skins/cinematic/system_bars.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/transitions.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// Tracks whether the Lightbox is the top route of the root navigator (installed on the router).
class CineTopRouteObserver extends NavigatorObserver {
  final ValueNotifier<bool> lightboxOnTop = ValueNotifier(false);
  final List<Route<dynamic>> _stack = [];

  void _update() => lightboxOnTop.value = _stack.isNotEmpty && _stack.last is CineLightboxRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.add(route);
    _update();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _update();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _update();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (i >= 0 && newRoute != null) _stack[i] = newRoute;
    _update();
  }
}

/// The observer the Cinematic router installs; the frame listens to it.
final CineTopRouteObserver cineTopRouteObserver = CineTopRouteObserver();

bool _isBuildError(FlutterErrorDetails d) =>
    d.library == 'widgets library' && (d.context?.toDescription().startsWith('building') ?? false);

bool _benign(Object e) => e is AppError || e is DioException || e is SocketException || e is TimeoutException;

/// The error hooks of the Cinematic root, reference counted: a restart builds the new frame before
/// the old one is disposed, so a per-instance "previous handler" would restore the wrong one. The
/// first frame saves the originals, the last one puts them back.
abstract final class _ErrorHooks {
  static int _users = 0;
  static bool _release = false;
  static ErrorWidgetBuilder? _builder;
  static FlutterExceptionHandler? _onError;
  static ui.ErrorCallback? _onDispatcherError;

  static void install({required bool release}) {
    _release = release;
    if (_users++ > 0) return;
    _builder = ErrorWidget.builder;
    _onError = FlutterError.onError;
    _onDispatcherError = PlatformDispatcher.instance.onError;
    if (release) {
      ErrorWidget.builder = (details) {
        appLogger.e('A widget failed to build', details.exception, details.stack);
        return const CineBrokenPart();
      };
    }
    final prevError = _onError;
    FlutterError.onError = (details) {
      appLogger.e('Flutter error', details.exception, details.stack);
      // A widget that fails to build is already replaced by `CineBrokenPart`; the notice is for
      // everything else that escaped.
      if (_release && !_benign(details.exception) && !_isBuildError(details)) {
        appFatalError.value = FatalErrorReport(details.exception, details.stack);
      }
      prevError?.call(details);
    };
    final prevDispatcher = _onDispatcherError;
    PlatformDispatcher.instance.onError = (error, stack) {
      appLogger.e('Uncaught error', error, stack);
      if (!_benign(error)) appFatalError.value = FatalErrorReport(error, stack);
      return prevDispatcher?.call(error, stack) ?? true;
    };
  }

  static void uninstall() {
    if (--_users > 0) return;
    _users = 0;
    ErrorWidget.builder = _builder ?? ErrorWidget.builder;
    FlutterError.onError = _onError;
    PlatformDispatcher.instance.onError = _onDispatcherError;
  }
}

/// The root stack above the router, in the order of cinematic 2.4 (Flutter draws these above every
/// route): the router (page, sticky, chrome, panel, sheet, dialog and lightbox layers are routes);
/// the toast host; the stop-press banner; the rating-card slot; the `g` chip; the shutter; the
/// splash; the grid and motion-timings overlays. The frame also installs the global keys and the
/// error hooks.
class CineAppFrame extends ConsumerStatefulWidget {
  const CineAppFrame({super.key, required this.child, this.releaseErrorWidget = kReleaseMode, this.splash = true});

  final Widget child;

  /// Renders `CineBrokenPart` instead of Flutter's red screen when a widget throws. Debug keeps the
  /// red screen.
  final bool releaseErrorWidget;

  /// Whether the frame mounts the Press start splash (tests turn it off).
  final bool splash;

  @override
  ConsumerState<CineAppFrame> createState() => _CineAppFrameState();
}

class _CineAppFrameState extends ConsumerState<CineAppFrame> {
  final GlobalKey<CineToastHostState> _toastKey = GlobalKey<CineToastHostState>();
  double _bannerHeight = 0;
  late final GoRouter _router = ref.read(skinRouterProvider);

  FocusNode? _lastFocus;

  /// Every keyboard focus change is cut into view below the running head (cinematic 14.4).
  void _onFocus() {
    final node = FocusManager.instance.primaryFocus;
    if (node == _lastFocus) return;
    _lastFocus = node;
    if (node == null || !mounted || FocusManager.instance.highlightMode != FocusHighlightMode.traditional) return;
    cineRevealFocus(node);
  }

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_onFocus);
    _router.routerDelegate.addListener(_routeChanged);
    applyCineRestingSystemUi();
    // Takes the edition arrival now, at boot, whichever route opens first.
    ref.read(cineArrivalProvider);
    _ErrorHooks.install(release: widget.releaseErrorWidget);
    appFatalError.addListener(_fatalChanged);
    cineTopRouteObserver.lightboxOnTop.addListener(_lightboxChanged);
  }

  /// The router notifies from inside a build (redirects settle there): rebuild after it.
  void _routeChanged() {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  void _fatalChanged() {
    if (mounted) setState(() {});
  }

  void _lightboxChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onFocus);
    _router.routerDelegate.removeListener(_routeChanged);
    appFatalError.removeListener(_fatalChanged);
    cineTopRouteObserver.lightboxOnTop.removeListener(_lightboxChanged);
    _ErrorHooks.uninstall();
    appFatalError.value = null;
    super.dispose();
  }

  void _tryAgain() {
    appFatalError.value = null;
    ref.read(skinRouterProvider).refresh();
  }

  void _restart() {
    appFatalError.value = null;
    AppRestart.of(context).restart();
  }

  @override
  Widget build(BuildContext context) {
    CineRouteMotion.appReduced = ref.watch(appReduceMotionProvider);
    // The offline edition and the unread count run only under this root: legacy shows nothing new.
    ref.watch(offlineEditionControllerProvider);
    ref.listen<OutboxSyncResult?>(outboxSyncProvider, (_, r) {
      if (r == null) return;
      final msg = syncedMessage(r.reads, r.bookmarks);
      if (msg != null) ref.read(cineToastsProvider.notifier).info(msg);
    });
    final router = _router;
    final mq = MediaQuery.of(context);
    final fatal = appFatalError.value;
    final splashDone = ref.watch(splashDoneProvider);

    // The frame sits above the Navigator, so the toasts, the banner and any route without a
    // Material of its own (sheets, dialogs) found no DefaultTextStyle and drew Flutter's fallback:
    // red text on a yellow double underline. Every Text under the frame inherits the skin's face.
    return DefaultTextStyle(
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: context.cine.colorInk100, decoration: TextDecoration.none),
      child: Builder(
      builder: (context) {
        final path = Uri.parse(cineLocationOf(router)).path;
        final inShell = navInfoFor(path).inShell;
        final bottom = mq.viewPadding.bottom + 16;
        final anchor = inShell ? CineThumbIndex.height + mq.viewPadding.bottom + 16 : bottom;
        final signedIn = ref.watch(authControllerProvider) is AuthAuthenticated;
        final banner = signedIn ? ref.watch(newChaptersBannerProvider).valueOrNull : null;
        final dismissed = ref.watch(stopPressDismissedProvider);
        final showBanner = banner != null && banner.maxId > dismissed && path != '/updates' && !isReaderPath(path);
        final c = context.cine;
        final side = (mq.viewPadding.left + 8 > c.space4 ? mq.viewPadding.left + 8 : c.space4);
        final sideR = (mq.viewPadding.right + 8 > c.space4 ? mq.viewPadding.right + 8 : c.space4);

        return CineShutterLayer(
          child: Stack(fit: StackFit.passthrough, children: [
            CineGlobalKeys(
              toastKey: _toastKey,
              chipBottom: anchor + (showBanner ? _bannerHeight + 8 : 0),
              child: Stack(fit: StackFit.passthrough, children: [
                CineToastHost(
                  key: _toastKey,
                  anchorBottom: anchor,
                  bannerHeight: showBanner ? _bannerHeight : 0,
                  hidden: cineTopRouteObserver.lightboxOnTop.value || ref.watch(cineReaderOwnsToastsProvider),
                  child: widget.child,
                ),
                if (showBanner)
                  Positioned(
                    left: side,
                    right: sideR,
                    bottom: anchor,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: _Sized(
                          onHeight: (h) {
                            if ((h - _bannerHeight).abs() > 0.5) setState(() => _bannerHeight = h);
                          },
                          // The banner sits above the router's Navigator, so its Dismiss tooltip needs an
                          // Overlay of its own; `Overlay.wrap` takes the size of its child.
                          child: Overlay.wrap(
                            child: CineStopPressBanner(
                              chapters: banner.chapters,
                              series: banner.series,
                              onRead: () => router.go('/updates'),
                              onDismiss: () => ref.read(stopPressDismissedProvider.notifier).dismiss(banner.maxId),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                const CineRatingCardSlot(),
              ],),
            ),
            if (fatal != null)
              Positioned.fill(
                child: CineErrorScreen.routeError(report: fatal, onRetry: _tryAgain, onRestart: _restart),
              ),
            if (widget.splash && !splashDone) const Positioned.fill(child: CineSplash()),
            const Positioned.fill(child: CineGridOverlay()),
            if (ref.watch(motionTimingsOverlayProvider))
              const Positioned(left: 8, bottom: 8, child: SafeArea(child: CineMotionTimingsPanel())),
          ],),
        );
      },
      ),
    );
  }
}

class _Sized extends StatefulWidget {
  const _Sized({required this.onHeight, required this.child});
  final ValueChanged<double> onHeight;
  final Widget child;

  @override
  State<_Sized> createState() => _SizedState();
}

class _SizedState extends State<_Sized> {
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = context.findRenderObject();
      if (mounted && box is RenderBox && box.hasSize) widget.onHeight(box.size.height);
    });
    return widget.child;
  }
}
