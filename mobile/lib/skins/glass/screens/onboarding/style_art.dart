import 'package:manhwamaniacs/features/onboarding/models/taste.dart';

/// The nine art-style crops of step 5 (glass 8.7, 12.7): `StyleId`, the name a screen reader hears and the file the art lives in.
class GlassStyle {
  const GlassStyle(this.id, this.label);
  final StyleId id;
  final String label;

  /// `mobile/assets/onboarding/styles/glass/{index}-{id}.webp`, one-based two-digit index.
  String assetPath(int index) => 'assets/onboarding/styles/glass/${index.toString().padLeft(2, '0')}-${id.wire}.webp';
}

const List<GlassStyle> kGlassStyles = [
  GlassStyle(StyleId.painted, 'Full-colour webtoon painting'),
  GlassStyle(StyleId.cel, 'Crisp cel shading'),
  GlassStyle(StyleId.screentone, 'Black-and-white screentone'),
  GlassStyle(StyleId.manhua3d, 'Manhua 3D/CG'),
  GlassStyle(StyleId.watercolour, 'Watercolour'),
  GlassStyle(StyleId.sketch, 'Sketchy indie'),
  GlassStyle(StyleId.retro, 'Retro 1990s'),
  GlassStyle(StyleId.chibi, 'Chibi comedy'),
  GlassStyle(StyleId.darkRealism, 'Dark realism'),
];

/// True only when all nine crops exist under `mobile/assets/onboarding/styles/glass/` and the folder is declared under
/// `flutter: assets:` (the owner supplies them through `shared/05`'s intake). `style_art_test.dart` asserts each file is under
/// 40,000 bytes once this is true; until then the tiles are typographic.
const bool kGlassStyleArtBundled = false;
