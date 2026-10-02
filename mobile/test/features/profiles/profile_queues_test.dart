import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/onboarding/models/taste.dart';
import 'package:manhwamaniacs/features/onboarding/providers/onboarding_providers.dart';
import 'package:manhwamaniacs/features/onboarding/repositories/onboarding_repository.dart';
import 'package:manhwamaniacs/features/onboarding/store/onboarding_draft.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profile_queues.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/profiles/providers/skin_outbox.dart';
import 'package:manhwamaniacs/features/profiles/repositories/profiles_repository.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_overrides.dart';

final _p = Profile(id: 1, name: 'a', avatarKey: null, mood: Mood.neutral, sortOrder: 0, matureContentEnabled: false, createdAt: DateTime.utc(2024));

class _Profiles implements ProfilesRepository {
  final skins = <String?>[];
  int lists = 0;

  @override
  Future<Result<List<Profile>>> list() async {
    lists++;
    return Ok([_p]);
  }

  @override
  Future<Result<Profile>> update(int id, {String? name, String? avatarKey, Mood? mood, int? sortOrder, bool? matureContentEnabled, String? skin, bool? notifyEnabled}) async {
    skins.add(skin);
    return Ok(_p);
  }

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

class _Onboarding implements OnboardingRepository {
  final steps = <OnboardingStep>[];

  @override
  Future<Result<void>> saveTaste(int profileId, TasteUpdate body) async {
    steps.add(body.step);
    return const Ok(null);
  }

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a queued skin switch and a pending onboarding done are sent once signed in, then the list refreshes', () async {
    SharedPreferences.setMockInitialValues({
      kSkinOutboxKey: '{"profileId":1,"skin":"glass"}',
      'mm.active_profile': '{"id":1,"name":"a","avatar_key":null,"mood":"default"}',
    });
    final prefs = await SharedPreferences.getInstance();
    final profiles = _Profiles();
    final onboarding = _Onboarding();
    final c = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      authenticatedAuthOverride(),
      profilesRepositoryProvider.overrideWithValue(profiles),
      onboardingRepositoryProvider.overrideWithValue(onboarding),
    ],);
    addTearDown(c.dispose);
    await c.read(onboardingStoreProvider).writePending(const OnboardingDraft());
    await c.read(profilesProvider.future);
    final listsBefore = profiles.lists;

    expect(await c.read(profileQueuesFlushProvider)(), isTrue);
    expect(profiles.skins, ['glass']);
    expect(prefs.getString(kSkinOutboxKey), isNull);
    expect(onboarding.steps.single.isDone, isTrue);
    expect(c.read(onboardingStoreProvider).readPending(), isNull);
    expect(profiles.lists, listsBefore + 1);
  });
}
