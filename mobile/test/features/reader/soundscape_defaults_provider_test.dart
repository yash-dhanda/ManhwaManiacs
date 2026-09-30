import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/providers/soundscape_defaults_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_overrides.dart';

Future<ProviderContainer> _c(Map<String, Object> seed) async {
  SharedPreferences.setMockInitialValues(seed);
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [sharedPrefsProvider.overrideWithValue(prefs), authenticatedAuthOverride(), activeProfileOverride()]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('defaults: scene off, match the story on, mix 80 / 50 / 30, master -12 dB, lower under narration on', () async {
    final d = (await _c({})).read(soundscapeDefaultsProvider);
    expect(d.scene, 'off');
    expect(d.matchStory, true);
    expect((d.bed, d.detail, d.tone), (0.80, 0.50, 0.30));
    expect(d.volumeDb, -12);
    expect(d.lowerUnderNarration, true);
  });

  test('writes round trip under the per-profile key and keep the mix layers they did not touch', () async {
    final c = await _c({});
    final n = c.read(soundscapeDefaultsRecordProvider.notifier);
    await n.setScene('rain');
    await n.setMix('bed', 0.4);
    await n.setVolumeDb(-99);
    await n.setMatchStory(false);
    await n.setLowerUnderNarration(false);
    final d = c.read(soundscapeDefaultsProvider);
    expect(d.scene, 'rain');
    expect(d.bed, 0.4);
    expect(d.detail, 0.5);
    expect(d.volumeDb, -30);
    expect(d.matchStory, false);
    expect(d.lowerUnderNarration, false);
    expect(c.read(sharedPrefsProvider).getKeys().single, matches(r'^mm\.soundscape\.defaults\.u\d+p\d+$'));
  });

  test('an unknown scene falls back to off and unknown fields survive', () async {
    final c = await _c({});
    final key = 'mm.soundscape.defaults.u1p1';
    expect(c.read(sharedPrefsProvider).getKeys(), isEmpty);
    await c.read(soundscapeDefaultsRecordProvider.notifier).setScene('lava');
    expect(c.read(soundscapeDefaultsProvider).scene, 'off');
    await c.read(soundscapeDefaultsRecordProvider.notifier).put({'future': 1});
    await c.read(soundscapeDefaultsRecordProvider.notifier).setScene('deep');
    expect(c.read(soundscapeDefaultsRecordProvider).intOf('future', 0), 1);
    expect(key, isNotEmpty);
  });
}
