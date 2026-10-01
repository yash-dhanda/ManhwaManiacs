import 'dart:math' as math;

import 'package:manhwamaniacs/core/storage/json_record.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_profile_settings.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_prefs_migration.dart' show LegacyReaderKeys;

/// The per-profile `glass` object inside `mm.reader-settings.u{user}p{profile}`: what Glass adds to the reader profile defaults
/// (glass 8.25.3, 9.4). Unknown fields survive every write. Nothing here is read by Cinematic, and a field that is absent falls
/// back to the stored legacy value (K05, K07, K09, K10, K11) and then to the value below.
abstract final class GlassReaderKeys {
  static const obj = 'glass';
  static const brightness = 'brightness';
  static const warmth = 'warmth';
  static const background = 'background';
  static const keepAwake = 'keepAwake';
  static const pageTinted = 'pageTinted';
  static const cruiseDefault = 'cruiseDefault';
  static const guidedDefault = 'guidedDefault';
  static const pageTransition = 'pageTransition';
  static const chapters = 'chapters';
  static const lockControls = 'lockControls';
  static const tapToScroll = 'tapToScroll';
  static const swipeChapter = 'swipeChapter';
  static const hideCinemaProgress = 'hideCinemaProgress';

  /// Per series, in the `mm.reader-prefs` entry of `source:series` (glass 9.4.1).
  static const cruiseSpeed = 'cruiseSpeed';
}

/// The device keys Glass reads and never writes (K05, K07; K04 and K08 stay device values used as they are).
abstract final class GlassLegacyKeys {
  static const keepAwake = 'settings_keep_screen_awake';
  static const lockControls = 'settings_lock_reader_controls';
}

/// Cruise default speed (glass 9.4.1): 0.25 to 4.00 in 0.05 steps, 1.00 by default.
const double kGlassCruiseMin = 0.25, kGlassCruiseMax = 4.0, kGlassCruiseDefault = 1.0;

/// Snaps a cruise speed to the 0.05 grid inside its range.
double snapCruise(double v) => ((v.clamp(kGlassCruiseMin, kGlassCruiseMax) * 20).round() / 20).clamp(kGlassCruiseMin, kGlassCruiseMax);

/// A logarithmic track (0 to 1) over the cruise range, so 1.0x sits where the magnet holds it (glass 8.25.3 Ambient).
double cruiseToTrack(double v) => (math.log(snapCruise(v) / kGlassCruiseMin) / math.log(kGlassCruiseMax / kGlassCruiseMin)).clamp(0.0, 1.0);

double trackToCruise(double t) => snapCruise(kGlassCruiseMin * math.pow(kGlassCruiseMax / kGlassCruiseMin, t.clamp(0.0, 1.0)));

/// The 1.0x magnet of the cruise slider: within +-0.08 snaps to 1.0.
double cruiseMagnet(double v) => (v - 1.0).abs() <= 0.08 ? 1.0 : snapCruise(v);

/// K11 `settings_reader_background`: `dark` becomes Graphite; `black` (AMOLED) and `white` (Paper) become Black.
String? glassBackgroundOfLegacy(String? k11) => switch (k11) { 'dark' => 'graphite', 'black' || 'white' => 'black', _ => null };

/// Reads a legacy device value (a SharedPreferences `get`), never written by Glass.
typedef LegacyRead = Object? Function(String key);

extension GlassReaderValues on JsonRecord {
  JsonRecord get glass => child(GlassReaderKeys.obj);

  /// 0.2 to 1.0 (K09 kept as is).
  double get glassBrightness => glass.doubleOf(GlassReaderKeys.brightness, 1.0).clamp(0.2, 1.0);

  /// 0 to 1 (K10 kept as is).
  double get glassWarmth => glass.doubleOf(GlassReaderKeys.warmth, 0.0).clamp(0.0, 1.0);

  /// `black` (the canvas `#000000`, glass 8.14.1) or `graphite` (`#0B0B0F`).
  String get glassBackground => glass.choice(GlassReaderKeys.background, const ['graphite', 'black'], 'black');

  bool get glassKeepAwake => glass.boolOf(GlassReaderKeys.keepAwake, false);

  bool get glassPageTinted => glass.boolOf(GlassReaderKeys.pageTinted, true);

  double get glassCruiseDefault => snapCruise(glass.doubleOf(GlassReaderKeys.cruiseDefault, kGlassCruiseDefault));

  bool get glassGuidedDefault => glass.boolOf(GlassReaderKeys.guidedDefault, false);
}

/// Writes one or more `glass.*` fields without touching the rest of the record (`readerSettingsProvider.notifier.put`).
Map<String, dynamic> glassPatch(JsonRecord record, Map<String, dynamic> fields) => {
      GlassReaderKeys.obj: {...record.glass.data, ...fields},
    };

/// The record the reader settings live in (re-exported so Glass and the migration name one place).
const String kGlassReaderSettingsPrefix = kReaderSettingsPrefix;

/// The Glass reader's per-profile values at read time (glass 8.25.3, the mobile rules): the new `glass.*` key when present,
/// otherwise derived from the stored legacy value, otherwise the default. Writes go only to the new keys ([GlassReaderValueSet.patch]).
class GlassReaderValueSet {
  const GlassReaderValueSet({
    this.brightness = 1.0,
    this.warmth = 0.0,
    this.background = 'black',
    this.pageTransition = 'none',
    this.chapters = 'continuous',
    this.keepAwake = false,
    this.lockControls = false,
    this.tapToScroll = false,
    this.swipeChapter = false,
    this.hideCinemaProgress = false,
    this.pageTinted = true,
  });

  /// [profile] is `mm.reader-settings.u{user}p{profile}`; [legacy] reads the device keys K05, K07, K09, K10 and K11.
  factory GlassReaderValueSet.resolve(JsonRecord profile, LegacyRead legacy) {
    final g = profile.glass;
    bool has(String k) => g.data.containsKey(k);
    double? numOf(String key) => switch (legacy(key)) { final num n => n.toDouble(), _ => null };
    bool? flag(String key) => switch (legacy(key)) { final bool b => b, _ => null };
    return GlassReaderValueSet(
      brightness: has(GlassReaderKeys.brightness) ? profile.glassBrightness : (numOf(LegacyReaderKeys.brightness) ?? 1.0).clamp(0.2, 1.0),
      warmth: has(GlassReaderKeys.warmth) ? profile.glassWarmth : (numOf(LegacyReaderKeys.warmth) ?? 0.0).clamp(0.0, 1.0),
      background: has(GlassReaderKeys.background)
          ? profile.glassBackground
          : (glassBackgroundOfLegacy(switch (legacy(LegacyReaderKeys.background)) { final String s => s, _ => null }) ?? 'black'),
      pageTransition: g.choice(GlassReaderKeys.pageTransition, const ['slide', 'fade', 'none'], 'none'),
      chapters: g.choice(GlassReaderKeys.chapters, const ['continuous', 'single'], 'continuous'),
      keepAwake: has(GlassReaderKeys.keepAwake) ? profile.glassKeepAwake : (flag(GlassLegacyKeys.keepAwake) ?? false),
      lockControls: has(GlassReaderKeys.lockControls) ? g.boolOf(GlassReaderKeys.lockControls, false) : (flag(GlassLegacyKeys.lockControls) ?? false),
      tapToScroll: g.boolOf(GlassReaderKeys.tapToScroll, false),
      swipeChapter: g.boolOf(GlassReaderKeys.swipeChapter, false),
      hideCinemaProgress: g.boolOf(GlassReaderKeys.hideCinemaProgress, false),
      pageTinted: profile.glassPageTinted,
    );
  }

  /// 0.2 to 1.0.
  final double brightness;

  /// 0 to 1.
  final double warmth;

  /// `black` or `graphite`.
  final String background;

  /// `slide`, `fade` or `none`.
  final String pageTransition;

  /// `continuous` or `single` (one at a time).
  final String chapters;
  final bool keepAwake, lockControls, tapToScroll, swipeChapter, hideCinemaProgress, pageTinted;

  bool get oneAtATime => chapters == 'single';

  /// The patch that writes [fields] into the `glass` object of [profile], keeping every other field (Cinematic's included).
  static Map<String, dynamic> patch(JsonRecord profile, Map<String, dynamic> fields) => glassPatch(profile, fields);
}

/// The series' cruise speed multiplier (`cruiseSpeed` in its `mm.reader-prefs` entry), else the profile's cruise default.
double glassCruiseSpeedOf(JsonRecord? series, JsonRecord profile) {
  final v = series?.data[GlassReaderKeys.cruiseSpeed];
  return v is num ? snapCruise(v.toDouble()) : profile.glassCruiseDefault;
}
