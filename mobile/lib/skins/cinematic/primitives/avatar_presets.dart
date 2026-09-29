import 'package:flutter/painting.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

class AvatarPreset {
  const AvatarPreset(this.key, this.name, this.field, this.glyph);
  final String key, name;
  final Color field;
  final int glyph;
}

/// The twelve presets of cinematic 7.25: a field colour and a Phosphor Fill glyph.
const List<AvatarPreset> kAvatarPresets = [
  AvatarPreset('violet', 'Matinee', CineColors.avatarViolet, CineGlyph.filmSlate),
  AvatarPreset('cyan', 'Newsreel', CineColors.avatarCyan, CineGlyph.newspaper),
  AvatarPreset('rose', 'Romance', CineColors.avatarRose, CineGlyph.heart),
  AvatarPreset('amber', 'Usher', CineColors.avatarAmber, CineGlyph.flashlight),
  AvatarPreset('emerald', 'Critic', CineColors.avatarEmerald, CineGlyph.penNib),
  AvatarPreset('ember', 'Premiere', CineColors.avatarEmber, CineGlyph.fire),
  AvatarPreset('blade', 'Swordplay', CineColors.avatarBlade, CineGlyph.sword),
  AvatarPreset('phantom', 'Phantom', CineColors.avatarPhantom, CineGlyph.ghost),
  AvatarPreset('arcane', 'Illusionist', CineColors.avatarArcane, CineGlyph.magicWand),
  AvatarPreset('lunar', 'Late show', CineColors.avatarLunar, CineGlyph.moonStars),
  AvatarPreset('star', 'Marquee', CineColors.avatarStar, CineGlyph.star),
  AvatarPreset('reader', 'Bookworm', CineColors.avatarReader, CineGlyph.bookOpenText),
];

/// Unknown keys fall back to Matinee.
AvatarPreset avatarPreset(String? key) => kAvatarPresets.firstWhere((p) => p.key == key, orElse: () => kAvatarPresets.first);
