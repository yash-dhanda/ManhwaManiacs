import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/cine_text.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// Types [text] one grapheme per [perGrapheme] (50 ms, `CineDur.type`) with a
/// blinking caret; the full string is in semantics from the first frame.
/// Reduced motion (or [animate] false): the whole value at once, no caret.
class TypedText extends StatefulWidget {
  const TypedText(
    this.text, {
    super.key,
    required this.style,
    this.scaler,
    this.delay = Duration.zero,
    this.perGrapheme = CineDur.type,
    this.animate = true,
    this.caret = true,
    this.maxLines,
    this.textAlign,
    this.header = false,
    this.onDone,
    this.semanticsLabel,
  });

  final String text;
  final TextStyle style;
  final TextScaler? scaler;
  final Duration delay;
  final Duration perGrapheme;
  final bool animate;
  final bool caret;
  final int? maxLines;
  final TextAlign? textAlign;
  final bool header;
  final VoidCallback? onDone;
  final String? semanticsLabel;

  @override
  State<TypedText> createState() => _TypedTextState();
}

class _TypedTextState extends State<TypedText> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  bool _done = false;

  int get _n => widget.text.characters.length;
  Duration get _total => widget.delay + widget.perGrapheme * _n;

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed && !_done) {
        _done = true;
        widget.onDone?.call();
      }
    });
  }

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _restart();
    }
  }

  void _restart() {
    _done = false;
    if (!widget.animate || cineReduced(context) || _n == 0) {
      _c.value = 1;
      _done = true;
      return;
    }
    _c.duration = _total;
    _c.forward(from: 0);
  }

  @override
  void didUpdateWidget(TypedText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) _restart();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chars = widget.text.characters;
    return Semantics(
      header: widget.header,
      label: widget.semanticsLabel ?? widget.text,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final finished = _c.isCompleted || _c.duration == null;
            final ms = _c.value * (_c.duration?.inMilliseconds ?? 0);
            final shown = finished ? _n : (((ms - widget.delay.inMilliseconds) / widget.perGrapheme.inMilliseconds).floor()).clamp(0, _n);
            final visible = chars.take(shown).toString();
            final rest = chars.skip(shown).toString();
            final blink = (ms ~/ CineDur.caret.inMilliseconds).isEven;
            return Text.rich(
              TextSpan(
                style: widget.style,
                children: [
                  TextSpan(text: visible),
                  if (!finished && widget.caret)
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: SizedBox(
                        width: 0,
                        height: (widget.style.fontSize ?? 16) * 0.9,
                        child: OverflowBox(
                          maxWidth: 3,
                          alignment: Alignment.centerLeft,
                          child: ColoredBox(color: blink ? (widget.style.color ?? CineColors.ink100) : Colors.transparent, child: const SizedBox(width: 2, height: double.infinity)),
                        ),
                      ),
                    ),
                  TextSpan(text: rest, style: const TextStyle(color: Colors.transparent)),
                ],
              ),
              textScaler: widget.scaler,
              maxLines: widget.maxLines,
              textAlign: widget.textAlign,
            );
          },
        ),
      ),
    );
  }
}

/// A numeral typed in `type.numeral`: the value in semantics from frame one.
class TypedNumeral extends StatelessWidget {
  const TypedNumeral(this.value, {super.key, this.delay = Duration.zero, this.animate = true, this.color, this.scale = 1, this.semanticsLabel});

  final String value;
  final Duration delay;
  final bool animate;
  final Color? color;
  final double scale;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final role = context.cine.typeNumeral;
    final base = cineStyle(context, role, color: color, features: kNumeralFeatures);
    return TypedText(
      value,
      style: scale == 1 ? base : base.copyWith(fontSize: base.fontSize! * scale),
      scaler: CineType.scaler(context, role),
      delay: delay,
      animate: animate,
      maxLines: 1,
      semanticsLabel: semanticsLabel,
    );
  }
}
