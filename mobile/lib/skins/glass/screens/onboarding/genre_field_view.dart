import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/platform/gravity.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/screens/onboarding/genre_field.dart';

/// "Fantasy, loved" / "Horror, not for me" / "Romance, not chosen" / "Action, liked" (glass 8.7).
String genreSemanticsLabel(String name, int weight) => '$name, ${switch (weight) {
      2 => 'loved',
      1 => 'liked',
      -1 => 'not for me',
      _ => 'not chosen',
    }}';

/// The genre field (glass 8.7, step 4): 24 bodies on one `Ticker`. Content twins drawn by one painter; a tap cycles the weight, a
/// long-press (450 ms) sets "not for me", a drag moves a bubble 1:1 and flings it; the device tilt (through the shared
/// [gravityProvider], only while this step is visible) and a hover pointer drive gravity. Reduced motion: a grid.
class GenreFieldView extends ConsumerStatefulWidget {
  const GenreFieldView({super.key, required this.names, required this.weights, required this.onWeight, this.visible = true, this.height});
  final List<String> names;

  /// name to weight (1 like, 2 love, -1 skip, missing 0).
  final Map<String, int> weights;
  final void Function(String name, int weight) onWeight;

  /// False while another step is showing: the tilt subscription ends.
  final bool visible;
  final double? height;

  @override
  ConsumerState<GenreFieldView> createState() => GenreFieldViewState();
}

class GenreFieldViewState extends ConsumerState<GenreFieldView> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  GenreField? _field;
  Size _size = Size.zero;
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  StreamSubscription<Offset>? _gravitySub;
  Offset? _hover;
  String? _dragging;
  String? _focused;
  Offset _lastPointer = Offset.zero;
  Duration _lastTime = Duration.zero;
  Offset _velocity = Offset.zero;
  Timer? _longTimer;
  bool _moved = false;
  bool _long = false;
  final FocusNode _node = FocusNode(debugLabel: 'genre-field');

  /// The field, for tests.
  GenreField? get field => _field;

  bool get _reduced => ref.read(glassReducedProvider);

  @override
  void dispose() {
    _longTimer?.cancel();
    unawaited(_gravitySub?.cancel());
    _ticker.dispose();
    _node.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(GenreFieldView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncWeights();
    _syncGravity();
  }

  void _syncWeights() {
    final f = _field;
    if (f == null) return;
    var changed = false;
    for (final b in f.bodies) {
      final w = widget.weights[b.name] ?? 0;
      if (b.weight != w) {
        b.weight = w;
        changed = true;
      }
    }
    if (changed) {
      if (_reduced) {
        f.layoutGrid(_cols());
      } else {
        f.wake();
        _wake();
      }
      setState(() {});
    }
  }

  int _cols() => GlassFrame.of(context) == GlassFrameKind.phone ? 4 : 6;

  void _ensure(Size size) {
    if (_field != null && _size == size) return;
    final old = _field;
    _size = size;
    final f = GenreField(size: size, names: widget.names, radiusScale: GenreField.fitScale(size, widget.names.length));
    if (old != null) {
      for (final b in f.bodies) {
        final o = old.byName(b.name);
        if (o != null) {
          b.p = Offset(o.p.dx.clamp(0, size.width), o.p.dy.clamp(0, size.height));
          b.weight = o.weight;
          b.scale = o.scale;
        }
      }
    }
    for (final b in f.bodies) {
      final w = widget.weights[b.name] ?? 0;
      b.weight = w;
      b.scale = genreScaleFor(w);
    }
    _field = f;
    if (_reduced) {
      f.layoutGrid(_cols());
    } else {
      _wake();
    }
    _syncGravity();
  }

  void _wake() {
    if (!_ticker.isActive && widget.visible && !_reduced) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _onTick(Duration d) {
    final f = _field;
    if (f == null) return;
    final dt = _last == Duration.zero ? 1 / 60 : (d - _last).inMicroseconds / 1e6;
    _last = d;
    if (_hover != null) {
      final half = _size.center(Offset.zero);
      final o = (_hover! - half);
      final g = Offset(o.dx / half.dx, o.dy / half.dy) * 200;
      f.setGravity(g.distance > 200 ? g / g.distance * 200 : g);
    }
    f.step(dt);
    if (mounted) setState(() {});
    if (f.allAsleep && _dragging == null) _ticker.stop();
  }

  bool get _tiltAllowed {
    if (!widget.visible || _reduced) return false;
    if (!ref.read(glassInAppPrefsProvider).lightFollowsDevice) return false;
    if (!TickerMode.valuesOf(context).enabled) return false;
    final route = ModalRoute.of(context);
    return route == null || route.isCurrent;
  }

  void _syncGravity() {
    final want = _tiltAllowed;
    if (want && _gravitySub == null) {
      _gravitySub = ref.read(gravityProvider).stream.listen((g) {
        // Android axes: x right, y up the screen. The bodies fall toward the low side.
        _field?.setGravity(Offset(-g.dx, g.dy) * GenreField.pxPerG);
        _wake();
      });
    } else if (!want && _gravitySub != null) {
      unawaited(_gravitySub!.cancel());
      _gravitySub = null;
      _field?.setGravity(Offset.zero);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_field != null) _syncGravity();
  }

  // ---- input ---------------------------------------------------------------------------------------------------

  GenreBody? _hit(Offset p) {
    final f = _field;
    if (f == null) return null;
    GenreBody? best;
    for (final b in f.bodies) {
      if ((b.p - p).distance <= b.radius && (best == null || b.rank > best.rank)) best = b;
    }
    return best;
  }

  void _cycle(String name) {
    final w = widget.weights[name] ?? 0;
    glassFire(ref, HapticEvent.select);
    widget.onWeight(name, nextGenreWeight(w));
  }

  void _skip(String name) {
    glassFire(ref, HapticEvent.thresholdCross);
    widget.onWeight(name, -1);
  }

  void _down(PointerDownEvent e) {
    final b = _hit(e.localPosition);
    _moved = false;
    _long = false;
    _longTimer?.cancel();
    if (b == null) return;
    _dragging = b.name;
    _lastPointer = e.localPosition;
    _lastTime = e.timeStamp;
    _velocity = Offset.zero;
    _longTimer = Timer(const Duration(milliseconds: 450), () {
      if (_dragging != null && !_moved) {
        _long = true;
        _skip(_dragging!);
      }
    });
  }

  void _move(PointerMoveEvent e) {
    final name = _dragging;
    final f = _field;
    if (name == null || f == null) return;
    if (!_moved && (e.localPosition - _lastPointer).distance > 8) {
      _moved = true;
      _longTimer?.cancel();
    }
    if (_moved && !_reduced) {
      final dt = (e.timeStamp - _lastTime).inMicroseconds / 1e6;
      if (dt > 0) _velocity = (e.localPosition - _lastPointer) / dt;
      _lastPointer = e.localPosition;
      _lastTime = e.timeStamp;
      f.dragTo(name, e.localPosition);
      _wake();
      setState(() {});
    }
  }

  void _up(PointerUpEvent e) {
    _longTimer?.cancel();
    final name = _dragging;
    _dragging = null;
    if (name == null) return;
    if (_moved) {
      if (!_reduced) _field?.fling(name, _velocity);
      _wake();
    } else if (!_long) {
      _cycle(name);
    }
  }

  KeyEventResult _key(FocusNode n, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final f = _field;
    if (f == null) return KeyEventResult.ignored;
    final cur = _focused == null ? null : f.byName(_focused!);
    final k = e.logicalKey;
    double? dir;
    if (k == LogicalKeyboardKey.arrowRight) dir = 0;
    if (k == LogicalKeyboardKey.arrowDown) dir = math.pi / 2;
    if (k == LogicalKeyboardKey.arrowLeft) dir = math.pi;
    if (k == LogicalKeyboardKey.arrowUp) dir = -math.pi / 2;
    if (dir != null) {
      final from = cur ?? f.bodies.first;
      final to = cur == null ? from : f.nearest(from, dir);
      if (to != null) setState(() => _focused = to.name);
      return KeyEventResult.handled;
    }
    if (cur == null) return KeyEventResult.ignored;
    if (k == LogicalKeyboardKey.space) {
      _cycle(cur.name);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.keyX) {
      _skip(cur.name);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final reduced = ref.watch(glassReducedProvider);
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth.isFinite ? c.maxWidth : 358.0;
        var h = widget.height ?? (c.maxHeight.isFinite ? c.maxHeight : 480.0);
        final wide = GlassFrame.of(context) != GlassFrameKind.phone;
        final width = wide ? math.min(w, 720.0) : w;
        if (wide) h = math.min(h, 480);
        if (reduced) {
          final probe = GenreField(size: Size(width, 100), names: widget.names);
          h = probe.gridHeight(_cols());
        }
        final size = Size(width, h);
        _ensure(size);
        final f = _field!;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _syncGravity();
        });
        final painter = _GenrePainter(field: f, focused: _focused, hasFocus: _node.hasFocus, tick: _ticker.isActive ? _last.inMicroseconds : 0);
        return Center(
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: Focus(
              focusNode: _node,
              onKeyEvent: _key,
              onFocusChange: (v) {
                if (v && _focused == null && _field != null) _focused = _field!.bodies.first.name;
                setState(() {});
              },
              child: MouseRegion(
                onHover: (e) {
                  if (wide && !reduced) {
                    _hover = e.localPosition;
                    _wake();
                  }
                },
                onExit: (_) {
                  _hover = null;
                  _field?.setGravity(Offset.zero);
                },
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: _down,
                  onPointerMove: _move,
                  onPointerUp: _up,
                  onPointerCancel: (_) {
                    _longTimer?.cancel();
                    _dragging = null;
                  },
                  child: Semantics(
                    container: true,
                    label: 'Genres you like',
                    child: Stack(
                      children: [
                        Positioned.fill(child: CustomPaint(painter: painter)),
                        ..._semanticNodes(f),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// One real semantics node per bubble (a `CustomPainter`'s virtual nodes cannot carry custom actions): a button with its state,
  /// the hint and the four actions, so the physics never has to be operated.
  List<Widget> _semanticNodes(GenreField f) => [
        for (final b in f.bodies)
          Positioned(
            left: b.p.dx - b.radius,
            top: b.p.dy - b.radius,
            width: b.radius * 2,
            height: b.radius * 2,
            child: Semantics(
                button: true,
                label: genreSemanticsLabel(b.name, b.weight),
                hint: 'Double-tap to change',
                onTap: () => _cycle(b.name),
                customSemanticsActions: {
                  const CustomSemanticsAction(label: 'Like'): () => widget.onWeight(b.name, 1),
                  const CustomSemanticsAction(label: 'Love'): () => widget.onWeight(b.name, 2),
                  const CustomSemanticsAction(label: 'Not for me'): () => widget.onWeight(b.name, -1),
                  const CustomSemanticsAction(label: 'Clear'): () => widget.onWeight(b.name, 0),
                },
                child: const SizedBox.expand(),
            ),
          ),
      ];
}

class _GenrePainter extends CustomPainter {
  _GenrePainter({required this.field, required this.focused, required this.hasFocus, required this.tick});

  final GenreField field;
  final String? focused;
  final bool hasFocus;
  final int tick;
  static final Map<String, TextPainter> _cache = {};

  TextPainter _tp(String name, double scale, Color color, bool strike) {
    final key = '$name|${scale.toStringAsFixed(2)}|${color.toARGB32()}|$strike';
    return _cache.putIfAbsent(
      key,
      () => TextPainter(
        text: TextSpan(
          text: name,
          style: TextStyle(fontFamily: gt.typeSubhead.family, fontSize: 15 * scale.clamp(0.8, 1.3), fontWeight: FontWeight.w600, color: color, decoration: strike ? TextDecoration.lineThrough : TextDecoration.none, decorationColor: color),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 2,
      )..layout(maxWidth: 200),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in field.bodies) {
      final r = b.radius;
      final c = b.p;
      final liked = b.weight == 1 || b.weight == 2;
      final fill = liked ? gt.colorIris600.withValues(alpha: 0.6) : const Color(0x9E131317);
      canvas.drawCircle(c, r, Paint()..color = fill);
      if (b.weight == 2) {
        canvas.drawCircle(c, r + 3, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = gt.colorIris300.withValues(alpha: 0.5));
      }
      canvas.drawCircle(c, r - 0.25, Paint()..style = PaintingStyle.stroke..strokeWidth = 0.5..color = const Color(0x38FFFFFF));
      canvas.drawCircle(
        c,
        r,
        Paint()..shader = const RadialGradient(center: Alignment(-0.5, -0.6), radius: 0.9, colors: [Color(0x33FFFFFF), Color(0x00FFFFFF)]).createShader(Rect.fromCircle(center: c, radius: r)),
      );
      if (hasFocus && focused == b.name) {
        canvas.drawCircle(c, r + 3, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = const Color(0xFFFFFFFF));
        canvas.drawCircle(c, r + 5, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = gt.colorIris400);
      }
      final color = b.weight == -1 ? gt.colorLabel2 : (liked ? gt.colorOnTint : gt.colorLabel1);
      final tp = _tp(b.name, r / 44, color, b.weight == -1);
      final maxW = r * 1.7;
      if (tp.width <= maxW) {
        tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
      } else {
        final scale = maxW / tp.width;
        canvas
          ..save()
          ..translate(c.dx, c.dy)
          ..scale(scale)
          ..translate(-tp.width / 2, -tp.height / 2);
        tp.paint(canvas, Offset.zero);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_GenrePainter old) => true;
}
