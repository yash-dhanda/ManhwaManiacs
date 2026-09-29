import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// What a widget that throws renders in release (cinematic 8.32): a `paper.1` box at the failed
/// widget's size (min 48 px tall) with a 2 px `proof` left rule and one caption line.
class CineBrokenPart extends StatelessWidget {
  const CineBrokenPart({super.key});

  static const String line = 'CORRECTION · This part of the page broke.';

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CineTokens>() ?? cinematicTokens;
    Widget text;
    try {
      text = CineRoleText(line, c.typeCaption, color: c.colorInk60);
    } catch (_) {
      text = Text(line, style: TextStyle(color: c.colorInk60, fontSize: 13));
    }
    return LayoutBuilder(
      builder: (context, box) => Container(
        width: box.maxWidth.isFinite ? box.maxWidth : 240,
        constraints: const BoxConstraints(minHeight: 48),
        padding: EdgeInsets.symmetric(horizontal: c.space3, vertical: c.space2),
        decoration: BoxDecoration(color: c.colorPaper1, border: Border(left: BorderSide(color: c.colorProof, width: 2))),
        alignment: Alignment.centerLeft,
        child: Directionality(textDirection: TextDirection.ltr, child: text),
      ),
    );
  }
}
