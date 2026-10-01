import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/physics.dart' show SpringSimulation;
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs_more.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/reactions/glass_reactions.dart';
import 'package:manhwamaniacs/skins/glass/primitives/reactions/reaction_flight.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The six bubble centres on a 120 degree arc above [centre], radius [r]: from 210 to 330 degrees (screen coordinates, up is
/// negative y). Pure, so the arc is a unit test.
List<Offset> bubbleCentres(Offset centre, {double r = 96, int n = 6}) => [
      for (var i = 0; i < n; i++)
        centre + Offset(math.cos((210 + 120 * i / (n - 1)) * math.pi / 180), math.sin((210 + 120 * i / (n - 1)) * math.pi / 180)) * r,
    ];

/// The bubble under [p] (within its radius plus 12 px), or null.
int? bubbleAt(List<Offset> centres, Offset p, {double radius = 38}) {
  int? best;
  var bestD = double.infinity;
  for (var i = 0; i < centres.length; i++) {
    final d = (centres[i] - p).distance;
    if (d <= radius && d < bestD) {
      bestD = d;
      best = i;
    }
  }
  return best;
}

/// The reaction button (glass 9.3.2). A tap sends Love. Press and hold 300 ms blooms six named glass bubbles in a 120 degree arc
/// above the finger on `springLens`; sliding magnifies the bubble under the finger to 1.4x on `springTrack`; releasing on a bubble
/// sends it, releasing outside cancels. `Enter` sends Love; `Shift+Enter` opens the picker (arrows choose, `Enter` sends).
/// Screen readers get six "React with {name}" actions. The send flies to the strip's slot on a ballistic arc.
class GlassReactionButton extends ConsumerStatefulWidget {
  const GlassReactionButton({super.key, required this.onSend, required this.onClear, this.mine, this.chapterLabel = 'this chapter', this.openRequest});
  final ValueChanged<ReactionKind> onSend;
  final VoidCallback onClear;

  /// The viewer's current reaction on the chapter.
  final ReactionKind? mine;
  final String chapterLabel;

  /// Each notification opens the picker from the keyboard (a list's `e` key, anchored to the row).
  final Listenable? openRequest;

  @override
  ConsumerState<GlassReactionButton> createState() => _GlassReactionButtonState();
}

class _GlassReactionButtonState extends ConsumerState<GlassReactionButton> with TickerProviderStateMixin {
  final GlobalKey _box = GlobalKey();
  late final AnimationController _bloom;
  late final List<AnimationController> _mag;
  OverlayEntry? _entry;
  bool _open = false;
  bool _keyboard = false;
  Offset _centre = Offset.zero; // where the arc is centred (global)
  Offset _finger = Offset.zero;
  int? _hover;
  int? _keyIndex;
  final FocusNode _bubbleFocus = FocusNode(debugLabel: 'GlassReactionBubbles');
  bool _mouse = false;
  FocusNode? _prevFocus;

  @override
  void initState() {
    super.initState();
    _bloom = AnimationController.unbounded(vsync: this);
    _mag = [for (var i = 0; i < 6; i++) AnimationController.unbounded(vsync: this, value: 1)];
    widget.openRequest?.addListener(_requested);
  }

  void _requested() => _openBubbles(keyboard: true);

  @override
  void didUpdateWidget(GlassReactionButton old) {
    super.didUpdateWidget(old);
    if (old.openRequest != widget.openRequest) {
      old.openRequest?.removeListener(_requested);
      widget.openRequest?.addListener(_requested);
    }
  }

  @override
  void dispose() {
    widget.openRequest?.removeListener(_requested);
    _entry?.remove();
    _entry?.dispose();
    _bubbleFocus.dispose();
    _bloom.dispose();
    for (final c in _mag) {
      c.dispose();
    }
    super.dispose();
  }

  Offset _buttonCentre() {
    final ro = _box.currentContext?.findRenderObject();
    return ro is RenderBox && ro.hasSize ? ro.localToGlobal(ro.size.center(Offset.zero)) : Offset.zero;
  }

  // ---- sending ----

  void _send(ReactionKind kind, {Offset? from}) {
    if (widget.mine == kind) {
      widget.onClear();
      return;
    }
    final start = from ?? _buttonCentre();
    glassFire(ref, HapticEvent.reactionSend);
    glassSound(ref, SoundEvent.reactionSend);
    widget.onSend(kind);
    final target = ref.read(glassReactionTargetsProvider).centerOf(kind);
    if (target != null) unawaited(_fly(kind, start, target));
  }

  Future<void> _fly(ReactionKind kind, Offset from, Offset to) async {
    final reduced = ref.read(glassMotionPrefsProvider).reduced;
    if (reduced || !mounted) return;
    final v = flightVelocity(from, to);
    final c = AnimationController(vsync: this, duration: Duration(milliseconds: (v.t * 1000).round()) + kBurst);
    final r = glassReaction(kind);
    final entry = OverlayEntry(
      builder: (_) => AnimatedBuilder(
        animation: c,
        builder: (context, _) {
          final t = c.value * c.duration!.inMicroseconds / 1e6;
          if (t <= v.t) {
            final p = flightAt(from, to, t);
            return Positioned(left: p.dx - 18, top: p.dy - 18, width: 36, height: 36, child: IgnorePointer(child: Icon(r.fill, size: 36, color: gt.colorBloom)));
          }
          final burst = burstParticles(to, ((t - v.t) / (kBurst.inMicroseconds / 1e6)));
          return IgnorePointer(
            child: Stack(children: [
              for (final b in burst) Positioned(left: b.at.dx - 2, top: b.at.dy - 2, width: 4, height: 4, child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: gt.colorBloom.withValues(alpha: b.opacity)))),
            ],),
          );
        },
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(entry);
    final e = GlassMotion.recorder.begin(MotionName.reactionBloomAndArc.label, c.duration!.inMilliseconds);
    await c.forward();
    GlassMotion.recorder.end(e);
    entry.remove();
    entry.dispose();
    c.dispose();
  }

  // ---- the bubbles ----

  List<Offset> _centres() => bubbleCentres(_centre);

  void _openBubbles({required bool keyboard}) {
    if (_open || !mounted) return;
    final size = MediaQuery.sizeOf(context);
    final b = _buttonCentre();
    _centre = Offset(b.dx.clamp(16 + 109.0, math.max(16 + 109.0, size.width - 16 - 109.0)), b.dy);
    _finger = b;
    _keyboard = keyboard;
    _keyIndex = keyboard ? 1 : null;
    _hover = keyboard ? 1 : null;
    _open = true;
    glassFire(ref, HapticEvent.reactionBloom);
    _prevFocus = FocusManager.instance.primaryFocus;
    _entry = OverlayEntry(builder: _bubbles);
    Overlay.of(context, rootOverlay: true).insert(_entry!);
    if (keyboard) WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _bubbleFocus.requestFocus() : null);
    // Reset before playing: setting the value afterwards stopped the bloom at 0 (the bubbles stayed stacked on the button).
    _bloom.value = 0;
    unawaited(GlassMotion.play(MotionName.reactionBloomAndArc, controller: _bloom, target: 1));
    if (keyboard) _magnify(1);
  }

  void _magnify(int? index) {
    for (var i = 0; i < 6; i++) {
      final target = i == index ? 1.4 : 1.0;
      if (ref.read(glassMotionPrefsProvider).reduced) {
        _mag[i].value = target;
      } else {
        unawaited(_mag[i].springTo(target, gt.springTrack));
      }
    }
  }

  Future<void> _closeBubbles() async {
    if (!_open) return;
    _open = false;
    _hover = null;
    _keyIndex = null;
    final e = _entry;
    _entry = null;
    if (e == null) return;
    final reduced = ref.read(glassMotionPrefsProvider).reduced;
    if (!reduced) await _bloom.animateWith(SpringSimulation(springOf(gt.springDismiss), _bloom.value, 0, 0)).catchError((Object _) {});
    e.remove();
    e.dispose();
    for (final c in _mag) {
      c.value = 1;
    }
    if (_keyboard && mounted) _prevFocus?.requestFocus();
  }

  void _move(PointerMoveEvent ev) {
    if (!_open || _keyboard) return;
    _finger = ev.position;
    final i = bubbleAt(_centres(), _finger);
    if (i != _hover) {
      _hover = i;
      if (i != null) glassFire(ref, HapticEvent.reactionCross);
      _magnify(i);
    }
    _entry?.markNeedsBuild();
  }

  void _up(PointerUpEvent ev) {
    if (!_open || _keyboard) return;
    final i = bubbleAt(_centres(), ev.position) ?? _hover;
    final from = _centres().elementAtOrNull(i ?? 0);
    unawaited(_closeBubbles());
    if (i != null) _send(kGlassReactions[i].kind, from: from);
  }

  KeyEventResult _bubbleKey(FocusNode n, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.arrowRight || k == LogicalKeyboardKey.arrowDown) {
      _keyIndex = math.min(5, (_keyIndex ?? 0) + 1);
    } else if (k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.arrowUp) {
      _keyIndex = math.max(0, (_keyIndex ?? 1) - 1);
    } else if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      final i = _keyIndex ?? 1;
      unawaited(_closeBubbles());
      _send(kGlassReactions[i].kind);
      return KeyEventResult.handled;
    } else if (k == LogicalKeyboardKey.escape) {
      unawaited(_closeBubbles());
      return KeyEventResult.handled;
    } else {
      return KeyEventResult.ignored;
    }
    _hover = _keyIndex;
    glassFire(ref, HapticEvent.reactionCross);
    _magnify(_keyIndex);
    _entry?.markNeedsBuild();
    return KeyEventResult.handled;
  }

  Widget _bubbles(BuildContext context) {
    final reduced = ref.read(glassMotionPrefsProvider).reduced;
    final centres = _centres();
    return AnimatedBuilder(
      animation: Listenable.merge([_bloom, ..._mag]),
      builder: (context, _) {
        final t = reduced ? 1.0 : _bloom.value.clamp(0.0, 1.3);
        final sizes = [for (var i = 0; i < 6; i++) 52.0 * _mag[i].value];
        final total = sizes.fold<double>(0, (a, b) => a + b);
        final origin = Offset(_centre.dx - total / 2, _centre.dy - 96 - 26);
        var x = 0.0;
        final offsets = <Offset>[];
        for (var i = 0; i < 6; i++) {
          final want = Offset.lerp(_finger == Offset.zero ? _centre : _buttonCentre(), centres[i], t)! - Offset(sizes[i] / 2, sizes[i] / 2);
          offsets.add(want - Offset(origin.dx + x, origin.dy));
          x += sizes[i];
        }
        final child = Focus(
          focusNode: _bubbleFocus,
          onKeyEvent: _bubbleKey,
          child: Stack(
            children: [
              if (_keyboard) Positioned.fill(child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => unawaited(_closeBubbles()))),
              Positioned(
                left: origin.dx,
                top: origin.dy,
                child: IgnorePointer(
                  ignoring: !_keyboard,
                  child: SkinGlassGroup(
                    key: const ValueKey('glass-reaction-bubbles'),
                    tier: GlassTierId.t2,
                    layer: GlassLayerKind.overlays,
                    debugLabel: 'ReactionBubbles',
                    gap: 0,
                    offsets: offsets,
                    shapes: [
                      for (var i = 0; i < 6; i++)
                        SkinGlassShape(
                          size: Size.square(sizes[i]),
                          shape: const GlassShape.circle(),
                          child: Center(child: Icon(kGlassReactions[i].fill, size: 36 * (sizes[i] / 52).clamp(1.0, 1.4), color: _hover == i ? gt.colorBloom : gt.colorOnGlass)),
                        ),
                    ],
                  ),
                ),
              ),
              // Picked with a pointer after a click or with the keys: each bubble is a selectable button.
              if (_keyboard)
                for (var i = 0; i < 6; i++)
                  Positioned(
                    left: centres[i].dx - 26,
                    top: centres[i].dy - 26,
                    width: 52,
                    height: 52,
                    child: MouseRegion(
                      onEnter: (_) {
                        _keyIndex = i;
                        _hover = i;
                        _magnify(i);
                        _entry?.markNeedsBuild();
                      },
                      child: Semantics(
                        button: true,
                        selected: _hover == i,
                        label: kGlassReactions[i].name,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            unawaited(_closeBubbles());
                            _send(kGlassReactions[i].kind, from: centres[i]);
                          },
                        ),
                      ),
                    ),
                  ),
              for (var i = 0; i < 6; i++)
                Positioned(
                  left: centres[i].dx - 40,
                  top: centres[i].dy + sizes[i] / 2 + 2,
                  width: 80,
                  child: IgnorePointer(child: Opacity(opacity: t.clamp(0.0, 1.0), child: GlassText(kGlassReactions[i].name, role: gt.typeCaption2, textAlign: TextAlign.center, color: _hover == i ? gt.colorBloom : gt.colorLabel1, onGlass: true))),
                ),
            ],
          ),
        );
        return child;
      },
    );
  }

  // ---- build ----

  @override
  Widget build(BuildContext context) {
    final mine = widget.mine;
    final r = mine == null ? null : glassReaction(mine);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, shift: true): () => _openBubbles(keyboard: true),
      },
      child: GlassPressable(
        material: GlassMaterial.content,
        sink: 0.92,
        shape: const GlassShape.circle(),
        // A touch tap sends Love; a mouse or trackpad click opens the picker (glass 11), its bubbles clickable.
        onTap: () => _mouse ? _openBubbles(keyboard: true) : _send(kTapReaction),
        onRawDown: (e) => _mouse = e.kind == PointerDeviceKind.mouse || e.kind == PointerDeviceKind.trackpad,
        onLongPress: () => _openBubbles(keyboard: false),
        longPressDuration: const Duration(milliseconds: 300),
        cancelDistance: double.infinity,
        onRawMove: _move,
        onRawUp: _up,
        onRawCancel: () => unawaited(_closeBubbles()),
        semanticsLabel: 'React to ${widget.chapterLabel}',
        semanticsHint: 'Tap to send Love, hold for more',
        customActions: {
          for (final rr in kGlassReactions) CustomSemanticsAction(label: rr.action): () => _send(rr.kind),
          if (widget.mine != null) const CustomSemanticsAction(label: 'Remove my reaction'): widget.onClear,
        },
        builder: (context, info) => SizedBox.square(
          key: _box,
          dimension: 48,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(shape: BoxShape.circle, color: r == null ? gt.colorFill3 : gt.colorBloomWash),
              child: SizedBox.square(
                dimension: 36,
                child: Center(child: Icon(r == null ? GlassGlyph28.heart.regular : r.fill, size: 22, color: r == null ? gt.colorLabel2 : gt.colorBloom)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
