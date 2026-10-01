import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';

void main() {
  test('fromJson resolves proxied cover paths against api base', () {
    final series = SourceSeriesSummary.fromJson(
      {
        'id': 'solo-leveling',
        'source_id': 'asurascans',
        'title': 'Solo Leveling',
        'chapter_count': 200,
        'genres': ['Action'],
        'cover_url': '/sources/asurascans/series/solo-leveling/cover',
        'source_url': 'https://asuracomic.net/series/solo-leveling',
      },
      'https://app.manhwamaniacs.xyz',
    );
    expect(series.sourceUrl, 'https://asuracomic.net/series/solo-leveling');

    expect(
      series.coverUrl,
      'https://app.manhwamaniacs.xyz/sources/asurascans/series/solo-leveling/cover',
    );
  });

  test('fromJson tolerates missing optional fields', () {
    final series = SourceSeriesSummary.fromJson(
      {
        'id': 'foo',
        'source_id': 'asurascans',
        'title': 'Foo',
        'chapter_count': 1,
      },
      'https://app.manhwamaniacs.xyz',
    );

    expect(series.genres, isEmpty);
    expect(series.coverUrl, isEmpty);
    expect(series.sourceUrl, isNull);
  });
}
