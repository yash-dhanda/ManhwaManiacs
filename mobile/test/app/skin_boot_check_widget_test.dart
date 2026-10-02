import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/app/skin_boot.dart';
import 'package:manhwamaniacs/app/skin_boot_check.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

Profile _p(int id, String skin) => Profile(
      id: id,
      name: 'P$id',
      avatarKey: null,
      mood: Mood.neutral,
      sortOrder: id,
      matureContentEnabled: false,
      createdAt: DateTime.utc(2024),
      skin: skin,
    );

final _a = _p(1, 'glass');
final _b = _p(2, 'cinematic');

class _Profiles extends ProfilesNotifier {
  @override
  Future<List<Profile>> build() async => [_a, _b];
}

void main() {
  testWidgets('choosing a profile with another skin is left to the picker (no boot restart)', (tester) async {
    SharedPreferences.setMockInitialValues({
      'mm.active_profile': '{"id":1,"name":"P1","avatar_key":null,"mood":"default"}',
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      skinIdProvider.overrideWithValue(SkinId.glass),
      profilesProvider.overrideWith(_Profiles.new),
    ],);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const SkinBootCheck(child: SizedBox()),
    ),);
    await tester.pump();
    // Boot: the restored profile runs in the running skin, nothing to do.
    expect(prefs.getString(kSkinBootRestartKey), isNull);

    // The picker selects B (Cinematic) and runs its own hand-off and restart.
    await container.read(activeProfileProvider.notifier).select(_b);
    await tester.pump();
    expect(prefs.getString(kSkinBootRestartKey), isNull);

    // A later list refresh (a form's edit) does not restart either.
    container.invalidate(profilesProvider);
    await tester.pump();
    await tester.pump();
    expect(prefs.getString(kSkinBootRestartKey), isNull);
    await tester.pump(const Duration(seconds: 1));
  });
}
