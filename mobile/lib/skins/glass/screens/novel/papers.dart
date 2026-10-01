import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:manhwamaniacs/core/color/oklch.dart';
import 'package:manhwamaniacs/features/novels/models/glass_novel_prefs.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

/// One paper's three colours (glass 8.15.1).
class PaperColors {
  const PaperColors(this.bg, this.ink, this.muted);
  final Color bg, ink, muted;

  @override
  bool operator ==(Object other) => other is PaperColors && other.bg == bg && other.ink == ink && other.muted == muted;

  @override
  int get hashCode => Object.hash(bg, ink, muted);
}

/// The generated paper fields of [p] (`design/tokens/glass.json`, `shared/01`).
PaperColors paperColors(GlassPaper p, [GlassTokens t = glassTokens]) => switch (p) {
      GlassPaper.voidPaper => PaperColors(t.colorPaperVoidPage, t.colorPaperVoidInk, t.colorPaperVoidMuted),
      GlassPaper.ink => PaperColors(t.colorPaperInkPage, t.colorPaperInkInk, t.colorPaperInkMuted),
      GlassPaper.nightPaper => PaperColors(t.colorPaperNightPaperPage, t.colorPaperNightPaperInk, t.colorPaperNightPaperMuted),
      GlassPaper.dusk => PaperColors(t.colorPaperDuskPage, t.colorPaperDuskInk, t.colorPaperDuskMuted),
      GlassPaper.moss => PaperColors(t.colorPaperMossPage, t.colorPaperMossInk, t.colorPaperMossMuted),
      GlassPaper.rosewood => PaperColors(t.colorPaperRosewoodPage, t.colorPaperRosewoodInk, t.colorPaperRosewoodMuted),
      GlassPaper.glass => PaperColors(t.colorPaperGlassPage, t.colorPaperGlassInk, t.colorPaperGlassMuted),
    };

/// WCAG contrast of [a] on [b].
double contrastRatio(Color a, Color b) {
  final la = relativeLuminance(a), lb = relativeLuminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Mixes [a] toward [b] by [t] in OKLab (the desktop panels: `oklabMix(paper.bg, #131317, 0.30)` is 70 % paper).
Color oklabMix(Color a, Color b, double t) => mixOklab(a, b, t);

/// The Glass paper's field strength (glass 8.15.1): the cover field at 10 %.
const double kGlassPaperFieldAlpha = 0.10;

/// The paper's relative luminance, the `Lb` every novel chrome surface passes (glass 2.1.7, C4). The Glass paper is black under a
/// 10 % field of luminance [fieldL]: `l x 0.10 + 0.02`.
double paperLb(GlassPaper p, {double? fieldL}) =>
    p == GlassPaper.glass ? (fieldL ?? 0.2) * kGlassPaperFieldAlpha + 0.02 : relativeLuminance(paperColors(p).bg);

/// The chrome tint (glass 9.4.4): the paper's ink at 12 % inside the glass.
const double kPaperTintAlpha = 0.12;
