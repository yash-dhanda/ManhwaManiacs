import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show PointerDeviceKind, kSecondaryMouseButton;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heroine/heroine.dart' show Heroine;
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/skins/glass/glass/ambient_field.dart' show moodColour;
import 'package:manhwamaniacs/skins/glass/glass/focus_ring.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart' show springOf;
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs_30.dart';
import 'package:manhwamaniacs/skins/glass/primitives/profile_orb.dart';
import 'package:manhwamaniacs/skins/glass/screens/profiles/orb_physics.dart';
import 'package:manhwamaniacs/skins/glass/transitions/poster_zoom.dart' show glassZoomMotion;
import 'package:manhwamaniacs/skins/glass/type.dart';

/// One entry of the picker's field: a real profile or the Add orb.
class OrbEntry {
  const OrbEntry.profile({required this.id, required this.name, required this.preset, required this.mood}) : add = false;
  const OrbEntry.add()
      : id = -1,
        name = 'Add profile',
        preset = GlassAvatarPreset.violetSpark,
        mood = Mood.neutral,
        add = true;
  final int id;
  final String name;
  final GlassAvatarPreset preset;
  final Mood mood;
  final bool add;
}

/// The controller the picker drives its field with (choose, drag physics and rects), so the screen never reaches into the state.
class OrbFieldController {
  _OrbFieldState? _state;

  /// The global centre and size of an orb's visual, or null.
  Rect? rectOf(int id) => _state?._rectOf(id);

  /// Chooses [id]: it inflates and every other orb is repelled.
  void choose(int id) => _state?._choose(id);

  /// Everything returns (an interrupted or cancelled pick).
  void reset() => _state?._physics.reset();

  /// The orb is hidden while its copy flies above the router.
  void hide(int id, {required bool hidden}) => _state?._hide(id, hidden);

  /// A one-shot hop (a saved profile, glass 8.6): -12 px and back.
  void hop(int id) => _state?._startHop(id);

  /// Arrival by the lens split: orbs spring from [centre] to their slots, 40 ms apart.
  void arriveFrom(Offset centre) => _state?._arriveFrom(centre);

  /// Arrival by the entrance wave from the centre (or the reduced fade).
  void arriveWave() => _state?._arriveFrom(null);

  /// Focus an orb by id.
  void focus(int id) => _state?._nodes[id]?.requestFocus();
}

/// The orbs of the picker (glass 8.5): a centred wrap, idle drift, hover growth on wide frames, drag 1:1 with a spring home,
/// keyboard focus and the long-press context menu. Orbs are content, never live glass.
class OrbField extends ConsumerStatefulWidget {
  const OrbField({
    super.key,
    required this.entries,
    required this.controller,
    required this.orbSize,
    required this.spacing,
    required this.onPick,
    required this.onAdd,
    required this.onEdit,
    required this.onContext,
    required this.onFocusChanged,
    this.manage = false,
    this.enabled = true,
    this.singleLabel,
  });

  final List<OrbEntry> entries;
  final OrbFieldController controller;
  final double orbSize;
  final double spacing;
  final void Function(OrbEntry) onPick;
  final VoidCallback onAdd;
  final void Function(OrbEntry) onEdit;
  final void Function(OrbEntry, Rect) onContext;
  final ValueChanged<int?> onFocusChanged;
  final bool manage;
  final bool enabled;

  /// "Continue as {name}" for the unreachable state's single orb.
  final String? singleLabel;

  @override
  ConsumerState<OrbField> createState() => _OrbFieldState();
}

class _OrbFieldState extends ConsumerState<OrbField> with SingleTickerProviderStateMixin {
  late final OrbPhysics _physics = OrbPhysics(spring: springOf(gt.springDismiss));
  late final Ticker _ticker;
  final Map<int, GlobalKey> _keys = {};
  final Map<int, FocusNode> _nodes = {};
  final Map<int, bool> _hidden = {};
  final Map<int, double> _hopT = {};
  Duration _last = Duration.zero;
  int? _hover;
  int? _dragging;
  final Map<int, double> _arrive = {};
  final Map<int, Offset> _arriveFromOffset = {};
  final Map<int, double> _arriveDelay = {};
  double _clockMs = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    widget.controller._state = this;
  }

  @override
  void didUpdateWidget(OrbField old) {
    super.didUpdateWidget(old);
    widget.controller._state = this;
  }

  @override
  void dispose() {
    if (widget.controller._state == this) widget.controller._state = null;
    _ticker.dispose();
    for (final n in _nodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  GlobalKey _key(int id) => _keys.putIfAbsent(id, () => GlobalKey(debugLabel: 'orb-$id'));
  FocusNode _node(int id) => _nodes.putIfAbsent(id, () => FocusNode(debugLabel: 'orb-$id')..addListener(() => _focusChanged(id)));

  void _focusChanged(int id) {
    final n = _nodes[id];
    if (n == null) return;
    if (n.hasFocus) widget.onFocusChanged(id);
    setState(() {});
  }

  Rect? _rectOf(int id) {
    final ro = _key(id).currentContext?.findRenderObject();
    if (ro is! RenderBox || !ro.attached || !ro.hasSize) return null;
    return ro.localToGlobal(Offset.zero) & ro.size;
  }

  void _wake() {
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    final dt = _last == Duration.zero ? 1 / 60 : math.min((elapsed - _last).inMicroseconds / 1e6, 1 / 30);
    _last = elapsed;
    _clockMs += dt * 1000;
    _physics.step(dt);
    var active = !_physics.resting;
    for (final id in _arrive.keys.toList()) {
      final delay = _arriveDelay[id] ?? 0;
      if (_clockMs < delay) {
        active = true;
        continue;
      }
      final v = (_arrive[id]! + dt / 0.643).clamp(0.0, 1.0);
      _arrive[id] = v;
      if (v >= 1) {
        _arrive.remove(id);
        _arriveFromOffset.remove(id);
      } else {
        active = true;
      }
    }
    for (final id in _hopT.keys.toList()) {
      final v = _hopT[id]! + dt / 0.5;
      if (v >= 1) {
        _hopT.remove(id);
      } else {
        _hopT[id] = v;
        active = true;
      }
    }
    if (_arrive.isNotEmpty || _hopT.isNotEmpty) active = true;
    if (mounted) setState(() {});
    if (!active) _ticker.stop();
  }

  void _choose(int id) {
    final centres = <int, Offset>{};
    for (final e in widget.entries) {
      final r = _rectOf(e.id);
      if (r != null) centres[e.id] = r.center;
    }
    _physics.choose(id, centres);
    _wake();
  }

  void _hide(int id, bool hidden) {
    _hidden[id] = hidden;
    setState(() {});
  }

  void _startHop(int id) {
    _hopT[id] = 0;
    _wake();
  }

  void _arriveFrom(Offset? centre) {
    var i = 0;
    _clockMs = 0;
    for (final e in widget.entries) {
      _arrive[e.id] = 0.0;
      _arriveDelay[e.id] = i * 40.0;
      final r = _rectOf(e.id);
      _arriveFromOffset[e.id] = (centre != null && r != null) ? centre - r.center : (r == null ? Offset.zero : Offset.zero);
      i++;
    }
    _wake();
    setState(() {});
  }

  Offset _arrivalOffset(int id) {
    final v = _arrive[id];
    if (v == null) return Offset.zero;
    final from = _arriveFromOffset[id] ?? Offset.zero;
    // The springCelebrate settle, approximated by an under-damped ease (overshoot ~ 6 %).
    final t = v;
    final e = 1 - math.pow(1 - t, 3) * math.cos(t * math.pi * 1.1);
    return from * (1 - e.clamp(-0.2, 1.2));
  }

  double _arrivalAlpha(int id) {
    final v = _arrive[id];
    if (v == null) return 1;
    final delay = _arriveDelay[id] ?? 0;
    if (_clockMs < delay) return 0;
    return math.min(1, v * 4);
  }

  @override
  Widget build(BuildContext context) {
    final reduced = ref.watch(glassReducedProvider);
    final entries = widget.entries;
    final s = widget.orbSize;
    final cells = [for (final e in entries) _cell(e, s, reduced)];
    return FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: Wrap(
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        spacing: widget.spacing,
        runSpacing: widget.spacing,
        children: cells,
      ),
    );
  }

  Widget _cell(OrbEntry e, double s, bool reduced) {
    final body = _physics.body(e.id);
    final arriveOffset = reduced ? Offset.zero : _arrivalOffset(e.id);
    final hop = _hopT[e.id];
    final hopY = hop == null ? 0.0 : -12 * math.sin(hop * math.pi);
    final hovered = _hover == e.id;
    final node = _node(e.id);
    final hasFocus = node.hasFocus;
    var scale = body.scale * (hovered && !reduced ? 1.08 : 1.0);
    if (_dragging == e.id) scale *= 1.02;
    final hidden = _hidden[e.id] ?? false;
    final alpha = hidden ? 0.0 : body.alpha * _arrivalAlpha(e.id);
    final orb = e.add
        ? _AddOrb(size: s)
        : Heroine(
            tag: 'profile-orb-${e.id}',
            motion: glassZoomMotion(),
            child: GlassProfileOrb(preset: e.preset, size: s, mood: moodColour(e.mood), name: e.name, drift: !widget.manage && widget.enabled && !reduced),
          );
    final label = e.add ? 'Add profile' : (widget.singleLabel != null ? widget.singleLabel! : 'Read as ${e.name}');
    final visual = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          key: _key(e.id),
          width: s,
          height: s,
          child: GlassFocusRing(
            shape: const GlassShape.circle(),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                ExcludeSemantics(child: orb),
                if (widget.manage && !e.add) Positioned(right: -2, top: -2, child: _PencilBadge()),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: s + widget.spacing - 4,
          child: ExcludeSemantics(
            child: GlassText(widget.singleLabel ?? e.name, role: gt.typeHeadline, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, color: e.add ? gt.colorLabel2 : gt.colorLabel1),
          ),
        ),
      ],
    );
    final breathe = widget.manage && !reduced && !e.add ? 1 + 0.01 * (1 + math.sin(_clockMs / 2000 * 2 * math.pi)) : 1.0;
    Widget cell = Transform.translate(
      offset: body.x + arriveOffset + Offset(0, hopY),
      child: Opacity(
        opacity: alpha.clamp(0.0, 1.0),
        child: Transform.scale(scale: scale * breathe, child: visual),
      ),
    );
    cell = MouseRegion(
      onEnter: (_) => setState(() => _hover = e.id),
      onExit: (_) => setState(() => _hover = null),
      child: cell,
    );
    cell = _OrbGesture(
      enabled: widget.enabled,
      onTap: () => e.add ? widget.onAdd() : (widget.manage ? widget.onEdit(e) : widget.onPick(e)),
      onLongPress: e.add
          ? null
          : () {
              final r = _rectOf(e.id);
              if (r != null) widget.onContext(e, r);
            },
      onDrag: (d) {
        _dragging = e.id;
        _physics.drag(e.id, d);
        _wake();
        setState(() {});
      },
      onRelease: (v) {
        _dragging = null;
        _physics.release(e.id, v);
        _wake();
      },
      child: cell,
    );
    return Semantics(
      button: true,
      label: label,
      focusable: true,
      focused: hasFocus,
      onTap: widget.enabled ? () => e.add ? widget.onAdd() : (widget.manage ? widget.onEdit(e) : widget.onPick(e)) : null,
      onLongPress: widget.enabled && !e.add
          ? () {
              final r = _rectOf(e.id);
              if (r != null) widget.onContext(e, r);
            }
          : null,
      excludeSemantics: true,
      child: Focus(
        focusNode: node,
        onKeyEvent: (n, ev) {
          if (ev is! KeyDownEvent || !widget.enabled) return KeyEventResult.ignored;
          if (ev.logicalKey == LogicalKeyboardKey.enter || ev.logicalKey == LogicalKeyboardKey.numpadEnter || ev.logicalKey == LogicalKeyboardKey.space) {
            e.add ? widget.onAdd() : (widget.manage ? widget.onEdit(e) : widget.onPick(e));
            return KeyEventResult.handled;
          }
          if (ev.logicalKey == LogicalKeyboardKey.contextMenu || (ev.logicalKey == LogicalKeyboardKey.f10 && HardwareKeyboard.instance.isShiftPressed) || ev.logicalKey == LogicalKeyboardKey.period) {
            final r = _rectOf(e.id);
            if (!e.add && r != null) {
              widget.onContext(e, r);
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: cell,
      ),
    );
  }
}

/// Tap, a 450 ms long-press, a secondary click, and a 1:1 drag with a release velocity, without a gesture-arena fight: raw pointers.
class _OrbGesture extends StatefulWidget {
  const _OrbGesture({required this.child, required this.onTap, required this.onLongPress, required this.onDrag, required this.onRelease, required this.enabled});
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<Offset> onDrag;
  final ValueChanged<Offset> onRelease;
  final bool enabled;

  @override
  State<_OrbGesture> createState() => _OrbGestureState();
}

class _OrbGestureState extends State<_OrbGesture> {
  static const double _slop = 8;
  Offset? _down;
  Offset? _last;
  Duration _lastTime = Duration.zero;
  Offset _velocity = Offset.zero;
  bool _moved = false;
  bool _long = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _reset() {
    _timer?.cancel();
    _down = null;
    _moved = false;
    _long = false;
  }

  @override
  Widget build(BuildContext context) => Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (e) {
          if (!widget.enabled) return;
          if (e.kind == PointerDeviceKind.mouse && e.buttons == kSecondaryMouseButton) {
            widget.onLongPress?.call();
            return;
          }
          _down = e.position;
          _last = e.position;
          _lastTime = e.timeStamp;
          _velocity = Offset.zero;
          _moved = false;
          _long = false;
          _timer?.cancel();
          if (widget.onLongPress != null) {
            _timer = Timer(const Duration(milliseconds: 450), () {
              if (_down != null && !_moved) {
                _long = true;
                widget.onLongPress!();
              }
            });
          }
        },
        onPointerMove: (e) {
          final d = _down;
          if (d == null) return;
          if (!_moved && (e.position - d).distance > _slop) {
            _moved = true;
            _timer?.cancel();
          }
          if (_moved) {
            final delta = e.position - _last!;
            final dt = (e.timeStamp - _lastTime).inMicroseconds / 1e6;
            if (dt > 0) _velocity = delta / dt;
            _last = e.position;
            _lastTime = e.timeStamp;
            widget.onDrag(delta);
          }
        },
        onPointerUp: (e) {
          if (_down == null) return;
          final moved = _moved, long = _long;
          final v = _velocity;
          _reset();
          if (moved) {
            widget.onRelease(v);
          } else if (!long) {
            widget.onTap();
          }
        },
        onPointerCancel: (e) {
          final moved = _moved;
          _reset();
          if (moved) widget.onRelease(Offset.zero);
        },
        child: widget.child,
      );
}

/// The Add orb: a 1.5 px dashed `g600` ring and a `plus` glyph.
class _AddOrb extends StatelessWidget {
  const _AddOrb({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: const _DashedRingPainter(),
          child: Center(child: Icon(GlassGlyph.plus.light, size: 32, color: gt.colorLabel2)),
        ),
      );
}

class _DashedRingPainter extends CustomPainter {
  const _DashedRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2 - 0.75;
    final c = size.center(Offset.zero);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = GlassColors.g600;
    const dashes = 36;
    for (var i = 0; i < dashes; i++) {
      final a0 = i / dashes * 2 * math.pi;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), a0, math.pi / dashes, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter old) => false;
}

/// The manage-mode pencil badge: the content twin of a 28 px `glassThin` circle with a 16 px `pencil-simple`.
class _PencilBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xB3131317), shape: BoxShape.circle, border: Border.fromBorderSide(BorderSide(color: Color(0x38FFFFFF), width: 0.5))),
        child: SizedBox.square(dimension: 28, child: Center(child: Icon(GlassGlyph30.pencilSimple.regular, size: 16, color: gt.colorOnGlass))),
      );
}
