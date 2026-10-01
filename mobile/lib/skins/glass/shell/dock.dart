import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/downloads/utils/active_download_count.dart';
import 'package:manhwamaniacs/features/updates/providers/unread_count_provider.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/icons/glass_icon.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/badge.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/overlay_queue.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/shell/accessory.dart';
import 'package:manhwamaniacs/skins/glass/shell/accessory_controller.dart';
import 'package:manhwamaniacs/skins/glass/shell/dock_geometry.dart';
import 'package:manhwamaniacs/skins/glass/shell/dock_menus.dart';
import 'package:manhwamaniacs/skins/glass/shell/dock_state.dart';
import 'package:manhwamaniacs/skins/glass/shell/search_orb.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_common.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

const List<GlassIconRole> _tabRoles = [GlassIconRole.home, GlassIconRole.library, GlassIconRole.sources, GlassIconRole.settings];
const List<String> _tabLabels = ['Home', 'Library', 'Sources', 'You'];

/// The droplet's stretch while it moves: `scaleX = 1 + min(|v| / 2000, 0.25)`, `scaleY = 1 / sqrt(scaleX)` (glass 7.15).
({double x, double y}) dropletStretch(double velocityPxPerS) {
  final x = 1 + math.min(velocityPxPerS.abs() / 2000, 0.25).toDouble();
  return (x: x, y: 1 / math.sqrt(x));
}

/// Where a droplet released at [posPx] (tab-space, tab widths) with [velocityPxPerS] lands: the nearest tab of the projection.
int dropletTarget({required double posPx, required double velocityPxPerS, required double tabWidth, int tabs = 4}) {
  final p = project(posPx, velocityPxPerS) / tabWidth;
  return p.round().clamp(0, tabs - 1);
}

/// The dock's badge counts (glass 7.15): Home a dot while updates are unread, Library queued + downloading + failed chapters, You a
/// dot while a letter is new.
class GlassDockBadges {
  const GlassDockBadges({this.homeDot = false, this.libraryCount = 0, this.youDot = false});
  final bool homeDot;
  final int libraryCount;
  final bool youDot;
}

final glassDockBadgesProvider = Provider<GlassDockBadges>((ref) {
  final unread = ref.watch(unreadNotificationCountProvider);
  final downloads = ref.watch(glassActiveDownloadCountProvider);
  final letters = ref.watch(lettersProvider).valueOrNull ?? const <Letter>[];
  return GlassDockBadges(homeDot: unread > 0, libraryCount: downloads, youDot: letters.any((l) => l.state == LetterState.newLetter));
});

/// The floating dock (glass 7.15): a 64 px `glassRegular` capsule with four tabs and a droplet, the 50 px search orb and the
/// accessory, one `SkinGlassGroup` layer. It minimises on scroll, hides in readers, takeovers, full-height sheets and while the
/// keyboard is open, and its droplet follows a drag.
class GlassDock extends ConsumerStatefulWidget {
  const GlassDock({super.key, required this.selected, required this.onSelect, required this.onReselect, required this.minimised, required this.hidden, this.onSearch});
  final GlassTab selected;
  final ValueChanged<GlassTab> onSelect;
  final ValueChanged<GlassTab> onReselect;
  final bool minimised;
  final bool hidden;

  /// The orb's tap (default: push `/search`).
  final VoidCallback? onSearch;

  @override
  ConsumerState<GlassDock> createState() => _GlassDockState();
}

class _GlassDockState extends ConsumerState<GlassDock> with TickerProviderStateMixin {
  late final AnimationController _pos = AnimationController.unbounded(vsync: this, value: widget.selected.index.toDouble());
  late final AnimationController _min = AnimationController(vsync: this, value: widget.minimised ? 1 : 0);
  late final AnimationController _hide = AnimationController(vsync: this, value: widget.hidden ? 1 : 0);
  bool _dragging = false;
  int _scrubTab = -1;
  double _merge = 0;

  @override
  void didUpdateWidget(GlassDock old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected && !_dragging) _moveTo(widget.selected.index);
    if (old.minimised != widget.minimised) unawaited(GlassMotion.play(MotionName.minimise, controller: _min, target: widget.minimised ? 1 : 0));
    if (old.hidden != widget.hidden) unawaited(GlassMotion.play(MotionName.minimise, controller: _hide, target: widget.hidden ? 1 : 0));
  }

  @override
  void dispose() {
    _pos.dispose();
    _min.dispose();
    _hide.dispose();
    super.dispose();
  }

  double _tabWidth = 80;

  void _moveTo(int i, {double velocityPxPerS = 0}) {
    unawaited(GlassMotion.play(MotionName.tabDroplet, controller: _pos, target: i.toDouble(), velocityPxPerS: velocityPxPerS, travelPx: _tabWidth));
  }

  // -- drag ---------------------------------------------------------------------

  void _catch() {
    if (_pos.isAnimating) {
      final c = _pos.catchMotion();
      unawaited(ref.read(glassHapticsProvider).fire(HapticEvent.motionCatch, velocity: c.velocity * _tabWidth));
    }
  }

  void _dragStart(DragStartDetails d) {
    _dragging = true;
    _catch();
    setState(() {});
  }

  void _dragUpdate(DragUpdateDetails d, double dockWidth) {
    final tabW = dockWidth / 4;
    final x = (d.localPosition.dx / tabW - 0.5);
    // Rubber-band at most 18 px past the first and last tab.
    const lo = 0.0, hi = 3.0;
    double v = x;
    if (x < lo) {
      v = lo - rubberband((lo - x) * tabW, 18) / tabW;
    } else if (x > hi) {
      v = hi + rubberband((x - hi) * tabW, 18) / tabW;
    }
    _pos.value = v;
    final tab = v.round().clamp(0, 3);
    if (tab != _scrubTab) {
      _scrubTab = tab;
      unawaited(ref.read(glassHapticsProvider).fire(HapticEvent.navScrub));
    }
    final over = (x - hi) * tabW; // px past the last tab's centre
    final merge = ((over - 20) / 28).clamp(0.0, 1.0);
    if (merge != _merge) setState(() => _merge = merge);
  }

  void _dragEnd(DragEndDetails d, double dockWidth) {
    final tabW = dockWidth / 4;
    final vx = d.velocity.pixelsPerSecond.dx;
    _dragging = false;
    if (_merge > 0.6) {
      setState(() => _merge = 0);
      _moveTo(widget.selected.index);
      (widget.onSearch ?? () => openGlassSearch(ref))();
      return;
    }
    final target = dropletTarget(posPx: _pos.value * tabW + tabW / 2, velocityPxPerS: vx, tabWidth: tabW);
    setState(() => _merge = 0);
    _scrubTab = -1;
    _moveTo(target, velocityPxPerS: vx);
    if (target != widget.selected.index) {
      unawaited(ref.read(glassHapticsProvider).fire(HapticEvent.navChange));
      widget.onSelect(GlassTab.values[target]);
    }
  }

  // -- build --------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final frameW = MediaQuery.sizeOf(context).width - 2 * kDockInset;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final acc = ref.watch(glassAccessoryProvider);
    final bar = ref.watch(glassBottomBarProvider.select((b) => b != GlassBottomBar.none));
    final showAcc = acc.visible && !bar;
    final assistive = ref.watch(glassAssistiveProvider);
    Future.microtask(() {
      if (mounted && ref.read(glassAccessoryVisibleProvider) != showAcc) ref.read(glassAccessoryVisibleProvider.notifier).state = showAcc;
    });
    final badges = ref.watch(glassDockBadgesProvider);

    return AnimatedBuilder(
      animation: Listenable.merge([_min, _hide, _pos]),
      builder: (context, _) {
        final m = _min.value.clamp(0.0, 1.0);
        final dockW = lerpDouble2(frameW - 8 - kSearchOrb, kDockMinHeight, m);
        final dockH = lerpDouble2(kDockHeight, kDockMinHeight, m);
        _tabWidth = dockW / 4;
        final accW = lerpDouble2(frameW, frameW - kDockMinHeight - kSearchOrb - 16, m);
        final accH = lerpDouble2(kAccessoryHeight, kDockMinHeight, m);
        final fullH = kDockHeight + (showAcc ? kAccessoryGap + kAccessoryHeight : 0);
        final groupH = lerpDouble2(fullH, kDockMinHeight, m);
        final hideT = _hide.value.clamp(0.0, 1.0);
        // Fully hidden, the dock leaves the glass registry (its shapes count against the 8-shape budget, glass 15.7).
        if (hideT > 0.98) return const SizedBox.shrink();
        final shapes = <SkinGlassShape>[
          SkinGlassShape(size: Size(dockW, dockH), child: _dockBody(context, dockW, dockH, m, badges, assistive)),
          SkinGlassShape(size: const Size.square(kSearchOrb), shape: const GlassShape.circle(), child: GlassSearchOrbBody(onTap: widget.onSearch ?? () => openGlassSearch(ref))),
          if (showAcc) SkinGlassShape(size: Size(accW, accH), child: GlassAccessoryBody(state: acc, minimised: m > 0.5)),
        ];
        final aligns = <Alignment>[Alignment.bottomLeft, Alignment.bottomRight, if (showAcc) Alignment(0, lerpDouble2(-1, 1, m))];
        return Positioned(
          left: kDockInset,
          right: kDockInset,
          bottom: safeBottom + kDockInset - hideT * (kDockHeight + safeBottom + kDockInset + 80),
          height: groupH,
          child: IgnorePointer(
            ignoring: hideT > 0.5,
            child: Semantics(
              container: true,
              explicitChildNodes: true,
              label: 'Main',
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(child: SkinGlassGroup(shapes: shapes, aligns: aligns, height: groupH, debugLabel: 'GlassDock')),
                  if (_merge > 0) Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _NeckPainter(progress: _merge, dockRight: dockW, orbLeft: frameW - kSearchOrb, y: groupH - kSearchOrb / 2)))),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _dockBody(BuildContext context, double w, double h, double m, GlassDockBadges badges, bool assistive) {
    final minimised = m > 0.5;
    if (minimised) {
      final t = widget.selected;
      return GlassPressable(
        material: GlassMaterial.content,
        semanticsLabel: '${_tabLabels[t.index]}, tab ${t.index + 1} of 4',
        semanticsSelected: true,
        onTap: () => ref.read(glassDockRestoreProvider)(),
        builder: (context, info) => Center(child: _tabIcon(t, true, info.states.pressed)),
      );
    }
    final tabW = w / 4;
    // The droplet is 56 wide at 1x; its labels scale with text (clamped at 1.5, glass 3.3), so it widens with them, within its tab.
    final dropW = math.min(56 * MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.5).scale(11) / 11, tabW - 4);
    return Listener(
      onPointerDown: (_) => _catch(),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: _dragStart,
        onHorizontalDragUpdate: (d) => _dragUpdate(d, w),
        onHorizontalDragEnd: (d) => _dragEnd(d, w),
        child: Stack(
          children: [
            // The droplet: a clear capsule under the active tab.
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _DropletPainter(pos: _pos.value, tabW: tabW, width: dropW, height: h, velocity: _pos.velocity * tabW, lifted: _dragging, tint: gt.colorIris400),
                ),
              ),
            ),
            Row(
              children: [
                for (final t in GlassTab.values)
                  Expanded(
                    child: _DockTab(
                      tab: t,
                      selected: widget.selected == t,
                      badges: badges,
                      onTap: () {
                        if (widget.selected == t) {
                          unawaited(ref.read(glassHapticsProvider).fire(HapticEvent.navReselect));
                          widget.onReselect(t);
                        } else {
                          unawaited(ref.read(glassHapticsProvider).fire(HapticEvent.navChange));
                          ref.read(glassWaveOriginProvider.notifier).state = Offset(globalRectOf(context).left + tabW * (t.index + 0.5), globalRectOf(context).center.dy);
                          widget.onSelect(t);
                        }
                      },
                      onMenu: (anchor) => unawaited(showGlassMenu(context, anchor: anchor, title: glassTabName(t), entries: dockMenuEntries(t, ref, context, anchor))),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabIcon(GlassTab t, bool active, bool pressed) {
    if (t == GlassTab.you) return const GlassMyOrb(size: 24, onDisc: true);
    return GlassIcon(_tabRoles[t.index], selected: active, pressed: pressed, color: active ? gt.colorIris400 : gt.colorOnGlass);
  }
}

double lerpDouble2(double a, double b, double t) => a + (b - a) * t;

class _DockTab extends ConsumerWidget {
  const _DockTab({required this.tab, required this.selected, required this.badges, required this.onTap, required this.onMenu});
  final GlassTab tab;
  final bool selected;
  final GlassDockBadges badges;
  final VoidCallback onTap;
  final void Function(Rect anchor) onMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = _tabLabels[tab.index];
    return GlassPressable(
      material: GlassMaterial.content,
      sink: 0.96,
      minHit: false,
      onTap: onTap,
      onLongPress: () => onMenu(globalRectOf(context)),
      longPressHaptic: HapticEvent.stackOpen,
      semanticsLabel: '$label, tab ${tab.index + 1} of 4',
      semanticsSelected: selected,
      builder: (context, info) {
        final icon = tab == GlassTab.you
            ? const GlassMyOrb(size: 24, onDisc: true)
            : GlassIcon(_tabRoles[tab.index], selected: selected, pressed: info.states.pressed, color: selected ? gt.colorIris400 : gt.colorOnGlass);
        Widget badge(Widget child) {
          if (tab == GlassTab.home && badges.homeDot) return GlassBadged(badge: const GlassBadge.dot(), child: child);
          if (tab == GlassTab.library && badges.libraryCount > 0) return GlassBadged(badge: GlassBadge.count(badges.libraryCount), child: child);
          if (tab == GlassTab.you && badges.youDot) return GlassBadged(badge: const GlassBadge.dot(), child: child);
          return child;
        }

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            badge(SizedBox(width: 24, height: 24, child: Center(child: icon))),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              textScaler: TextScaler.noScaling,
              style: roleStyle(context, gt.typeTabLabel, onGlass: true, wght: selected ? 700 : 600, maxScale: 1.5).copyWith(color: gt.colorOnGlass),
            ),
          ],
        );
      },
    );
  }
}

class _DropletPainter extends CustomPainter {
  const _DropletPainter({required this.pos, required this.tabW, required this.width, required this.height, required this.velocity, required this.lifted, required this.tint});
  final double pos;
  final double tabW;
  final double width;
  final double height;
  final double velocity;
  final bool lifted;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final s = dropletStretch(velocity);
    final lift = lifted ? 1.06 : 1.0;
    final c = Offset((pos + 0.5) * tabW, size.height / 2);
    final rect = Rect.fromCenter(center: c, width: width * s.x * lift, height: 52 * s.y * lift);
    final r = RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2));
    canvas.drawRRect(r, Paint()..color = Color.fromRGBO(255, 255, 255, lifted ? 0.10 : 0.14));
    canvas.drawRRect(r, Paint()..style = PaintingStyle.stroke..strokeWidth = 0.5..color = Color.lerp(const Color(0x40FFFFFF), tint, 0.12)!);
  }

  @override
  bool shouldRepaint(_DropletPainter o) => o.pos != pos || o.velocity != velocity || o.lifted != lifted || o.tabW != tabW || o.width != width;
}

class _NeckPainter extends CustomPainter {
  const _NeckPainter({required this.progress, required this.dockRight, required this.orbLeft, required this.y});
  final double progress;
  final double dockRight;
  final double orbLeft;
  final double y;

  @override
  void paint(Canvas canvas, Size size) {
    // A metaball neck between the droplet at the dock's end and the orb (the gap is 8 px; the neck thins as it lengthens).
    final thick = 26 * progress;
    final r = RRect.fromRectAndRadius(Rect.fromLTRB(dockRight - 12, y - thick / 2, orbLeft + 12, y + thick / 2), Radius.circular(thick / 2));
    canvas.drawRRect(r, Paint()..color = Color.fromRGBO(255, 255, 255, 0.14 * progress));
  }

  @override
  bool shouldRepaint(_NeckPainter o) => o.progress != progress;
}
