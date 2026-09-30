import 'package:manhwamaniacs/features/onboarding/models/taste.dart';

/// The nine commissioned crops (600 x 600 WebP, <= 60 KB) do not exist yet: typographic plates.
const bool kStyleArtBundled = false;

class ArtStyle {
  const ArtStyle(this.id, this.file, this.name, this.description);
  final StyleId id;
  final String file, name, description;
  String get asset => 'assets/onboarding/styles/$file';
}

const List<ArtStyle> kArtStyles = [
  ArtStyle(StyleId.painted, '01-painted.webp', 'Painted', 'Full-colour painted webtoon art.'),
  ArtStyle(StyleId.cel, '02-cel.webp', 'Cel', 'Crisp cel shading and clean lines.'),
  ArtStyle(StyleId.screentone, '03-screentone.webp', 'Screentone', 'Black-and-white ink with tone dots.'),
  ArtStyle(StyleId.manhua3d, '04-manhua-3d.webp', 'Manhua 3D', 'Rendered, three-dimensional colour.'),
  ArtStyle(StyleId.sketch, '05-sketch.webp', 'Sketch', 'Loose, sketchy indie linework.'),
  ArtStyle(StyleId.retro, '06-retro.webp', 'Retro', 'The look of 1990s manga.'),
  ArtStyle(StyleId.pastel, '07-pastel.webp', 'Pastel', 'Soft, light pastel colour.'),
  ArtStyle(StyleId.noir, '08-noir.webp', 'Noir', 'High-contrast black and shadow.'),
  ArtStyle(StyleId.chibi, '09-chibi.webp', 'Chibi', 'Small, round, comic proportions.'),
];
