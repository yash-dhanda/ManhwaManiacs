import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/sources/models/source_genre.dart';
import 'package:manhwamaniacs/features/sources/utils/genre_link.dart';

void main() {
  const genres = [SourceGenre(id: 'action', label: 'Action'), SourceGenre(id: '42', label: 'Slice of Life')];

  test('a matching label links to the catalogue filtered by the genre id', () {
    expect(genreRoute('asura', 'Action', genres), '/sources/asura?genre=action');
  });

  test('a case-only difference still matches', () {
    expect(genreRoute('asura', 'slice of life', genres), '/sources/asura?genre=42');
  });

  test('no match renders a plain tag', () {
    expect(genreRoute('asura', 'Isekai', genres), isNull);
    expect(genreRoute('asura', 'Action', const []), isNull);
  });
}
