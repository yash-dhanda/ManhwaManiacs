import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/cine_icon.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/nav_map.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

class _Tab {
  const _Tab(this.label, this.role);
  final String label;
  final CineIconRole role;
}

const _tabs = [
  _Tab('TONIGHT', CineIconRole.home),
  _Tab('LIBRARY', CineIconRole.library),
  _Tab('DISCOVER', CineIconRole.discover),
  _Tab('DOWNLOADS', CineIconRole.downloads),
  _Tab('INDEX', CineIconRole.indexRole),
];

/// The badge text: the count, "99+" past 99.
String thumbBadgeText(int n) => n > 99 ? '99+' : '$n';

/// The spoken label of a tab: `Library, 3 new`.
String thumbTabSemantics(int index, int badge) {
  final name = _tabs[index].label[0] + _tabs[index].label.substring(1).toLowerCase();
  if (badge <= 0) return name;
  return index == 3 ? '$name, $badge' : '$name, $badge new';
}

/// The phone thumb index (cinematic 7.14), a pure view: height 56 + the bottom inset, `#000`, a
/// 1 px `rule.1` top; five cells (an icon 24 above the label in `typeNav`, the fixed-cell rule);
/// the active cell has `ink.100` Fill icon and label and the 24 x 2 px `spot` thumb notch on its
/// top edge, which slides between cells with Rule slide (320 ms `settle`; reduced: fades).
class CineThumbIndex extends StatefulWidget {
  const CineThumbIndex({super.key, required this.active, this.badges = const [0, 0, 0, 0, 0], required this.onSelect, this.onLongPress});

  final int active;

  /// One count per tab; 0 hides the badge.
  final List<int> badges;
  final ValueChanged<int> onSelect;

  /// Only Library, Downloads and Index have a long-press.
  final ValueChanged<int>? onLongPress;

  static const double height = 56;

  @override
  State<CineThumbIndex> createState() => _CineThumbIndexState();
}

class _CineThumbIndexState extends State<CineThumbIndex> {
  @override
  void didUpdateWidget(CineThumbIndex old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active && !CineMotion.reduced(context)) {
      final h = CineMotion.track(MotionName.ruleSlide, 320);
      Timer(const Duration(milliseconds: 320), h.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final mq = MediaQuery.of(context);
    final reduced = CineMotion.reduced(context);
    final bottom = mq.viewPadding.bottom;
    final margin = c.space4;
    final sideL = mq.viewPadding.left + 8 > margin ? mq.viewPadding.left + 8 : 0.0;
    final sideR = mq.viewPadding.right + 8 > margin ? mq.viewPadding.right + 8 : 0.0;
    return Semantics(
      container: true,
      label: 'Sections',
      child: Container(
        height: CineThumbIndex.height + bottom,
        decoration: BoxDecoration(color: const Color(0xFF000000), border: Border(top: c.ruleHair)),
        padding: EdgeInsets.fromLTRB(sideL, 0, sideR, bottom),
        child: LayoutBuilder(builder: (context, box) {
          final cell = box.maxWidth / _tabs.length;
          return Stack(children: [
            if (reduced)
              for (var i = 0; i < _tabs.length; i++)
                Positioned(
                  left: cell * i + (cell - 24) / 2,
                  top: 0,
                  child: AnimatedOpacity(
                    opacity: i == widget.active ? 1 : 0,
                    duration: CineDur.reduced,
                    child: Container(width: 24, height: 2, color: c.colorSpot),
                  ),
                )
            else
              AnimatedPositioned(
                duration: CineDur.column,
                curve: CineCurves.settle,
                left: cell * widget.active + (cell - 24) / 2,
                top: 0,
                child: Container(width: 24, height: 2, color: c.colorSpot),
              ),
            Row(children: [
              for (var i = 0; i < _tabs.length; i++)
                Expanded(
                  child: _Cell(
                    index: i,
                    active: i == widget.active,
                    badge: i < widget.badges.length ? widget.badges[i] : 0,
                    onTap: () => widget.onSelect(i),
                    onLongPress: widget.onLongPress == null || i == 0 || i == 2 ? null : () => widget.onLongPress!(i),
                  ),
                ),
            ],),
          ],);
        },),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.index, required this.active, required this.badge, required this.onTap, required this.onLongPress});
  final int index, badge;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final tab = _tabs[index];
    final color = active ? c.colorInk100 : c.colorInk60;
    return Semantics(
      button: true,
      selected: active,
      label: thumbTabSemantics(index, badge),
      excludeSemantics: true,
      onTap: onTap,
      child: CinePressable(
        hit: false,
        onTap: onTap,
        onLongPress: onLongPress,
        builder: (context, st) => SizedBox(
          height: CineThumbIndex.height,
          child: Stack(alignment: Alignment.center, children: [
            Column(mainAxisSize: MainAxisSize.min, children: [
              CineIcon(tab.role, weight: active ? CineIconWeight.fill : CineIconWeight.light, color: st.hovered && !active ? c.colorInk100 : color),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: CineRoleText(tab.label, c.typeNav, color: color, fixedCell: true, maxLines: 1),
              ),
            ],),
            if (badge > 0)
              Positioned(
                top: 6,
                left: 0,
                right: 0,
                child: Align(
                  alignment: const Alignment(0.34, 0),
                  child: _Badge(text: thumbBadgeText(badge)),
                ),
              ),
          ],),
        ),
      ),
    );
  }
}

/// A `spot` square with `#000` Plex Mono 10 (capped at 1.3), min 16 x 16.
class _Badge extends StatelessWidget {
  const _Badge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final scale = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
    final line = scale.scale(12);
    return Container(
      constraints: BoxConstraints(minWidth: 16, minHeight: line > 16 ? line : 16),
      padding: const EdgeInsets.symmetric(horizontal: 3),
      color: c.colorSpot,
      // Not `alignment:`: under the cell's loose width that stretched the square into a bar
      // across the whole tab, over its icon.
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: Text(
          text,
          maxLines: 1,
          textScaler: scale,
          style: CineText.literal(context, CineFace.plexMono, 10, 12, wght: 600).copyWith(color: const Color(0xFF000000)),
        ),
      ),
    );
  }
}

/// A screen's primary scroll controller, registered so the first tap on its active tab scrolls
/// it to the top (400 ms `durGlide` `settle`; reduced: a jump).
class CineScrollRegistry {
  final Map<int, List<ScrollController>> _byBranch = {};

  void register(int branch, ScrollController c) => (_byBranch[branch] ??= []).add(c);

  void unregister(int branch, ScrollController c) => _byBranch[branch]?.remove(c);

  /// True when something scrolled.
  bool scrollToTop(int branch, {required bool reduced}) {
    final list = _byBranch[branch];
    if (list == null) return false;
    for (final c in list.reversed) {
      if (!c.hasClients || c.offset <= 0) continue;
      if (reduced) {
        c.jumpTo(0);
      } else {
        c.animateTo(0, duration: CineDur.glide, curve: CineCurves.settle);
      }
      return true;
    }
    return false;
  }
}

final cineScrollRegistryProvider = Provider<CineScrollRegistry>((ref) => CineScrollRegistry(), name: 'cineScrollRegistry');

/// Wrap a screen's primary [controller] in this so its tab can scroll it to the top.
class CineScrollToTop extends ConsumerStatefulWidget {
  const CineScrollToTop({super.key, required this.controller, required this.child, this.location});
  final ScrollController controller;
  final Widget child;

  /// Overrides the location used to find the branch (tests).
  final String? location;

  @override
  ConsumerState<CineScrollToTop> createState() => _CineScrollToTopState();
}

class _CineScrollToTopState extends ConsumerState<CineScrollToTop> {
  int? _branch;
  late final CineScrollRegistry _registry = ref.read(cineScrollRegistryProvider);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_branch != null) return;
    final loc = widget.location ?? _routeLocation(context);
    _branch = navInfoFor(loc).branch;
    if (_branch != null) _registry.register(_branch!, widget.controller);
  }

  @override
  void dispose() {
    if (_branch != null) _registry.unregister(_branch!, widget.controller);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

String _routeLocation(BuildContext context) {
  try {
    return GoRouterState.of(context).uri.toString();
  } catch (_) {
    return '/';
  }
}
