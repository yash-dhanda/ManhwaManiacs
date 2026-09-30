import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs_more.dart';

/// One reaction as Glass names and draws it (glass 9.3.2). Cinematic's labels stay in `features/circle/utils/reaction_kinds.dart`.
class GlassReaction {
  const GlassReaction(this.kind, this.name, this.glyph);
  final ReactionKind kind;
  final String name;
  final Glyph glyph;

  /// The Phosphor Fill glyph.
  IconData get fill => glyph.fill;

  /// "React with Hype" (the screen-reader action).
  String get action => 'React with $name';
}

/// The six offered reactions in bloom order: Hype, Love, Wrecked, Tears, Twist, Masterpiece.
const List<GlassReaction> kGlassReactions = [
  GlassReaction(ReactionKind.hype, 'Hype', GlassGlyph28.fire),
  GlassReaction(ReactionKind.loved, 'Love', GlassGlyph28.heart),
  GlassReaction(ReactionKind.wrecked, 'Wrecked', GlassGlyph28.smileyMelting),
  GlassReaction(ReactionKind.tears, 'Tears', GlassGlyph28.drop),
  GlassReaction(ReactionKind.shook, 'Twist', GlassGlyph28.lightning),
  GlassReaction(ReactionKind.chefsKiss, 'Masterpiece', GlassGlyph28.handsClapping),
];

/// A stored `laughed` renders as "Laughed" and is never offered.
const GlassReaction kGlassLaughed = GlassReaction(ReactionKind.laughed, 'Laughed', GlassGlyph28.smiley);

GlassReaction glassReaction(ReactionKind k) => k == ReactionKind.laughed ? kGlassLaughed : kGlassReactions.firstWhere((r) => r.kind == k);

bool isOffered(ReactionKind k) => kGlassReactions.any((r) => r.kind == k);

/// A tap sends Love.
const ReactionKind kTapReaction = ReactionKind.loved;

/// Where each reaction's slot in the strip is, so the send can fly to it (the strip registers its glyph slots).
class ReactionTargets {
  final Map<ReactionKind, GlobalKey> _keys = {};

  void register(ReactionKind kind, GlobalKey key) => _keys[kind] = key;

  void unregister(ReactionKind kind, GlobalKey key) {
    if (_keys[kind] == key) _keys.remove(kind);
  }

  /// The global centre of [kind]'s slot, or null when no strip is on screen.
  Offset? centerOf(ReactionKind kind) {
    final ro = _keys[kind]?.currentContext?.findRenderObject();
    return ro is RenderBox && ro.attached && ro.hasSize ? ro.localToGlobal(ro.size.center(Offset.zero)) : null;
  }
}

final glassReactionTargetsProvider = Provider<ReactionTargets>((ref) => ReactionTargets());
