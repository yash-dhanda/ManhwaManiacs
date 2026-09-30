import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// A raised footnote mark (§7.5): IBM Plex Mono at 0.72 x the size, lifted by
/// 0.35 x the font size. Never a Unicode superscript; spoken "footnote 3".
InlineSpan footnoteMark(int n, double fontSize, {Color color = CineColors.ink60}) => WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: Semantics(
        label: 'footnote $n',
        child: ExcludeSemantics(
          child: Transform.translate(
            offset: Offset(0, -0.35 * fontSize),
            child: Text('$n', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: fontSize * 0.72, color: color, height: 1)),
          ),
        ),
      ),
    );

/// A caption with a footnote mark after it.
class WithFootnote extends StatelessWidget {
  const WithFootnote(this.text, this.mark, {super.key, required this.style, this.scaler, this.markColor = CineColors.ink60});

  final String text;
  final int mark;
  final TextStyle style;
  final TextScaler? scaler;
  final Color markColor;

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(style: style, children: [TextSpan(text: text), footnoteMark(mark, style.fontSize ?? 14, color: markColor)]),
        textScaler: scaler,
      );
}

/// Speaks a folio: "2 D AGO" -> "2 days ago", "CH 142" -> "chapter 142",
/// "12 H" -> "12 hours".
String spokenFolio(String folio) {
  var s = folio.trim();
  s = s.replaceAllMapped(RegExp(r'(\d+) D AGO'), (m) => '${m[1]} ${m[1] == '1' ? 'day' : 'days'} ago');
  s = s.replaceAllMapped(RegExp(r'(\d+) H AGO'), (m) => '${m[1]} ${m[1] == '1' ? 'hour' : 'hours'} ago');
  s = s.replaceAllMapped(RegExp(r'(\d+) M AGO'), (m) => '${m[1]} ${m[1] == '1' ? 'minute' : 'minutes'} ago');
  s = s.replaceAllMapped(RegExp(r'\bCH (\d+(?:\.\d+)?)'), (m) => 'chapter ${m[1]}');
  s = s.replaceAllMapped(RegExp(r'(\d+) H\b'), (m) => '${m[1]} ${m[1] == '1' ? 'hour' : 'hours'}');
  s = s.replaceAllMapped(RegExp(r'(\d+) M\b'), (m) => '${m[1]} ${m[1] == '1' ? 'minute' : 'minutes'}');
  return s.toLowerCase();
}
