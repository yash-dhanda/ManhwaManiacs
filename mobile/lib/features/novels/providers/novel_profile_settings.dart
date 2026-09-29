import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/storage/json_record.dart';

// TODO(mobile/14): the Type sheet owns this record (`mm.novel-settings.u{user}p{profile}`); this
// file holds the fields Settings (mobile/18) edits, under the names mobile/14 and 23 use.

const kNovelSettingsPrefix = 'mm.novel-settings.';
const kNovelFaces = ['newsreader', 'literata', 'sourceserif', 'archivo', 'atkinson'];
const kNovelStocks = ['issue', 'nitrate', 'ink', 'sepiaNight', 'dusk', 'moss', 'rosewood'];

/// Per-book type controls the profile falls back to (`bookDefaults`).
class BookDefaults {
  const BookDefaults({required this.face, required this.fontSize, required this.lineHeight, required this.measure});

  final String face;
  final int fontSize;
  final double lineHeight;
  final int measure;

  Map<String, dynamic> toJson() => {'face': face, 'fontSize': fontSize, 'lineHeight': lineHeight, 'measure': measure};

  BookDefaults copyWith({String? face, int? fontSize, double? lineHeight, int? measure}) => BookDefaults(
        face: face ?? this.face,
        fontSize: fontSize ?? this.fontSize,
        lineHeight: lineHeight ?? this.lineHeight,
        measure: measure ?? this.measure,
      );
}

/// The built-in book defaults: Newsreader (Atkinson with Hyperlegible text on), 18 px (17 for
/// Archivo), 1.60 (1.70 for Atkinson), 64 ch.
BookDefaults builtInBookDefaults({required bool legible, String? face}) {
  final f = face ?? (legible ? 'atkinson' : 'newsreader');
  return BookDefaults(face: f, fontSize: f == 'archivo' ? 17 : 18, lineHeight: f == 'atkinson' ? 1.70 : 1.60, measure: 64);
}

/// The profile's book defaults: what it stored, else the built-ins.
BookDefaults readBookDefaults(JsonRecord settings, {required bool legible}) {
  final r = settings.child('bookDefaults');
  final base = builtInBookDefaults(legible: legible, face: r.choice('face', kNovelFaces, legible ? 'atkinson' : 'newsreader'));
  return BookDefaults(
    face: base.face,
    fontSize: r.intOf('fontSize', base.fontSize).clamp(14, 40),
    lineHeight: r.doubleOf('lineHeight', base.lineHeight).clamp(1.30, 2.10),
    measure: r.intOf('measure', base.measure).clamp(48, 88),
  );
}

/// One book's type as the novel reader opens it: its own stored value where it has one, else the
/// profile default. A book with no stored size opens at [systemScaledSize] (the system text scale
/// applied to the default) clamped to 14-40.
BookDefaults resolveBookPrefs(JsonRecord? own, BookDefaults defaults, {double systemScale = 1.0, bool hasStoredDefaults = true}) {
  final o = own ?? const JsonRecord();
  final size = o.data['fontSize'] is num
      ? o.intOf('fontSize', defaults.fontSize)
      : (hasStoredDefaults ? defaults.fontSize : systemScaledSize(defaults.fontSize, systemScale));
  return BookDefaults(
    face: o.choice('face', kNovelFaces, defaults.face),
    fontSize: size.clamp(14, 40),
    lineHeight: (o.data['lineHeight'] is num ? o.doubleOf('lineHeight', defaults.lineHeight) : defaults.lineHeight).clamp(1.30, 2.10),
    measure: (o.data['measure'] is num ? o.intOf('measure', defaults.measure) : defaults.measure).clamp(48, 88),
  );
}

int systemScaledSize(int base, double scale) => (base * scale).round().clamp(14, 40);

extension NovelSettingsView on JsonRecord {
  String get novelStock => choice('stock', kNovelStocks, 'issue');
  String get novelLayout => choice('layout', const ['scroll', 'paged'], 'scroll');
  String get novelPageTurn => choice('pageTurn', const ['cut', 'slide', 'fade'], 'slide');
  bool get novelBold => boolOf('bold', false);
  bool get novelJustify => boolOf('justify', false);
  bool get novelAutoNext => boolOf('autoNextChapter', true);
  String get novelSoundscape => stringOf('soundscape', 'off');
}

class NovelSettingsNotifier extends ProfileRecordNotifier {
  @override
  String get prefix => kNovelSettingsPrefix;

  Future<void> setBookDefaults(BookDefaults d) => put({'bookDefaults': d.toJson()});
}

/// `mm.novel-settings.u{user}p{profile}`.
final novelSettingsProvider = NotifierProvider<NovelSettingsNotifier, JsonRecord>(NovelSettingsNotifier.new, name: 'novelSettings');

// TODO(mobile/15): the Listen step owns `mm.listen-settings.u{user}p{profile}`; Settings adds
// only the fields below (its `speed` is read and written under the same name).
const kListenSettingsPrefix = 'mm.listen-settings.';
const kSleepDefaults = ['off', '5', '10', '15', '30', '45', '60', 'chapter', 'nextChapter'];

extension ListenSettingsView on JsonRecord {
  double get speed => doubleOf('speed', 1.0).clamp(0.5, 3.0);
  String get sleepDefault => choice('sleepDefault', kSleepDefaults, 'off');
  bool get autoPlayNext => boolOf('autoPlayNext', true);
  bool get keepPlayerVisible => boolOf('keepPlayerVisible', false);
  bool get shakeToExtend => boolOf('shakeToExtend', true);
}

class ListenSettingsNotifier extends ProfileRecordNotifier {
  @override
  String get prefix => kListenSettingsPrefix;
}

final listenSettingsProvider = NotifierProvider<ListenSettingsNotifier, JsonRecord>(ListenSettingsNotifier.new, name: 'listenSettings');
