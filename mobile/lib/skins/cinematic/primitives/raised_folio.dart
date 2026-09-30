import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// A raised footnote mark (cinematic 7.5): IBM Plex Mono at 0.72 x the size, lifted by 0.35 x the
/// font size in a `WidgetSpan`. Never a Unicode superscript; spoken "footnote 3".
InlineSpan raisedFolio(int n, double fontSize,
        {Color color = CineColors.ink60,}) =>
    WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: Semantics(
        label: 'footnote $n',
        child: ExcludeSemantics(
          child: Transform.translate(
            offset: Offset(0, -0.35 * fontSize),
            child: Text('$n',
                style: TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: fontSize * 0.72,
                    color: color,
                    height: 1,),),
          ),
        ),
      ),
    );

/// A caption with a raised folio after it.
class CaptionWithFolio extends StatelessWidget {
  const CaptionWithFolio(this.text, this.mark,
      {super.key,
      required this.style,
      this.scaler,
      this.markColor = CineColors.ink60,});
  final String text;
  final int mark;
  final TextStyle style;
  final TextScaler? scaler;
  final Color markColor;

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(style: style, children: [
          TextSpan(text: text),
          raisedFolio(mark, style.fontSize ?? 14, color: markColor),
        ],),
        textScaler: scaler,
      );
}
