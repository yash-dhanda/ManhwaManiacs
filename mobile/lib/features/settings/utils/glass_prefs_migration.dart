import 'dart:convert';

import 'package:manhwamaniacs/core/storage/json_record.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_profile_settings.dart';
import 'package:manhwamaniacs/features/reader/utils/glass_reader_values.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_prefs_migration.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Marker per profile: `mm.glass.migrated.v1.u{user}p{profile}`.
const String kGlassMigratedPrefix = 'mm.glass.migrated.v1.';

/// The per-profile Glass library columns (K15), read by the Glass library (`mobile/32`); lives in `mm.glass.prefs`.
const String kGlassLibraryColumnsField = 'libraryColumns';

/// K15 `settings_library_cover_scale`: under 0.85 is Compact (4 columns), 0.85 to 1.25 Comfortable (3), over 1.25 two columns.
int libraryColumnsFromCoverScale(double k15) => k15 < 0.85 ? 4 : (k15 <= 1.25 ? 3 : 2);

/// K11 `settings_reader_background`: `dark` becomes Graphite; `black` (AMOLED) and `white` (Paper) become Black.
String? glassBackgroundFromLegacy(String? k11) => switch (k11) { 'dark' => 'graphite', 'black' || 'white' => 'black', _ => null };

Map<String, dynamic> _decode(String? raw) {
  if (raw == null) return {};
  try {
    final v = jsonDecode(raw);
    return v is Map ? Map<String, dynamic>.from(v) : {};
  } catch (_) {
    return {};
  }
}

String glassMigratedKey(int userId, int profileId) => '$kGlassMigratedPrefix' 'u${userId}p$profileId';

/// The one-time copy of the stored mobile values into a profile's Glass defaults (glass 8.25.3, the mobile rows). Runs once per
/// profile when it becomes active in the Glass skin. Old keys are only read; every Glass field the profile already holds is kept.
/// Rows that need no write (cruise speed, direction, fit, zoom, novel paper) are read where they are used: the series entry seeds
/// from `legacyDefaultsOf` on its first open, the novel paper falls back at read time, and cruise falls back to `glass.cruiseDefault`.
/// Returns whether it ran.
Future<bool> runGlassPrefsMigration(SharedPreferences prefs, {required int userId, required int profileId}) async {
  final marker = glassMigratedKey(userId, profileId);
  if (prefs.getBool(marker) ?? false) return false;

  final key = '$kReaderSettingsPrefix' 'u${userId}p$profileId';
  final record = _decode(prefs.getString(key));
  final glass = record['glass'] is Map ? Map<String, dynamic>.from(record['glass'] as Map) : <String, dynamic>{};

  void seed(String field, Object? value) {
    if (value != null && !glass.containsKey(field)) glass[field] = value;
  }

  final k09 = prefs.getDouble(LegacyReaderKeys.brightness);
  if (k09 != null) seed(GlassReaderKeys.brightness, k09.clamp(0.2, 1.0));
  final k10 = prefs.getDouble(LegacyReaderKeys.warmth);
  if (k10 != null) seed(GlassReaderKeys.warmth, k10.clamp(0.0, 1.0));
  seed(GlassReaderKeys.background, glassBackgroundFromLegacy(prefs.getString(LegacyReaderKeys.background)));
  final k05 = prefs.getBool('settings_keep_screen_awake');
  if (k05 != null) seed(GlassReaderKeys.keepAwake, k05);
  if (glass.isNotEmpty) {
    record['glass'] = glass;
    await prefs.setString(key, jsonEncode(record));
  }

  final k15 = prefs.getDouble('settings_library_cover_scale');
  if (k15 != null) {
    final prefsKey = 'mm.glass.prefs.u${userId}p$profileId';
    final own = _decode(prefs.getString(prefsKey));
    if (!own.containsKey(kGlassLibraryColumnsField)) {
      own[kGlassLibraryColumnsField] = libraryColumnsFromCoverScale(k15);
      await prefs.setString(prefsKey, jsonEncode(own));
    }
  }

  await prefs.setBool(marker, true);
  return true;
}

/// A JsonRecord of the profile's reader record, for tests.
JsonRecord readerRecordOf(SharedPreferences prefs, int userId, int profileId) => JsonRecord.decode(prefs.getString('$kReaderSettingsPrefix' 'u${userId}p$profileId'));
