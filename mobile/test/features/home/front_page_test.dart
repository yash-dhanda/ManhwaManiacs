// ignore_for_file: require_trailing_commas, avoid_redundant_argument_values, library_private_types_in_public_api, directives_ordering
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/home/utils/front_page.dart';

void main() {
  final now = DateTime(2026, 9, 30, 21);

  test('plays with no stamp, on a new day, and when the variant changes', () {
    expect(shouldPlayFrontPage(null, now, FrontVariant.normal), isTrue);
    expect(shouldPlayFrontPage((date: '2026-09-29', variant: FrontVariant.normal), now, FrontVariant.normal), isTrue);
    expect(shouldPlayFrontPage((date: '2026-09-30', variant: FrontVariant.normal), now, FrontVariant.normal), isFalse);
    expect(shouldPlayFrontPage((date: '2026-09-30', variant: FrontVariant.normal), now, FrontVariant.atRisk), isTrue,
        reason: 'the at-risk line types once more after 20:00');
    expect(shouldPlayFrontPage((date: '2026-09-30', variant: FrontVariant.atRisk), now, FrontVariant.atRisk), isFalse);
  });

  test('the stamp round-trips', () {
    final s = (date: localDateString(now), variant: FrontVariant.atRisk);
    expect(localDateString(now), '2026-09-30');
    expect(decodeFrontStamp(encodeFrontStamp(s)), s);
    expect(decodeFrontStamp('junk'), isNull);
  });
}
