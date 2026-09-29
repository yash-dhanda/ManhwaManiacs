import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/a11y/folio.dart';

void main() {
  test('spoken folios', () {
    const rows = <(String, int?, String)>[
      ('CH 142 · 63%', null, 'Chapter 142, 63 percent read'),
      ('2 H', null, '2 hours ago'),
      ('1 H', null, '1 hour ago'),
      ('PAUSED 21 D', null, 'Paused 21 days'),
      ('READING', 12, 'Reading, 12'),
      ('p. 12', null, 'page 12'),
      ('12 MIN', null, '12 minutes'),
      ('18+', null, 'Mature, 18 plus'),
      ('CH 12 OF 40', null, 'Chapter 12 of 40'),
      ('NEXT · CH 143', null, 'Next, chapter 143'),
      ('3 NEW', null, '3 new chapters'),
      ('1 NEW', null, '1 new chapter'),
      ('Filters', 2, 'Filters, 2'),
      ('CH 143 · p.12', null, 'Chapter 143, page 12'),
    ];
    for (final (visual, count, spoken) in rows) {
      expect(folioLabel(visual, count: count), spoken, reason: visual);
    }
  });
}
