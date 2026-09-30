import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/core/diagnostics/motion_recorder.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/motion_math.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// Lets a page skip a headline from elsewhere.
class TypedHeadlineController {
  _TypedHeadlineState? _state;

  void skip() => _state?._skip();
}

/// The main headline typing reveal (cinematic 10.2): one grapheme per 50 ms on a timestamp clock,
/// the full string laid out from frame 0, a `spot` caret that blinks three times when done.
class TypedHeadline extends StatefulWidget {
  const TypedHeadline(
    this.text, {
    super.key,
    required this.style,
    this.cap = 2.0,
    this.level,
    this.onDone,
    this.controller,
    this.delay = Duration.zero,
  });

  final String text;
  final TextStyle style;
  final double cap;

  /// 1-3, or null for a typed line that is not a page title.
  final int? level;
  final VoidCallback? onDone;
  final TypedHeadlineController? controller;

  /// Wait this long before the first grapheme (a stat block's numeral starts 120 ms after its rule).
  final Duration delay;

  @override
  State<TypedHeadline> createState() => _TypedHeadlineState();
}

class _TypedHeadlineState extends State<TypedHeadline> with TickerProviderStateMixin {
  static const int _blinkMs = 3340;

  late final int _len = widget.text.characters.length;
  late final Ticker _ticker;
  late final AnimationController _blink;
  MotionHandle? _handle;
  int _n = 0;
  Timer? _delayTimer;
  bool _began = false;
  bool _typing = false, _skipped = false, _done = false, _reduced = false, _started = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    _blink = AnimationController(vsync: this, duration: const Duration(milliseconds: _blinkMs));
    widget.controller?._state = this;
    assert(() {
      if (_len > 60) debugPrint('TypedHeadline: headlines only, <= 60 graphemes (got $_len)');
      return true;
    }());
    assert(_len <= 60, 'TypedHeadline is for headlines of at most 60 graphemes');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduced = CineMotion.reduced(context);
    if (_reduced || _len == 0) {
      _n = _len;
      _done = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onDone?.call();
      });
    } else {
      _typing = true;
      if (widget.delay == Duration.zero) {
        _begin();
      } else {
        _delayTimer = Timer(widget.delay, () {
          if (mounted && !_skipped) _begin();
        });
      }
    }
  }

  void _begin() {
    setState(() => _began = true);
    _handle = CineMotion.track(MotionName.type, 50 * _len);
    _ticker.start();
  }

  void _tick(Duration elapsed) {
    if (_skipped) {
      _ticker.stop();
      return;
    }
    final n = typedCount(elapsed.inMilliseconds, _len);
    if (n != _n) setState(() => _n = n);
    if (n >= _len) _finish();
  }

  void _finish({bool skipped = false}) {
    _ticker.stop();
    _handle?.end(interrupted: skipped);
    _handle = null;
    if (_done) return;
    setState(() {
      _typing = false;
      _done = true;
      _n = _len;
    });
    _blink.forward(from: 0);
    widget.onDone?.call();
  }

  void _skip() {
    if (!_typing || _done) return;
    _skipped = true;
    _finish(skipped: true);
  }

  @override
  void dispose() {
    if (widget.controller?._state == this) widget.controller?._state = null;
    _delayTimer?.cancel();
    _handle?.end(interrupted: true);
    _ticker.dispose();
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cine = context.cine;
    final s = widget.style;
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: widget.cap);
    final size = scaler.scale(s.fontSize ?? 16);
    Widget head(Widget child) => Semantics(
          header: widget.level != null,
          headingLevel: widget.level,
          label: widget.text,
          excludeSemantics: true,
          child: child,
        );
    if (_reduced) return head(Text(widget.text, style: s, textScaler: scaler));

    final chars = widget.text.characters;
    final revealed = chars.take(_n).toString();
    final rest = chars.skip(_n).toString();
    final caret = (!_began && !_done) ? const TextSpan() : WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: AnimatedBuilder(
        animation: _blink,
        builder: (_, __) {
          double o = 1;
          if (_done) {
            final ms = _blink.value * _blinkMs;
            o = ms < 3180 ? ((ms ~/ 530).isOdd ? 1.0 : 0.0) : 1 - (ms - 3180) / 160;
          }
          return Opacity(
            opacity: o.clamp(0.0, 1.0),
            child: SizedBox(
              width: 0,
              height: 0.86 * size,
              child: OverflowBox(
                minWidth: 0,
                maxWidth: 0.12 * size,
                alignment: Alignment.centerLeft,
                child: Container(width: 0.12 * size, height: 0.86 * size, color: cine.colorSpot),
              ),
            ),
          );
        },
      ),
    );
    final text = Text.rich(
      TextSpan(style: s, children: [
        TextSpan(text: revealed),
        caret,
        TextSpan(text: rest, style: const TextStyle(color: Color(0x00000000))),
      ],),
      textScaler: scaler,
    );
    return head(GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _skip,
      child: Focus(
        canRequestFocus: _typing,
        onKeyEvent: (_, e) {
          if (e is KeyDownEvent && (e.logicalKey == LogicalKeyboardKey.enter || e.logicalKey == LogicalKeyboardKey.space)) {
            _skip();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: text,
      ),
    ),);
  }
}
