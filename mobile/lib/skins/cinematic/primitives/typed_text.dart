import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/motion_math.dart';

/// A run of typed text; [italic] is set in the role's italic (names and titles).
class TypedRun {
  const TypedRun(this.text, {this.italic = false});
  final String text;
  final bool italic;
}

/// Text typed at 50 ms per grapheme (cinematic 10.2.2), for lines a headline may not be: the letter
/// sender kicker, the `Sent to you` note, the privacy preview line. The whole string is laid out
/// from frame 0 (untyped graphemes are transparent), the full text is the semantics label, and
/// reduced motion shows it whole at once. [delay] waits before the first grapheme.
class TypedText extends StatefulWidget {
  const TypedText(this.runs, {super.key, required this.style, this.delay = Duration.zero, this.maxLines, this.overflow, this.onDone, this.type = true});

  TypedText.plain(String text, {Key? key, required TextStyle style, Duration delay = Duration.zero, int? maxLines, TextOverflow? overflow, VoidCallback? onDone, bool type = true})
      : this([TypedRun(text)], key: key, style: style, delay: delay, maxLines: maxLines, overflow: overflow, onDone: onDone, type: type);

  final List<TypedRun> runs;
  final TextStyle style;
  final Duration delay;
  final int? maxLines;
  final TextOverflow? overflow;
  final VoidCallback? onDone;

  /// False shows the text whole (a letter that has been seen before).
  final bool type;

  @override
  State<TypedText> createState() => _TypedTextState();
}

class _TypedTextState extends State<TypedText> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  late final String _full = widget.runs.map((r) => r.text).join();
  late final int _len = _full.characters.length;
  int _n = 0;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!widget.type || CineMotion.reduced(context) || _len == 0) {
      _n = _len;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onDone?.call();
      });
    } else {
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final ms = elapsed.inMilliseconds - widget.delay.inMilliseconds;
    final n = ms < 0 ? 0 : typedCount(ms, _len);
    if (n != _n) setState(() => _n = n);
    if (n >= _len) {
      _ticker.stop();
      widget.onDone?.call();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    var left = _n;
    for (final r in widget.runs) {
      final chars = r.text.characters;
      final typed = left <= 0 ? 0 : (left >= chars.length ? chars.length : left);
      left -= chars.length;
      final style = r.italic ? widget.style.copyWith(fontStyle: FontStyle.italic) : null;
      if (typed > 0) spans.add(TextSpan(text: chars.take(typed).toString(), style: style));
      if (typed < chars.length) {
        spans.add(TextSpan(text: chars.skip(typed).toString(), style: (style ?? widget.style).copyWith(color: const Color(0x00000000))));
      }
    }
    return Semantics(
      label: _full,
      excludeSemantics: true,
      child: Text.rich(TextSpan(children: spans), style: widget.style, maxLines: widget.maxLines, overflow: widget.overflow),
    );
  }
}
