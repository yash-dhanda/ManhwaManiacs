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
      ('CH 142 · 12 OF 201', null, 'Chapter 12 of 201'),
      ('NEXT · CH 143', null, 'Next, chapter 143'),
      ('3 NEW', null, '3 new chapters'),
      ('1 NEW', null, '1 new chapter'),
      ('Filters', 2, 'Filters, 2'),
      ('CH 143 · p.12', null, 'Chapter 143, page 12'),
      ('12-DAY STREAK', null, '12-day streak'),
      ('4.1 GB', null, '4.1 gigabytes'),
      ('84/89 OK', null, '84 of 89 answering'),
      ('8 ASKS LEFT', null, '8 asks left'),
      ('LIVE · 15 S', null, 'Live, refreshes in 15 seconds'),
      ('4.1 GB OF 10 GB · 21 GB FREE ON THIS PHONE', null, '4.1 of 10 gigabytes used, 21 gigabytes free on this phone'),
      ('4.1 GB · 21 GB FREE ON THIS TABLET', null, '4.1 gigabytes used, 21 gigabytes free on this tablet'),
      ('12 CH · 240 MB', null, '12 chapters, 240 megabytes'),
      ('2 D AGO', null, '2 days ago'),
      ('1 H AGO', null, '1 hour ago'),
      ('3 W AGO', null, '3 weeks ago'),
      ('CH 142', null, 'Chapter 142'),
    ];
    for (final (visual, count, spoken) in rows) {
      expect(folioLabel(visual, count: count), spoken, reason: visual);
    }
  });
}
