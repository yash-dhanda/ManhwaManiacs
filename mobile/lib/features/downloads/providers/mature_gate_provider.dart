import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences key of the last known gate value for a `(user, profile)` scope.
String matureGatePrefsKey(String scopeId) => 'mm.mature-gate.$scopeId';

T? _soft<T>(T Function() read) {
  try {
    return read();
  } catch (_) {
    // A dependency that cannot be built (a bare container): the gate degrades to "closed".
    return null;
  }
}

/// Whether the 18+ gate is open for the active profile: the live value when it has loaded,
/// else the last one stored for this scope (so an offline cold start knows it), else closed.
final matureGateOpenProvider = Provider<bool>(
  (ref) {
    final scope = _soft(() => ref.watch(activeDownloadsScopeIdProvider));
    final prefs = _soft<SharedPreferences>(() => ref.read(sharedPrefsProvider));
    // Only a settled value: while it reloads (a profile switch) or after it fails, Riverpod keeps the
    // previous profile's value, which must not open this scope's gate or be saved under its key.
    final live = _soft(() => switch (ref.watch(matureContentProvider)) { AsyncData(:final value) => value, _ => null });
    if (scope == null || prefs == null) return live ?? false;
    final key = matureGatePrefsKey(scope);
    if (live != null) {
      if (prefs.getBool(key) != live) prefs.setBool(key, live);
      return live;
    }
    return prefs.getBool(key) ?? false;
  },
  name: 'matureGateOpen',
);
