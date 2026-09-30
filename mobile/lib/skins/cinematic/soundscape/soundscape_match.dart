import 'package:manhwamaniacs/features/profiles/models/mood.dart';

const _byGenre = <String, String>{
  'romance': 'rain-on-glass', 'josei': 'rain-on-glass', 'shoujo': 'rain-on-glass',
  'action': 'low-drone', 'martial arts': 'low-drone', 'murim': 'low-drone', 'sports': 'low-drone',
  'comedy': 'cafe', 'slice of life': 'cafe', 'school': 'cafe',
  'horror': 'night-wind', 'thriller': 'night-wind', 'mystery': 'night-wind', 'psychological': 'night-wind',
  'fantasy': 'temple-bells', 'isekai': 'temple-bells', 'regression': 'temple-bells', 'cultivation': 'temple-bells', 'historical': 'temple-bells',
  'drama': 'night-city', 'crime': 'night-city', 'sci-fi': 'night-city',
  'adventure': 'afternoon-park', 'seinen': 'afternoon-park',
};

String _moodDefault(Mood m) => switch (m) {
      Mood.romantic => 'rain-on-glass',
      Mood.action => 'low-drone',
      Mood.comedy => 'cafe',
      Mood.horror => 'night-wind',
      Mood.sliceOfLife => 'afternoon-park',
      Mood.fantasy => 'temple-bells',
      Mood.neutral => 'projector-room',
    };

/// MATCH THE MOOD: the first of the series' genres (case-insensitive, in order) that maps to a
/// loop, else the profile mood's default.
String matchTheMood(List<String> genres, Mood mood) {
  for (final g in genres) {
    final id = _byGenre[g.trim().toLowerCase()];
    if (id != null) return id;
  }
  return _moodDefault(mood);
}
