import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Device marker of the one-time copy (cinematic 8.14.8, last paragraph).
const kReaderPrefsMigratedKey = 'mm.reader-prefs.migrated.v1';

/// Device seed: the migrated defaults, so a profile created later starts from them too.
const kReaderPrefsSeedKey = 'mm.reader-prefs.seed.v1';

/// Legacy device-wide keys K01-K03, K06, K09-K12 (never deleted or rewritten here).
abstract final class LegacyReaderKeys {
  static const direction = 'settings_reading_direction';
  static const fit = 'settings_reader_fit_mode';
  static const tapZones = 'settings_reader_tap_zones';
  static const autoNext = 'settings_auto_next_chapter';
  static const brightness = 'reader_brightness';
  static const warmth = 'settings_reader_warmth';
  static const background = 'settings_reader_background';
  static const colorMode = 'settings_reader_color_mode';
}

/// K09: 0.2 -> -75, 0.6 -> -38, 1.0 -> 0.
int brightnessFromLegacy(double k09) => -((1 - k09.clamp(0.2, 1.0)) / 0.8 * 75).round();

/// K10: 0-1 -> 0-100.
int warmthFromLegacy(double k10) => (k10.clamp(0.0, 1.0) * 100).round();

/// K11: `dark` -> INK, `black` -> BLACK, `white` -> SLATE (cinematic 2.1.6).
String? groundFromLegacy(String? k11) => switch (k11) { 'dark' => 'ink', 'black' => 'black', 'white' => 'slate', _ => null };

/// K12: `normal` / `sepia` / `grayscale`.
String? colourFromLegacy(String? k12) => switch (k12) { 'normal' => 'normal', 'sepia' => 'sepia', 'grayscale' => 'grey', _ => null };

/// K03 `retreat` / `toggle` / `advance` -> `previous` / `menu` / `next`.
String? _zone(String a) => switch (a) { 'retreat' => 'previous', 'toggle' => 'menu', 'advance' => 'next', _ => null };

/// K01 + K02: layout, direction and fit as the profile defaults. Only the keys legacy actually
/// stored produce a field.
Map<String, dynamic> legacyDefaultsOf(SharedPreferences prefs) {
  final out = <String, dynamic>{};
  final series = <String, dynamic>{};
  switch (prefs.getString(LegacyReaderKeys.direction)) {
    case 'vertical':
      series['layout'] = 'strip';
    case 'leftToRight':
      series
        ..['layout'] = 'single'
        ..['direction'] = 'ltr';
    case 'rightToLeft':
      series
        ..['layout'] = 'single'
        ..['direction'] = 'rtl';
  }
  switch (prefs.getString(LegacyReaderKeys.fit)) {
    case 'width':
      series['fit'] = 'width';
    case 'height' || 'screen':
      series['fit'] = 'height';
  }
  if (series.isNotEmpty) out['seriesDefaults'] = series;

  final zones = prefs.getString(LegacyReaderKeys.tapZones)?.split(',');
  if (zones != null && zones.length == 3) {
    final mapped = [for (final z in zones) _zone(z)];
    if (!mapped.contains(null)) {
      out['tapZone.left'] = mapped[0];
      out['tapZone.center'] = mapped[1];
      out['tapZone.right'] = mapped[2];
    }
  }
  final auto = prefs.getBool(LegacyReaderKeys.autoNext);
  if (auto != null) out['autoNextChapter'] = auto;
  final bright = prefs.getDouble(LegacyReaderKeys.brightness);
  if (bright != null) out['brightness'] = brightnessFromLegacy(bright);
  final warm = prefs.getDouble(LegacyReaderKeys.warmth);
  if (warm != null) out['warmth'] = warmthFromLegacy(warm);
  final ground = groundFromLegacy(prefs.getString(LegacyReaderKeys.background));
  if (ground != null) out['ground'] = ground;
  final colour = colourFromLegacy(prefs.getString(LegacyReaderKeys.colorMode));
  if (colour != null) out['colour'] = colour;
  return out;
}

Map<String, dynamic> _decode(String? raw) {
  if (raw == null) return {};
  try {
    final v = jsonDecode(raw);
    return v is Map ? Map<String, dynamic>.from(v) : {};
  } catch (_) {
    return {};
  }
}

/// Copies the legacy values into every profile's `mm.reader-settings` record ([profileKeys] are
/// the full SharedPreferences keys) as that profile's defaults, once per device. A field the
/// profile already holds is kept; unknown fields survive; the legacy keys are only read. Also
/// stores the device seed for profiles created later. Returns whether it ran.
Future<bool> migrateReaderPrefs(SharedPreferences prefs, {required Iterable<String> profileKeys}) async {
  if (prefs.getBool(kReaderPrefsMigratedKey) ?? false) return false;
  final defaults = legacyDefaultsOf(prefs);
  await prefs.setString(kReaderPrefsSeedKey, jsonEncode(defaults));
  for (final key in profileKeys) {
    final own = _decode(prefs.getString(key));
    final merged = {...own};
    for (final e in defaults.entries) {
      if (e.key == 'seriesDefaults') {
        final ownSeries = own['seriesDefaults'] is Map ? Map<String, dynamic>.from(own['seriesDefaults'] as Map) : <String, dynamic>{};
        merged['seriesDefaults'] = {...(e.value as Map<String, dynamic>), ...ownSeries};
      } else if (!own.containsKey(e.key)) {
        merged[e.key] = e.value;
      }
    }
    await prefs.setString(key, jsonEncode(merged));
  }
  await prefs.setBool(kReaderPrefsMigratedKey, true);
  return true;
}

/// The device seed as a map (empty before the migration ran).
Map<String, dynamic> readerPrefsSeed(SharedPreferences prefs) => _decode(prefs.getString(kReaderPrefsSeedKey));
