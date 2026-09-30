import 'package:manhwamaniacs/features/onboarding/models/onboarding_catalog.dart';
import 'package:manhwamaniacs/features/onboarding/models/taste.dart';

/// The genre names, heaviest first then A-Z, capped at 40 (all of them under 30).
List<String> genreParagraph(List<GenreWeight> genres) {
  final sorted = [...genres]..sort((a, b) {
      final w = b.weight.compareTo(a.weight);
      return w != 0 ? w : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  return [for (final g in sorted.take(40)) g.name];
}

/// One tap: none -> like -> love -> none; a skipped word clears.
GenreMark? tapGenre(GenreMark? m) => switch (m) {
      null => GenreMark.like,
      GenreMark.like => GenreMark.love,
      GenreMark.love || GenreMark.skip => null,
    };

GenreMark holdGenre() => GenreMark.skip;

enum GenreMenuAction { like, love, skip, clear }

GenreMark? menuGenre(GenreMenuAction a) => switch (a) {
      GenreMenuAction.like => GenreMark.like,
      GenreMenuAction.love => GenreMark.love,
      GenreMenuAction.skip => GenreMark.skip,
      GenreMenuAction.clear => null,
    };

String genreLabel(String name, GenreMark? m) => switch (m) {
      GenreMark.like => '$name, liked',
      GenreMark.love => '$name, loved',
      GenreMark.skip => '$name, skipped',
      null => '$name, not chosen',
    };

/// Names marked love first, then like (the catalog's `genres=` parameter).
List<String> likedGenres(Map<String, GenreMark?> marks) => [
      for (final e in marks.entries)
        if (e.value == GenreMark.love) e.key,
      for (final e in marks.entries)
        if (e.value == GenreMark.like) e.key,
    ];
