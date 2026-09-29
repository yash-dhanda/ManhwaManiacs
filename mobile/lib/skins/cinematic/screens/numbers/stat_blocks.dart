import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/cine_text.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/folio.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/rules.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/typed_text.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// One stat block (7.6): a 3 px `rule.heavy` on top, a kicker, a `type.numeral`
/// value (Bodoni Moda 900, lining and tabular figures), a caption; no frame.
///
/// [signature] runs the first-paint moment: the rule draws (480 ms) after
/// [ruleDelay], the numeral types at 50 ms per grapheme 120 ms after its rule
/// starts. Otherwise the numeral cross-fades in over 160 ms.
class StatBlock extends StatelessWidget {
  const StatBlock({
    super.key,
    required this.kicker,
    required this.value,
    required this.caption,
    this.footnote,
    this.signature = false,
    this.ruleDelay = Duration.zero,
  });

  final String kicker;
  final String value;
  final String caption;
  final int? footnote;
  final bool signature;
  final Duration ruleDelay;

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    final capStyle = cineStyle(context, t.typeCaption, color: CineColors.ink60);
    final numeral = signature
        ? TypedNumeral(value, delay: ruleDelay + const Duration(milliseconds: 120), semanticsLabel: '$kicker $value')
        : _FadeIn(child: TypedNumeral(value, animate: false, semanticsLabel: '$kicker $value'));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      DrawnRule(delay: ruleDelay, animate: signature),
      const SizedBox(height: 12),
      CineText(kicker, t.typeKicker, color: CineColors.ink60),
      const SizedBox(height: 4),
      numeral,
      const SizedBox(height: 4),
      if (footnote == null) CineText(caption, t.typeCaption, color: CineColors.ink60) else WithFootnote(caption, footnote!, style: capStyle, scaler: CineType.scaler(context, t.typeCaption)),
    ],);
  }
}

/// A 160 ms (`durBeat`) fade-in; reduced motion shows the child at once.
class _FadeIn extends StatefulWidget {
  const _FadeIn({required this.child});
  final Widget child;

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: CineDur.beat);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    cineReduced(context) ? _c.value = 1 : _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _c, child: widget.child);
}

/// The four blocks 2 x 2 on phones and 4 across on tablets.
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.blocks, required this.wide});
  final List<Widget> blocks;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    if (wide) {
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (var i = 0; i < blocks.length; i++) ...[if (i > 0) const SizedBox(width: 24), Expanded(child: blocks[i])],
      ],);
    }
    return Column(children: [
      for (var r = 0; r < blocks.length; r += 2) ...[
        if (r > 0) const SizedBox(height: 24),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: blocks[r]),
          const SizedBox(width: 24),
          Expanded(child: r + 1 < blocks.length ? blocks[r + 1] : const SizedBox.shrink()),
        ],),
      ],
    ],);
  }
}
