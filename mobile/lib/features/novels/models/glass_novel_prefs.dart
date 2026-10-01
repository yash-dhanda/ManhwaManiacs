import 'package:flutter/foundation.dart' show immutable;
import 'package:manhwamaniacs/core/storage/json_record.dart';

/// The Glass novel reader's preferences (glass 3.4, 8.15.1, 8.15.5), resolved at read time from the
/// records `mobile/14` extended. Glass adds only its own fields (`glassFace`, `paper`, `glassPageTurn`,
/// `lineGuide`) and never rewrites a legacy key's value; the shared fields are clamped on read to Glass's
/// ranges, so a Cinematic value outside them is shown clamped and stored unchanged.

/// The three Glass faces (glass 3.4): Literata, Google Sans Flex `ROND 0`, Atkinson Hyperlegible Next.
enum GlassFace {
  literata('literata', 'Literata'),
  sans('sans', 'Sans'),
  atkinson('atkinson', 'Atkinson');

  const GlassFace(this.wire, this.label);
  final String wire;
  final String label;

  static GlassFace? fromWire(Object? v) {
    for (final f in values) {
      if (f.wire == v) return f;
    }
    return null;
  }
}

/// The seven dark papers (glass 8.15.1).
enum GlassPaper {
  voidPaper('void', 'Void'),
  ink('ink', 'Ink'),
  nightPaper('night-paper', 'Night Paper'),
  dusk('dusk', 'Dusk'),
  moss('moss', 'Moss'),
  rosewood('rosewood', 'Rosewood'),
  glass('glass', 'Glass');

  const GlassPaper(this.wire, this.label);
  final String wire;
  final String label;

  static GlassPaper? fromWire(Object? v) {
    for (final p in values) {
      if (p.wire == v) return p;
    }
    return null;
  }
}

/// The three Glass page turns (glass 8.15.4).
enum GlassPageTurn {
  slide('slide', 'Slide'),
  lift('lift', 'Lift'),
  fade('fade', 'Fade');

  const GlassPageTurn(this.wire, this.label);
  final String wire;
  final String label;

  static GlassPageTurn fromWire(Object? v) => values.firstWhere((t) => t.wire == v, orElse: () => slide);
}

/// The tap presets (glass 8.15.4). Stored in the shared `tapZones` field with the spellings `mobile/14`
/// writes (`standard`, `bothMargins`, `oneHand`).
enum GlassTapZones {
  standard('standard', 'Standard'),
  bothMargins('bothMargins', 'Both margins'),
  oneHand('oneHand', 'One hand');

  const GlassTapZones(this.wire, this.label);
  final String wire;
  final String label;

  static GlassTapZones fromWire(Object? v) => values.firstWhere((t) => t.wire == v, orElse: () => standard);
}

/// glass 3.4 ranges and steps.
abstract final class GlassNovelRange {
  static const double sizeMin = 15, sizeMax = 30;
  static const double lineMin = 1.40, lineMax = 2.10, lineStep = 0.05;
  static const double measureMin = 48, measureMax = 88, measureStep = 2;
  static const double paraMin = 0, paraMax = 1.2, paraStep = 0.1;
  static const double letterMin = -0.02, letterMax = 0.10, letterStep = 0.01;

  /// Glass defaults (glass 3.4): 19 phone and tablet, 20 desktop frame.
  static const double sizePhone = 19, sizeDesktop = 20;
  static const double line = 1.75, measure = 68, para = 0.6, letter = 0;
}

double _snap(double v, double lo, double hi, double step) {
  final c = v.isFinite ? v.clamp(lo, hi).toDouble() : lo;
  final snapped = lo + ((c - lo) / step).round() * step;
  return (snapped.clamp(lo, hi) * 1000).round() / 1000;
}

double clampGlassSize(double v) => v.isFinite ? v.roundToDouble().clamp(GlassNovelRange.sizeMin, GlassNovelRange.sizeMax) : GlassNovelRange.sizePhone;
double clampGlassLine(double v) => _snap(v, GlassNovelRange.lineMin, GlassNovelRange.lineMax, GlassNovelRange.lineStep);
double clampGlassMeasure(double v) => _snap(v, GlassNovelRange.measureMin, GlassNovelRange.measureMax, GlassNovelRange.measureStep);
double clampGlassPara(double v) => _snap(v, GlassNovelRange.paraMin, GlassNovelRange.paraMax, GlassNovelRange.paraStep);
double clampGlassLetter(double v) => _snap(v, GlassNovelRange.letterMin, GlassNovelRange.letterMax, GlassNovelRange.letterStep);

/// K25 `fontFamily` and Cinematic's `face` to a Glass face (A1): `atkinson` stays; `archivo` and `sans`
/// become Sans; the serifs become Literata.
GlassFace? glassFaceOfLegacy({Object? cineFace, Object? fontFamily}) {
  switch (cineFace) {
    case 'atkinson':
      return GlassFace.atkinson;
    case 'archivo':
      return GlassFace.sans;
    case 'newsreader' || 'literata' || 'source-serif' || 'sourceserif':
      return GlassFace.literata;
  }
  return switch (fontFamily) { 'sans' => GlassFace.sans, 'serif' => GlassFace.literata, _ => null };
}

/// K26 `mm.novel-palette` to a Glass paper (glass 8.15.1). The old warm dark `dusk` swatch (`#1E1B18`) is
/// not mapped by the contract; it becomes Night Paper (the web twin does the same). Nothing stored is Void.
GlassPaper glassPaperOfK26(String? k26) => switch (k26) {
      'paper' || 'sepia' || 'cream' || 'dusk' => GlassPaper.nightPaper,
      'solarized-light' || 'solarized-dark' || 'midnight' => GlassPaper.dusk,
      'soft-grey' => GlassPaper.ink,
      'dawn' || 'rose-pine' => GlassPaper.rosewood,
      'forest' => GlassPaper.moss,
      'black' => GlassPaper.voidPaper,
      'app' => GlassPaper.glass,
      _ => GlassPaper.voidPaper,
    };

/// The keys Glass writes.
abstract final class GlassNovelKeys {
  // Per book (K25 entry).
  static const face = 'glassFace';
  static const size = 'fontSize';
  static const line = 'lineHeight';
  static const measure = 'measure';
  static const para = 'paragraphSpacing';
  static const letter = 'letterSpacing';

  /// What `resetBook` removes: the Glass-visible per-book fields (Cinematic's `face` survives).
  static const bookTypography = [face, size, line, measure, para, letter];

  // Per profile (`mm.novel-settings`).
  static const layout = 'layout';
  static const bold = 'bold';
  static const justify = 'justify';
  static const tapZones = 'tapZones';
  static const paper = 'paper';
  static const pageTurn = 'glassPageTurn';
  static const lineGuide = 'lineGuide';

  // Profile defaults (`mm.novel-defaults`).
  static const defSize = 'size';
  static const defLine = 'lineHeight';
  static const defMeasure = 'measure';
  static const defFace = 'glassFace';
}

/// Everything the Glass page is set with.
@immutable
class GlassNovelValues {
  const GlassNovelValues({
    this.face = GlassFace.literata,
    this.fontSize = GlassNovelRange.sizePhone,
    this.lineHeight = GlassNovelRange.line,
    this.measure = GlassNovelRange.measure,
    this.paragraphSpacing = GlassNovelRange.para,
    this.letterSpacing = GlassNovelRange.letter,
    this.paged = false,
    this.bold = false,
    this.justify = false,
    this.tapZones = GlassTapZones.standard,
    this.paper = GlassPaper.voidPaper,
    this.pageTurn = GlassPageTurn.slide,
    this.lineGuide = false,
    this.defaultSize = GlassNovelRange.sizePhone,
  });

  final GlassFace face;
  final double fontSize, lineHeight, measure, paragraphSpacing, letterSpacing;
  final bool paged, bold, justify, lineGuide;
  final GlassTapZones tapZones;
  final GlassPaper paper;
  final GlassPageTurn pageTurn;

  /// The size `0` resets to (the profile default, else the Glass default for the frame).
  final double defaultSize;

  GlassNovelValues copyWith({double? fontSize, double? measure, GlassPaper? paper, bool? paged, GlassPageTurn? pageTurn, GlassFace? face}) => GlassNovelValues(
        face: face ?? this.face,
        fontSize: fontSize ?? this.fontSize,
        lineHeight: lineHeight,
        measure: measure ?? this.measure,
        paragraphSpacing: paragraphSpacing,
        letterSpacing: letterSpacing,
        paged: paged ?? this.paged,
        bold: bold,
        justify: justify,
        tapZones: tapZones,
        paper: paper ?? this.paper,
        pageTurn: pageTurn ?? this.pageTurn,
        lineGuide: lineGuide,
        defaultSize: defaultSize,
      );

  @override
  bool operator ==(Object other) =>
      other is GlassNovelValues &&
      other.face == face &&
      other.fontSize == fontSize &&
      other.lineHeight == lineHeight &&
      other.measure == measure &&
      other.paragraphSpacing == paragraphSpacing &&
      other.letterSpacing == letterSpacing &&
      other.paged == paged &&
      other.bold == bold &&
      other.justify == justify &&
      other.tapZones == tapZones &&
      other.paper == paper &&
      other.pageTurn == pageTurn &&
      other.lineGuide == lineGuide &&
      other.defaultSize == defaultSize;

  @override
  int get hashCode => Object.hash(face, fontSize, lineHeight, measure, paragraphSpacing, letterSpacing, paged, bold, justify, tapZones, paper, pageTurn, lineGuide, defaultSize);
}

double? _num(Map<String, dynamic> m, String k) => m[k] is num ? (m[k] as num).toDouble() : null;

/// Resolves the Glass values (A1). [book] is the book's K25 entry, [settings] `mm.novel-settings`,
/// [defaults] `mm.novel-defaults`, [k26] the stored `mm.novel-palette` value. Order for each per-book
/// field: the book's own value, then the profile default, then the Glass default. A book with no
/// stored size (and a profile with none) opens at `clamp(round(scale(d)), 15, 30)` for the frame's
/// default `d`: [scale] is `MediaQuery.textScalerOf(context).scale`.
GlassNovelValues resolveGlassNovel({
  required Map<String, dynamic> book,
  required JsonRecord settings,
  required JsonRecord defaults,
  required String? k26,
  required bool legible,
  required bool desktopFrame,
  double Function(double size)? scale,
}) {
  final d = defaults.data;
  final glassDefault = desktopFrame ? GlassNovelRange.sizeDesktop : GlassNovelRange.sizePhone;
  final profileSize = _num(d, GlassNovelKeys.defSize);
  final defaultSize = profileSize != null ? clampGlassSize(profileSize) : glassDefault;
  final bookSize = _num(book, GlassNovelKeys.size);
  final double size;
  if (bookSize != null) {
    size = clampGlassSize(bookSize);
  } else if (profileSize != null) {
    size = clampGlassSize(profileSize);
  } else {
    size = clampGlassSize((scale ?? (x) => x)(glassDefault).roundToDouble());
  }
  final face = GlassFace.fromWire(book[GlassNovelKeys.face]) ??
      glassFaceOfLegacy(cineFace: book['face'], fontFamily: book['fontFamily']) ??
      GlassFace.fromWire(d[GlassNovelKeys.defFace]) ??
      (legible ? GlassFace.atkinson : GlassFace.literata);
  final s = settings.data;
  return GlassNovelValues(
    face: face,
    fontSize: size,
    lineHeight: clampGlassLine(_num(book, GlassNovelKeys.line) ?? _num(d, GlassNovelKeys.defLine) ?? GlassNovelRange.line),
    measure: clampGlassMeasure(_num(book, GlassNovelKeys.measure) ?? _num(d, GlassNovelKeys.defMeasure) ?? GlassNovelRange.measure),
    paragraphSpacing: clampGlassPara(_num(book, GlassNovelKeys.para) ?? GlassNovelRange.para),
    letterSpacing: clampGlassLetter(_num(book, GlassNovelKeys.letter) ?? GlassNovelRange.letter),
    paged: s[GlassNovelKeys.layout] == 'paged',
    bold: settings.boolOf(GlassNovelKeys.bold, false),
    justify: settings.boolOf(GlassNovelKeys.justify, false),
    tapZones: GlassTapZones.fromWire(s[GlassNovelKeys.tapZones]),
    paper: GlassPaper.fromWire(s[GlassNovelKeys.paper]) ?? glassPaperOfK26(k26),
    pageTurn: GlassPageTurn.fromWire(s[GlassNovelKeys.pageTurn]),
    lineGuide: settings.boolOf(GlassNovelKeys.lineGuide, false),
    defaultSize: defaultSize,
  );
}
