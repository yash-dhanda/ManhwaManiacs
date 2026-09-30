import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide ShortcutRegistry;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/color/cover_palette.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloaded_series_provider.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/home/providers/home_feed_provider.dart';
import 'package:manhwamaniacs/features/home/utils/continue_hidden.dart';
import 'package:manhwamaniacs/features/home/utils/rerank.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/glass/ambient_field.dart';
import 'package:manhwamaniacs/skins/glass/parts/recommend/lift_provider.dart';
import 'package:manhwamaniacs/skins/glass/parts/recommend/recommend_orbs.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/magnet_targets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/pull_to_refresh.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/continue_with_recap.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/greeting_header.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/hero_claim.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_actions.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_chrome.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_data.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_dock_menu.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_field_ripple.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_rail_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_rails.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_rails_view.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_states.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/spotlight.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/spotlight_card.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/spotlights.dart';
import 'package:manhwamaniacs/skins/glass/shell/accessory_controller.dart';
import 'package:manhwamaniacs/skins/glass/shell/error_surface.dart';
import 'package:manhwamaniacs/skins/glass/shell/glass_scaffold.dart';
import 'package:manhwamaniacs/skins/glass/shell/global_keys.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// Glass Home (`tonight`, glass 8.8, 9.1.1): the typed greeting, the hero spotlight, the rails with the AI light, every state. The data
/// is the shared `homeFeedProvider`; Light follows the story as the spotlight pages.
class GlassHomeScreen extends ConsumerStatefulWidget {
  const GlassHomeScreen({super.key});

  @override
  ConsumerState<GlassHomeScreen> createState() => _GlassHomeScreenState();
}

class _GlassHomeScreenState extends ConsumerState<GlassHomeScreen> with WidgetsBindingObserver {
  final GlassMagnetRegistry _magnets = GlassMagnetRegistry();
  final HomeHeroClaims _claims = HomeHeroClaims();
  final GlassPullToRefreshController _refresh = GlassPullToRefreshController();
  final GlobalKey _spotKey = GlobalKey();
  final Object _token = Object();
  late final GlassAccessoryController _accessory = ref.read(glassAccessoryProvider.notifier);
  late final ShortcutRegistry _shortcuts = ref.read(shortcutRegistryProvider.notifier);
  VoidCallback? _offRefresh;
  CoverPalette? _palette;
  bool _resumed = true;
  bool _spotOnScreen = true;
  bool _spotPast = false;
  List<String> _noted = const [];
  bool _wasCurrent = true;
  Offset? _rippleAt;
  bool _rippled = false;
  Timer? _rateTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _offRefresh = useGlassRefresh(() => unawaited(_refresh.refresh()));
    Future.microtask(_registerKeys);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final r = state == AppLifecycleState.resumed;
    if (r != _resumed && mounted) setState(() => _resumed = r);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Coming back to Home as the current route: the in-session re-rank takes effect (a rail moves only while off screen).
    final current = ModalRoute.of(context)?.isCurrent ?? true;
    if (current && !_wasCurrent) _noted = ref.read(rerankNotesProvider);
    _wasCurrent = current;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _offRefresh?.call();
    _rateTimer?.cancel();
    final s = _shortcuts;
    final t = _token;
    Future.microtask(() => s.unregister(t));
    final a = _accessory;
    Future.microtask(() {
      try {
        a.setContinue(null);
      } catch (_) {}
    });
    _refresh.dispose();
    super.dispose();
  }

  void _registerKeys() {
    if (!mounted) return;
    const a = SingleActivator(LogicalKeyboardKey.abort);
    ShortcutEntry e(String d, List<String> keys, {bool single = false}) => ShortcutEntry(group: 'Home', activator: a, description: d, onInvoke: () {}, keys: keys, singleKey: single);
    _shortcuts.register(_token, [
      e('Page the spotlight', ['←', '→']),
      e('Move between rails', ['↑', '↓']),
      e('Open the focused item', ['Enter']),
      e('Open its menu', ['.'], single: true),
      e('Previously on', ['P'], single: true),
      e('Not interested (AI card)', ['Delete']),
    ]);
  }

  // -- scroll and visibility ------------------------------------------------------------------------------------------

  void _measure() {
    if (!mounted) return;
    final ro = _spotKey.currentContext?.findRenderObject();
    if (ro is! RenderBox || !ro.attached) return;
    final top = ro.localToGlobal(Offset.zero).dy;
    final bottom = top + ro.size.height;
    final screenH = MediaQuery.sizeOf(context).height;
    final on = bottom > 0 && top < screenH;
    final past = bottom < MediaQuery.paddingOf(context).top + 64;
    if (on != _spotOnScreen || past != _spotPast) {
      setState(() {
        _spotOnScreen = on;
        _spotPast = past;
      });
    }
    _syncAccessory();
  }

  void _syncAccessory() {
    final item = firstContinue(ref.read(homeFeedProvider).valueOrNull, ref.read(continueHiddenProvider));
    if (_spotPast && item != null) {
      final row = item.row;
      _accessory.setContinue(
        GlassContinueAccessory(
          title: 'Continue ${row.title ?? row.seriesKey}',
          subtitle: chLabelOf(row.chapterNumber),
          coverUrl: row.coverUrl,
          onOpen: (from) => unawaited(continueWithRecap(context, ref, HomeContinueTarget.fromContinue(item), from)),
        ),
      );
    } else {
      _accessory.setContinue(null);
    }
  }

  bool get _tiltActive {
    if (!_resumed || !_spotOnScreen) return false;
    final tab = ref.read(glassActiveTabProvider);
    final depth = ref.read(glassDepthProvider)[GlassTab.home] ?? 0;
    final prefs = ref.read(glassInAppPrefsProvider);
    final reduced = ref.read(glassMotionPrefsProvider).reduced;
    return tab == GlassTab.home && depth == 0 && TickerMode.valuesOf(context).enabled && prefs.lightFollowsDevice && !reduced && (ModalRoute.of(context)?.isCurrent ?? true);
  }

  // -- actions ----------------------------------------------------------------------------------------------------------

  Future<RefreshResult> _onRefresh() async {
    final out = await ref.read(homeFeedProvider.notifier).refreshFromServer();
    if (out.error != null) {
      surfaceError(ref, out.error!, retry: () => unawaited(_refresh.refresh()));
      return RefreshResult.unchanged;
    }
    return out.changed ? RefreshResult.changed : RefreshResult.unchanged;
  }

  void _rateLimit(Duration wait) {
    final n = wait.inSeconds.clamp(1, 3600);
    ref.read(glassRateLimitProvider.notifier).state = GlassRateLimit('Sources are busy. Retrying in $n s', n);
    glassFire(ref, HapticEvent.warning);
    _rateTimer?.cancel();
    _rateTimer = Timer(wait, () {
      if (!mounted) return;
      ref.read(glassRateLimitProvider.notifier).state = null;
      unawaited(ref.read(homeFeedProvider.notifier).refresh());
    });
  }

  SpotlightHandlers _handlers() => SpotlightHandlers(
        targets: () => _magnets.targets,
        onMagnetChanged: (id) => ref.read(magnetHeldProvider.notifier).state = id,
        onLiftPhase: (sourceId, seriesKey, rectOf) => liftPhaseHandler(ref, sourceId: sourceId, seriesKey: seriesKey, rectOf: rectOf),
        onPrimary: (s, from) {
          switch (s.primary) {
            case SpotlightAction.continueReading:
              if (s.target != null) {
                unawaited(continueWithRecap(context, ref, s.target!, from));
              } else if (s.hasSeries) {
                unawaited(openSeries(ref, s.sourceId!, s.seriesKey!, from: from));
              }
            case SpotlightAction.openSeries:
              if (s.hasSeries) unawaited(openSeries(ref, s.sourceId!, s.seriesKey!, from: from));
            case SpotlightAction.searchSources:
              unawaited(ref.read(skinRouterProvider).push<void>(Routes.discover({'q': s.title})));
            case SpotlightAction.openWrapped:
              unawaited(ref.read(skinRouterProvider).push<void>(Routes.annual(s.year ?? ref.read(clockProvider)().year)));
            case SpotlightAction.previouslyOn:
              if (s.hasSeries) unawaited(openRecap(ref, s.sourceId!, s.seriesKey!, s.target?.recap?.toKey ?? s.recap?.toKey ?? s.target?.chapterKey ?? '', from: from));
          }
        },
        onSecondary: (s, from) {
          if (!s.hasSeries) return;
          if (s.secondaryIsRecap) {
            unawaited(openRecap(ref, s.sourceId!, s.seriesKey!, s.target?.recap?.toKey ?? s.recap?.toKey ?? s.target?.chapterKey ?? '', from: from));
          } else {
            unawaited(openSeries(ref, s.sourceId!, s.seriesKey!, from: from));
          }
        },
        onOpen: (s, from, {velocity}) {
          if (s.isWrapped) {
            unawaited(ref.read(skinRouterProvider).push<void>(Routes.annual(s.year ?? ref.read(clockProvider)().year)));
          } else if (s.hasSeries) {
            unawaited(openSeries(ref, s.sourceId!, s.seriesKey!, from: from, velocity: velocity));
          } else {
            unawaited(ref.read(skinRouterProvider).push<void>(Routes.discover({'q': s.title})));
          }
        },
        onDrop: (s, id) {
          if (s.hasSeries) recommendTo(context, ref, sourceId: s.sourceId!, seriesKey: s.seriesKey!, profileId: id);
        },
      );

  void _focused(int i, SpotlightSpec s) {
    final p = spotlightPalette(s);
    if (p == _palette) return;
    setState(() => _palette = p);
    if (!_rippled) {
      _rippled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ro = _spotKey.currentContext?.findRenderObject();
        if (mounted && ro is RenderBox && ro.attached) setState(() => _rippleAt = ro.localToGlobal(ro.size.center(Offset.zero)));
      });
    }
  }

  // -- build -------------------------------------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(homeFeedProvider);
    final fv = view.valueOrNull;
    final now = ref.watch(clockProvider)();
    final hidden = ref.watch(continueHiddenProvider);
    final profile = ref.watch(activeProfileProvider);
    final mode = ref.watch(contentModeControllerProvider);
    final scope = ref.watch(contentModeScopeProvider);
    final downloaded = ref.watch(downloadedShelfProvider).valueOrNull ?? const [];
    final followed = ref.watch(homeFollowedProvider).valueOrNull ?? const [];
    ref.listen<AsyncValue<HomeFeedView>>(homeFeedProvider, (prev, next) {
      final v = next.valueOrNull;
      if (v?.retryAfter != null && prev?.valueOrNull?.retryAfter == null) _rateLimit(v!.retryAfter!);
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncAccessory());
    });
    ref.listen<List<HiddenContinue>>(continueHiddenProvider, (_, __) => WidgetsBinding.instance.addPostFrameCallback((_) => _syncAccessory()));

    final continueRows = fv?.feed?.section(HomeSectionType.continueReading)?.items.whereType<HomeContinueItem>().where((c) => !hidden.any((h) => h.sourceId == c.row.sourceId && h.seriesKey == c.row.seriesKey && h.chapterKey == c.row.chapterKey)).toList();
    final specs = fv == null ? const <SpotlightSpec>[] : composeSpotlights(fv, now: now, continueRows: continueRows);
    final rails = fv == null
        ? const <HomeRailSpec>[]
        : composeHomeRails(
            fv,
            hidden: hidden,
            downloaded: downloaded,
            followed: followed,
            inMode: scope.novelsEnabled ? (f) => scope.mode == scope.modeOf(f.sourceId) : null,
            noted: _noted,
            aiThinking: view.isReloading && !view.isRefreshing,
          );
    final feed = fv?.feed;
    final env = HomeRailEnv(handlers: _handlers(), aiReason: feed?.ai.reason, now: now);
    final newProfile = specs.isNotEmpty && specs.first.kind == SpotlightKind.start && !(fv?.offline ?? false);
    final mood0 = profile?.mood ?? Mood.neutral;
    final ambient = _palette != null ? GlassAmbientSpec.palette(_palette!, opacity: 0.26, fallbackMood: mood0) : GlassAmbientSpec.mood(mood0);

    Widget body;
    if (fv == null) {
      body = view.hasError ? HomeErrorLens(onRetry: _retry) : const HomeLoadingSkeleton();
    } else if (fv.state == HomeFeedState.unavailable) {
      body = HomeErrorLens(onRetry: _retry);
    } else {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KeyedSubtree(
            key: _spotKey,
            child: Spotlight(specs: specs, handlers: env.handlers, onFocusedChanged: _focused, tiltActive: _tiltActive, controlsOnScreen: _spotOnScreen),
          ),
          const SizedBox(height: 16),
          HomeRailsView(rails: rails, env: env, waveKey: Object.hash(feed?.generatedAt, feed?.issueNo, mode, profile?.id), footer: newProfile ? const HomeNewProfileLens() : null),
        ],
      );
    }

    final page = HomeHeroScope(
      claims: _claims,
      child: GlassRecommendOrbs(
        registry: _magnets,
        child: GlassScaffold(
          title: 'Home',
          contentModeSwitch: true,
          trailing: homeBarActions(ref),
          overflow: homeOverflow(ref, refresh: () => unawaited(_refresh.refresh())),
          ambient: ambient,
          largeTitleOverride: const GreetingHeader(),
          refreshSliver: GlassPullToRefresh(controller: _refresh, onRefresh: _onRefresh),
          slivers: [
            SliverToBoxAdapter(child: _ScrollProbe(onScroll: _measure)),
            SliverToBoxAdapter(child: body),
          ],
        ),
      ),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_rippleAt != null) Positioned.fill(child: HomeFieldRipple(palette: _palette, origin: _rippleAt!)),
        page,
      ],
    );
  }

  Future<bool> _retry() async {
    await ref.read(homeFeedProvider.notifier).refresh();
    return ref.read(homeFeedProvider).valueOrNull?.state != HomeFeedState.unavailable;
  }
}

/// Reports the page's scroll to the screen (the spotlight's visibility, the accessory).
class _ScrollProbe extends StatefulWidget {
  const _ScrollProbe({required this.onScroll});
  final VoidCallback onScroll;

  @override
  State<_ScrollProbe> createState() => _ScrollProbeState();
}

class _ScrollProbeState extends State<_ScrollProbe> {
  ScrollPosition? _pos;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final p = Scrollable.maybeOf(context)?.position;
    if (p != _pos) {
      _pos?.removeListener(widget.onScroll);
      _pos = p?..addListener(widget.onScroll);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onScroll());
  }

  @override
  void dispose() {
    _pos?.removeListener(widget.onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

String chLabelOf(num? n) => n == null ? '' : 'Ch ${n == n.roundToDouble() ? n.round() : n}';
