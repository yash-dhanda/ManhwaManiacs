import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Offline copies (the OFFLINE EDITION states) of the raw payloads, per
/// profile: `mm.numbers.last.{days}.u{user}p{profile}` and
/// `mm.annual.last.{year}.u{user}p{profile}`. Raw JSON, so the models stay
/// parse-only.
class NumbersSnapshot {
  const NumbersSnapshot(this._prefs,
      {required this.userId, required this.profileId,});

  final SharedPreferences _prefs;
  final int userId;
  final int profileId;

  String get _scope => 'u${userId}p$profileId';

  String numbersKey(int days) => 'mm.numbers.last.$days.$_scope';
  String annualKey(int year) => 'mm.annual.last.$year.$_scope';

  Future<void> writeNumbers(int days, Map<String, dynamic> json) =>
      _prefs.setString(numbersKey(days), jsonEncode(json));
  Future<void> writeAnnual(int year, Map<String, dynamic> json) =>
      _prefs.setString(annualKey(year), jsonEncode(json));

  Map<String, dynamic>? readNumbers(int days) => _read(numbersKey(days));
  Map<String, dynamic>? readAnnual(int year) => _read(annualKey(year));

  Map<String, dynamic>? _read(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final v = jsonDecode(raw);
      return v is Map<String, dynamic> ? v : null;
    } catch (_) {
      return null;
    }
  }
}
