import 'package:manhwamaniacs/core/storage/json_record.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_profile_settings.dart';

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
    this.sideMarginPct = 0,
    this.gap = false,
    this.pageTurn = 'slide',
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
    final hasZones = ['left', 'center', 'right'].any((k) => profile.data.containsKey('tapZone.$k'));
    return ReaderPrefs(
      layout: s.layout,
      direction: s.direction,
      fit: s.fit,
      zoom: (s.zoom / 100).clamp(0.5, 3.0),
      autoScrollSpeedX: s.autoScrollSpeed,
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
