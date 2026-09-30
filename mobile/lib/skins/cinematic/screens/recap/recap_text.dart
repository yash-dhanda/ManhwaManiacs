import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:manhwamaniacs/features/recap/providers/recap_providers.dart' show kRecapParagraphToken;
import 'package:manhwamaniacs/skins/cinematic/screens/recap/drop_cap_paragraph.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';

/// The recap prose (cinematic 9.1.5): Newsreader 18/28 (20/32 from 600 dp), at most 58 ch wide,
/// every word fading in over 160 ms as it is revealed (no fade under reduced motion), a
/// Bodoni Moda drop cap on the first paragraph and cast names in italics. While streaming the
/// text is excluded from semantics; complete, it is one labelled node.
class RecapText extends StatefulWidget {
  const RecapText({super.key, required this.words, required this.cast, required this.complete, this.wide = false});

  /// Revealed tokens (`kRecapParagraphToken` between paragraphs).
  final List<String> words;
  final List<String> cast;
  final bool complete;
  final bool wide;

  /// The plain text of [words], paragraphs split by a blank line.
  static String plain(List<String> words) {
    final b = StringBuffer();
    for (final w in words) {
      if (w == kRecapParagraphToken) {
        b.write('\n\n');
      } else {
        if (b.isNotEmpty && !b.toString().endsWith('\n\n')) b.write(' ');
        b.write(w);
      }
    }
    return b.toString();
  }

  /// The paragraphs of [words]: token lists with the breaks removed.
  static List<List<int>> paragraphs(List<String> words) {
    final out = <List<int>>[<int>[]];
    for (var i = 0; i < words.length; i++) {
      if (words[i] == kRecapParagraphToken) {
        if (out.last.isNotEmpty) out.add(<int>[]);
      } else {
        out.last.add(i);
      }
    }
    if (out.last.isEmpty) out.removeLast();
    return out;
  }

  @override
  State<RecapText> createState() => _RecapTextState();
}

class _RecapTextState extends State<RecapText> with SingleTickerProviderStateMixin {
  static const _fade = Duration(milliseconds: 160);
  late final Ticker _ticker;
  final Map<int, Duration> _shown = {};
  Duration _now = Duration.zero;
  bool _reduced = false;

  void _onTick(Duration d) {
    setState(() => _now = d);
    final last = _shown.values.isEmpty ? Duration.zero : _shown.values.reduce((a, b) => a > b ? a : b);
    if (d - last > _fade) _ticker.stop();
  }

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = CineMotion.reduced(context);
  }

  @override
  void didUpdateWidget(RecapText old) {
    super.didUpdateWidget(old);
    if (_reduced) return;
    var any = false;
    for (var i = old.words.length; i < widget.words.length; i++) {
      _shown[i] = _ticker.isActive ? _now : Duration.zero;
      any = true;
    }
    if (any && !_ticker.isActive) {
      _now = Duration.zero;
      for (final k in _shown.keys.toList()) {
        _shown[k] = Duration.zero;
      }
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  double _alpha(int i) {
    if (_reduced) return 1;
    final t = _shown[i];
    if (t == null) return 1;
    return ((_now - t).inMicroseconds / _fade.inMicroseconds).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final size = widget.wide ? 20.0 : 18.0, leading = widget.wide ? 32.0 : 28.0;
    final ink = widget.wide ? c.colorInk80 : c.colorInk100;
    final style = CineText.literal(context, CineFace.newsreader, size, leading).copyWith(color: ink);
    // The cap is three lines tall (84 px on 28 px leading, 96 px on 32 px), Bodoni Moda Roman 800.
    final capStyle = CineText.literal(context, CineFace.bodoni, leading * 3, leading * 3, wght: 800).copyWith(color: c.colorInk100, height: 0.95);
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.5);
    final paras = RecapText.paragraphs(widget.words);
    final names = [for (final n in widget.cast) if (n.trim().isNotEmpty) n.trim()]..sort((a, b) => b.length.compareTo(a.length));
    final nameRe = names.isEmpty ? null : RegExp('(?<![\\w])(${names.map(RegExp.escape).join('|')})(?![\\w])');

    // The spans of the plain paragraph text in [s0, s1): one run per word (its own fade), split
    // again where a cast name sits so it can be italic.
    List<InlineSpan> spansFor(List<int> idx, String plain, List<(int, int)> ital, int s0, int s1) {
      final out = <InlineSpan>[];
      void emit(int x, int y, Color color) {
        x = x < s0 ? s0 : x;
        y = y > s1 ? s1 : y;
        if (y <= x) return;
        var cur = x;
        for (final r in ital) {
          final ra = r.$1 > cur ? r.$1 : cur, rb = r.$2 < y ? r.$2 : y;
          if (rb <= ra) continue;
          if (ra > cur) out.add(TextSpan(text: plain.substring(cur, ra), style: TextStyle(color: color)));
          out.add(TextSpan(text: plain.substring(ra, rb), style: TextStyle(color: color, fontStyle: FontStyle.italic)));
          cur = rb;
        }
        if (cur < y) out.add(TextSpan(text: plain.substring(cur, y), style: TextStyle(color: color)));
      }

      var pos = 0;
      for (final i in idx) {
        final len = widget.words[i].length;
        emit(pos, pos + len + 1, ink.withValues(alpha: ink.a * _alpha(i)));
        pos += len + 1;
      }
      return out;
    }

    final children = <Widget>[];
    for (var p = 0; p < paras.length; p++) {
      final idx = paras[p];
      final plain = idx.map((i) => widget.words[i]).join(' ');
      final ital = nameRe == null ? const <(int, int)>[] : [for (final m in nameRe.allMatches(plain)) (m.start, m.end)];
      final built = p == 0 && plain.length >= 2
          ? RecapDropCap(
              text: plain,
              style: style,
              capStyle: capStyle,
              textScaler: scaler,
              buildSpans: (slice, start) => spansFor(idx, plain, ital, start, start + slice.length),
            )
          : Text.rich(TextSpan(style: style, children: spansFor(idx, plain, ital, 0, plain.length)), textScaler: scaler);
      children.add(Padding(padding: EdgeInsets.only(top: p == 0 ? 0 : leading * 0.6), child: built));
    }
    final body = Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
    if (!widget.complete) return ExcludeSemantics(child: body);
    return Semantics(container: true, label: RecapText.plain(widget.words), excludeSemantics: true, child: body);
  }
}
