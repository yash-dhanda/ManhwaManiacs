import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/onboarding/models/taste.dart';
import 'package:manhwamaniacs/skins/glass/screens/onboarding/style_art.dart';

void main() {
  test('nine styles in the order of the brief with their spoken names', () {
    expect(kGlassStyles.map((s) => s.id.wire), ['painted', 'cel', 'screentone', 'manhua-3d', 'watercolour', 'sketch', 'retro', 'chibi', 'dark-realism']);
    expect(kGlassStyles.map((s) => s.label), ['Full-colour webtoon painting', 'Crisp cel shading', 'Black-and-white screentone', 'Manhua 3D/CG', 'Watercolour', 'Sketchy indie', 'Retro 1990s', 'Chibi comedy', 'Dark realism']);
    expect(kGlassStyles.first.id, StyleId.painted);
    expect(kGlassStyles.first.assetPath(1), 'assets/onboarding/styles/glass/01-painted.webp');
  });

  test('the crops, once bundled, exist and stay under 40,000 bytes', () {
    if (!kGlassStyleArtBundled) return;
    for (var i = 0; i < kGlassStyles.length; i++) {
      final f = File(kGlassStyles[i].assetPath(i + 1));
      expect(f.existsSync(), isTrue, reason: f.path);
      expect(f.lengthSync(), lessThan(40000));
    }
  });
}
