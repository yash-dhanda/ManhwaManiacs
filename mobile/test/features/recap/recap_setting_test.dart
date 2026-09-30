import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/recap/recap_setting.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_overrides.dart';

class _Profiles extends ActiveProfileNotifier {
  @override
  ActiveProfile? build() => const ActiveProfile(id: 1, name: 'One', avatarKey: null, mood: Mood.neutral);
  void to(int id) => state = ActiveProfile(id: id, name: 'P$id', avatarKey: null, mood: Mood.neutral);
}

Future<(ProviderContainer, SharedPreferences)> _c([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [
    sharedPrefsProvider.overrideWithValue(prefs),
    authenticatedAuthOverride(),
    activeProfileProvider.overrideWith(_Profiles.new),
  ],);
  addTearDown(c.dispose);
  return (c, prefs);
}

void main() {
  test('default is ask, 7 days, chapters 3 days, no skips; autoContinue defaults to true', () async {
    final (c, _) = await _c();
    final s = c.read(recapSettingProvider);
    expect((s.mode, s.seriesDays, s.chapterDays), (RecapMode.ask, 7, 3));
    expect(s.skipSeries, isEmpty);
    expect(s.cinematicMode, CinematicRecapMode.afterDays);
    expect(c.read(recapAutoContinueProvider), isTrue);
  });

  test('the three Cinematic values map to off, always and ask with seriesDays = N', () async {
    final (c, prefs) = await _c();
    final n = c.read(recapSettingProvider.notifier);
    await n.setCinematicMode(CinematicRecapMode.never);
    expect(c.read(recapSettingProvider).mode, RecapMode.off);
    expect(c.read(recapSettingProvider).cinematicMode, CinematicRecapMode.never);
    await n.setCinematicMode(CinematicRecapMode.always);
    expect(c.read(recapSettingProvider).mode, RecapMode.always);
    await n.setCinematicMode(CinematicRecapMode.afterDays, days: 21);
    expect(c.read(recapSettingProvider).mode, RecapMode.ask);
    expect(c.read(recapSettingProvider).seriesDays, 21);
    await n.setCinematicMode(CinematicRecapMode.afterDays, days: 99);
    expect(c.read(recapSettingProvider).seriesDays, 60);
    expect(jsonDecode(prefs.getString('mm.recap.u1p1')!), {'mode': 'ask', 'seriesDays': 60, 'chapterDays': 3, 'skipSeries': <String>[]});
  });

  test('writes keep chapterDays and skipSeries', () async {
    final (c, prefs) = await _c({
      'mm.recap.u1p1': jsonEncode({'mode': 'off', 'seriesDays': 9, 'chapterDays': 5, 'skipSeries': ['a:b']}),
    });
    final n = c.read(recapSettingProvider.notifier);
    await n.setCinematicMode(CinematicRecapMode.always);
    await n.skip('c:d');
    await n.allow('a:b');
    final m = jsonDecode(prefs.getString('mm.recap.u1p1')!) as Map<String, dynamic>;
    expect(m, {'mode': 'always', 'seriesDays': 9, 'chapterDays': 5, 'skipSeries': ['c:d']});
  });

  test('each profile has its own value', () async {
    final (c, _) = await _c();
    await c.read(recapSettingProvider.notifier).setCinematicMode(CinematicRecapMode.never);
    await c.read(recapAutoContinueProvider.notifier).set(false);
    (c.read(activeProfileProvider.notifier) as _Profiles).to(2);
    expect(c.read(recapSettingProvider).mode, RecapMode.ask);
    expect(c.read(recapAutoContinueProvider), isTrue);
    (c.read(activeProfileProvider.notifier) as _Profiles).to(1);
    expect(c.read(recapSettingProvider).mode, RecapMode.off);
    expect(c.read(recapAutoContinueProvider), isFalse);
  });

  test('a corrupt value falls back to the default', () async {
    for (final raw in ['not json', '[]', '{"mode":"bogus","seriesDays":"x"}']) {
      final (c, _) = await _c({'mm.recap.u1p1': raw});
      final s = c.read(recapSettingProvider);
      expect((s.mode, s.seriesDays), (RecapMode.ask, 7), reason: raw);
    }
  });
}
