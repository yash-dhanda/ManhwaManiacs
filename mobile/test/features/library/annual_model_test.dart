import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/annual.dart';

void main() {
  test('circle annual_block (a map) folds into members with finished titles', () {
    final a = Annual.fromJson({
      'year': 2026,
      'circle': {
        'overlaps': [
          {
            'member': {'profile_id': 7, 'name': 'Ana'},
            'series': {'title': 'Solo Leveling'},
            'both': 'finished',
          },
          {
            'member': {'profile_id': 7, 'name': 'Ana'},
            'series': {'title': 'TBATE'},
            'both': 'read',
          },
        ],
        'with': [
          {'profile_id': 7, 'name': 'Ana'},
        ],
      },
    });
    expect(a.circle, hasLength(1));
    expect(a.circle!.single.name, 'Ana');
    expect(a.circle!.single.finishedTogether, ['Solo Leveling']);
  });

  test('since/until are naive UTC instants', () {
    final a = Annual.fromJson({'year': 2025, 'until': '2026-01-01T07:00:00'});
    expect(a.until!.toUtc(), DateTime.utc(2026, 1, 1, 7));
    expect(a.until!.isUtc, isFalse);
  });
}
