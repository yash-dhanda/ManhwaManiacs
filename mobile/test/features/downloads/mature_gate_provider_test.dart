// ignore_for_file: require_trailing_commas
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Live extends MatureContentController {
  _Live(this.v);
  final bool? v;
  @override
  Future<bool> build() async => v ?? (throw Exception('offline'));
}

void main() {
  Future<bool> gate(Map<String, Object> seed, bool? live) async {
    SharedPreferences.setMockInitialValues(seed);
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      activeDownloadsScopeIdProvider.overrideWithValue('u1p2'),
      matureContentProvider.overrideWith(() => _Live(live)),
    ]);
    addTearDown(c.dispose);
    c.listen(matureContentProvider, (_, __) {});
    await Future<void>.delayed(Duration.zero);
    return c.read(matureGateOpenProvider);
  }

  test('live value wins and is stored', () async {
    expect(await gate({}, true), isTrue);
    expect(
        (await SharedPreferences.getInstance()).getBool('mm.mature-gate.u1p2'),
        isTrue);
  });
  test('offline falls back to the last known value, else closed', () async {
    expect(await gate({'mm.mature-gate.u1p2': true}, null), isTrue);
    expect(await gate({}, null), isFalse);
  });
}
