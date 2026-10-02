import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/library/repositories/library_repository.dart';
import 'package:manhwamaniacs/features/onboarding/models/taste.dart';
import 'package:manhwamaniacs/features/onboarding/providers/onboarding_providers.dart';
import 'package:manhwamaniacs/features/onboarding/repositories/onboarding_repository.dart';
import 'package:manhwamaniacs/features/onboarding/store/onboarding_draft.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/profiles/repositories/profiles_repository.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/glass/screens/onboarding/onboarding_flow.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/test_overrides.dart';

class _Lib implements LibraryRepository {
  @override
  Future<Result<FollowedSeries>> follow({required String sourceId, required String seriesKey}) async =>
      const Err(ApiError(statusCode: 409, code: 'already_followed', message: 'followed'));

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

class _Profiles implements ProfilesRepository {
  @override
  Future<Result<List<Profile>>> list() async => const Ok([]);

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

class _Onboarding implements OnboardingRepository {
  final hold = Completer<void>();

  @override
  Future<Result<void>> saveTaste(int profileId, TasteUpdate body) async {
    await hold.future;
    return const Ok(null);
  }

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

Future<ProviderContainer> _c(List<Override> extra) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [
    sharedPrefsProvider.overrideWithValue(prefs),
    authenticatedAuthOverride(),
    activeProfileOverride(),
    ...extra,
  ],);
  addTearDown(c.dispose);
  c.listen(glassOnboardingFlowProvider, (_, __) {});
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('re-picking a title followed before a resume counts, so Finish is not blocked', () async {
    final c = await _c([libraryRepositoryProvider.overrideWithValue(_Lib())]);
    const item = WorldItem(title: 'S', anilistId: 3, available: [WorldAvailability(sourceId: 'src', sourceName: 'Src', seriesKey: 'k')]);
    final pick = await c.read(glassOnboardingFlowProvider.notifier).togglePick(item);
    expect(pick?.failed, isFalse);
    expect(c.read(glassOnboardingFlowProvider).picks.any((p) => !p.failed), isTrue);
  });

  test('done counts at once, before the save answers, so Home is not redirected back to /welcome', () async {
    final repo = _Onboarding();
    final c = await _c([onboardingRepositoryProvider.overrideWithValue(repo), profilesRepositoryProvider.overrideWithValue(_Profiles())]);
    final saving = c.read(glassOnboardingFlowProvider.notifier).saveDone(spacing: Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(onboardingStoreProvider).readPending(), isNotNull);
    repo.hold.complete();
    await saving;
  });
}
