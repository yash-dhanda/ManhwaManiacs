import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/onboarding/onboarding_flow.dart';

import '../auth/auth_test_support.dart' show FakeProfiles, profile;
import 'onboarding_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a saved done refreshes the profile list, so the picker no longer resumes onboarding', () async {
    final parts = await onboardingParts(profileStep: 2);
    final c = ProviderContainer(overrides: parts.overrides);
    addTearDown(c.dispose);
    final repo = c.read(profilesRepositoryProvider) as FakeProfiles;
    expect((await c.read(profilesProvider.future)).single.onboardingStep, '2');
    // The server records the step.
    repo.items = [profile(1, 'Tester')];
    final sub = c.listen(onboardingFlowProvider, (_, __) {});
    addTearDown(sub.close);

    expect(await c.read(onboardingFlowProvider.notifier).saveDone(spacing: Duration.zero), isTrue);
    expect(c.read(profilesProvider).valueOrNull?.single.onboardingStep, 'done');
  });
}
