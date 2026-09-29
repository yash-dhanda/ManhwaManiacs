// ignore_for_file: require_trailing_commas, avoid_redundant_argument_values, library_private_types_in_public_api, directives_ordering
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/storage/profile_scoped_key.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';

import 'support/test_overrides.dart';

final _key = Provider<String>((ref) => profileScopedKey(ref, prefix: 'mm.home.last.manga.', deviceKey: 'mm.home.last.manga.device', watch: true));

void main() {
  test('user and profile: prefix u{user}p{profile}', () {
    final c = ProviderContainer(overrides: [authenticatedAuthOverride(), activeProfileOverride()]);
    addTearDown(c.dispose);
    expect(c.read(_key), 'mm.home.last.manga.u1p1');
  });

  test('no profile: the device key', () {
    final c = ProviderContainer(overrides: [authenticatedAuthOverride(), activeProfileProvider.overrideWith(_None.new)]);
    addTearDown(c.dispose);
    expect(c.read(_key), 'mm.home.last.manga.device');
  });

  test('signed out: the device key', () {
    final c = ProviderContainer(overrides: [activeProfileOverride()]);
    addTearDown(c.dispose);
    expect(c.read(_key), 'mm.home.last.manga.device');
  });
}

class _None extends ActiveProfileNotifier {
  @override
  ActiveProfile? build() => null;
}
