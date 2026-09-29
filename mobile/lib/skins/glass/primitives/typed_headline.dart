import 'dart:async';
import 'dart:ui' as ui;

import 'package:characters/characters.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/glass_motion_recorder.dart' show GlassMotionEntry;
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/revealed_headings.dart';
import 'package:motor/motor.dart';

/// The typing reveal (glass 10.2): one grapheme every 50 ms by timestamp (dropped frames never slow it),
/// the whole text laid out in full from frame 0 with the unseen graphemes transparent, a caret of light
/// riding on `springTrack`. At most 48 graphemes type; the tail fades in as one span over 200 ms. When it
/// ends the caret blinks three times (530 ms on, 530 ms off) and dematerialises (350 ms). A tap, a key
/// press with focus on the headline (or nowhere) or navigating away skips it; focus arriving on the
/// headline never does. Once per app session per profile per placement; no haptic and no sound per
/// character; reduced motion shows the plain text at once.
class TypedHeadline extends ConsumerStatefulWidget {
  const TypedHeadline(
    this.text, {
    super.key,
    required this.role,
    required this.placement,
    this.color,
    this.headingLevel,
    this.textAlign = TextAlign.start,
    this.onDone,
  });

  final String text;
  final GlassTypeRole role;

  /// `home.greeting`, `login.heading`, `onboarding.first`, `wrapped.cover`, `recap.deck`, `gallery:greeting`.
  final String placement;
  final Color? color;
  final int? headingLevel;
  final TextAlign textAlign;
  final VoidCallback? onDone;

  static const int cap = 48;
  static const int stepMs = 50;
  static const int blinkMs = 530;
  static const int tailFadeMs = 200;
  static const int dematerialiseMs = 350;

  /// The whole timeline for [graphemes] graphemes: typing, the tail fade, three blinks, the dematerialise.
  static Duration timeline(int graphemes) =>
      Duration(milliseconds: (graphemes > cap ? cap : graphemes) * stepMs + (graphemes > cap ? tailFadeMs : 0) + 3 * 2 * blinkMs + dematerialiseMs);

  @override
  ConsumerState<TypedHeadline> createState() => _TypedHeadlineState();
}

class _TypedHeadlineState extends ConsumerState<TypedHeadline> with TickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  late final SingleMotionController _cx = SingleMotionController(motion: SpringMotion(springOf(gt.springTrack)), vsync: this);
  late final SingleMotionController _cy = SingleMotionController(motion: SpringMotion(springOf(gt.springTrack)), vsync: this);
  final FocusNode _focus = FocusNode(debugLabel: 'TypedHeadline', skipTraversal: true);
  final ValueNotifier<double> _ms = ValueNotifier(0);
  late final List<String> _g = widget.text.characters.toList();
  late Set<String> _revealed;
  late String _key;
  bool _typing = false;
  bool _done = false;
  bool _skipped = false;
  bool _placed = false;
  double _skipAt = 0;
  Animation<double>? _secondary;
  GlassMotionEntry? _entry;
  int _lastVisible = -1;

  int get _n => _g.length;
  int get _typed => _n > TypedHeadline.cap ? TypedHeadline.cap : _n;
  double get _typeEnd => _typed * TypedHeadline.stepMs.toDouble();
  double get _tailEnd => _typeEnd + (_n > TypedHeadline.cap ? TypedHeadline.tailFadeMs : 0);
  double get _blinkEnd => _tailEnd + 6 * TypedHeadline.blinkMs;
  double get _total => _blinkEnd + TypedHeadline.dematerialiseMs;

  @override
  void initState() {
    super.initState();
    _cx.value = 0;
    _cy.value = 0;
    _revealed = ref.read(revealedHeadingsProvider);
    _key = '${glassProfileIdOf(ref)}:${widget.placement}';
    if (_revealed.contains(_key)) {
      _done = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final sec = ModalRoute.of(context)?.secondaryAnimation;
    if (sec != _secondary) {
      _secondary?.removeStatusListener(_onRoute);
      _secondary = sec;
      _secondary?.addStatusListener(_onRoute);
    }
    if (!_typing && !_done && !ref.read(glassMotionPrefsProvider).reduced) _begin();
  }

  void _begin() {
    if (_typing || _done) return;
    _typing = true;
    _revealed.add(_key);
    HardwareKeyboard.instance.addHandler(_onKey);
    _entry = GlassMotion.recorder.begin(MotionName.typingReveal.label, TypedHeadline.timeline(_n).inMilliseconds);
    unawaited(_ticker.start());
  }

  void _onRoute(AnimationStatus s) {
    if (s == AnimationStatus.forward) _skip();
  }

  bool _onKey(KeyEvent e) {
    if (e is! KeyDownEvent) return false;
    // A key press skips it while focus is on the headline or while no widget holds primary focus.
    final primary = FocusManager.instance.primaryFocus;
    if (primary == null || primary == _focus || _focus.hasFocus) _skip();
    return false;
  }

  /// Completes the typing at once; the caret still blinks and leaves.
  void _skip() {
    if (!_typing || _skipped || _done) return;
    _skipped = true;
    _skipAt = _ms.value;
    // Jump to the end of typing and the tail; keep the caret's blink and exit on their own clock.
    final shift = _tailEnd - _skipAt;
    if (shift > 0) _offset += shift;
  }

  double _offset = 0;
  double _tx = 0;
  double _ty = 0;

  void _onTick(Duration elapsed) {
    final ms = elapsed.inMicroseconds / 1000 + _offset;
    if (ms >= _total) {
      _finish();
      return;
    }
    _ms.value = ms;
    final v = _visibleAt(ms);
    if (v != _lastVisible) {
      _lastVisible = v;
    }
  }

  int _visibleAt(double ms) => (ms ~/ TypedHeadline.stepMs).clamp(0, _typed);

  void _finish() {
    _ticker.stop();
    HardwareKeyboard.instance.removeHandler(_onKey);
    final e = _entry;
    _entry = null;
    if (e != null) GlassMotion.recorder.end(e);
    _typing = false;
    _done = true;
    if (mounted) setState(() {});
    widget.onDone?.call();
  }

  @override
  void dispose() {
    _secondary?.removeStatusListener(_onRoute);
    HardwareKeyboard.instance.removeHandler(_onKey);
    _ticker.dispose();
    _cx.dispose();
    _cy.dispose();
    _focus.dispose();
    _ms.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final legible = ref.watch(glassA11yProvider.select((a) => a.legible));
    final reduced = ref.watch(glassReducedProvider);
    final style = roleStyle(context, widget.role, legible: legible).copyWith(color: widget.color ?? gt.colorLabel1);
    final plain = Text(widget.text, style: style, textAlign: widget.textAlign, textScaler: TextScaler.noScaling);
    Widget body;
    if (reduced || _done) {
      body = plain;
    } else {
      body = LayoutBuilder(
        builder: (context, c) => GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (_) => _skip(),
          child: Focus(
            focusNode: _focus,
            child: ValueListenableBuilder<double>(
              valueListenable: _ms,
              builder: (context, ms, _) => _frame(context, ms, style, c.hasBoundedWidth ? c.maxWidth : double.infinity),
            ),
          ),
        ),
      );
    }
    return Semantics(header: widget.headingLevel != null, headingLevel: widget.headingLevel, label: widget.text, child: ExcludeSemantics(child: body));
  }

  InlineSpan _spans(double ms, TextStyle style) {
    final visible = _visibleAt(ms);
    final transparent = style.copyWith(color: const Color(0x00000000));
    final color = style.color ?? gt.colorLabel1;
    final children = <InlineSpan>[];
    final tailStart = _typed;
    final tailAlpha = _n > TypedHeadline.cap ? ((ms - _typeEnd) / TypedHeadline.tailFadeMs).clamp(0.0, 1.0) : 1.0;
    for (var i = 0; i < _n; i++) {
      if (i < visible) {
        final age = ms - i * TypedHeadline.stepMs;
        if (i == visible - 1 && age < 40) {
          // The newest grapheme: a 40 ms fade and a 0.8 to 1 scale on springTick.
          final p = (age / 40).clamp(0.0, 1.0);
          children.add(WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Transform.scale(scale: 0.8 + 0.2 * p, child: Opacity(opacity: p, child: Text(_g[i], style: style, textScaler: TextScaler.noScaling))),
          ),);
        } else {
          children.add(TextSpan(text: _g[i], style: style));
        }
      } else if (i >= tailStart && tailAlpha > 0) {
        children.add(TextSpan(text: _g[i], style: style.copyWith(color: color.withValues(alpha: color.a * tailAlpha))));
      } else {
        children.add(TextSpan(text: _g[i], style: transparent));
      }
    }
    return TextSpan(children: children, style: style);
  }

  Widget _frame(BuildContext context, double ms, TextStyle style, double maxWidth) {
    final span = _spans(ms, style);
    final layoutSpan = TextSpan(text: widget.text, style: style);
    final painter = TextPainter(text: layoutSpan, textDirection: TextDirection.ltr, textAlign: widget.textAlign, textScaler: TextScaler.noScaling)..layout(maxWidth: maxWidth);
    final visible = _visibleAt(ms);
    final units = _g.take(visible).join().length;
    final off = painter.getOffsetForCaret(TextPosition(offset: units), Rect.zero);
    final em = style.fontSize ?? 16;
    final lineH = painter.preferredLineHeight;
    painter.dispose();
    // The caret follows its target on springTrack (both axes).
    if (!_placed) {
      _placed = true;
      _cx.value = off.dx;
      _cy.value = off.dy;
      _tx = off.dx;
      _ty = off.dy;
    } else if (_tx != off.dx || _ty != off.dy) {
      _tx = off.dx;
      _ty = off.dy;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _cx.animateTo(_tx);
        _cy.animateTo(_ty);
      });
    }
    // Caret opacity: solid while typing, three blinks, then the dematerialise.
    double alpha = 1;
    double blur = 0;
    if (ms >= _tailEnd) {
      final since = ms - _tailEnd;
      if (since < 6 * TypedHeadline.blinkMs) {
        alpha = (since ~/ TypedHeadline.blinkMs).isEven ? 1 : 0;
      } else {
        final p = ((since - 6 * TypedHeadline.blinkMs) / TypedHeadline.dematerialiseMs).clamp(0.0, 1.0);
        alpha = 1 - gt.curveDematerialize.curve.transform(p);
        blur = 6 * p;
      }
    }
    final caret = AnimatedBuilder(
      animation: Listenable.merge([_cx, _cy]),
      builder: (context, _) => Positioned(
        left: _cx.value - 1,
        top: _cy.value + (lineH - em * 0.72) / 2,
        child: IgnorePointer(
          child: Opacity(
            opacity: alpha,
            child: ImageFiltered(
              enabled: blur > 0.05,
              imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: CustomPaint(size: Size(2, em * 0.72), painter: _CaretPainter()),
            ),
          ),
        ),
      ),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        RichText(text: span, textAlign: widget.textAlign, textScaler: TextScaler.noScaling),
        caret,
      ],
    );
  }
}

class _CaretPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(1));
    canvas.drawRRect(r, Paint()..color = const Color(0x73A99BFF)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawRRect(r, Paint()..color = gt.colorIris400);
    canvas.drawRect(Rect.fromLTWH(size.width / 2 - 0.5, 1, 1, size.height - 2), Paint()..color = const Color(0xFFFFFFFF));
  }

  @override
  bool shouldRepaint(_CaretPainter old) => false;
}
