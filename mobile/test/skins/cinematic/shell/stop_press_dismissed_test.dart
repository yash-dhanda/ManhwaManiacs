import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/stop_press_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/test_overrides.dart';

void main() {
  test('a dismissed stop press stays dismissed across launches, per profile', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    ProviderContainer launch() {
      final c = ProviderContainer(overrides: [sharedPrefsProvider.overrideWithValue(prefs), activeProfileOverride()]);
      addTearDown(c.dispose);
      return c;
    }

    launch().read(stopPressDismissedProvider.notifier).dismiss(42);
    expect(launch().read(stopPressDismissedProvider), 42);
    expect(prefs.getKeys().single, endsWith('.1'));
  });
}
