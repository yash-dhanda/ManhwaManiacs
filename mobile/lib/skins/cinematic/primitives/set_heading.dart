import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/diagnostics/motion_recorder.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/on_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// Heading ids that have already revealed this session (cinematic 10.1.1).
final seenHeadingsProvider = StateProvider<Set<String>>((ref) => <String>{}, name: 'seenHeadings');

/// 10.1.1: H3s, mastheads, cover/feature/book/takeover titles.
enum SetTrigger { inView, mount, signal }

/// Per-letter fade, slide up and un-blur (cinematic 10.1, 10.1.6): one controller per heading.
class SetHeading extends ConsumerStatefulWidget {
  const SetHeading(
    this.text, {
    super.key,
    required this.id,
    required this.style,
    required this.cap,
    required this.level,
    this.trigger = SetTrigger.inView,
    this.linked = false,
    this.startDelayMs = 120,
    this.focusNode,
    this.roman,
  });

  final String text;
  final String id;
  final TextStyle style;

  /// The role's 3.3 text-scale cap (`CineTextRole.cap`).
  final double cap;

  /// 1 masthead, 2 section head, 3 subsection; null is not a heading (Login cover lines).
  final int? level;
  final SetTrigger trigger;
  final bool linked;

  /// `scalarStaggerLetter.startDelay`; the splash passes 0 because its timeline replaces it.
  final int startDelayMs;

  /// Lets a route change move focus to the masthead.
  final FocusNode? focusNode;

  /// A grapheme range `[start, end)` of [text] set in Roman inside an italic heading (the seed
  /// title of "Because you read *{title}*", cinematic 9.1.4).
  final ({int start, int end})? roman;

  @override
  ConsumerState<SetHeading> createState() => _SetHeadingState();
}

class _SetHeadingState extends ConsumerState<SetHeading> with TickerProviderStateMixin {
  late final bool _signal = widget.trigger == SetTrigger.signal;
  late final bool _seenAtMount = !_signal && ref.read(seenHeadingsProvider).contains(widget.id);
  late final int _n = widget.text.characters.where((c) => c != ' ').length;
  late final double _step = _n < 2 ? 0 : math.min(24.0, 560 / (_n - 1));
  late final int _plannedMs = (widget.startDelayMs + _step * math.max(0, _n - 1) + 640).round();
  late final AnimationController _c;
  late final AnimationController _hover;
  late final AnimationController _out;
  ScrollPosition? _pos;
  Animation<double>? _route;
  Timer? _signalTimer;
  MotionHandle? _handle;
  bool _armed = false;
  double _screenH = 0;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: Duration(milliseconds: _plannedMs));
    _hover = AnimationController(vsync: this, duration: Duration(milliseconds: 200 + 10 * math.max(0, _n - 1)));
    _out = AnimationController(vsync: this, duration: const Duration(milliseconds: 160));
    _out.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _hover.value = 0;
        _out.value = 0;
      }
    });
    if (_seenAtMount) {
      _c.value = 1;
      return;
    }
    _c.addStatusListener((s) {
      if (s != AnimationStatus.completed) return;
      _handle?.end();
      _handle = null;
      _pos?.removeListener(_check);
      if (!_signal) ref.read(seenHeadingsProvider.notifier).update((set) => {...set, widget.id});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.trigger == SetTrigger.mount) {
        _start();
      } else {
        _check();
      }
    });
  }

  void _start() {
    if (_c.isAnimating || _c.isCompleted) return;
    _handle = CineMotion.track(MotionName.letterSet, _c.duration!.inMilliseconds);
    _c.forward();
  }

  void _onRoute(AnimationStatus s) {
    if (s == AnimationStatus.completed && mounted) _start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenH = MediaQuery.sizeOf(context).height;
    _reduced = CineMotion.reduced(context);
    if (_reduced && !_c.isAnimating) _c.duration = const Duration(milliseconds: 200);
    if (_seenAtMount) return;
    if (_signal && !_armed) {
      // plays when the route's push (the match cut) completes, else 160 ms after the first frame
      _armed = true;
      final r = ModalRoute.of(context)?.animation;
      if (r == null || r.isCompleted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _signalTimer = Timer(const Duration(milliseconds: 160), () {
            if (mounted) _start();
          });
        });
      } else {
        (_route = r).addStatusListener(_onRoute);
      }
    }
    _pos?.removeListener(_check);
    _pos = Scrollable.maybeOf(context)?.position;
    _pos?.addListener(_check);
  }

  void _check() {
    if (!mounted || _c.isCompleted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return;
    final h = box.size.height;
    final visible = visiblePixels(box, _screenH);
    if (widget.trigger == SetTrigger.inView && !_c.isAnimating && visible >= h * 0.5) _start();
    if (_c.isAnimating && visible == 0) _c.value = 1; // left the viewport mid-reveal: jump to the end (4.7)
  }

  @override
  void dispose() {
    _pos?.removeListener(_check);
    _route?.removeStatusListener(_onRoute);
    _signalTimer?.cancel();
    _handle?.end(interrupted: true);
    _c.dispose();
    _hover.dispose();
    _out.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cine = context.cine;
    final s = widget.style.copyWith(fontFeatures: const [ui.FontFeature.disable('kern')]);
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: widget.cap);
    Widget head(Widget child) {
      final inner = widget.level == null
          ? Semantics(label: widget.text, excludeSemantics: true, child: child)
          : Semantics(header: true, headingLevel: widget.level, label: widget.text, excludeSemantics: true, child: child);
      return widget.focusNode == null ? inner : Focus(focusNode: widget.focusNode, skipTraversal: true, child: inner);
    }

    final r = widget.roman;
    final plain = r == null
        ? Text(widget.text, style: s, textScaler: scaler, softWrap: true)
        : Text.rich(
            TextSpan(style: s, children: [
              TextSpan(text: widget.text.characters.take(r.start).toString()),
              TextSpan(text: widget.text.characters.skip(r.start).take(r.end - r.start).toString(), style: const TextStyle(fontStyle: FontStyle.normal)),
              TextSpan(text: widget.text.characters.skip(r.end).toString()),
            ],),
            textScaler: scaler,
            softWrap: true,
          );
    final whole = head(plain);
    if (!widget.linked && _seenAtMount) return whole;
    if (_reduced) return FadeTransition(opacity: _c, child: whole);
    final total = _c.duration!.inMilliseconds.toDouble(), wipeTotal = _hover.duration!.inMilliseconds.toDouble();
    final rise = cine.scalarLetterRise * scaler.scale(s.fontSize!);
    final ink = s.color ?? DefaultTextStyle.of(context).style.color!;
    final delay = widget.startDelayMs.toDouble();
    var i = 0;
    Widget letter(String ch, int gi) {
      final k = i++, start = delay + _step * k;
      final isRoman = r != null && gi >= r.start && gi < r.end;
      final main = Interval(start / total, math.min(1, (start + 640) / total), curve: CineCurves.settle);
      final sharp = Interval(start / total, math.min(1, (start + 440) / total), curve: CineCurves.settle);
      final wipe = Interval(10 * k / wipeTotal, math.min(1, (10 * k + 200) / wipeTotal), curve: CineCurves.easeSet);
      return AnimatedBuilder(
        animation: Listenable.merge([_c, _hover, _out]),
        builder: (_, __) {
          final t = main.transform(_c.value), b = cine.blurLetter * (1 - sharp.transform(_c.value));
          final child = Text(
            ch,
            textScaler: scaler,
            style: s.copyWith(
              color: Color.lerp(ink, cine.colorSpot, wipe.transform(_hover.value) * (1 - _out.value)),
              fontStyle: isRoman ? FontStyle.normal : null,
            ),
          );
          return Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, rise * (1 - t)),
              child: b < 0.05 ? child : ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: b, sigmaY: b), child: child),
            ),
          );
        },
      );
    }

    final words = widget.text.split(' ');
    final starts = <int>[];
    var at = 0;
    for (final w in words) {
      starts.add(at);
      at += w.characters.length + 1;
    }
    final dir = Directionality.of(context);
    final body = head(LayoutBuilder(builder: (context, box) {
      // A word wider than the line cannot break inside its nowrap Row: the plain string wraps
      // normally and fades in over 200 ms instead of revealing per letter (10.1.1 Long words).
      final widest = [
        for (var w = 0; w < words.length; w++) _width(w < words.length - 1 ? '${words[w]} ' : words[w], s, scaler, dir),
      ].fold(0.0, math.max);
      if (widest > box.maxWidth) {
        return FadeTransition(opacity: _c.drive(CurveTween(curve: Interval(0, math.min(1, 200 / total)))), child: plain);
      }
      i = 0;
      return Wrap(children: [
        for (var w = 0; w < words.length; w++)
          Row(mainAxisSize: MainAxisSize.min, children: [
            for (final (j, ch) in words[w].characters.indexed) letter(ch, starts[w] + j),
            if (w < words.length - 1) Text(' ', style: s, textScaler: scaler),
          ],),
      ],);
    },),);
    if (!widget.linked) return body;
    return MouseRegion(
      onEnter: (_) {
        _out.value = 0;
        _hover.forward(from: 0);
      },
      onExit: (_) => _out.forward(from: 0),
      child: body,
    );
  }

  static double _width(String word, TextStyle s, TextScaler scaler, TextDirection dir) {
    final p = TextPainter(text: TextSpan(text: word, style: s), textScaler: scaler, textDirection: dir, maxLines: 1)..layout();
    final w = p.width;
    p.dispose();
    return w;
  }
}

/// Type role step-down for long titles (DESIGN §3.1): one role smaller past 24
/// graphemes, two past 40. [sizes] runs largest to smallest.
double setHeadingSize(String text, List<double> sizes) {
  final n = text.characters.length;
  final step = n > 40 ? 2 : (n > 24 ? 1 : 0);
  return sizes[step.clamp(0, sizes.length - 1)];
}
