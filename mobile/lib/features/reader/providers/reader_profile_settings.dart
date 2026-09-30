import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/storage/json_record.dart';

// TODO(mobile/12): the reader steps own this record (`mm.reader-settings.u{user}p{profile}`); this
// file holds the fields Settings (mobile/18) edits, under the names mobile/12, 13 and 23 use.

const kReaderSettingsPrefix = 'mm.reader-settings.';
const kReaderPrefsPrefix = 'mm.reader-prefs.';

/// Per-series controls the profile falls back to (`seriesDefaults`), then the built-ins.
class SeriesDefaults {
  const SeriesDefaults({this.layout = 'strip', this.direction = 'ltr', this.fit = 'width', this.zoom = 100, this.autoScrollSpeed = 1.0});

  static const layouts = ['strip', 'single', 'double', 'guided'];
  static const directions = ['ltr', 'rtl'];
  static const fits = ['width', 'height', 'original'];

  final String layout, direction, fit;
  final int zoom;
  final double autoScrollSpeed;

  factory SeriesDefaults.of(JsonRecord r) => SeriesDefaults(
        layout: r.choice('layout', layouts, 'strip'),
        direction: r.choice('direction', directions, 'ltr'),
        fit: r.choice('fit', fits, 'width'),
        zoom: r.intOf('zoom', 100).clamp(50, 300),
        autoScrollSpeed: r.doubleOf('autoScrollSpeed', 1.0).clamp(0.5, 3.0),
      );

  Map<String, dynamic> toJson() => {'layout': layout, 'direction': direction, 'fit': fit, 'zoom': zoom, 'autoScrollSpeed': autoScrollSpeed};

  SeriesDefaults copyWith({String? layout, String? direction, String? fit, int? zoom, double? autoScrollSpeed}) => SeriesDefaults(
        layout: layout ?? this.layout,
        direction: direction ?? this.direction,
        fit: fit ?? this.fit,
        zoom: zoom ?? this.zoom,
        autoScrollSpeed: autoScrollSpeed ?? this.autoScrollSpeed,
      );
}

/// One series' reading controls as the reader opens them: its own stored value where it has
/// one, else the profile default, else the built-in.
SeriesDefaults resolveSeriesReaderPrefs(JsonRecord? own, SeriesDefaults defaults) {
  final o = own ?? const JsonRecord();
  return SeriesDefaults(
    layout: o.choice('layout', SeriesDefaults.layouts, defaults.layout),
    direction: o.choice('direction', SeriesDefaults.directions, defaults.direction),
    fit: o.choice('fit', SeriesDefaults.fits, defaults.fit),
    zoom: o.data['zoom'] is num ? o.intOf('zoom', defaults.zoom).clamp(50, 300) : defaults.zoom,
    autoScrollSpeed:
        o.data['autoScrollSpeed'] is num ? o.doubleOf('autoScrollSpeed', defaults.autoScrollSpeed).clamp(0.5, 3.0) : defaults.autoScrollSpeed,
  );
}

/// The guided-view auto-advance block of the Ambient section.
class GuidedAutoAdvance {
  const GuidedAutoAdvance({this.on = false, this.mode = 'PACE_BY_WORDS', this.fixedMs = 3500});

  final bool on;
  final String mode;
  final int fixedMs;

  factory GuidedAutoAdvance.of(JsonRecord r) => GuidedAutoAdvance(
        on: r.boolOf('on', false),
        mode: r.choice('mode', const ['PACE_BY_WORDS', 'FIXED'], 'PACE_BY_WORDS'),
        fixedMs: r.intOf('fixedMs', 3500).clamp(2000, 10000),
      );

  Map<String, dynamic> toJson() => {'on': on, 'mode': mode, 'fixedMs': fixedMs};
}

/// Typed reads of the per-profile manga record. Every getter carries the prompt's default.
extension ReaderSettingsView on JsonRecord {
  bool get gap => boolOf('gap', false);
  String get pageTurn => choice('pageTurn', const ['cut', 'slide', 'fade'], 'slide');
  int get brightness => intOf('brightness', 0).clamp(-75, 0);
  int get warmth => intOf('warmth', 0).clamp(0, 100);
  String get colour => choice('colour', const ['normal', 'sepia', 'grey'], 'normal');
  String get ground => choice('ground', const ['black', 'ink', 'slate'], 'black');
  int get sideMargin => const [0, 5, 10, 15, 20, 25].contains(intOf('sideMargin', 0)) ? intOf('sideMargin', 0) : 0;
  String tapZone(String side) => choice('tapZone.$side', const ['previous', 'menu', 'next'], switch (side) { 'left' => 'previous', 'right' => 'next', _ => 'menu' });
  String get stripTaps => choice('stripTaps', const ['menu', 'scroll'], 'menu');
  bool get swipeSideways => boolOf('swipeSideways', true);
  bool get cinema => boolOf('cinema', false);
  bool get autoNextChapter => boolOf('autoNextChapter', true);
  bool get resumeAfterRelease => boolOf('resumeAfterRelease', true);
  SeriesDefaults get seriesDefaults => SeriesDefaults.of(child('seriesDefaults'));
  String get soundscape => stringOf('soundscape', 'off');
  bool get pauseSoundscapeForNarration => boolOf('pauseSoundscapeForNarration', false);
  bool get paceByDialogue => boolOf('paceByDialogue', false);
  bool get pageTint => boolOf('pageTint', true);
  GuidedAutoAdvance get guidedAutoAdvance => GuidedAutoAdvance.of(child('guidedAutoAdvance'));
}

class ReaderSettingsNotifier extends ProfileRecordNotifier {
  @override
  String get prefix => kReaderSettingsPrefix;

  Future<void> setSeriesDefaults(SeriesDefaults d) => put({'seriesDefaults': d.toJson()});

  Future<void> setGuided({bool? on, String? mode, int? fixedMs}) {
    final g = state.guidedAutoAdvance;
    return put({
      'guidedAutoAdvance': {'on': on ?? g.on, 'mode': mode ?? g.mode, 'fixedMs': fixedMs ?? g.fixedMs},
    });
  }
}

/// `mm.reader-settings.u{user}p{profile}`.
final readerSettingsProvider = NotifierProvider<ReaderSettingsNotifier, JsonRecord>(ReaderSettingsNotifier.new, name: 'readerSettings');

/// Per-device values (the Reading: manga app rows share these with the reader).
final stripWidthProvider = NotifierProvider<DeviceValueNotifier<int>, int>(
  () => DeviceValueNotifier<int>('mm.reader.device.stripWidth', 680),
  name: 'stripWidth',
);

final soundscapeVolumeProvider = NotifierProvider<DeviceValueNotifier<double>, double>(
  () => DeviceValueNotifier<double>('mm.reader.device.soundscapeVolume', 0.40),
  name: 'soundscapeVolume',
);
