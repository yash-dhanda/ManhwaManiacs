import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/downloads/providers/download_switches_provider.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_overrides.dart';

class _Profiles extends ActiveProfileNotifier {
  @override
  ActiveProfile? build() => const ActiveProfile(id: 1, name: 'One', avatarKey: null, mood: Mood.neutral);
  void to(int id) => state = ActiveProfile(id: id, name: 'P$id', avatarKey: null, mood: Mood.neutral);
}

void main() {
  test('defaults: save-next on, auto-new off; each is per profile', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      authenticatedAuthOverride(),
      activeProfileProvider.overrideWith(_Profiles.new),
    ],);
    addTearDown(c.dispose);
    expect(c.read(saveNextProvider), isTrue);
    expect(c.read(autoNewProvider), isFalse);

    await c.read(saveNextProvider.notifier).set(false);
    await c.read(autoNewProvider.notifier).set(true);
    expect(prefs.getBool('mm.downloads.save-next.u1p1'), isFalse);
    expect(prefs.getBool('mm.downloads.auto-new.u1p1'), isTrue);

    (c.read(activeProfileProvider.notifier) as _Profiles).to(2);
    expect(c.read(saveNextProvider), isTrue);
    expect(c.read(autoNewProvider), isFalse);

    (c.read(activeProfileProvider.notifier) as _Profiles).to(1);
    expect(c.read(saveNextProvider), isFalse);
    expect(c.read(autoNewProvider), isTrue);
  });
}
