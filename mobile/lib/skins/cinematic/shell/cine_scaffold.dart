import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/auth/providers/session_offline_provider.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/nav_map.dart';
import 'package:manhwamaniacs/skins/cinematic/navigation.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_banner_strip.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_content_mode.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/running_head.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

export 'package:manhwamaniacs/skins/cinematic/shell/running_head.dart' show CineBack, CineHeadAction;

/// What a screen inside [CineScaffold] can read: the height its running head (and first-run note)
/// takes, for screens that paint art under the bar.
class CineScaffoldScope extends InheritedWidget {
  const CineScaffoldScope({super.key, required this.topExtent, required super.child});
  final double topExtent;

  static double topExtentOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CineScaffoldScope>()?.topExtent ?? 0;

  @override
  bool updateShouldNotify(CineScaffoldScope o) => o.topExtent != topExtent;
}

/// Keyboard focus is never left out of view or under the running head (cinematic 14.4, WCAG 2.4.11): after the frame, the nearest
/// vertical scroller cuts the focused control into view, clear of the head, by the distance plus 8 px. Flutter's forward traversal
/// never scrolls back, so a Tab that wraps to the top of a scrolled page (the Numbers range tabs, a long form) needs this.
/// [CineAppFrame] calls it on every keyboard focus change.
void cineRevealFocus(FocusNode node) {
  final ctx = node.context;
  if (ctx == null) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!ctx.mounted) return;
    final ro = ctx.findRenderObject();
    final scrollable = Scrollable.maybeOf(ctx, axis: Axis.vertical);
    if (ro is! RenderBox || !ro.attached || scrollable == null) return;
    final box = scrollable.context.findRenderObject();
    if (box is! RenderBox || !box.attached) return;
    final view = box.localToGlobal(Offset.zero) & box.size;
    // The running head floats over the top of its scaffold's body.
    final scope = ctx.getElementForInheritedWidgetOfExactType<CineScaffoldScope>();
    final scopeBox = scope?.findRenderObject();
    final head = scope != null && scopeBox is RenderBox && scopeBox.attached
        ? scopeBox.localToGlobal(Offset.zero).dy + (scope.widget as CineScaffoldScope).topExtent
        : view.top;
    final rect = ro.localToGlobal(Offset.zero) & ro.size;
    final shift = cineRevealShift(focused: rect, top: math.max(view.top, head), bottom: view.bottom);
    if (shift == 0) return;
    final pos = scrollable.position;
    final target = (pos.pixels + shift).clamp(pos.minScrollExtent, pos.maxScrollExtent);
    // A cut, not a glide: this skin cuts and dissolves, nothing springs.
    if (target != pos.pixels) pos.jumpTo(target);
  });
  WidgetsBinding.instance.ensureVisualUpdate();
}

/// How far a scroller must move so [focused] sits between [top] and [bottom] with 8 px to spare; negative scrolls up. 0 when it fits.
double cineRevealShift({required Rect focused, required double top, required double bottom}) {
  if (focused.top < top) return focused.top - top - 8;
  if (focused.bottom > bottom) return focused.bottom - bottom + 8;
  return 0;
}

/// Pads [child] down to just below the running head. It reads the extent where it is built, so it
/// must sit inside [CineScaffold.body]: a screen's own build context is above the scaffold and
/// sees only the status bar, which put mastheads under the head.
class CineBelowHead extends StatelessWidget {
  const CineBelowHead({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(padding: EdgeInsets.only(top: CineScaffoldScope.topExtentOf(context)), child: child);
}

/// The section folio the previous branch carried, so a new masthead's kicker folio rolls from it
/// with `CineFolioFlip`.
class CineSectionFolio extends InheritedWidget {
  const CineSectionFolio({super.key, required this.previous, required this.current, required super.child});
  final int? previous;
  final int? current;

  static CineSectionFolio? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<CineSectionFolio>();

  @override
  bool updateShouldNotify(CineSectionFolio o) => o.previous != previous || o.current != current;
}

/// The page scaffold every app-frame screen uses (cinematic 7.13, 8.0.9, 8.33.4, 14.4).
class CineScaffold extends ConsumerStatefulWidget {
  const CineScaffold({
    super.key,
    required this.body,
    this.runningTitle,
    this.back,
    this.trailing = const [],
    this.overArt = false,
    this.customRunningHead = false,
    this.contentModeChip = false,
    this.tabletLayout = false,
    this.firstRunNote = true,
    this.mastheadFocusNode,
    this.mastheadKey,
    this.location,
  });

  final Widget body;

  /// Defaults to the title `nav_map.dart` gives the route.
  final String? runningTitle;

  /// Null on branch roots; pushed screens pass `const CineBack()`. When neither is given the
  /// scaffold shows a back arrow whenever the route can pop.
  final CineBack? back;
  final List<CineHeadAction> trailing;
  final bool overArt;

  /// The screen paints its own running head (Tonight's trailer scrub); the rest of the scaffold
  /// stays.
  final bool customRunningHead;
  final bool contentModeChip;

  /// Opt out of the centred 720 px column from 600 px width.
  final bool tabletLayout;
  final bool firstRunNote;
  final FocusNode? mastheadFocusNode;

  /// The masthead's key: the running title cross-fades in once it scrolls under the bar.
  final GlobalKey? mastheadKey;

  /// Overrides the location read from the router (tests, gallery).
  final String? location;

  @override
  ConsumerState<CineScaffold> createState() => _CineScaffoldState();
}

class _CineScaffoldState extends ConsumerState<CineScaffold> {
  bool _solid = false;
  bool _titleVisible = true;
  double _topExtent = 0;
  final GlobalKey _headKey = GlobalKey();
  final FocusNode _ownMasthead = FocusNode(debugLabel: 'cine-masthead');
  Animation<double>? _route;

  // Offline edition (7.13).
  CineEditionPhase _edition = CineEditionPhase.none;
  Timer? _editionTimer;

  String get _location {
    if (widget.location != null) return widget.location!;
    try {
      return GoRouterState.of(context).uri.toString();
    } catch (_) {
      return '/';
    }
  }

  @override
  void initState() {
    super.initState();
    _titleVisible = widget.mastheadKey == null;
    if (ref.read(sessionOfflineProvider)) _edition = CineEditionPhase.glyph;
    ref.listenManual<bool>(sessionOfflineProvider, (was, offline) => _onOffline(offline));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final r = ModalRoute.of(context)?.animation;
    if (r != _route) {
      _route?.removeStatusListener(_routeStatus);
      _route = r;
      if (r == null || r.isCompleted) {
        _focusMasthead();
      } else {
        r.addStatusListener(_routeStatus);
      }
    }
  }

  void _routeStatus(AnimationStatus s) {
    if (s == AnimationStatus.completed) _focusMasthead();
  }

  /// Route focus (14.4): the new screen's level-1 heading takes focus once the route has landed.
  void _focusMasthead() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) (widget.mastheadFocusNode ?? _ownMasthead).requestFocus();
    });
  }

  void _onOffline(bool offline) {
    _editionTimer?.cancel();
    if (offline) {
      setState(() => _edition = CineEditionPhase.badge);
      _editionTimer = Timer(CineDur.holdEdition, () {
        if (mounted) setState(() => _edition = CineEditionPhase.glyph);
      });
    } else if (_edition != CineEditionPhase.none) {
      setState(() => _edition = CineEditionPhase.backOnline);
      _editionTimer = Timer(CineDur.holdBrief, () {
        if (mounted) setState(() => _edition = CineEditionPhase.none);
      });
    }
  }

  @override
  void dispose() {
    _route?.removeStatusListener(_routeStatus);
    _editionTimer?.cancel();
    _ownMasthead.dispose();
    super.dispose();
  }

  bool _recheckScheduled = false;
  double _pixels = 0;

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    _pixels = n.metrics.pixels;
    // Geometry is final only after the frame: measure the masthead against the bar then.
    if (!_recheckScheduled) {
      _recheckScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _recheckScheduled = false;
        if (mounted) _recheck();
      });
    }
    return false;
  }

  void _recheck() {
    final solid = _pixels > 24;
    var titleVisible = _titleVisible;
    final key = widget.mastheadKey;
    if (key != null) {
      final mast = key.currentContext?.findRenderObject();
      final head = _headKey.currentContext?.findRenderObject();
      if (mast is RenderBox && head is RenderBox && mast.attached && head.attached) {
        final mastBottom = mast.localToGlobal(Offset(0, mast.size.height)).dy;
        final headBottom = head.localToGlobal(Offset(0, head.size.height)).dy;
        titleVisible = mastBottom <= headBottom;
      }
    }
    if (solid != _solid || titleVisible != _titleVisible) {
      setState(() {
        _solid = solid;
        _titleVisible = titleVisible;
      });
    }
  }

  void _openEditionSheet() {
    showCineSheet<void>(
      context,
      kicker: 'OFFLINE EDITION',
      title: 'Offline edition',
      builder: (ctx) {
        final c = ctx.cine;
        return Padding(
          padding: EdgeInsets.symmetric(vertical: c.space4), // the sheet body sets the gutter
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            CineRoleText(
              "The server isn't reachable right now. Chapters you saved still open on this device.",
              c.typeBody,
              color: c.colorInk60,
            ),
            SizedBox(height: c.space4),
            CineButton(
              label: 'Go to Downloads',
              onPressed: () {
                Navigator.of(ctx).maybePop();
                goSection(context, 3);
              },
            ),
          ],),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = _location;
    final info = navInfoFor(loc);
    final title = widget.runningTitle ?? info.title;
    final mq = MediaQuery.of(context);
    final showBack = widget.back != null || (info.branch == null && (GoRouter.maybeOf(context)?.canPop() ?? false));
    final back = showBack ? (widget.back ?? const CineBack()) : null;

    // Nothing followed yet: known only once the follow cache has answered.
    final note = widget.firstRunNote && info.firstRunNote && ref.watch(_followCountProvider) == 0;

    final head = widget.customRunningHead
        ? const SizedBox.shrink()
        : CineRunningHead(
            key: _headKey,
            title: title,
            titleVisible: _titleVisible,
            back: back,
            trailing: widget.trailing,
            chip: widget.contentModeChip ? const CineContentModeChip() : null,
            solid: _solid,
            overArt: widget.overArt,
            edition: _edition,
            onEditionGlyph: _openEditionSheet,
            titleFocusNode: widget.mastheadFocusNode == null ? _ownMasthead : null,
          );

    final tablet = mq.size.width >= 600 && !widget.tabletLayout;
    final headBase = cineHitMin(context) + mq.viewPadding.top;

    Widget content = widget.body;
    if (tablet) {
      content = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: content),
      );
    }
    if (mq.size.width >= 600) {
      // The 32 px tablet margin becomes max(32, side inset + 8); screens read it through the grid.
      content = MediaQuery(
        data: mq.copyWith(
          padding: mq.padding.copyWith(
            left: math.max(mq.padding.left, mq.viewPadding.left),
            right: math.max(mq.padding.right, mq.viewPadding.right),
          ),
        ),
        child: content,
      );
    }
    final topExtent = math.max(_topExtent, widget.customRunningHead ? 0.0 : headBase);
    if (!widget.overArt && !widget.customRunningHead) {
      content = MediaQuery(
        data: MediaQuery.of(context).copyWith(padding: MediaQuery.of(context).padding.copyWith(top: topExtent)),
        child: content,
      );
    }

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: '$title · ManhwaManiacs',
      child: CineScaffoldScope(
        topExtent: topExtent,
        child: Material(
          color: const Color(0xFF000000),
          child: Stack(children: [
            Positioned.fill(child: NotificationListener<ScrollNotification>(onNotification: _onScroll, child: content)),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _Measure(
                onSize: (h) {
                  if ((h - _topExtent).abs() > 0.5) setState(() => _topExtent = h);
                },
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  head,
                  if (note)
                    CineBannerStrip(
                      kicker: 'NOTHING FOLLOWED YET',
                      line: 'Follow a series from Discover to start your shelf.',
                      tone: CineBannerTone.plain,
                      actions: [CineBannerAction('Discover', () => goSection(context, 2))],
                    ),
                ],),
              ),
            ),
          ],),
        ),
      ),
    );
  }
}

/// How many series the active profile follows, for the first-run note. Null while unknown.
final _followCountProvider = Provider.autoDispose<int?>(
  (ref) => ref.watch(updatesProvider.select((s) => s.valueOrNull?.followed.length)),
);

class _Measure extends StatefulWidget {
  const _Measure({required this.onSize, required this.child});
  final ValueChanged<double> onSize;
  final Widget child;

  @override
  State<_Measure> createState() => _MeasureState();
}

class _MeasureState extends State<_Measure> {
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = context.findRenderObject();
      if (box is RenderBox && box.hasSize) widget.onSize(box.size.height);
    });
    return widget.child;
  }
}
