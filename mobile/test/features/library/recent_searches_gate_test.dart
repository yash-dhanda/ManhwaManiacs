import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/utils/recent_searches.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('terms keep the gate flag; the purge drops gate-open terms and legacy strings', () async {
    SharedPreferences.setMockInitialValues({recentSearchesKeyFor(7): '["old term"]'});
    final prefs = await SharedPreferences.getInstance();
    await writeRecentSearch(prefs, 'safe one', profileId: 7);
    await writeRecentSearch(prefs, 'spicy one', profileId: 7, gateOpen: true);
    expect(readRecentSearches(prefs, profileId: 7), ['spicy one', 'safe one', 'old term']);
    await dropGateOpenRecentSearches(prefs, profileId: 7);
    expect(readRecentSearches(prefs, profileId: 7), ['safe one']);
  });

  test('another profile is untouched', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await writeRecentSearch(prefs, 'mine', profileId: 1, gateOpen: true);
    await writeRecentSearch(prefs, 'theirs', profileId: 2, gateOpen: true);
    await dropGateOpenRecentSearches(prefs, profileId: 1);
    expect(readRecentSearches(prefs, profileId: 1), isEmpty);
    expect(readRecentSearches(prefs, profileId: 2), ['theirs']);
  });
}
