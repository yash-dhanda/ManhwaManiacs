/// The Listen settings a profile keeps (cinematic 8.30.2 row 05), stored in
/// `mm.listen-settings.u{user}p{profile}` as JSON. Unknown fields survive a write (the record is a
/// `JsonRecord`); this is the typed, normalised view the player reads.
library;

import 'package:manhwamaniacs/core/storage/json_record.dart';
import 'package:manhwamaniacs/features/novels/utils/sleep_timer.dart';

const String kListenSettingsPrefix = 'mm.listen-settings.';

/// The stored `sleepDefault` spellings.
const List<String> kSleepDefaults = ['off', '5', '10', '15', '30', '45', '60', 'chapter', 'nextChapter'];

const double kListenMinSpeed = 0.5, kListenMaxSpeed = 3.0, kListenSpeedStep = 0.05;

/// The speed ruler's preset slugs.
const List<double> kListenSpeedPresets = [0.8, 1, 1.25, 1.5, 2];

/// Snaps [speed] to the 0.05 grid inside 0.50-3.00.
double normaliseListenSpeed(num speed) {
  final steps = ((speed.toDouble() - kListenMinSpeed) / kListenSpeedStep).round();
  return double.parse((kListenMinSpeed + steps * kListenSpeedStep).clamp(kListenMinSpeed, kListenMaxSpeed).toStringAsFixed(2));
}

class ListenSettings {
  const ListenSettings({
    this.speed = 1.0,
    this.sleepDefault = 'off',
    this.shakeToExtend = true,
    this.autoPlayNext = true,
    this.keepPlayerVisible = false,
  });

  factory ListenSettings.fromRecord(JsonRecord r) => ListenSettings(
        speed: normaliseListenSpeed(r.doubleOf('speed', 1.0)),
        sleepDefault: r.choice('sleepDefault', kSleepDefaults, 'off'),
        shakeToExtend: r.boolOf('shakeToExtend', true),
        autoPlayNext: r.boolOf('autoPlayNext', true),
        keepPlayerVisible: r.boolOf('keepPlayerVisible', false),
      );

  final double speed;
  final String sleepDefault;
  final bool shakeToExtend, autoPlayNext, keepPlayerVisible;

  SleepChoice get sleepChoice => SleepChoice.parse(sleepDefault);

  Map<String, dynamic> toJson() => {
        'speed': speed,
        'sleepDefault': sleepDefault,
        'shakeToExtend': shakeToExtend,
        'autoPlayNext': autoPlayNext,
        'keepPlayerVisible': keepPlayerVisible,
      };

  @override
  bool operator ==(Object other) =>
      other is ListenSettings &&
      other.speed == speed &&
      other.sleepDefault == sleepDefault &&
      other.shakeToExtend == shakeToExtend &&
      other.autoPlayNext == autoPlayNext &&
      other.keepPlayerVisible == keepPlayerVisible;

  @override
  int get hashCode => Object.hash(speed, sleepDefault, shakeToExtend, autoPlayNext, keepPlayerVisible);
}
