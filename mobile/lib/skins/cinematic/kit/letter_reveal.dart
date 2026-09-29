import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/cine_text.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

enum SetTrigger { mount, inView, signal }

/// Stand-in for mobile/04's `SetHeading` (letter reveal), with the
/// `typedRange` this step adds: graphemes inside `[start, end)` type at 50 ms
/// per grapheme starting at the stagger time of the range's first grapheme;
/// the full string stays in the semantics label. Reduced motion fades the
/// whole title in over 200 ms.
///
/// TODO(mobile/04): replace by `primitives/set_heading.dart` (`typedRange` there,
/// with its case in `set_heading_test.dart`); `inView` starts on mount here (lazy
/// slivers only build what is near the viewport).
class SetHeading extends StatefulWidget {
  const SetHeading(
    this.text, {
    super.key,
    required this.role,
    this.level = 2,
    this.trigger = SetTrigger.mount,
    this.go = true,
    this.color,
    this.typedRange,
    this.textAlign,
    this.stagger = const Duration(milliseconds: 24),
    this.delay = Duration.zero,
    this.maxLines,
  });

  final String text;
  final CineTextRole role;
  final int level;
  final SetTrigger trigger;

  /// For [SetTrigger.signal]: the reveal starts when this turns true.
  final bool go;
  final Color? color;
  final (int, int)? typedRange;
  final TextAlign? textAlign;
  final Duration stagger;
  final Duration delay;
  final int? maxLines;

  @override
  State<SetHeading> createState() => _SetHeadingState();
}

class _SetHeadingState extends State<SetHeading> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  bool _ran = false;

  int get _n => widget.text.characters.length;

  Duration get _total {
    final r = widget.typedRange;
    final letters = widget.delay + widget.stagger * _n + CineDur.letter;
    if (r == null) return letters;
    final typedEnd = widget.delay + widget.stagger * r.$1 + CineDur.type * (r.$2 - r.$1);
    return typedEnd > letters ? typedEnd : letters;
  }

  bool get _armed => widget.trigger != SetTrigger.signal || widget.go;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeRun();
  }

  @override
  void didUpdateWidget(SetHeading old) {
    super.didUpdateWidget(old);
    _maybeRun();
  }

  void _maybeRun() {
    if (_ran || !_armed) return;
    _ran = true;
    if (cineReduced(context)) {
      _c.duration = CineDur.clip;
    } else {
      _c.duration = _total;
    }
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = cineReduced(context);
    final base = cineStyle(context, widget.role, color: widget.color);
    final text = widget.role.upper ? widget.text.toUpperCase() : widget.text;
    final chars = text.characters.toList();
    return Semantics(
      header: true,
      headingLevel: widget.level,
      label: text,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final ms = _c.value * (_c.duration?.inMilliseconds ?? 0);
            final spans = <InlineSpan>[];
            final base0 = base.color ?? CineColors.ink100;
            for (var i = 0; i < chars.length; i++) {
              double a;
              if (!_ran) {
                a = 0;
              } else if (reduced) {
                a = _c.value;
              } else if (widget.typedRange != null && i >= widget.typedRange!.$1 && i < widget.typedRange!.$2) {
                final at = widget.delay.inMilliseconds + widget.stagger.inMilliseconds * widget.typedRange!.$1 + CineDur.type.inMilliseconds * (i - widget.typedRange!.$1);
                a = ms >= at ? 1 : 0;
              } else {
                final start = widget.delay.inMilliseconds + widget.stagger.inMilliseconds * i;
                a = CineCurves.settle.transform(((ms - start) / CineDur.letter.inMilliseconds).clamp(0.0, 1.0));
              }
              spans.add(TextSpan(text: chars[i], style: TextStyle(color: base0.withValues(alpha: base0.a * a))));
            }
            return Text.rich(
              TextSpan(style: base, children: spans),
              textScaler: CineType.scaler(context, widget.role),
              textAlign: widget.textAlign,
              maxLines: widget.maxLines,
            );
          },
        ),
      ),
    );
  }
}
