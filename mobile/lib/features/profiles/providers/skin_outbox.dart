import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/logging/app_logger.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/profiles/repositories/profiles_repository.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/skin.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kSkinOutboxKey = 'mm.skin.outbox';

/// The queued `PATCH /profiles/{id}` for a skin switch. One entry per device:
/// the latest switch wins. It stays until the server has it, and while it
/// exists it beats the server's `profile.skin` at boot (S12).
class SkinOutbox {
  SkinOutbox(this._prefs, this._repo);

  final SharedPreferences _prefs;
  final ProfilesRepository _repo;
  Future<void>? _inFlight;

  Future<void> enqueue(int profileId, SkinId skin) =>
      _prefs.setString(kSkinOutboxKey, jsonEncode({'profileId': profileId, 'skin': skin.name}));

  Map<String, dynamic>? _entry() {
    final raw = _prefs.getString(kSkinOutboxKey);
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw);
      return m is Map<String, dynamic> && m['profileId'] is int && m['skin'] is String ? m : null;
    } catch (_) {
      return null;
    }
  }

  String? pendingFor(int profileId) {
    final e = _entry();
    return e != null && e['profileId'] == profileId ? e['skin'] as String : null;
  }

  /// A second call while one runs joins it.
  Future<void> flush() => _inFlight ??= _flush().whenComplete(() => _inFlight = null);

  Future<void> _flush() async {
    final sent = _prefs.getString(kSkinOutboxKey);
    final e = _entry();
    if (e == null) return;
    final result = await _repo.update(e['profileId'] as int, skin: e['skin'] as String);
    var drop = !result.isErr;
    if (result.isErr) {
      final err = result.error;
      if (err is ApiError && (err.statusCode == 404 || err.statusCode == 422)) {
        appLogger.w('Skin outbox: dropping ${e['skin']} for profile ${e['profileId']}: $err');
        drop = true;
      }
    }
    // Only if it is still the same entry: a newer switch made meanwhile stays.
    if (drop && _prefs.getString(kSkinOutboxKey) == sent) {
      await _prefs.remove(kSkinOutboxKey);
    }
  }
}

final skinOutboxProvider = Provider<SkinOutbox>(
  (ref) => SkinOutbox(ref.watch(sharedPrefsProvider), ref.watch(profilesRepositoryProvider)),
  name: 'skinOutbox',
);
