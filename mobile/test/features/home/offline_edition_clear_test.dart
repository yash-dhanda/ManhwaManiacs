import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/home/utils/offline_edition.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_fixtures.dart';

void main() {
  test('clearLastFeeds deletes both kinds', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [sharedPrefsProvider.overrideWithValue(prefs)]);
    addTearDown(c.dispose);
    final feed = loadHome('ready');
    final probe = Provider<void>((ref) {
      saveLastFeed(ref, 'manga', feed, sourceMature: (_) => false);
      saveLastFeed(ref, 'novel', feed, sourceMature: (_) => false);
    });
    c.read(probe);
    expect(prefs.getKeys().where((k) => k.startsWith('mm.home.last.')).length, 2);
    c.read(Provider<void>(clearLastFeeds));
    expect(prefs.getKeys().where((k) => k.startsWith('mm.home.last.')), isEmpty);
  });
}
