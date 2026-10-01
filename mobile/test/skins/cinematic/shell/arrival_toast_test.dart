import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/app/skin_boot.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('the arrival is taken at boot and its toast is only due for 10 s', () async {
    SharedPreferences.setMockInitialValues({kSkinFromKey: 'glass'});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [sharedPrefsProvider.overrideWithValue(prefs)]);
    addTearDown(c.dispose);

    final at = c.read(cineArrivalProvider);
    expect(at, isNotNull);
    expect(prefs.containsKey(kSkinFromKey), isFalse);
    expect(cineArrivalToastDue(at, at!.add(const Duration(seconds: 2))), isTrue);
    // Reaching the shell minutes later (the switch landed on the profile form) offers no Undo.
    expect(cineArrivalToastDue(at, at.add(const Duration(minutes: 3))), isFalse);
    expect(cineArrivalToastDue(null, DateTime.now()), isFalse);
  });
}
