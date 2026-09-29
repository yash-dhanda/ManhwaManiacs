import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The page masthead (cinematic 7.27): kicker (folio + section), the level-1 heading revealed on
/// mount, a one-line deck and a `rule.heavy` drawn after the letters land; 32 px below.
class CineMasthead extends StatelessWidget {
  const CineMasthead({super.key, required this.kicker, required this.title, this.deck, this.focusNode, this.id});

  /// `No. 02 — YOUR SHELF`.
  final String kicker, title;
  final String? deck;
  final FocusNode? focusNode;
  final String? id;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    // The rule draws after the letters land: the reveal runs about 1.2 s for a short title.
    final letters = title.characters.where((ch) => ch != ' ').length;
    final landed = 120 + (letters < 2 ? 0 : (letters - 1) * (24.0 < 560 / (letters - 1) ? 24.0 : 560 / (letters - 1))) + 640;
    return Padding(
      padding: EdgeInsets.only(bottom: c.space8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        CineRoleText(kicker, c.typeKicker, color: c.colorInk45),
        SizedBox(height: c.space2),
        SetHeading(
          title,
          id: id ?? 'masthead-$title',
          style: CineText.style(context, c.typeMasthead).copyWith(color: c.colorInk100),
          cap: c.typeMasthead.cap,
          level: 1,
          trigger: SetTrigger.mount,
          focusNode: focusNode,
        ),
        if (deck != null) ...[SizedBox(height: c.space2), CineRoleText(deck!, c.typeDeck, color: c.colorInk60, maxLines: 2, overflow: TextOverflow.ellipsis)],
        SizedBox(height: c.space4),
        CineRuleDraw(kind: CineRuleKind.heavy, delay: Duration(milliseconds: landed.round())),
      ],),
    );
  }
}
