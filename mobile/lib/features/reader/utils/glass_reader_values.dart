import 'dart:math' as math;

import 'package:manhwamaniacs/core/storage/json_record.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_profile_settings.dart';

// TODO(mobile/35): the Glass reader builds on these fields; it may add its own under the same `glass` object. Nothing here is read
// by Cinematic, and a field that is absent falls back to the value below.

/// The per-profile `glass` object inside `mm.reader-settings.u{user}p{profile}`: what Glass adds to the reader profile defaults
/// (glass 8.25.3, 9.4). Unknown fields survive every write.
abstract final class GlassReaderKeys {
  static const obj = 'glass';
  static const brightness = 'brightness';
  static const warmth = 'warmth';
  static const background = 'background';
  static const keepAwake = 'keepAwake';
  static const pageTinted = 'pageTinted';
  static const cruiseDefault = 'cruiseDefault';
  static const guidedDefault = 'guidedDefault';
}

/// Cruise default speed (glass 9.4.1): 0.25 to 4.00 in 0.05 steps, 1.00 by default.
const double kGlassCruiseMin = 0.25, kGlassCruiseMax = 4.0, kGlassCruiseDefault = 1.0;

/// Snaps a cruise speed to the 0.05 grid inside its range.
double snapCruise(double v) => ((v.clamp(kGlassCruiseMin, kGlassCruiseMax) * 20).round() / 20).clamp(kGlassCruiseMin, kGlassCruiseMax);

/// A logarithmic track (0 to 1) over the cruise range, so 1.0x sits where the magnet holds it (glass 8.25.3 Ambient).
double cruiseToTrack(double v) => (math.log(snapCruise(v) / kGlassCruiseMin) / math.log(kGlassCruiseMax / kGlassCruiseMin)).clamp(0.0, 1.0);

double trackToCruise(double t) => snapCruise(kGlassCruiseMin * math.pow(kGlassCruiseMax / kGlassCruiseMin, t.clamp(0.0, 1.0)));

extension GlassReaderValues on JsonRecord {
  JsonRecord get glass => child(GlassReaderKeys.obj);

  /// 0.2 to 1.0 (K09 kept as is).
  double get glassBrightness => glass.doubleOf(GlassReaderKeys.brightness, 1.0).clamp(0.2, 1.0);

  /// 0 to 1 (K10 kept as is).
  double get glassWarmth => glass.doubleOf(GlassReaderKeys.warmth, 0.0).clamp(0.0, 1.0);

  /// `graphite` (the Glass default) or `black`.
  String get glassBackground => glass.choice(GlassReaderKeys.background, const ['graphite', 'black'], 'graphite');

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
