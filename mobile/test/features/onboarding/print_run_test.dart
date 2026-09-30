import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/onboarding/utils/art_styles.dart';
import 'package:manhwamaniacs/features/onboarding/utils/print_run.dart';

WorldItem item(int id, {bool available = true}) => WorldItem(
      title: 'T$id',
      anilistId: id,
      available: available ? [WorldAvailability(sourceId: 's', sourceName: 'S', seriesKey: 'k$id')] : const [],
    );

void main() {
  test('follows at most 4 at once, keeps pick order, skips information-only picks', () async {
    var inFlight = 0, peak = 0;
    final seen = <String>[];
    final r = await runFollows([for (var i = 1; i <= 9; i++) item(i, available: i != 3)], ({required sourceId, required seriesKey}) async {
      inFlight++;
      peak = inFlight > peak ? inFlight : peak;
      seen.add(seriesKey);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      inFlight--;
      return seriesKey != 'k5';
    });
    expect(peak, 4);
    expect(seen.contains('k3'), isFalse);
    expect([for (final p in r.followed) p.anilistId], [1, 2, 4, 6, 7, 8, 9]);
    expect([for (final p in r.failed) p.anilistId], [5]);
  });

  test('a throwing follow counts as failed', () async {
    final r = await runFollows([item(1)], ({required sourceId, required seriesKey}) async => throw StateError('x'));
    expect(r.failed.length, 1);
  });

  test('followedToast', () {
    expect(followedToast(5, 5), isNull);
    expect(followedToast(4, 5), "Followed 4 of 5. One couldn't be added.");
    expect(followedToast(3, 5), "Followed 3 of 5. Two couldn't be added.");
    expect(followedToast(1, 10), "Followed 1 of 10. Nine couldn't be added.");
    expect(followedToast(0, 10), "Followed 0 of 10. 10 couldn't be added.");
    expect(followedToast(0, 12), "Followed 0 of 12. 12 couldn't be added.");
  });

  test('flightList caps at 12', () {
    expect(flightList([for (var i = 0; i < 14; i++) item(i)]).length, 12);
    expect(flightList([item(1), item(2)]).length, 2);
  });

  test('art styles: nine, in order; bundled art fits its budget', () {
    expect(kArtStyles.length, 9);
    expect(kArtStyles.first.name, 'Painted');
    expect(kArtStyles.last.id.wire, 'chibi');
    if (kStyleArtBundled) {
      for (final s in kArtStyles) {
        final f = File('assets/onboarding/styles/${s.file}');
        expect(f.existsSync(), isTrue, reason: s.file);
        expect(f.lengthSync(), lessThanOrEqualTo(61440));
      }
    }
  });
}
