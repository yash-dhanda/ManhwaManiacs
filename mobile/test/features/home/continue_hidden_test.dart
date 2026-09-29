// ignore_for_file: require_trailing_commas, avoid_redundant_argument_values, library_private_types_in_public_api, directives_ordering
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/home/utils/continue_hidden.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_overrides.dart';
import 'home_fixtures.dart';

void main() {
  final at = DateTime(2026, 9, 30);

  test('filterHidden drops a row until its chapter changes', () {
    final a5 = contRow('a', chapter: 5, at: at), a6 = contRow('a', chapter: 6, at: at), b = contRow('b', at: at);
    final hidden = [hiddenOf(a5)];
    expect(filterHidden([a5, b], hidden).map((r) => r.seriesKey), ['b']);
    expect(filterHidden([a6, b], hidden).map((r) => r.seriesKey), ['a', 'b'], reason: 'a new chapter brings the series back');
  });

  test('encode and decode round trip; junk decodes to nothing', () {
    final h = [(sourceId: 's', seriesKey: 'k', chapterKey: 'c1')];
    expect(decodeHidden(encodeHidden(h)), h);
    expect(decodeHidden('nope'), isEmpty);
    expect(decodeHidden(null), isEmpty);
  });

  test('hide and unhide persist under the per-profile key', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      authenticatedAuthOverride(),
      activeProfileOverride(),
    ]);
    addTearDown(c.dispose);
    final row = contRow('a', at: at);
    hideContinue(c.read, row);
    expect(c.read(continueHiddenProvider), [hiddenOf(row)]);
    expect(decodeHidden(prefs.getString('mm.continue.hidden.u1p1')), [hiddenOf(row)]);
    unhideContinue(c.read, row);
    expect(c.read(continueHiddenProvider), isEmpty);
  });
}
