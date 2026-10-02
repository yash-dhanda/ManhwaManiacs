import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/downloads/utils/auto_download.dart';
import 'package:manhwamaniacs/skins/back_parent.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/parts/recommend/recommend_orbs.dart';
import 'package:manhwamaniacs/skins/glass/parts/streak/streak_ui.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart' show GlassMenuBack;
import 'package:manhwamaniacs/skins/glass/primitives/new_chapters_capsule.dart' show GlassCapsuleHost;
import 'package:manhwamaniacs/skins/glass/primitives/overlay_queue.dart';
import 'package:manhwamaniacs/skins/glass/primitives/recede.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast_host.dart';
import 'package:manhwamaniacs/skins/glass/routes/route_table.dart';
import 'package:manhwamaniacs/skins/glass/screens/downloads/downloads_feed.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_dock_menu.dart';
import 'package:manhwamaniacs/skins/glass/shell/accessory.dart';
import 'package:manhwamaniacs/skins/glass/shell/accessory_controller.dart';
import 'package:manhwamaniacs/skins/glass/shell/arrival.dart';
import 'package:manhwamaniacs/skins/glass/shell/dock.dart';
import 'package:manhwamaniacs/skins/glass/shell/dock_state.dart';
import 'package:manhwamaniacs/skins/glass/shell/glass_scaffold.dart';
import 'package:manhwamaniacs/skins/glass/shell/overlays.dart';
import 'package:manhwamaniacs/skins/glass/shell/search_orb.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';
import 'package:manhwamaniacs/skins/glass/shell/sidebar.dart';
import 'package:manhwamaniacs/skins/glass/shell/sidebar_geometry.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/transitions/dive.dart';

/// The width from which the desktop frame starts with the sidebar expanded and docked.
const double kSidebarDockWidth = 1180;

/// What the sidebar does for a window: docked expanded, docked collapsed, or collapsed with an expanded overlay (glass 8.0.1). Pure.
({bool hasSidebar, bool dockedExpanded, bool overlayOpen}) sidebarPlan({required GlassFrameKind frame, required double width, required bool? choice}) {
  if (frame == GlassFrameKind.phone) return (hasSidebar: false, dockedExpanded: false, overlayOpen: false);
  if (width >= kSidebarDockWidth) return (hasSidebar: true, dockedExpanded: choice ?? true, overlayOpen: false);
  return (hasSidebar: true, dockedExpanded: false, overlayOpen: choice ?? false);
}

/// The shell (glass 8.0.1, 15.3): the four branches with their stacks, the floating dock, orb and accessory on phones, the inset
/// sidebar on tablet and desktop frames, the toast and capsule hosts, the recede scope's page, the global overlays and the key map.
class GlassShell extends ConsumerStatefulWidget {
  const GlassShell({super.key, required this.navigationShell, required this.location});
  final StatefulNavigationShell navigationShell;

  /// The shell's own location (beneath any sheet route).
  final String location;

  @override
  ConsumerState<GlassShell> createState() => _GlassShellState();
}

class _GlassShellState extends ConsumerState<GlassShell> with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 120), value: 1);
  late final FocusNode _overlayFocus = FocusNode(debugLabel: 'sidebar overlay');
  final FocusNode _expandReturn = FocusNode(debugLabel: 'sidebar return');
  int _index = 0;
  VoidCallback? _homeHooks;

  /// The sheet stack this shell sits under: the dock leaves while any sheet is up, so it never covers a sheet's controls.
  GlassRecedeController? _recede;

  void _onSheets() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final r = GlassRecedeScope.maybeOf(context);
    if (r != _recede) {
      _recede?.count.removeListener(_onSheets);
      _recede = r?..count.addListener(_onSheets);
    }
  }

  @override
  void initState() {
    super.initState();
    _homeHooks = registerHomeShellHooks();
    _index = widget.navigationShell.currentIndex;
    Future.microtask(() {
      if (!mounted) return;
      ref.read(glassActiveTabProvider.notifier).state = GlassTab.values[_index];
      ref.read(glassSidebarToggleProvider.notifier).state = _toggleSidebar;
    });
  }

  @override
  void didUpdateWidget(GlassShell old) {
    super.didUpdateWidget(old);
    final i = widget.navigationShell.currentIndex;
    if (i != _index) {
      _index = i;
      Future.microtask(() {
        if (!mounted) return;
        ref.read(glassActiveTabProvider.notifier).state = GlassTab.values[i];
        _fade.value = 0;
        unawaited(GlassMotion.play(MotionName.tabSwitch, controller: _fade, target: 1));
      });
    }
  }

  @override
  void dispose() {
    _recede?.count.removeListener(_onSheets);
    _homeHooks?.call();
    _fade.dispose();
    _overlayFocus.dispose();
    _expandReturn.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    final size = MediaQuery.sizeOf(context);
    final plan = sidebarPlan(frame: GlassFrame.of(context), width: size.width, choice: ref.read(glassSidebarChoiceProvider));
    if (!plan.hasSidebar) return;
    final n = ref.read(glassSidebarChoiceProvider.notifier);
    if (size.width >= kSidebarDockWidth) {
      n.state = !plan.dockedExpanded;
    } else {
      n.state = !plan.overlayOpen;
    }
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    if (n is ScrollUpdateNotification && n.scrollDelta != null) {
      ref.read(glassDockMinimisedProvider.notifier).onScroll(n.scrollDelta!, atTop: n.metrics.pixels <= n.metrics.minScrollExtent, assistive: ref.read(glassAssistiveProvider));
    }
    return false;
  }

  void _select(GlassTab t) => widget.navigationShell.goBranch(t.index);

  void _reselect(GlassTab t) {
    final i = t.index;
    final depth = ref.read(glassDepthProvider)[t] ?? 0;
    if (depth > 0) {
      widget.navigationShell.goBranch(i, initialLocation: true);
    } else {
      GlassScrollTop.scrollToTop();
    }
  }

  /// The tablet frame's accessory (glass 8.0.1): a floating 48 px capsule bottom-centre of the content column, 480 wide at most.
  Widget _floatingAccessory(Size size, double leftPad, double margin) {
    final acc = ref.watch(glassAccessoryProvider);
    final bar = ref.watch(glassBottomBarProvider.select((b) => b != GlassBottomBar.none));
    final show = acc.visible && !bar;
    Future.microtask(() {
      if (mounted && ref.read(glassAccessoryVisibleProvider) != show) ref.read(glassAccessoryVisibleProvider.notifier).state = show;
    });
    if (!show) return const SizedBox.shrink();
    final column = size.width - leftPad - margin * 2;
    final w = column < 480 ? column : 480.0;
    return Positioned(
      left: leftPad + margin + (column - w) / 2,
      bottom: 24,
      width: w,
      height: 48,
      child: SkinGlass(size: Size(w, 48), tier: GlassTierId.t3, debugLabel: 'GlassFloatingAccessory', child: GlassAccessoryBody(state: acc, minimised: false)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final frame = GlassFrame.of(context);
    final phone = frame == GlassFrameKind.phone;
    final choice = ref.watch(glassSidebarChoiceProvider);
    final plan = sidebarPlan(frame: frame, width: size.width, choice: choice);
    final minimised = ref.watch(glassDockMinimisedProvider);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    final path = Uri.tryParse(widget.location)?.path ?? widget.location;
    final tab = GlassTab.values[widget.navigationShell.currentIndex];
    final sheetLarge = GlassRecedeScope.maybeOf(context)?.sheetProgress.value == 1;
    final margin = GlassFrame.screenMargin(context);
    final leftPad = plan.hasSidebar ? sidebarContentStart(expanded: plan.dockedExpanded) - margin : 0.0;
    Future.microtask(() {
      if (!mounted) return;
      final edge = ref.read(glassSidebarEdgeProvider.notifier);
      final want = sidebarEdge(hasSidebar: plan.hasSidebar, expanded: plan.dockedExpanded);
      if (edge.state != want) edge.state = want;
      final reader = ref.read(glassReaderActiveProvider.notifier);
      if (reader.state != isReader(path)) reader.state = isReader(path);
    });

    Widget content = NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: FadeTransition(opacity: _fade, child: widget.navigationShell),
    );
    content = AutoDownloadTrigger(
      onQueued: (n) => showGlassToast(ref, GlassToastSpec(queuedNewChaptersLine(n))),
      child: GlassDownloadsFeed(child: GlassRecede(child: GlassDiveScope(child: Padding(padding: EdgeInsets.only(left: leftPad), child: content)))),
    );

    final sheetUp = (_recede?.count.value ?? 0) > 0;
    final hidden = hidesDock(path) || sheetLarge || sheetUp || keyboard || ref.watch(recommendOrbsUpProvider) || ref.watch(glassSearchOpenProvider);
    final children = <Widget>[
      Positioned.fill(child: content),
      if (phone)
        Positioned.fill(
          child: GlassArrivalReveal(
            child: Stack(
              children: [
                GlassDock(
                  selected: tab,
                  onSelect: _select,
                  onReselect: _reselect,
                  minimised: minimised,
                  hidden: hidden,
                  onSearch: () => openGlassSearch(ref),
                ),
              ],
            ),
          ),
        ),
      if (frame == GlassFrameKind.tablet) _floatingAccessory(size, leftPad, margin),
      if (plan.hasSidebar) ...[
        if (plan.overlayOpen)
          Positioned.fill(
            child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _toggleSidebar, child: const ColoredBox(color: Color(0x66000000))),
          ),
        Positioned.fill(
          child: GlassArrivalReveal(
            child: Stack(
              fit: StackFit.expand,
              children: [
                GlassSidebar(
                expanded: plan.dockedExpanded || plan.overlayOpen,
                overlay: plan.overlayOpen,
                location: widget.location,
                onToggle: _toggleSidebar,
                onNavigated: () {
                  if (plan.overlayOpen) ref.read(glassSidebarChoiceProvider.notifier).state = false;
                },
              ),
              ],
            ),
          ),
        ),
      ],
    ];

    return ValueListenableBuilder<int>(
      valueListenable: GlassMenuBack.open,
      builder: (context, menus, child) => PopScope(
      canPop: widget.navigationShell.currentIndex == 0 && menus == 0 && backParentOf(widget.location, glass: true) == null && !plan.overlayOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (GlassMenuBack.closeTop()) return;
        if (plan.overlayOpen) {
          ref.read(glassSidebarChoiceProvider.notifier).state = false;
          return;
        }
        // A page off a tab root with nothing beneath it (a `go`, a deep link) backs to its parent.
        final parent = backParentOf(widget.location, glass: true);
        if (parent != null) {
          GoRouter.of(context).go(parent);
        } else {
          widget.navigationShell.goBranch(0);
        }
      },
      child: child!,
      ),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () {
            if (plan.overlayOpen) ref.read(glassSidebarChoiceProvider.notifier).state = false;
          },
        },
        child: GlassOverlays(
          hideNewChapters: isReader(path) || path == '/updates',
          bare: hidesDock(path),
          child: GlassToastHost(
            child: GlassCapsuleHost(
              // The recommend orbs (mobile/43): one layer above the navigator for every screen's lifted posters.
              child: GlassRecommendOrbs(
                registry: ref.read(glassRecommendMagnetsProvider),
                child: GlassStreakEventsListener(child: Stack(fit: StackFit.expand, children: children)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

