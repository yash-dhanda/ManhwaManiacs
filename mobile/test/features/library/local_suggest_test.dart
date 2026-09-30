import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';

void main() {
  test('a source row parses as a shelf card that opens its series', () {
    final i = WorldItem.fromShelfJson({
      'kind': 'source',
      'source': 'asura',
      'series_id': 'solo',
      'title': 'Solo',
      'cover_url': '/sources/asura/series/solo/cover',
      'author': 'Chugong',
      'why': 'Slow burn.',
    });
    expect(i.shelf, isTrue);
    expect(i.openTarget!.sourceId, 'asura');
    expect(i.openTarget!.seriesKey, 'solo');
    expect(i.why, 'Slow burn.');
    expect(i.author, 'Chugong');
  });
}
