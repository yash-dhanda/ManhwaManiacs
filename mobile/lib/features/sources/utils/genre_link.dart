import 'package:manhwamaniacs/features/sources/models/source_genre.dart';

/// Where a series tag links (glass 8.12 Header): `/sources/{id}?genre={genreId}` when a label in the source's own genre list
/// matches [genre] case-insensitively, else null (the tag renders plain).
String? genreRoute(String sourceId, String genre, List<SourceGenre> sourceGenres) {
  final want = genre.trim().toLowerCase();
  for (final g in sourceGenres) {
    if (g.label.trim().toLowerCase() == want) {
      return '/sources/${Uri.encodeComponent(sourceId)}?genre=${Uri.encodeQueryComponent(g.id)}';
    }
  }
  return null;
}
