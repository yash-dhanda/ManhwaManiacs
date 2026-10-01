import 'dart:math' as math;
import 'dart:ui';

// Share card coordinates in canvas px (glass 9.2.4). Logical = canvas / 3; the PNG is the 360 logical px frame at pixel ratio 3.

enum ShareFormat { story, post }

const double kShareScale = 3;

/// The figure slot of a Wrapped card: 312 x 304 frame units.
const Size kFigureUnits = Size(312, 304);

Size shareCanvas(ShareFormat f) => f == ShareFormat.story ? const Size(1080, 1920) : const Size(1080, 1350);

/// The logical frame the share side is laid out in: 360 x 640 (Story) or 360 x 450 (Post).
Size shareLogical(ShareFormat f) => shareCanvas(f) / kShareScale;

class ShareBoxes {
  const ShareBoxes({
    required this.eyebrow,
    required this.headline,
    required this.figure,
    required this.footnote,
    required this.wordmarkBaseline,
    required this.monoBaseline,
    required this.nameBaseline,
    required this.numeral,
    required this.context,
    required this.cover,
    required this.bars,
  });

  final Rect eyebrow;
  final Rect headline;
  final Rect figure;

  /// Empty on Post (the layout has no footnote).
  final Rect footnote;
  final double wordmarkBaseline;
  final double monoBaseline;
  final double nameBaseline;

  /// The stat, streak, milestone and single-stat layout (card 2's): numeral, context line, and the cover (Story only).
  final Rect numeral;
  final Rect context;
  final Rect cover;
  final Rect bars;
}

const double kShareMargin = 72;

ShareBoxes shareBoxes(ShareFormat f) {
  const w = 1080.0;
  Rect row(double top, double bottom) => Rect.fromLTRB(kShareMargin, top, w - kShareMargin, bottom);
  if (f == ShareFormat.story) {
    return ShareBoxes(
      eyebrow: row(216, 264),
      headline: row(288, 600),
      figure: row(648, 1560),
      footnote: row(1584, 1656),
      wordmarkBaseline: 1760,
      monoBaseline: 1816,
      nameBaseline: 1864,
      numeral: row(648, 968),
      context: row(1000, 1066),
      cover: const Rect.fromLTRB(420, 1120, 660, 1480),
      bars: row(1120, 1480),
    );
  }
  return ShareBoxes(
    eyebrow: row(144, 192),
    headline: row(208, 480),
    figure: row(512, 1080),
    footnote: Rect.zero,
    wordmarkBaseline: 1176,
    monoBaseline: 1224,
    nameBaseline: 1268,
    numeral: row(512, 776),
    context: row(800, 866),
    cover: Rect.zero,
    bars: Rect.zero,
  );
}

/// The uniform scale that fits the 312 x 304 figure units into [box] (canvas px), and the top-left it sits at (centred).
({double scale, Offset origin}) figureFit(Rect box) {
  final s = math.min(box.width / kFigureUnits.width, box.height / kFigureUnits.height);
  return (scale: s, origin: Offset(box.left + (box.width - kFigureUnits.width * s) / 2, box.top + (box.height - kFigureUnits.height * s) / 2));
}
