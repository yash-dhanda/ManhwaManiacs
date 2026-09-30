import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/stack/back_menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/stack/route_snapshot.dart';
import 'package:manhwamaniacs/skins/glass/primitives/stack/stack_overview_math.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// Opens the overview, or its flat menu under Reduce Motion or a screen reader (glass 7.37). [levels] is the current tab's stack,
/// oldest first, the current screen last. `mobile/29` calls this from a long-press on Back and `Ctrl+\` / `⌘\`.
Future<void> openGlassStackOverview(
  BuildContext context,
  WidgetRef ref, {
  required List<GlassRouteSnapshot> levels,
  required Rect backButtonRect,
  required String tabName,
  required void Function(GlassRouteSnapshot level) onPick,
  void Function(GlassRouteSnapshot level)? onRemove,
  Widget Function(GlassRouteSnapshot level)? leadingFor,
}) {
  if (levels.length <= 1) return Future.value();
  if (ref.read(glassMotionPrefsProvider).reduced || ref.read(glassAssistiveProvider)) {
    return showGlassBackMenu(context, anchor: backButtonRect, levels: levels, tabName: tabName, onPick: onPick, leadingFor: leadingFor);
  }
  final done = Completer<void>();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => GlassStackOverview(
      levels: levels,
      onPick: (l) {
        entry.remove();
        done.complete();
        onPick(l);
      },
      onRemove: (l) {
        entry.remove();
        done.complete();
        onRemove?.call(l);
      },
      onClose: () {
        entry.remove();
        if (!done.isCompleted) done.complete();
      },
    ),
  );
  Overlay.of(context, rootOverlay: true).insert(entry);
  return done.future;
}

/// The stack overview (glass 7.37): the current tab's levels fan in 3D on `springSmooth` (Stack fan): each card its snapshot at
/// scale 0.62, `rotateX(14 deg)` about its bottom edge with perspective 0.0012, radius 26, spaced by 28 % of its height, deepest at
/// the top, the current screen at the bottom; a 0.5 px strata rim along the top edge in the level's tint, its title and its depth
/// number; `dimModal` behind. Tap a card: it comes forward on `springZoom` while the newer levels drop away front to back 40 ms
/// apart, then [onPick]. Swipe a card sideways past 40 % of its width to remove it and every newer level ([onRemove]). Keys: up and
/// down move, Enter picks, Delete removes, Esc closes. One overlay; the cards are images, not glass.
class GlassStackOverview extends ConsumerStatefulWidget {
  const GlassStackOverview({super.key, required this.levels, required this.onPick, required this.onRemove, required this.onClose});
  final List<GlassRouteSnapshot> levels;
  final void Function(GlassRouteSnapshot level) onPick;
  final void Function(GlassRouteSnapshot level) onRemove;
  final VoidCallback onClose;

  @override
  ConsumerState<GlassStackOverview> createState() => _GlassStackOverviewState();
}

class _GlassStackOverviewState extends ConsumerState<GlassStackOverview> with TickerProviderStateMixin {
  late final AnimationController _fan;
  late final AnimationController _leave;
  final FocusNode _focus = FocusNode(debugLabel: 'GlassStackOverview');
  final Map<int, double> _drag = {};
  int _focused = 0;
  int? _picked;
  bool _removing = false;
  static const int _leaveMs = 800;

  int get _n => widget.levels.length;

  @override
  void initState() {
    super.initState();
    _fan = AnimationController(vsync: this);
    _leave = AnimationController(vsync: this, duration: const Duration(milliseconds: _leaveMs));
    _focused = _n - 1;
    glassFire(ref, HapticEvent.stackOpen);
    glassSound(ref, SoundEvent.stackOpen);
    unawaited(GlassMotion.play(MotionName.stackFan, controller: _fan, target: 1));
    WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _focus.requestFocus() : null);
  }

  @override
  void dispose() {
    _fan.dispose();
    _leave.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _leaveWith(int index, {required bool remove}) async {
    if (_picked != null) return;
    setState(() {
      _picked = index;
      _removing = remove;
    });
    if (remove) {
      glassFire(ref, HapticEvent.thresholdCross);
    } else {
      glassFire(ref, HapticEvent.stackPick);
      if (index == 0) glassSound(ref, SoundEvent.navRoot);
    }
    if (ref.read(glassMotionPrefsProvider).reduced) {
      _leave.value = 1;
    } else {
      await _leave.forward();
    }
    if (!mounted) return;
    final level = widget.levels[index];
    remove ? widget.onRemove(level) : widget.onPick(level);
  }

  KeyEventResult _key(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.arrowUp) {
      setState(() => _focused = math.max(0, _focused - 1));
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowDown) {
      setState(() => _focused = math.min(_n - 1, _focused + 1));
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      unawaited(_leaveWith(_focused, remove: false));
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.delete || k == LogicalKeyboardKey.backspace) {
      if (_focused > 0) unawaited(_leaveWith(_focused, remove: true));
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.escape) {
      widget.onClose();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final slots = stackSlots(_n);
    final cs = cardSize(size.width, size.height);
    final offsets = cardOffsets(slots.count, cs.height, available: size.height - pad.top - pad.bottom - 48);
    final baseTop = pad.top + 24.0;
    final bottomTop = baseTop + (offsets.isEmpty ? 0 : offsets.last);
    return Focus(
      focusNode: _focus,
      onKeyEvent: _key,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        scopesRoute: true,
        namesRoute: true,
        label: 'Stack overview',
        child: AnimatedBuilder(
          animation: Listenable.merge([_fan, _leave]),
          builder: (context, _) {
            final fan = _fan.value.clamp(0.0, 1.2);
            final t = _leave.value * _leaveMs;
            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _picked == null ? widget.onClose : null,
                    child: ColoredBox(color: Color.lerp(const Color(0x00000000), GlassColors.dimModal, fan.clamp(0.0, 1.0))!),
                  ),
                ),
                for (var s = 0; s < slots.count; s++) ..._card(context, s, slots, size, cs, offsets[s] + baseTop, bottomTop, fan, t, offsets.length > 1 ? offsets[1] : cs.height),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _card(BuildContext context, int slot, StackSlots slots, Size screen, ({double width, double height}) cs, double top, double bottomTop, double fan, double tMs, double spacing) {
    final compress = slots.earlier > 0 && slot == 0;
    final index = compress ? 0 : slots.first + (slots.earlier > 0 ? slot - 1 : slot);
    final level = widget.levels[index];
    final left = (screen.width - cs.width) / 2 + (_drag[index] ?? 0);
    // The fan opens from all cards stacked at the current screen's place.
    var y = bottomTop + (top - bottomTop) * fan.clamp(0.0, 1.0);
    final scale = 1 / kCardScale + (1 - 1 / kCardScale) * fan.clamp(0.0, 1.0);
    var tilt = kFanDegrees * math.pi / 180 * fan.clamp(0.0, 1.0);
    var opacity = 1.0;
    var w = cs.width, h = cs.height;
    final picked = _picked;
    var x = left;
    if (picked != null) {
      if (!_removing && index == picked) {
        final z = SpringCurve(gt.springZoom).transform((tMs / 558).clamp(0.0, 1.0));
        x = left + (0 - left) * z;
        y = y + (0 - y) * z;
        w = cs.width + (screen.width - cs.width) * z;
        h = cs.height + (screen.height - cs.height) * z;
        tilt *= 1 - z;
      }
      if (index > picked) {
        // Newer levels drop away, front to back, 40 ms apart.
        final delay = (_n - 1 - index) * 40;
        final d = SpringCurve(gt.springDismiss).transform(((tMs - delay) / 378).clamp(0.0, 1.0));
        y += screen.height * d;
        opacity = 1 - d;
      } else if (_removing && index == picked) {
        final d = SpringCurve(gt.springDismiss).transform((tMs / 378).clamp(0.0, 1.0));
        x += screen.width * d;
        opacity = 1 - d;
      }
    }
    final focused = _focused == index && picked == null;
    final image = level.image;
    final radius = BorderRadius.circular(kCardRadius);
    final body = ClipRSuperellipse(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (image != null)
            RawImage(image: image, fit: BoxFit.cover)
          else
            ColoredBox(color: Color.alphaBlend(level.rimTint.withValues(alpha: 0.22), gt.colorSurface1)),
          Positioned(left: kCardRadius, right: kCardRadius, top: 0, height: 0.5, child: ColoredBox(color: level.rimTint)),
          Positioned(
            left: 16,
            right: 16,
            top: 12,
            child: Row(
              children: [
                Expanded(child: GlassText(compress ? '+${slots.earlier} earlier' : level.title, role: gt.typeSubhead, wght: 600, maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (!compress) GlassText('${level.depth}', role: gt.typeMono, color: gt.colorLabel3),
              ],
            ),
          ),
          if (focused) IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(borderRadius: radius, border: Border.all(color: gt.colorIris400, width: 2)))),
        ],
      ),
    );
    final label = compress ? '${slots.earlier} earlier levels' : 'Back to ${level.title}, level ${index + 1} of $_n';
    final visual = Positioned(
      left: x,
      top: y,
      width: w,
      height: h,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.identity()
              ..setEntry(3, 2, kFanPerspective)
              ..rotateX(tilt),
            child: Transform.scale(scale: picked == null ? scale : 1, alignment: Alignment.bottomCenter, child: ExcludeSemantics(child: body)),
          ),
        ),
      ),
    );
    // The hit target is the card's exposed strip in layout space (a 3D paint transform is not hit-tested with its perspective).
    final strip = slot == slots.count - 1 ? h : math.max(44.0, spacing);
    final hit = Positioned(
      left: x,
      top: y,
      width: w,
      height: strip,
      child: Opacity(
        opacity: 0,
        alwaysIncludeSemantics: true,
        child: Semantics(
          button: true,
          label: label,
          onTap: compress ? null : () => unawaited(_leaveWith(index, remove: false)),
          customSemanticsActions: {
            if (!compress && index > 0) const CustomSemanticsAction(label: 'Remove this and newer levels'): () => unawaited(_leaveWith(index, remove: true)),
          },
          child: GestureDetector(
            key: ValueKey('glass-stack-card-$index'),
            behavior: HitTestBehavior.opaque,
            onTap: compress ? null : () => unawaited(_leaveWith(index, remove: false)),
            onHorizontalDragUpdate: compress || index == 0 || picked != null ? null : (d) => setState(() => _drag[index] = (_drag[index] ?? 0) + d.delta.dx),
            onHorizontalDragEnd: compress || index == 0 || picked != null
                ? null
                : (d) {
                    final dx = _drag[index] ?? 0;
                    if (swipeRemoves(dx, d.velocity.pixelsPerSecond.dx, cs.width)) {
                      unawaited(_leaveWith(index, remove: true));
                    } else {
                      setState(() => _drag.remove(index));
                    }
                  },
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
    return [visual, hit];
  }
}
