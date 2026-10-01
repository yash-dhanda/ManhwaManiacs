/// Typography controls for the novel reader: size, leading, measure and face.
///
/// The ranges and defaults are the web's, value for value
/// (`frontend/src/features/novels/typography.ts`), so a book tuned on one
/// client reads the same on the other. What differs is how they are *spent*,
/// and only where the medium forces it — noted at each constant.
///
/// **System faces only.** The app bundles no webfont, so "serif" and "sans"
/// are families the phone already has. The stacks below lead with the best
/// long-form faces each platform ships and fall back through the usual
/// suspects, so the choice is a real change of face on both platforms rather
/// than "Georgia or nothing".
library;

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/painting.dart';

enum NovelFontFamily {
  serif,
  sans;

  static NovelFontFamily fromWire(String? value) =>
      value == 'sans' ? NovelFontFamily.sans : NovelFontFamily.serif;

  String get wire => name;
}

/// Long-form serif stack.
///
/// Iowan Old Style (iOS, Apple Books' own face) and Charter are the two best
/// reading faces that ship on a device; Georgia is the near-universal floor.
/// Noto Serif is Android's own, and is listed before the generic because an
/// Android that resolves neither of the first three should still land on a
/// real book face rather than whatever `serif` maps to.
const List<String> kNovelSerifStack = <String>[
  'Iowan Old Style',
  'Charter',
  'Bitstream Charter',
  'Georgia',
  'Palatino',
  'Noto Serif',
  'Tinos',
  'Times New Roman',
  'serif',
];

/// The platform UI face, which is what a sans reader actually wants here:
/// `null` family with these fallbacks resolves to SF on iOS and Roboto on
/// Android without naming either.
const List<String> kNovelSansStack = <String>[
  'SF Pro Text',
  'Roboto',
  'Helvetica Neue',
  'Noto Sans',
  'sans-serif',
];

List<String> novelFontStack(NovelFontFamily family) =>
    family == NovelFontFamily.sans ? kNovelSansStack : kNovelSerifStack;

/// Body size in logical pixels.
const double kMinNovelFontSize = 15;
const double kMaxNovelFontSize = 26;
const double kNovelFontSizeStep = 1;
const double kDefaultNovelFontSize = 19;

/// Unitless line-height multiplier. Generous by default — this is prose.
const double kMinNovelLineHeight = 1.4;
const double kMaxNovelLineHeight = 2.1;
const double kNovelLineHeightStep = 0.05;
const double kDefaultNovelLineHeight = 1.75;

/// Column width in characters.
const double kMinNovelMeasure = 48;
const double kMaxNovelMeasure = 88;
const double kNovelMeasureStep = 2;

/// The comfortable default: ~68 characters a line.
const double kDefaultNovelMeasure = 68;

/// Average character advance as a fraction of the font size, for turning a
/// measure in characters into a column width in logical pixels.
///
/// The web sets the column in `ch`, a unit the browser resolves against the
/// chosen face's own zero-width. Flutter has no such unit, so this is the
/// stand-in: 0.5em is the conventional figure for a mixed-case Latin serif at
/// text sizes, and the two faces on offer here sit either side of it.
///
/// A phone in portrait is narrower than even the minimum measure, so on that
/// screen this control does nothing at all and the column is simply the page.
/// It earns its place on a tablet and in landscape, where an un-capped column
/// runs to 120 characters and becomes genuinely hard to track back from.
const double kNovelMeasureEmFactor = 0.5;

/// The paragraph's first-line indent, in ems.
///
/// This is most of what makes prose read as a novel rather than a chat log:
/// paragraphs are INDENTED, not separated by blank lines. The first paragraph
/// of a chapter (and the one after a scene break) is set flush, as books set
/// them — an indent there marks a break from something that isn't there.
const double kNovelParagraphIndentEm = 1.4;

double _clampTo(double value, double min, double max, double fallback) {
  if (value.isNaN || value.isInfinite) return fallback;
  return value.clamp(min, max).toDouble();
}

double clampNovelFontSize(double value) => _clampTo(
      value,
      kMinNovelFontSize,
      kMaxNovelFontSize,
      kDefaultNovelFontSize,
    ).roundToDouble();

double clampNovelLineHeight(double value) {
  final clamped = _clampTo(
    value,
    kMinNovelLineHeight,
    kMaxNovelLineHeight,
    kDefaultNovelLineHeight,
  );
  // Two decimals: the step is 0.05 and repeated float arithmetic on it drifts.
  return (clamped * 100).round() / 100;
}

double clampNovelMeasure(double value) => _clampTo(
      value,
      kMinNovelMeasure,
      kMaxNovelMeasure,
      kDefaultNovelMeasure,
    ).roundToDouble();

/// Step a value and re-clamp — the +/- buttons in the type panel.
double stepNovelFontSize(double current, int steps) =>
    clampNovelFontSize(current + steps * kNovelFontSizeStep);

double stepNovelLineHeight(double current, int steps) =>
    clampNovelLineHeight(current + steps * kNovelLineHeightStep);

double stepNovelMeasure(double current, int steps) =>
    clampNovelMeasure(current + steps * kNovelMeasureStep);

/// The column width for [measure] characters at [fontSize], never wider than
/// the [available] width. Returning the available width (rather than
/// overflowing it) is what makes the control a cap rather than a demand.
double novelColumnWidth({
  required double measure,
  required double fontSize,
  required double available,
}) {
  final wanted = measure * fontSize * kNovelMeasureEmFactor;
  return wanted < available ? wanted : available;
}


// ── Cinematic reader (mobile/14) ─────────────────────────────────────────────

/// The five bundled reading faces of the Cinematic novel reader (cinematic 3.4).
enum NovelFace {
  newsreader('newsreader', 'Newsreader', 'Newsreader'),
  literata('literata', 'Literata', 'Literata'),
  sourceSerif('sourceserif', 'Source Serif', 'SourceSerif4'),
  atkinson('atkinson', 'Atkinson Hyperlegible', 'AtkinsonHyperlegibleNext'),
  archivo('archivo', 'Archivo', 'Archivo');

  const NovelFace(this.wire, this.label, this.family);

  /// The stored spelling; the same ids `kNovelFaces` (Settings) uses.
  final String wire;
  final String label;

  /// The Flutter asset family in `pubspec.yaml`.
  final String family;

  static NovelFace? fromWire(String? v) {
    for (final f in values) {
      if (f.wire == v) return f;
    }
    return null;
  }

  bool get serif => this != atkinson && this != archivo;

  /// The optical-size axis range, or null when the face has none.
  (double, double)? get opszRange => switch (this) {
        newsreader => (6, 72),
        literata => (7, 72),
        sourceSerif => (8, 60),
        _ => null,
      };

  double get wghtMax => (this == literata || this == sourceSerif || this == archivo) ? 900 : 800;
}

/// Size and leading a face opens at when a book stores none (cinematic 3.4).
({double size, double leading}) faceDefaults(NovelFace face, {required bool tablet}) => (
      size: face == NovelFace.archivo ? (tablet ? 18 : 17) : (tablet ? 19 : 18),
      leading: face == NovelFace.atkinson ? 1.70 : 1.60,
    );

/// A skin's drop cap, as data (glass 3.4, cinematic 8.15.2): the cap's face ([style] without a size), its
/// size in ems of the body size, the lines it spans, the gap after it in ems of the cap size and the
/// shortest paragraph that gets one. A [NovelType] without one sets Cinematic's cap.
@immutable
class NovelDropCapSpec {
  const NovelDropCapSpec({required this.style, required this.sizeEm, this.lines = 3, this.gapEm = 0.08, this.minLength = 80});
  final TextStyle style;
  final double sizeEm;
  final int lines;
  final double gapEm;
  final int minLength;

  /// The cap's style at [bodySize] in [color].
  TextStyle at(double bodySize, Color color) => style.copyWith(fontSize: sizeEm * bodySize, height: 1, color: color);

  @override
  bool operator ==(Object other) =>
      other is NovelDropCapSpec && other.style == style && other.sizeEm == sizeEm && other.lines == lines && other.gapEm == gapEm && other.minLength == minLength;

  @override
  int get hashCode => Object.hash(style, sizeEm, lines, gapEm, minLength);
}

/// Everything that decides how the Cinematic reader sets its body text, already resolved (book
/// prefs over profile settings over face defaults). The page, the paginator and the Type sheet
/// preview all read this one value. A skin that sets its own faces passes [faceStyle] (family and
/// `FontVariation`s, already resolved for [fontSize]) and [dropCapSpec]; both null is Cinematic.
@immutable
class NovelType {
  const NovelType({
    this.face = NovelFace.newsreader,
    this.fontSize = 18,
    this.lineHeight = 1.60,
    this.measure = 64,
    this.letterSpacing = 0,
    this.paragraphSpacing = 0,
    this.bold = false,
    this.osBold = false,
    this.justify = false,
    this.faceStyle,
    this.dropCapSpec,
  });

  final NovelFace face;

  /// The skin's body face (family, variations, features); when set it replaces [face]'s style.
  final TextStyle? faceStyle;

  /// The skin's drop cap; null sets Cinematic's.
  final NovelDropCapSpec? dropCapSpec;

  /// Absolute logical pixels, 14-40. The body renders with `TextScaler.noScaling`.
  final double fontSize;
  final double lineHeight;

  /// Column width in `ch` (the advance of `0` in the body style), 48-88.
  final double measure;

  /// In em, -0.02 to +0.08.
  final double letterSpacing;

  /// Extra space between paragraphs in em, 0-1.2; when > 0 the first-line indent is dropped.
  final double paragraphSpacing;
  final bool bold;

  /// OS Bold Text (`MediaQuery.boldTextOf`).
  final bool osBold;
  final bool justify;

  double get wght => ((bold ? 520 : 400) + (osBold ? 120 : 0)).clamp(100, face.wghtMax).toDouble();

  /// The body [TextStyle] in [color]; the caller passes the stock ink.
  TextStyle style(Color color, {double? size}) {
    final s = size ?? fontSize;
    final own = faceStyle;
    if (own != null) return own.copyWith(fontSize: s, height: lineHeight, color: color, letterSpacing: letterSpacing * s);
    final opsz = face.opszRange;
    return TextStyle(
      fontFamily: face.family,
      fontSize: s,
      height: lineHeight,
      color: color,
      letterSpacing: letterSpacing * s,
      fontVariations: [
        if (opsz != null) FontVariation('opsz', s.clamp(opsz.$1, opsz.$2).toDouble()),
        if (face == NovelFace.archivo) const FontVariation('wdth', 100),
        FontVariation('wght', wght),
      ],
      fontFeatures: face.serif ? const [FontFeature.oldstyleFigures()] : null,
    );
  }

  NovelType copyWith({
    NovelFace? face,
    double? fontSize,
    double? lineHeight,
    double? measure,
    double? letterSpacing,
    double? paragraphSpacing,
    bool? bold,
    bool? osBold,
    bool? justify,
    TextStyle? faceStyle,
    NovelDropCapSpec? dropCapSpec,
  }) =>
      NovelType(
        face: face ?? this.face,
        fontSize: fontSize ?? this.fontSize,
        lineHeight: lineHeight ?? this.lineHeight,
        measure: measure ?? this.measure,
        letterSpacing: letterSpacing ?? this.letterSpacing,
        paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
        bold: bold ?? this.bold,
        osBold: osBold ?? this.osBold,
        justify: justify ?? this.justify,
        faceStyle: faceStyle ?? this.faceStyle,
        dropCapSpec: dropCapSpec ?? this.dropCapSpec,
      );

  @override
  bool operator ==(Object other) =>
      other is NovelType &&
      other.face == face &&
      other.fontSize == fontSize &&
      other.lineHeight == lineHeight &&
      other.measure == measure &&
      other.letterSpacing == letterSpacing &&
      other.paragraphSpacing == paragraphSpacing &&
      other.bold == bold &&
      other.osBold == osBold &&
      other.justify == justify &&
      other.faceStyle == faceStyle &&
      other.dropCapSpec == dropCapSpec;

  @override
  int get hashCode => Object.hash(face, fontSize, lineHeight, measure, letterSpacing, paragraphSpacing, bold, osBold, justify, faceStyle, dropCapSpec);
}

// ── Cinematic ranges (cinematic 8.15.5) ──────────────────────────────────────

const double kCineMinFontSize = 14;
const double kCineMaxFontSize = 40;
const double kCineMinLeading = 1.30;
const double kCineMaxLeading = 2.10;
const double kCineMinMeasure = 48;
const double kCineMaxMeasure = 88;
const double kCineDefaultMeasure = 64;
const double kCineMaxParagraphSpacing = 1.2;
const double kCineMinLetterSpacing = -0.02;
const double kCineMaxLetterSpacing = 0.08;

double _snap(double v, double lo, double hi, double step, double fallback) {
  if (v.isNaN || v.isInfinite) return fallback;
  final c = v.clamp(lo, hi);
  return ((c / step).round() * step * 1000).round() / 1000;
}

double clampCineFontSize(double v) => v.isNaN ? 18 : v.clamp(kCineMinFontSize, kCineMaxFontSize).roundToDouble();
double clampCineLeading(double v) => _snap(v, kCineMinLeading, kCineMaxLeading, 0.05, 1.60);
double clampCineMeasure(double v) => v.isNaN ? kCineDefaultMeasure : (v.clamp(kCineMinMeasure, kCineMaxMeasure) / 2).round() * 2.0;
double clampParagraphSpacing(double v) => _snap(v, 0, kCineMaxParagraphSpacing, 0.1, 0);
double clampLetterSpacing(double v) => _snap(v, kCineMinLetterSpacing, kCineMaxLetterSpacing, 0.01, 0);
