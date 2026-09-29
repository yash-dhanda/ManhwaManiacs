import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/settings/providers/a11y_prefs_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_overrides.dart';

Future<ProviderContainer> _c(Map<String, Object> seed, {bool profile = true}) async {
  SharedPreferences.setMockInitialValues(seed);
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [
    sharedPrefsProvider.overrideWithValue(prefs),
    if (profile) authenticatedAuthOverride(),
    if (profile) activeProfileOverride(),
  ],);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('defaults', () async {
    final c = await _c({});
    expect(c.read(a11yPrefsProvider).legible, false);
    expect(c.read(a11yPrefsProvider).motion, 'system');
    expect(c.read(legibleTextProvider), false);
    expect(c.read(appReduceMotionProvider), false);
  });

  test('round trip through SharedPreferences', () async {
    final c = await _c({});
    await c.read(a11yPrefsProvider.notifier).setLegible(true);
    await c.read(a11yPrefsProvider.notifier).setMotion('reduced');
    expect(c.read(legibleTextProvider), true);
    expect(c.read(appReduceMotionProvider), true);
    final prefs = c.read(sharedPrefsProvider);
    final key = prefs.getKeys().singleWhere((k) => k.startsWith('mm.boot.a11y.'));
    final fresh = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      authenticatedAuthOverride(),
      activeProfileOverride(),
    ],);
    addTearDown(fresh.dispose);
    expect(key, matches(r'^mm\.boot\.a11y\.u\d+p\d+$'));
    expect(fresh.read(a11yPrefsProvider).legible, true);
    expect(fresh.read(appReduceMotionProvider), true);
  });

  test('two profiles are isolated', () async {
    final c = await _c({'mm.boot.a11y.u1p2': '{"legible":true,"motion":"reduced"}'});
    // The seeded test profile is a different scope from u1p2.
    expect(c.read(a11yPrefsProvider).legible, false);
    final device = await _c({'mm.boot.a11y.device': '{"legible":true,"motion":"system"}'}, profile: false);
    expect(device.read(a11yPrefsProvider).legible, true);
  });

  test('unknown fields survive a write', () async {
    final c = await _c({});
    final prefs = c.read(sharedPrefsProvider);
    await c.read(a11yPrefsProvider.notifier).setLegible(false); // creates the scoped key
    final key = prefs.getKeys().singleWhere((k) => k.startsWith('mm.boot.a11y.'));
    await prefs.setString(key, '{"legible":false,"motion":"system","solid":true}');
    c.invalidate(a11yPrefsProvider);
    await c.read(a11yPrefsProvider.notifier).setLegible(true);
    expect(prefs.getString(key), contains('"solid":true'));
    expect(prefs.getString(key), contains('"legible":true'));
  });
}
