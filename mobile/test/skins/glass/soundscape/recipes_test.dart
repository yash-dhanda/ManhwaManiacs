import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/soundscape/recipes.dart';

void main() {
  test('the table covers 6 scenes x 3 layers with each cell loop, events or silent as the spec says', () {
    expect(kRecipes.length, 6);
    for (final s in SoundScene.values) {
      expect(kRecipes[s]!.keys, SoundLayer.values);
    }
    LayerKind k(SoundScene s, SoundLayer l) => kRecipes[s]![l]!;
    expect(k(SoundScene.rain, SoundLayer.detail), LayerKind.events);
    expect(k(SoundScene.rain, SoundLayer.tone), LayerKind.loop);
    expect(k(SoundScene.wind, SoundLayer.detail), LayerKind.events);
    expect(k(SoundScene.wind, SoundLayer.tone), LayerKind.silent);
    expect(k(SoundScene.ocean, SoundLayer.detail), LayerKind.loop);
    expect(k(SoundScene.hearth, SoundLayer.detail), LayerKind.events);
    expect(k(SoundScene.stream, SoundLayer.detail), LayerKind.silent);
    expect(k(SoundScene.deep, SoundLayer.bed), LayerKind.loop);
    expect(kLoopLayers.length, 8);
  });

  test('every genre word maps to its scene, and nothing falls back to Rain', () {
    const table = {
      SoundScene.rain: ['horror', 'thriller', 'mystery', 'psychological'],
      SoundScene.hearth: ['romance', 'slice of life', 'comedy', 'drama', 'historical'],
      SoundScene.stream: ['fantasy', 'isekai', 'school', 'supernatural'],
      SoundScene.ocean: ['adventure', 'sports'],
      SoundScene.wind: ['action', 'martial arts', 'murim', 'military'],
      SoundScene.deep: ['sci-fi', 'mecha', 'cyberpunk', 'space'],
    };
    table.forEach((scene, words) {
      for (final w in words) {
        expect(matchScene([w]), scene, reason: w);
        expect(matchScene([w.toUpperCase()]), scene, reason: w);
      }
    });
    expect(matchScene(['Cooking', 'Tragedy']), SoundScene.rain);
    expect(matchScene(const []), SoundScene.rain);
  });

  test('the first genre that names a scene wins', () {
    expect(matchScene(['Cooking', 'Romance', 'Horror']), SoundScene.hearth);
  });

  test('a remembered scene beats Match the story, which beats the default', () {
    expect(chooseScene(remembered: SoundScene.deep, matchStory: true, genres: ['horror'], fallback: SoundScene.wind), SoundScene.deep);
    expect(chooseScene(matchStory: true, genres: ['horror'], fallback: SoundScene.wind), SoundScene.rain);
    expect(chooseScene(matchStory: false, genres: ['horror'], fallback: SoundScene.wind), SoundScene.wind);
    expect(chooseScene(matchStory: false, genres: ['horror']), isNull);
  });

  test('dB to gain', () {
    expect(dbToGain(-12), closeTo(0.2512, 1e-4));
    expect(dbToGain(-30), closeTo(0.0316, 1e-4));
    expect(dbToGain(0), 1);
  });
}
