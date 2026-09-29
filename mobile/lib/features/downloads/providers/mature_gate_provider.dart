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
    final live = _soft(() => ref.watch(matureContentProvider).valueOrNull);
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
