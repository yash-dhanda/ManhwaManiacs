import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/providers/glass_density_provider.dart';
import 'package:manhwamaniacs/features/library/utils/glass_density.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_overrides.dart';

class _Profile extends ActiveProfileNotifier {
  _Profile(this.id);
  final int id;
  @override
  ActiveProfile? build() => ActiveProfile(id: id, name: 'P$id', avatarKey: null, mood: Mood.neutral);
}

Future<ProviderContainer> _open(Map<String, Object> prefs, {int profile = 1}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final p = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [
    sharedPrefsProvider.overrideWithValue(p),
    authenticatedAuthOverride(),
    activeProfileProvider.overrideWith(() => _Profile(profile)),
  ],);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('migration from the K15 cover scale', () async {
    Future<GlassDensity> at(double s) async => (await _open({'settings_library_cover_scale': s})).read(glassDensityProvider);
    expect((await at(0.84)).phone, GlassPhoneDensity.c4);
    expect((await at(0.84)).wide, GlassDensityWide.compact);
    expect((await at(0.85)).phone, GlassPhoneDensity.c3);
    expect((await at(1.25)).phone, GlassPhoneDensity.c3);
    expect((await at(1.26)).phone, GlassPhoneDensity.c2);
    expect((await at(1.26)).wide, GlassDensityWide.comfortable);
    expect((await at(0.8)).phone.columns, 4);
    expect((await at(1.0)).phone.columns, 3);
    expect((await at(1.4)).phone.columns, 2);
  });

  test('K16 list view wins over the scale; nothing stored is 3 / Comfortable', () async {
    final a = (await _open({'manhwamaniacs:library-query': '{"viewMode":"list"}', 'settings_library_cover_scale': 1.4})).read(glassDensityProvider);
    expect((a.phone, a.wide), (GlassPhoneDensity.list, GlassDensityWide.list));
    expect((await _open({})).read(glassDensityProvider), const GlassDensity());
  });

  test('the libraryColumns the settings migration seeded in mm.glass.prefs wins over K15; K16 list still wins', () async {
    Future<GlassDensity> at(Map<String, Object> p) async => (await _open(p)).read(glassDensityProvider);
    expect((await at({'mm.glass.prefs.u1p1': '{"libraryColumns":4}', 'settings_library_cover_scale': 1.4})).phone, GlassPhoneDensity.c4);
    expect((await at({'mm.glass.prefs.u1p1': '{"libraryColumns":2}'})).phone, GlassPhoneDensity.c2);
    expect((await at({'mm.glass.prefs.u1p1': '{"libraryColumns":9}', 'settings_library_cover_scale': 1.4})).phone, GlassPhoneDensity.c2);
    expect((await at({'mm.glass.prefs.u1p2': '{"libraryColumns":4}'})).phone, GlassPhoneDensity.c3);
    final l = await at({'mm.glass.prefs.u1p1': '{"libraryColumns":4}', 'manhwamaniacs:library-query': '{"viewMode":"list"}'});
    expect(l.phone, GlassPhoneDensity.list);
  });

  test('the derived value is written once, the legacy keys stay, and a change persists per profile', () async {
    var c = await _open({'settings_library_cover_scale': 1.4});
    c.read(glassDensityProvider);
    final prefs = c.read(sharedPrefsProvider);
    expect(prefs.getDouble('settings_library_cover_scale'), 1.4);
    expect(prefs.getKeys().where((k) => k.startsWith('mm.glass.library-density.')), hasLength(1));
    c.read(glassDensityProvider.notifier).stepPhoneBy(larger: false);
    expect(c.read(glassDensityProvider).phone, GlassPhoneDensity.c3);
    final stored = <String, Object>{for (final k in prefs.getKeys()) k: prefs.get(k)!};
    c = await _open(stored);
    expect(c.read(glassDensityProvider).phone, GlassPhoneDensity.c3);
    // Another profile has its own key: it migrates from the legacy scale again.
    c = await _open(stored, profile: 2);
    expect(c.read(glassDensityProvider).phone, GlassPhoneDensity.c2);
  });
}
