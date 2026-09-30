import 'package:manhwamaniacs/features/circle/models/circle_models.dart';

/// One reaction stamp: the label, the glyph (a Phosphor name, null for a text stamp), the text stamp
/// words and whether it is always offered (`hype` and `wrecked` show only with a count).
class ReactionSpec {
  const ReactionSpec(this.kind, this.label, {this.glyph, this.stampText, this.offered = true});
  final ReactionKind kind;
  final String label;
  final String? glyph, stampText;
  final bool offered;
}

/// The seven kinds in stored order.
const List<ReactionSpec> reactionSpecs = [
  ReactionSpec(ReactionKind.loved, 'Loved', glyph: 'heart'),
  ReactionSpec(ReactionKind.shook, 'Shook', glyph: 'lightning'),
  ReactionSpec(ReactionKind.laughed, 'Laughed', glyph: 'smiley'),
  ReactionSpec(ReactionKind.tears, 'Tears', glyph: 'drop'),
  ReactionSpec(ReactionKind.chefsKiss, "Chef's kiss", glyph: 'sparkle'),
  ReactionSpec(ReactionKind.hype, 'Hype', stampText: 'HYPE', offered: false),
  ReactionSpec(ReactionKind.wrecked, 'Wrecked', stampText: 'WRECKED', offered: false),
];

ReactionSpec reactionSpec(ReactionKind k) => reactionSpecs.firstWhere((s) => s.kind == k);

sealed class ReactionAction {
  const ReactionAction();
}

final class SetReaction extends ReactionAction {
  const SetReaction(this.kind);
  final ReactionKind kind;
}

final class ClearReaction extends ReactionAction {
  const ClearReaction();
}

/// Pressing the viewer's own stamp again removes it; another kind moves it.
ReactionAction pressReaction(ReactionKind? mine, ReactionKind kind) => mine == kind ? const ClearReaction() : SetReaction(kind);
