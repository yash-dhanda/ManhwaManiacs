import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Offline copies (the OFFLINE EDITION states) of the raw payloads, per
/// profile: `mm.numbers.last.{days}.u{user}p{profile}` and
/// `mm.annual.last.{year}.u{user}p{profile}`. Stored as `{savedAt, payload}`; the older shape (the bare payload, no
/// `savedAt`) still reads, with a null age. Raw JSON, so the models stay parse-only.
class NumbersSnapshot {
  const NumbersSnapshot(this._prefs,
      {required this.userId, required this.profileId,});

  final SharedPreferences _prefs;
  final int userId;
  final int profileId;

  String get _scope => 'u${userId}p$profileId';

  String numbersKey(int days) => 'mm.numbers.last.$days.$_scope';
  String annualKey(int year) => 'mm.annual.last.$year.$_scope';

  Future<void> writeNumbers(int days, Map<String, dynamic> json, {DateTime? now}) => _write(numbersKey(days), json, now);
  Future<void> writeAnnual(int year, Map<String, dynamic> json, {DateTime? now}) => _write(annualKey(year), json, now);

  Future<void> _write(String key, Map<String, dynamic> json, DateTime? now) =>
      _prefs.setString(key, jsonEncode({'savedAt': (now ?? DateTime.now()).toUtc().toIso8601String(), 'payload': json}));

  Map<String, dynamic>? readNumbers(int days) => _read(numbersKey(days))?.payload;
  Map<String, dynamic>? readAnnual(int year) => _read(annualKey(year))?.payload;

  /// When the snapshot was taken; null for the older shape or no snapshot.
  DateTime? numbersSavedAt(int days) => _read(numbersKey(days))?.savedAt;
  DateTime? annualSavedAt(int year) => _read(annualKey(year))?.savedAt;

  /// Deletes every statistics and Wrapped snapshot of this profile (the 18+ purge).
  Future<void> purge() async {
    for (final k in _prefs.getKeys().where((k) => (k.startsWith('mm.numbers.last.') || k.startsWith('mm.annual.last.')) && k.endsWith('.$_scope')).toList()) {
      await _prefs.remove(k);
    }
  }

  ({Map<String, dynamic> payload, DateTime? savedAt})? _read(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final v = jsonDecode(raw);
      if (v is! Map<String, dynamic>) return null;
      final inner = v['payload'];
      if (inner is Map<String, dynamic> && v.containsKey('savedAt')) {
        return (payload: inner, savedAt: DateTime.tryParse('${v['savedAt']}')?.toLocal());
      }
      return (payload: v, savedAt: null);
    } catch (_) {
      return null;
    }
  }
}

/// "just now" under a minute, "12 min ago", "2 h ago", "3 d ago"; "earlier" when the age is unknown.
String snapshotAge(DateTime? savedAt, DateTime now) {
  if (savedAt == null) return 'earlier';
  final d = now.difference(savedAt);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours} h ago';
  return '${d.inDays} d ago';
}
