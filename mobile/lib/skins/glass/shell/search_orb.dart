import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/features/library/utils/recent_searches.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/icons/glass_icon.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/search_field.dart';
import 'package:manhwamaniacs/skins/glass/screens/search/search_page.dart';
import 'package:manhwamaniacs/skins/glass/shell/focus_policy.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_common.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// Where the orb was when the search opened, so the field can grow out of it and shrink back into it.
final glassSearchOriginProvider = StateProvider<Rect?>((ref) => null);

/// `mobile/38` fills this with the Discover body; the default is the real search body.
final glassDiscoverBodyProvider = StateProvider<Widget Function(BuildContext context, String query)?>((ref) => (context, query) => GlassSearchBody(query: query));

/// True from the moment `/search` starts opening until it starts closing: the shell sinks the dock under it.
final glassSearchOpenProvider = StateProvider<bool>((ref) => false);

/// The 50 px search orb's content (its glass is a shape of the dock's group). A tap records where the orb is, so the
/// field grows out of it, then opens `/search`.
class GlassSearchOrbBody extends ConsumerWidget {
  const GlassSearchOrbBody({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) => GlassPressable(
        material: GlassMaterial.content,
        sink: 0.92,
        shape: const GlassShape.circle(),
        minHit: false,
        onTap: () {
          ref.read(glassSearchOriginProvider.notifier).state = globalRectOf(context);
          onTap();
        },
        semanticsLabel: 'Search',
        tooltip: 'Search',
        builder: (context, info) => const Center(child: GlassIcon(GlassIconRole.search)),
      );
}

/// Opens `/search`. The morph starts from the orb's last tapped rect (or the field's trailing end when it was never tapped).
void openGlassSearch(WidgetRef ref, {String? query}) {
  final loc = query == null || query.isEmpty ? '/search' : '/search?q=${Uri.encodeQueryComponent(query)}';
  unawaited(ref.read(skinRouterProvider).push<void>(loc));
}

/// Open: the orb grows into the capsule along `springMorph` (settled at [kGlassSearchOpen]). Close: a quicker ease back in.
const Duration kGlassSearchOpen = Duration(milliseconds: 420);
const Duration kGlassSearchClose = Duration(milliseconds: 300);

/// Reduce Motion: the whole page cross-fades, nothing moves.
const Duration kGlassSearchFade = Duration(milliseconds: 150);

/// Kept for callers of the old single duration.
const Duration kGlassSearchDuration = kGlassSearchOpen;

const Key kGlassSearchCapsuleKey = ValueKey('glass-search-capsule');
const Key kGlassSearchFadeKey = ValueKey('glass-search-fade');

final Curve _openCurve = SpringCurve(GlassSprings.morph, settleMs: kGlassSearchOpen.inMilliseconds);

/// The `/search` page (a root-navigator, non-opaque route; glass 7.4). Opening: the shell behind blurs and dims, the dock
/// sinks, a capsule springs out of the orb into the bottom field, the field fades in on it and the keyboard rises with it,
/// and the Discover body fades and rises in, section by section. "Cancel" plays it backwards and pops.
class GlassSearchPage extends ConsumerStatefulWidget {
  const GlassSearchPage({super.key});

  /// Runs [q] on the enclosing search page (Recent rows, Trending chips). False when there is no page (a bare body in a test).
  static bool run(BuildContext context, String q) {
    final s = context.findAncestorStateOfType<_GlassSearchPageState>();
    s?._pick(q);
    return s != null;
  }

  @override
  ConsumerState<GlassSearchPage> createState() => _GlassSearchPageState();
}

class _GlassSearchPageState extends ConsumerState<GlassSearchPage> {
  final TextEditingController _q = TextEditingController();
  final FocusNode _focus = FocusNode(debugLabel: 'search field');
  Animation<double>? _route;
  late final StateController<bool> _open = ref.read(glassSearchOpenProvider.notifier);

  @override
  void initState() {
    super.initState();
    final initial = GoRouter.of(context).state.uri.queryParameters['q']; // the top route right now: this one
    if (initial != null) _q.text = initial;
    // Focus as the morph starts, so the keyboard rises with the capsule rather than after it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
    Future.microtask(() {
      if (mounted) _open.state = true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final a = ModalRoute.of(context)?.animation;
    if (a != _route) {
      _route?.removeStatusListener(_status);
      _route = a?..addStatusListener(_status);
    }
  }

  void _status(AnimationStatus s) {
    // A pop from a router rebuild reverses mid-build; providers change after the frame.
    if (s == AnimationStatus.reverse) {
      final open = _open;
      Future.microtask(() {
        if (open.mounted) open.state = false;
      });
    }
  }

  @override
  void dispose() {
    _route?.removeStatusListener(_status);
    final open = _open;
    Future.microtask(() {
      if (open.mounted) open.state = false;
    });
    _q.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _current => ModalRoute.of(context)?.isCurrent ?? false;

  /// Keeps the URL in step with the field (deep links, restoration); the body reads the field, not the URL.
  void _write(String q) {
    if (!_current) return;
    final scope = GoRouterState.of(context).uri.queryParameters['scope'];
    final qp = <String, String>{if (q.isNotEmpty) 'q': q, if (scope != null) 'scope': scope};
    GoRouter.of(context).replace<void>(Uri(path: '/search', queryParameters: qp.isEmpty ? null : qp).toString());
  }

  void _query(String q) {
    if (!mounted) return;
    setState(() {});
    _write(q);
  }

  void _record(String q) {
    final t = q.trim();
    if (t.length < 2) return;
    unawaited(writeRecentSearch(ref.read(sharedPrefsProvider), t, profileId: ref.read(activeProfileProvider)?.id, gateOpen: ref.read(matureGateOpenProvider)));
  }

  void _pick(String q) {
    if (!_current) return;
    _q.value = TextEditingValue(text: q, selection: TextSelection.collapsed(offset: q.length));
    _focus.unfocus();
    _record(q);
    _query(q);
  }

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context)!.animation!;
    final reduced = ref.watch(glassReducedProvider);
    final body = ref.watch(glassDiscoverBodyProvider);
    final origin = ref.watch(glassSearchOriginProvider);
    final size = MediaQuery.sizeOf(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final fieldRect = Rect.fromLTWH(kFieldInset, size.height - (keyboard > 0 ? keyboard + 12 : safeBottom + kFieldInset) - 50, size.width - 2 * kFieldInset, 50);
    final orb = origin == null || origin.isEmpty ? Rect.fromLTWH(fieldRect.right - 50, fieldRect.top, 50, 50) : origin;
    // Spring out, ease back in; under Reduce Motion everything sits at rest and only the page's opacity moves.
    double morph() {
      if (reduced) return 1;
      final v = route.value.clamp(0.0, 1.0);
      return route.status == AnimationStatus.reverse ? Curves.easeInCubic.transform(v) : _openCurve.transform(v);
    }

    double settled(double v) => v.clamp(0.0, 1.0);
    return Material(
      type: MaterialType.transparency,
      child: GlassFocusBandsScope(
        top: MediaQuery.paddingOf(context).top,
        bottom: size.height - fieldRect.top,
        child: FadeTransition(
          key: kGlassSearchFadeKey,
          opacity: reduced ? route : kAlwaysCompleteAnimation,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // The shell recedes: blurred and dimmed behind, and nothing behind takes a tap.
              AnimatedBuilder(
                animation: route,
                builder: (context, _) {
                  final v = reduced ? 1.0 : settled(route.value);
                  return BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 18 * v, sigmaY: 18 * v),
                    child: ColoredBox(color: Color.fromRGBO(0, 0, 0, 0.45 * v)),
                  );
                },
              ),
              // The page has no visible title (the field is the page); screen readers get the one level-1 heading (G2).
              Positioned(left: 0, top: 0, width: 1, height: 1, child: Semantics(header: true, headingLevel: 1, label: 'Search', child: const SizedBox.expand())),
              if (body != null) body(context, _q.text),
              // The morph: a frosted capsule springs from the orb to the field, then hands over to the real glass.
              AnimatedBuilder(
                animation: route,
                builder: (context, _) {
                  final v = morph();
                  final rect = Rect.lerp(orb, fieldRect, v)!;
                  final fade = reduced ? 0.0 : 1 - const Interval(0.55, 1).transform(settled(v));
                  return Positioned.fromRect(
                    rect: rect,
                    child: IgnorePointer(
                      child: Opacity(
                        key: kGlassSearchCapsuleKey,
                        opacity: fade,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(rect.height / 2),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: ColoredBox(color: gt.colorFill2),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Positioned.fromRect(
                rect: fieldRect,
                child: AnimatedBuilder(
                  animation: route,
                  builder: (context, child) => Opacity(opacity: reduced ? 1 : const Interval(0.35, 0.8).transform(settled(morph())), child: child),
                  child: GlassSearchField(
                    variant: GlassSearchVariant.bottom,
                    ridesKeyboard: false,
                    controller: _q,
                    focusNode: _focus,
                    onQuery: _query,
                    onSubmitted: _record,
                    onCancel: () {
                      if (_current) unawaited(Navigator.of(context).maybePop());
                    },
                    onCollapse: () {
                      if (_current) unawaited(Navigator.of(context).maybePop());
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fades and lifts one section of the search body in after the capsule, [i] steps (55 ms each) behind the first.
/// Under Reduce Motion, or outside a route, it is the child as is.
Widget glassSearchStagger(BuildContext context, int i, Widget child, {required bool reduced}) {
  final a = ModalRoute.of(context)?.animation;
  if (reduced || a == null) return child;
  final begin = (0.2 + 0.13 * i).clamp(0.0, 0.7);
  final curve = Interval(begin, 1, curve: Curves.easeOutCubic);
  return AnimatedBuilder(
    animation: a,
    child: child,
    builder: (context, child) {
      final v = curve.transform(a.value.clamp(0.0, 1.0));
      return Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 14 * (1 - v)), child: child));
    },
  );
}

const double kFieldInset = 21;
