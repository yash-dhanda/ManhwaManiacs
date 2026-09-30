import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/recap/recap_deck.dart';
import 'package:manhwamaniacs/skins/glass/screens/recap/deck_card.dart';

/// The compact recap (`scope=chapter`, from the pill): one card "Last time" of 3 to 4 sentences.
class CompactRecap extends StatelessWidget {
  const CompactRecap({super.key, required this.deck});
  final DeckState deck;

  @override
  Widget build(BuildContext context) {
    final sec = deck.sections.where((s) => s.kind == 'last_time' || s.kind == 'left_off').firstOrNull;
    return DeckCardFrame(title: sec != null && sec.title.trim().isNotEmpty ? sec.title : 'Last time', child: sectionBody(sec));
  }
}
