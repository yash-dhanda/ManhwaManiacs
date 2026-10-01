import 'package:manhwamaniacs/core/storage/json_record.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_profile_settings.dart';
import 'package:manhwamaniacs/features/reader/utils/glass_reader_values.dart';

/// The per-series soundscape record `{scene, mix: {bed, detail, tone}}` (glass 15.5); written only while "Remember for this series" is on.
class SeriesSoundscape {
  const SeriesSoundscape({required this.scene, this.bed = 0.8, this.detail = 0.5, this.tone = 0.3});
  final String scene;
  final double bed, detail, tone;

  static const scenes = ['rain', 'wind', 'ocean', 'hearth', 'stream', 'deep'];

  /// Null when absent or the scene is unknown.
  static SeriesSoundscape? of(JsonRecord? r) {
    if (r == null || !scenes.contains(r.data['scene'])) return null;
    final m = r.child('mix');
    double v(String k, double d) => m.doubleOf(k, d).clamp(0.0, 1.0);
    return SeriesSoundscape(scene: r.data['scene'] as String, bed: v('bed', 0.8), detail: v('detail', 0.5), tone: v('tone', 0.3));
  }

  Map<String, dynamic> toJson() => {'scene': scene, 'mix': {'bed': bed, 'detail': detail, 'tone': tone}};
}

/// Which of the two side panels are open and which opened last (tablets).
class ReaderPanels {
  const ReaderPanels({this.left = false, this.right = false, this.lastOpened});

  final bool left, right;

  /// `'left'`, `'right'` or null.
  final String? lastOpened;

  factory ReaderPanels.of(JsonRecord r) => ReaderPanels(
        left: r.boolOf('left', false),
        right: r.boolOf('right', false),
        lastOpened: r.data['lastOpened'] is String ? r.data['lastOpened'] as String : null,
      );

  Map<String, dynamic> toJson() => {'left': left, 'right': right, 'lastOpened': lastOpened};
}

/// The reader's controls for one series as the reader opens them (cinematic 8.14.8): the series'
/// own value where it has one, else the profile default, else the built-in. Skin-neutral: the
/// Cinematic and Glass readers both read this.
class ReaderPrefs {
  const ReaderPrefs({
    this.layout = 'strip',
    this.direction = 'ltr',
    this.fit = 'width',
    this.zoom = 1.0,
    this.autoScrollSpeedX = 1.0,
    this.cruiseSpeed = 1.0,
    this.soundscape,
    this.sideMarginPct = 0,
    this.gap = false,
    this.pageTurn = 'cut',
    this.brightness = 0,
    this.warmthPct = 0,
    this.colour = 'normal',
    this.ground = 'black',
    this.tapZones,
    this.stripTaps = 'menu',
    this.swipeChapter = true,
    this.cinema = false,
    this.autoNextChapter = true,
    this.resumeAfterRelease = true,
    this.panels = const ReaderPanels(),
  });

  /// `strip | single | double | guided` (upper-case in the record's documentation).
  final String layout;
  final String direction, fit;

  /// The series' resting zoom, 0.50-3.00.
  final double zoom;

  /// Auto-scroll speed as a multiplier, 0.50-3.00.
  final double autoScrollSpeedX;

  /// Glass cruise speed, 0.25-4.00 in 0.05 steps: the series' own, else `glass.cruiseDefault`, else 1.0.
  final double cruiseSpeed;

  /// Glass per-series soundscape, null until "Remember for this series" saved one.
  final SeriesSoundscape? soundscape;
  final int sideMarginPct;
  final bool gap;
  final String pageTurn;

  /// -75..0.
  final int brightness;
  final int warmthPct;

  /// `normal | sepia | grey`.
  final String colour;

  /// `black | ink | slate`.
  final String ground;

  /// Three of `previous | menu | next`, or null for automatic.
  final List<String>? tapZones;

  /// `menu | scroll`.
  final String stripTaps;
  final bool swipeChapter, cinema, autoNextChapter, resumeAfterRelease;
  final ReaderPanels panels;

  bool get rtl => direction == 'rtl';

  /// [profile] is the `mm.reader-settings` record, [series] the series' own entry of the
  /// `mm.reader-prefs` map (null when it has none).
  factory ReaderPrefs.resolve(JsonRecord profile, JsonRecord? series) {
    final s = resolveSeriesReaderPrefs(series, profile.seriesDefaults);
    final zones = [profile.tapZone('left'), profile.tapZone('center'), profile.tapZone('right')];
    final hasZones = ['left', 'center', 'right'].any((k) => profile.data['tapZone.$k'] is String);
    return ReaderPrefs(
      layout: s.layout,
      direction: s.direction,
      fit: s.fit,
      zoom: (s.zoom / 100).clamp(0.5, 3.0),
      autoScrollSpeedX: s.autoScrollSpeed,
      cruiseSpeed: series != null && series.data[GlassReaderKeys.cruiseSpeed] is num
          ? snapCruise(series.doubleOf(GlassReaderKeys.cruiseSpeed, 1.0))
          : profile.glassCruiseDefault,
      soundscape: SeriesSoundscape.of(series?.child('soundscape')),
      sideMarginPct: profile.sideMargin,
      gap: profile.gap,
      pageTurn: profile.pageTurn,
      brightness: profile.brightness,
      warmthPct: profile.warmth,
      colour: profile.colour,
      ground: profile.ground,
      tapZones: hasZones ? zones : null,
      stripTaps: profile.stripTaps,
      swipeChapter: profile.swipeSideways,
      cinema: profile.cinema,
      autoNextChapter: profile.autoNextChapter,
      resumeAfterRelease: profile.resumeAfterRelease,
      panels: ReaderPanels.of(profile.child('panels')),
    );
  }
}
