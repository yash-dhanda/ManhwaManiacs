import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs_more.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/soundscape/mixer.dart';
import 'package:manhwamaniacs/skins/glass/soundscape/recipes.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The glyph colour of every pattern: `label2` (glass 9.4.2). The patterns stay `label2` while the scene name on the T4 body is `onGlass`.
const Color kGlyphInk = Color(0xA3EBEBF5);

/// One clock for every orb: a single `Ticker` that stops with the sheet (glass 4.10 Scene glyph loops).
class OrbClock extends ChangeNotifier {
  OrbClock(TickerProvider vsync) {
    _ticker = vsync.createTicker((d) {
      time = d.inMicroseconds / 1e6;
      notifyListeners();
    });
  }
  late final Ticker _ticker;
  double time = 1.0;

  void run(bool on) {
    if (on && !_ticker.isActive) _ticker.start();
    if (!on && _ticker.isActive) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

/// A scene's loop drawn on a 64 x 64 canvas clipped to the orb. Speeds are per 60 Hz frame, scaled by the real time [t] in seconds.
class SceneGlyphPainter extends CustomPainter {
  SceneGlyphPainter(this.scene, this.clock, {this.still = false}) : super(repaint: clock);
  final SoundScene scene;
  final OrbClock clock;

  /// Reduce Motion: one still frame.
  final bool still;

  double get _t => still ? 1.0 : clock.time;

  /// Frames elapsed at 60 Hz.
  double get _f => _t * 60;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipPath(Path()..addOval(Offset.zero & size));
    canvas.scale(size.width / 64);
    final p = Paint()..color = kGlyphInk;
    final r = math.Random(scene.index + 1);
    switch (scene) {
      case SoundScene.rain:
        // 12 streaks, 1 x 8 px, falling 0.6 px/frame at 10 degrees from vertical.
        for (var i = 0; i < 12; i++) {
          final x0 = r.nextDouble() * 64, y0 = r.nextDouble() * 80;
          final fall = (y0 + _f * 0.6) % 80 - 8;
          final x = (x0 + math.tan(10 * math.pi / 180) * fall) % 64;
          canvas.save();
          canvas.translate(x, fall);
          canvas.rotate(10 * math.pi / 180);
          canvas.drawRect(const Rect.fromLTWH(0, 0, 1, 8), p);
          canvas.restore();
        }
      case SoundScene.wind:
        // 6 leaves, 3 x 2 px, drifting left to right 0.4 px/frame on a +-4 px sine.
        for (var i = 0; i < 6; i++) {
          final x0 = r.nextDouble() * 70, y0 = 8 + r.nextDouble() * 48;
          final x = (x0 + _f * 0.4) % 70 - 3;
          canvas.drawRect(Rect.fromLTWH(x, y0 + 4 * math.sin(x / 8 + i), 3, 2), p);
        }
      case SoundScene.ocean:
        // 3 wave lines, 2 px thick, scrolling 0.3 px/frame.
        final stroke = Paint()..color = kGlyphInk..style = PaintingStyle.stroke..strokeWidth = 2;
        for (var i = 0; i < 3; i++) {
          final path = Path();
          for (var x = 0.0; x <= 64; x += 2) {
            final y = 20 + i * 14 + 3 * math.sin((x + _f * 0.3) / 6 + i);
            x == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
          }
          canvas.drawPath(path, stroke);
        }
      case SoundScene.hearth:
        // 8 embers of 2 px rising 0.5 px/frame with a 30 % flicker.
        for (var i = 0; i < 8; i++) {
          final x = 8 + r.nextDouble() * 48, y0 = r.nextDouble() * 64;
          final y = 64 - ((y0 + _f * 0.5) % 64);
          final flicker = 1 - 0.3 * (0.5 + 0.5 * math.sin(_t * 7 + i * 1.7));
          canvas.drawRect(Rect.fromLTWH(x, y, 2, 2), Paint()..color = kGlyphInk.withValues(alpha: kGlyphInk.a * flicker));
        }
      case SoundScene.stream:
        // 4 ripple rings of 1 px expanding from 2 to 20 px radius in 2 s.
        final ring = Paint()..style = PaintingStyle.stroke..strokeWidth = 1;
        for (var i = 0; i < 4; i++) {
          final phase = ((_t / 2) + i / 4) % 1;
          ring.color = kGlyphInk.withValues(alpha: kGlyphInk.a * (1 - phase));
          canvas.drawCircle(const Offset(32, 32), 2 + 18 * phase, ring);
        }
      case SoundScene.deep:
        // 14 stars of 2 px drifting 0.3 px/frame with a 5 s twinkle.
        for (var i = 0; i < 14; i++) {
          final x = (r.nextDouble() * 64 + _f * 0.3) % 64, y = r.nextDouble() * 64;
          final tw = 0.5 + 0.5 * math.sin(2 * math.pi * _t / 5 + i);
          canvas.drawRect(Rect.fromLTWH(x, y, 2, 2), Paint()..color = kGlyphInk.withValues(alpha: kGlyphInk.a * (0.4 + 0.6 * tw)));
        }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(SceneGlyphPainter old) => old.scene != scene || old.still != still;
}

/// The 8 level bars, 3 px wide and 2 px apart, centred in the orb (glass 9.4.2 Level bars): bars 1-3 the Bed, 4-6 the Detail, 7-8 the
/// Tone. Static at the mix values under Reduce Motion; otherwise they follow the controller's [levels] at 30 fps.
class LevelBars extends StatelessWidget {
  const LevelBars({super.key, required this.levels, required this.mix, required this.reduced});
  final ValueListenable<List<double>> levels;
  final MixLevels mix;
  final bool reduced;

  @override
  Widget build(BuildContext context) {
    final still = [for (var i = 0; i < 8; i++) mix.of(LevelMeter.layerOfBar[i])];
    Widget paint(List<double> v) => CustomPaint(size: const Size(38, 32), painter: _BarsPainter(v));
    if (reduced) return paint(still);
    return ValueListenableBuilder<List<double>>(valueListenable: levels, builder: (_, v, __) => paint(v));
  }
}

class _BarsPainter extends CustomPainter {
  const _BarsPainter(this.values);
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = gt.colorOnGlass;
    for (var i = 0; i < 8; i++) {
      final h = math.max(2.0, values[i].clamp(0.0, 1.0) * size.height);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(i * 5.0, (size.height - h) / 2, 3, h), const Radius.circular(1.5)), p);
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => !listEquals(old.values, values);
}

/// A 64 px scene orb: a `fill2` twin (no backdrop read) with the scene's pattern, optional level bars and the `cloud-slash` badge.
class SceneOrb extends StatelessWidget {
  const SceneOrb({
    super.key,
    required this.scene,
    required this.clock,
    required this.selected,
    required this.matched,
    required this.builtin,
    required this.reduced,
    required this.onSelect,
    this.bars,
  });

  final SoundScene scene;
  final OrbClock clock;
  final bool selected, matched, builtin, reduced;
  final VoidCallback onSelect;

  /// The 8 bar values (null when this orb is not playing).
  final Widget? bars;

  @override
  Widget build(BuildContext context) {
    final hit = GlassFrame.hitMin(context);
    final label = matched ? '${scene.label}, matched to this series' : scene.label;
    return Semantics(
      container: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: label,
      hint: selected && builtin ? 'Playing the built-in version' : null,
      onTap: onSelect,
      excludeSemantics: true,
      child: SizedBox(
        width: math.max(88.0, hit),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: GlassPressable(
                material: GlassMaterial.content,
                shape: const GlassShape.circle(),
                sink: 0.94,
                minHit: false,
                noSemantics: true,
                onTap: onSelect,
                haptic: HapticEvent.select,
                selected: selected,
                builder: (context, info) => Stack(
                  alignment: Alignment.center,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: gt.colorFill2,
                        border: Border.all(color: selected ? gt.colorIris400 : const Color(0x38FFFFFF), width: selected ? 2 : 0.5),
                      ),
                      child: ExcludeSemantics(child: SizedBox.expand(child: CustomPaint(painter: SceneGlyphPainter(scene, clock, still: reduced)))),
                    ),
                    if (bars != null) ExcludeSemantics(child: bars),
                    if (selected && builtin)
                      Positioned(
                        right: 2,
                        top: 2,
                        child: ExcludeSemantics(child: Icon(GlassGlyph28.cloudSlash.regular, size: 14, color: gt.colorOnGlass)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            GlassText(scene.label, role: gt.typeFootnote, onGlass: true),
            if (matched) GlassText('Matched: ${scene.label}', role: gt.typeCaption1, onGlass: true),
          ],
        ),
      ),
    );
  }
}
