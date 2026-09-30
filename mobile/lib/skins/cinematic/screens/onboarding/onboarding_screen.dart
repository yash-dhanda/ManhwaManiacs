import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/onboarding/providers/onboarding_providers.dart';
import 'package:manhwamaniacs/features/onboarding/utils/onboarding_steps.dart';
import 'package:manhwamaniacs/features/onboarding/utils/print_run.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/flight.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/onboarding/art_style_step.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/onboarding/formats_step.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/onboarding/genres_step.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/onboarding/onboarding_flow.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/onboarding/onboarding_states.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/onboarding/onboarding_top_bar.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/onboarding/print_overlay.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/onboarding/seeds_step.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/cine_page_physics.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

const _kickers = {2: 'FORMATS', 3: 'GENRES', 4: 'ART STYLE', 5: 'YOUR FIRST ISSUE'};
const _headlines = {
  2: 'What do you read?',
  3: 'Tap once to like, twice to love, hold to skip.',
  4: 'Which of these do you like the look of?',
  5: 'Choose three or more to start.',
};
const _names = {2: 'Formats', 3: 'Genres', 4: 'Art style', 5: 'Seeds'};

Future<ui.Image?> _resolveImage(String url) {
  final done = Completer<ui.Image?>();
  final stream = CachedNetworkImageProvider(url).resolve(ImageConfiguration.empty);
  late ImageStreamListener l;
  l = ImageStreamListener((info, _) {
    if (!done.isCompleted) done.complete(info.image.clone());
    stream.removeListener(l);
  }, onError: (Object _, StackTrace? __) {
    if (!done.isCompleted) done.complete(null);
    stream.removeListener(l);
  },);
  stream.addListener(l);
  return done.future.timeout(const Duration(milliseconds: 800), onTimeout: () => null);
}

/// How a step's catalog stands: what the page shows.
enum _Mode { normal, offline, unreachable }

/// "The first issue" (cinematic 8.7): the takeover that sets a new profile's taste in four steps
/// and plays Cut to home. Reads `step` once; from then on the step lives here.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.requestedStep});
  final int? requestedStep;

  /// Resolves a cover to a decoded image for the flight (tests swap it for a preloaded one).
  @visibleForTesting
  static Future<ui.Image?> Function(String url) imageLoader = _resolveImage;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _page = PageController();
  final Map<int, FocusNode> _heads = {};
  late final List<int> _stack;
  bool _printing = false, _busy = false;
  SwipeablePageRoute<dynamic>? _route;

  bool get _glass => Flags.glassAvailable;

  @override
  void initState() {
    super.initState();
    final activeId = ref.read(activeProfileProvider)?.id;
    final saved = ref.read(profilesProvider).valueOrNull?.where((p) => p.id == activeId).firstOrNull?.onboarding;
    final entry = entryStep(widget.requestedStep, resumeStep(saved, _glass), _glass);
    _stack = [entry];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final flow = ref.read(onboardingFlowProvider.notifier)..enter(entry);
      unawaited(flow.restore());
      // Only Back and the pager's backward swipe leave a step: no iOS edge swipe.
      _route = context.getSwipeablePageRoute<dynamic>();
      _route?.canSwipe = false;
      _arrived(entry);
    });
  }

  @override
  void dispose() {
    _route?.canSwipe = true;
    _page.dispose();
    for (final n in _heads.values) {
      n.dispose();
    }
    super.dispose();
  }

  FocusNode _head(int step) => _heads.putIfAbsent(step, () => FocusNode(debugLabel: 'onboarding-head-$step'));

  void _arrived(int step) {
    _head(step).requestFocus();
    final (i, t) = folioFor(step, _glass);
    unawaited(SemanticsService.sendAnnouncement(View.of(context), 'Step $i of $t: ${_names[step]}', TextDirection.ltr));
  }

  // --- moves -------------------------------------------------------------------------------

  Future<void> _to(int index, {required bool forward}) async {
    if (CineMotion.reduced(context)) {
      _page.jumpToPage(index);
    } else {
      await _page.animateToPage(index, duration: context.cine.durColumn, curve: CineCurves.settle);
    }
  }

  void _next() {
    final cur = _stack.last;
    final n = nextStep(cur, _glass);
    if (n == null || _busy) return;
    final flow = ref.read(onboardingFlowProvider.notifier);
    flow
      ..commit(n)
      ..enter(n);
    setState(() => _stack.add(n));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _to(_stack.length - 1, forward: true);
      if (mounted) _arrived(n);
    });
  }

  Future<void> _stepBack() async {
    if (_busy || _printing) return;
    if (_stack.length > 1) {
      final target = _stack.length - 2;
      await _to(target, forward: false);
      if (!mounted) return;
      _settledAt(target);
      return;
    }
    context.go(Routes.profiles(), extra: const {'transition': 'dip'});
  }

  /// A backward move landed on page [i]: trim the list so a forward swipe has nothing to reach.
  void _settledAt(int i) {
    if (i >= _stack.length - 1) return;
    setState(() => _stack.removeRange(i + 1, _stack.length));
    ref.read(onboardingFlowProvider.notifier).enter(_stack.last);
    _arrived(_stack.last);
  }

  void _leaveToTonight({String transition = 'dip'}) => context.go(Routes.tonight(), extra: {'transition': transition});

  Future<void> _skip() async {
    if (_busy) return;
    _busy = true;
    unawaited(ref.read(onboardingFlowProvider.notifier).saveDone());
    _leaveToTonight();
  }

  /// Offline: Tonight's offline edition without saving `done`; the saved step is kept.
  void _skipForNow() => _leaveToTonight();

  // --- print and Cut to home ---------------------------------------------------------------

  Future<bool> _armFlight(List<WorldItem> flying) async {
    final flow = ref.read(onboardingFlowProvider.notifier);
    final items = <FlightItem>[];
    for (final it in flying) {
      final box = flow.posterKey(it.anilistId).currentContext?.findRenderObject() as RenderBox?;
      final url = it.coverUrl;
      final a = it.available.firstOrNull;
      if (box == null || !box.hasSize || url == null || a == null) continue;
      final image = await OnboardingScreen.imageLoader(url);
      if (image == null) continue;
      items.add(FlightItem(key: '${a.sourceId}:${a.seriesKey}', image: image, rect: box.localToGlobal(Offset.zero) & box.size));
    }
    if (items.isEmpty) return false;
    ref.read(cineFlightProvider.notifier).arm(items);
    return true;
  }

  Future<void> _print() async {
    if (_busy) return;
    _busy = true;
    final container = ProviderScope.containerOf(context, listen: false);
    final toasts = container.read(cineToastsProvider.notifier);
    final reduced = CineMotion.reduced(context);
    cineFeedback(context, HapticEvent.tapPrimary, sound: SoundEvent.tapPrimary);
    setState(() => _printing = true);
    container.read(printUiProvider.notifier).state = const PrintUi(printing: true);
    final outcome = await ref.read(onboardingFlowProvider.notifier).printIssue();
    if (!mounted) return;
    final msgs = <String>[];
    var errors = false;
    if (outcome.allFailed) {
      msgs.add("Couldn't follow any of them. Try again from Discover.");
      errors = true;
    } else {
      final t = followedToast(outcome.followed.length, outcome.attempted);
      if (t != null) {
        msgs.add(t);
        errors = true;
      }
      if (!outcome.savedDone && outcome.followed.isNotEmpty) msgs.add('Your picks are followed. Your taste will save when the server answers.');
    }
    void say() {
      for (final m in msgs) {
        errors && !m.startsWith('Your picks') ? toasts.error(m) : toasts.info(m);
      }
    }

    final canFly = !outcome.allFailed && outcome.followed.isNotEmpty && outcome.homeOk;
    if (!canFly) {
      _leaveToTonight();
      say();
      return;
    }
    if (reduced) {
      _leaveToTonight(transition: 'crossfade');
      say();
      return;
    }
    final flying = flightList(outcome.followed);
    container.read(printUiProvider.notifier).state = PrintUi(printing: true, fade: true, keep: {for (final f in flying) f.anilistId});
    await Future<void>.delayed(const Duration(milliseconds: 240));
    if (!mounted) return;
    final armed = await _armFlight(flying);
    if (!mounted) return;
    context.go(Routes.tonight(), extra: const {'transition': 'none'});
    if (armed) {
      Timer(flightDuration(flying.length) + const Duration(milliseconds: 400), say);
    } else {
      say();
    }
  }

  // --- pages ---------------------------------------------------------------------------------

  _Mode _mode(int step, bool online) {
    if (!online) return _Mode.offline;
    if (step == 4) return _Mode.normal;
    final async = ref.watch(onboardingCatalogProvider(ref.read(onboardingFlowProvider.notifier).keyFor(step)));
    final err = async.error;
    if (err == null) return _Mode.normal;
    return err is NetworkError || err is TimeoutError ? _Mode.offline : _Mode.unreachable;
  }

  Widget _stepSliver(int step) {
    final key = ref.read(onboardingFlowProvider.notifier).keyFor(step);
    return switch (step) {
      2 => FormatsStep(catalogKey: key),
      3 => GenresStep(catalogKey: key),
      4 => const ArtStyleStep(),
      _ => SeedsStep(catalogKey: key),
    };
  }

  Widget _pageFor(int step, bool online) {
    final grid = CineGrid.of(context);
    final c = context.cine;
    final mode = _mode(step, online);
    final side = EdgeInsets.only(left: grid.left - 8, right: grid.right - 8);
    if (mode == _Mode.offline) {
      return CustomScrollView(slivers: [
        SliverPadding(padding: EdgeInsets.fromLTRB(grid.left, 24, grid.right, 24), sliver: const SliverToBoxAdapter(child: OnboardingOffline())),
      ],);
    }
    final headStyle = CineText.style(context, c.typeMasthead).copyWith(color: c.colorInk100);
    return CustomScrollView(slivers: [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(grid.left, 24, grid.right, 24),
        sliver: SliverToBoxAdapter(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            StepKicker(_kickers[step]!),
            const SizedBox(height: 12),
            Focus(
              focusNode: _head(step),
              skipTraversal: true,
              child: TypedHeadline(_headlines[step]!, style: headStyle, cap: c.typeMasthead.cap, level: 1),
            ),
          ],),
        ),
      ),
      SliverPadding(padding: side, sliver: mode == _Mode.unreachable && step == 5 ? const SliverToBoxAdapter(child: SeedsUnreachable()) : _stepSliver(step)),
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
    ],);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final online = ref.watch(deviceOnlineProvider).valueOrNull ?? true;
    final grid = CineGrid.of(context);
    final cur = _stack.last;
    final (index, total) = folioFor(cur, _glass);
    final picks = ref.watch(onboardingFlowProvider.select((s) => s.picks.length));
    final mode = _mode(cur, online);
    final last = nextStep(cur, _glass) == null;

    final String label;
    final VoidCallback? onPressed;
    String? why;
    if (mode == _Mode.offline) {
      label = 'Skip for now';
      onPressed = _skipForNow;
    } else if (last && mode == _Mode.unreachable) {
      label = 'Finish';
      onPressed = _skip;
    } else if (last) {
      label = 'Print my first issue';
      onPressed = picks >= 3 && !_printing ? _print : null;
      why = 'Pick three or more first.';
    } else {
      label = 'Next';
      onPressed = _next;
    }

    final entries = <ShortcutEntry>[
      ShortcutEntry(group: 'Onboarding', activator: const SingleActivator(LogicalKeyboardKey.arrowRight), description: 'Next step', onInvoke: () => onPressed?.call(), keys: const ['→']),
      ShortcutEntry(group: 'Onboarding', activator: const SingleActivator(LogicalKeyboardKey.arrowLeft), description: 'Previous step', onInvoke: _stepBack, keys: const ['←']),
    ];

    final pager = NotificationListener<ScrollEndNotification>(
      onNotification: (n) {
        if (n.metrics.axis == Axis.horizontal && _page.hasClients) {
          final i = _page.page?.round() ?? 0;
          if (i < _stack.length - 1 && (_page.page! - i).abs() < 0.01) _settledAt(i);
        }
        return false;
      },
      child: PageView.builder(
        controller: _page,
        physics: const CinePagePhysics(),
        itemCount: _stack.length,
        itemBuilder: (context, i) => _Fade(
          key: ValueKey('step-${_stack[i]}'),
          child: _pageFor(_stack[i], online),
        ),
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_stepBack());
      },
      child: RegisteredShortcuts(
        group: 'Onboarding',
        entries: entries,
        child: Scaffold(
          backgroundColor: const Color(0xFF000000),
          body: Column(children: [
            OnboardingTopBar(index: index, total: total, onBack: () => unawaited(_stepBack()), onSkip: _skip, enabled: !_printing),
            Expanded(
              child: Stack(children: [
                Positioned.fill(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: _printing && !CineMotion.reduced(context) ? 0.3 : 1),
                    duration: CineMotion.reduced(context) ? Duration.zero : c.durLine,
                    curve: CineCurves.lift,
                    builder: (_, b, child) => ColorFiltered(colorFilter: ColorFilter.matrix(_brightness(b)), child: child),
                    child: pager,
                  ),
                ),
                if (_printing) PrintOverlay(fade: ref.watch(printUiProvider).fade),
              ],),
            ),
            ColoredBox(
              color: const Color(0xFF000000),
              child: Padding(
                padding: EdgeInsets.fromLTRB(grid.left, 16, grid.right, 16 + MediaQuery.viewPaddingOf(context).bottom),
                child: SizedBox(width: double.infinity, child: CineButton(label: label, onPressed: onPressed, fullWidth: true, disabledReason: onPressed == null ? why : null)),
              ),
            ),
          ],),
        ),
      ),
    );
  }
}

List<double> _brightness(double b) => [b, 0, 0, 0, 0, 0, b, 0, 0, 0, 0, 0, b, 0, 0, 0, 0, 0, 1, 0];

/// Reduced motion: the incoming step fades in over 150 ms (`durReduced`).
class _Fade extends StatelessWidget {
  const _Fade({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!CineMotion.reduced(context)) return child;
    return TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: 1), duration: const Duration(milliseconds: 150), builder: (_, t, c) => Opacity(opacity: t, child: c), child: child);
  }
}
