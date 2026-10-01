import 'dart:math' as math;

/// The six scenes and three layers of the soundscape (glass 9.4.2). Pure data: the generator renders them, the mixer plays them.
enum SoundScene {
  rain('Rain'),
  wind('Wind'),
  ocean('Ocean'),
  hearth('Hearth'),
  stream('Stream'),
  deep('Deep');

  const SoundScene(this.label);
  final String label;

  static SoundScene? byName(String? n) {
    for (final s in values) {
      if (s.name == n) return s;
    }
    return null;
  }
}

enum SoundLayer { bed, detail, tone }

/// How a built-in layer sounds: a `loop` (a 30 s rendered WAV), `events` (a bank of short sounds scattered by the scheduler), or `silent`
/// until its recorded layer arrives. The mixer slider of a silent layer still exists and controls the recorded layer.
enum LayerKind { loop, events, silent }

const Map<SoundScene, Map<SoundLayer, LayerKind>> kRecipes = {
  SoundScene.rain: {SoundLayer.bed: LayerKind.loop, SoundLayer.detail: LayerKind.events, SoundLayer.tone: LayerKind.loop},
  SoundScene.wind: {SoundLayer.bed: LayerKind.loop, SoundLayer.detail: LayerKind.events, SoundLayer.tone: LayerKind.silent},
  SoundScene.ocean: {SoundLayer.bed: LayerKind.loop, SoundLayer.detail: LayerKind.loop, SoundLayer.tone: LayerKind.silent},
  SoundScene.hearth: {SoundLayer.bed: LayerKind.loop, SoundLayer.detail: LayerKind.events, SoundLayer.tone: LayerKind.silent},
  SoundScene.stream: {SoundLayer.bed: LayerKind.loop, SoundLayer.detail: LayerKind.silent, SoundLayer.tone: LayerKind.silent},
  SoundScene.deep: {SoundLayer.bed: LayerKind.loop, SoundLayer.detail: LayerKind.silent, SoundLayer.tone: LayerKind.silent},
};

/// Event layers: Poisson rate per second (Rain's droplets wander between 8 and 20 on a 0.1 Hz random walk) and the bank size.
const Map<SoundScene, ({double rate, int bank})> kEventRates = {
  SoundScene.rain: (rate: 14, bank: 12),
  SoundScene.wind: (rate: 0.5, bank: 6),
  SoundScene.hearth: (rate: 6, bank: 12),
};

/// Every loop is normalised to -24 dBFS RMS, the Hearth bed to -18.
double loopTargetDb(SoundScene s, SoundLayer l) => s == SoundScene.hearth && l == SoundLayer.bed ? -18 : -24;

/// The loops that exist as rendered WAVs (eight of them, about 15.4 MB).
List<(SoundScene, SoundLayer)> get kLoopLayers => [
      for (final s in SoundScene.values)
        for (final l in SoundLayer.values)
          if (kRecipes[s]![l] == LayerKind.loop) (s, l),
    ];

/// `10^(db / 20)`.
double dbToGain(double db) => math.pow(10, db / 20).toDouble();

/// Match the story (glass 9.4.2): the first of the series' genres that names a scene, lowercased; nothing matches Rain.
SoundScene matchScene(Iterable<String> genres) {
  const table = <String, SoundScene>{
    'horror': SoundScene.rain,
    'thriller': SoundScene.rain,
    'mystery': SoundScene.rain,
    'psychological': SoundScene.rain,
    'romance': SoundScene.hearth,
    'slice of life': SoundScene.hearth,
    'comedy': SoundScene.hearth,
    'drama': SoundScene.hearth,
    'historical': SoundScene.hearth,
    'fantasy': SoundScene.stream,
    'isekai': SoundScene.stream,
    'school': SoundScene.stream,
    'supernatural': SoundScene.stream,
    'adventure': SoundScene.ocean,
    'sports': SoundScene.ocean,
    'action': SoundScene.wind,
    'martial arts': SoundScene.wind,
    'murim': SoundScene.wind,
    'military': SoundScene.wind,
    'sci-fi': SoundScene.deep,
    'mecha': SoundScene.deep,
    'cyberpunk': SoundScene.deep,
    'space': SoundScene.deep,
  };
  for (final g in genres) {
    final hit = table[g.trim().toLowerCase()];
    if (hit != null) return hit;
  }
  return SoundScene.rain;
}

/// The order a reader picks a scene in: a remembered per-series scene, then Match the story (when on), then the default.
SoundScene? chooseScene({SoundScene? remembered, required bool matchStory, required Iterable<String> genres, SoundScene? fallback}) {
  if (remembered != null) return remembered;
  if (matchStory) return matchScene(genres);
  return fallback;
}
