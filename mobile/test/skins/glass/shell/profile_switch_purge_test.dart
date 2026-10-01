import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/utils/recent_searches.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/glass/shell/profile_switch.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/test_overrides.dart';

String _recents() => jsonEncode([
      {'q': 'open', 'gateOpen': true},
      {'q': 'closed', 'gateOpen': false},
    ]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('switching to a profile with 18+ off purges its gate-open searches, not the outgoing one\'s', () async {
    SharedPreferences.setMockInitialValues({
      'mm.active_profile': '{"id":1,"name":"A","avatar_key":null,"mood":"default"}',
      recentSearchesKeyFor(1): _recents(),
      recentSearchesKeyFor(2): _recents(),
    });
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      skinIdProvider.overrideWithValue(SkinId.glass),
      ...noDownloadsStoreOverrides(),
    ],);
    addTearDown(c.dispose);
    final b = Profile(id: 2, name: 'B', avatarKey: null, mood: Mood.neutral, sortOrder: 1, matureContentEnabled: false, createdAt: DateTime.utc(2024), skin: 'glass');

    await c.read(glassProfileSwitchProvider).prepare(b);
    await Future<void>.delayed(Duration.zero);

    expect([for (final e in readRecentSearchEntries(prefs, profileId: 1)) e.q], ['open', 'closed']);
    expect([for (final e in readRecentSearchEntries(prefs, profileId: 2)) e.q], ['closed']);
  });
}
