/// The descriptors on the rating card, from a series' genres (cinematic 7.24): case-insensitive
/// substring matches in a fixed order, at most three, joined by " · ".
const List<(List<String> needles, String label)> _rules = [
  (['gore'], 'Gore'),
  (['violen'], 'Violence'),
  (['smut', 'ecchi', 'hentai', 'adult', 'erotic', 'sexual', 'mature'], 'Sexual content'),
  (['horror'], 'Horror'),
  (['psycholog'], 'Psychological themes'),
  (['drug'], 'Drug use'),
];

List<String> ratingDescriptors(Iterable<String> genres) {
  final lower = [for (final g in genres) g.toLowerCase()];
  final out = <String>[];
  for (final (needles, label) in _rules) {
    if (lower.any((g) => needles.any(g.contains))) out.add(label);
    if (out.length == 3) break;
  }
  return out.isEmpty ? const ['Mature themes'] : out;
}

String ratingDescriptorLine(Iterable<String> genres) => ratingDescriptors(genres).join(' · ');

/// What a screen reader hears, once.
String ratingAnnouncement(Iterable<String> genres) => 'Rated 18 plus: ${ratingDescriptors(genres).join(', ')}';
