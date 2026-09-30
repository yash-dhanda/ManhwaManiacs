import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/storage/profile_scoped_key.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

/// A schemaless JSON object with typed reads and a default for every field. Unknown fields
/// survive a write, so two features (or two versions of one) can share a record.
class JsonRecord {
  const JsonRecord([this.data = const {}]);

  final Map<String, dynamic> data;

  factory JsonRecord.decode(String? raw) {
    if (raw == null) return const JsonRecord();
    try {
      final v = jsonDecode(raw);
      return v is Map ? JsonRecord(Map<String, dynamic>.from(v)) : const JsonRecord();
    } catch (_) {
      return const JsonRecord();
    }
  }

  bool boolOf(String k, bool d) => data[k] is bool ? data[k] as bool : d;
  int intOf(String k, int d) => data[k] is num ? (data[k] as num).round() : d;
  double doubleOf(String k, double d) => data[k] is num ? (data[k] as num).toDouble() : d;
  String stringOf(String k, String d) => data[k] is String ? data[k] as String : d;

  /// A nested object as its own record (empty when absent or not an object).
  JsonRecord child(String k) => data[k] is Map ? JsonRecord(Map<String, dynamic>.from(data[k] as Map)) : const JsonRecord();

  /// One of [allowed], else [d].
  String choice(String k, List<String> allowed, String d) => allowed.contains(data[k]) ? data[k] as String : d;

  JsonRecord merge(Map<String, dynamic> patch) => JsonRecord({...data, ...patch});

  String encode() => jsonEncode(data);
}

/// A profile-scoped [JsonRecord] in SharedPreferences under `{prefix}u{user}p{profile}`.
abstract class ProfileRecordNotifier extends Notifier<JsonRecord> {
  String get prefix;

  String _key({required bool watch}) => profileScopedKey(ref, prefix: prefix, deviceKey: '${prefix}device', watch: watch);

  @override
  JsonRecord build() => JsonRecord.decode(ref.watch(sharedPrefsProvider).getString(_key(watch: true)));

  /// Merge [patch] into the record and save it.
  Future<void> put(Map<String, dynamic> patch) async {
    state = state.merge(patch);
    await ref.read(sharedPrefsProvider).setString(_key(watch: false), state.encode());
  }

  /// Forget everything this record holds.
  Future<void> reset() async {
    state = const JsonRecord();
    await ref.read(sharedPrefsProvider).remove(_key(watch: false));
  }
}

/// A per-device SharedPreferences value with a default.
class DeviceValueNotifier<T extends Object> extends Notifier<T> {
  DeviceValueNotifier(this.key, this.fallback);

  final String key;
  final T fallback;

  @override
  T build() {
    final v = ref.watch(sharedPrefsProvider).get(key);
    return v is T ? v : fallback;
  }

  Future<void> set(T value) async {
    state = value;
    final p = ref.read(sharedPrefsProvider);
    switch (value) {
      case final bool b:
        await p.setBool(key, b);
      case final int i:
        await p.setInt(key, i);
      case final double d:
        await p.setDouble(key, d);
      case final String s:
        await p.setString(key, s);
    }
  }
}
