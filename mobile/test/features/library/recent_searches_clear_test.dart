import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/utils/recent_searches.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('clearRecentSearches empties the profile key only', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await writeRecentSearch(prefs, 'solo', profileId: 1);
    await writeRecentSearch(prefs, 'tower', profileId: 2);
    await clearRecentSearches(prefs, profileId: 1);
    expect(readRecentSearches(prefs, profileId: 1), isEmpty);
    expect(readRecentSearches(prefs, profileId: 2), ['tower']);
  });
}
