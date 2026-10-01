import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/novels/utils/speaker_slots.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/glass_paragraph.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

/// glass 2.1.5 (owner revision: no text underlines): the band behind a run is its hue at 14 %; the non-colour cue is a 2 px tick at
/// 60 % down the run's leading edge, 2 px before its first glyph, dashed 3 on / 2 off from the 11th speaker.
const double kSpeakerBandAlpha = 0.14;
const double kSpeakerLineAlpha = 0.60;
const double kSpeakerLineWidth = 2;
const double kSpeakerDashOn = 3, kSpeakerDashOff = 2;

/// Slot 1-10 to `GlassTokens.spk{n}`.
Color speakerHue(int slot, [GlassTokens t = glassTokens]) {
  final hues = [t.colorSpk1, t.colorSpk2, t.colorSpk3, t.colorSpk4, t.colorSpk5, t.colorSpk6, t.colorSpk7, t.colorSpk8, t.colorSpk9, t.colorSpk10];
  return hues[(slot - 1) % 10];
}

/// The bands and leading ticks of one paragraph's attributed runs (D9). The text keeps the paper ink.
class SpeakerBandsDecoration extends GlassParagraphDecoration {
  const SpeakerBandsDecoration(this.runs, {this.hideBackground});
  final List<SpeakerRun> runs;

  /// A run whose band the listen highlight covers drops its background (its tick stays), glass 8.16.7.
  final bool Function(SpeakerRun run)? hideBackground;

  @override
  void paintBehind(Canvas canvas, GlassParagraphGeometry g) {
    for (final r in runs) {
      if (hideBackground?.call(r) ?? false) continue;
      final paint = Paint()..color = speakerHue(r.slot).withValues(alpha: kSpeakerBandAlpha);
      for (final b in g.boxes(r.start, r.end)) {
        canvas.drawRect(b, paint);
      }
    }
  }

  @override
  void paintFront(Canvas canvas, GlassParagraphGeometry g) {
    for (final r in runs) {
      final boxes = g.boxes(r.start, r.end);
      if (boxes.isEmpty) continue;
      final paint = Paint()
        ..color = speakerHue(r.slot).withValues(alpha: kSpeakerLineAlpha)
        ..strokeWidth = kSpeakerLineWidth;
      final b = boxes.first;
      final x = b.left - 2 - kSpeakerLineWidth / 2;
      if (!r.dotted) {
        canvas.drawLine(Offset(x, b.top), Offset(x, b.bottom), paint);
        continue;
      }
      for (var y = b.top; y < b.bottom; y += kSpeakerDashOn + kSpeakerDashOff) {
        canvas.drawLine(Offset(x, y), Offset(x, ui.clampDouble(y + kSpeakerDashOn, b.top, b.bottom)), paint);
      }
    }
  }

  @override
  bool operator ==(Object other) => other is SpeakerBandsDecoration && identical(other.runs, runs);

  @override
  int get hashCode => identityHashCode(runs);
}
