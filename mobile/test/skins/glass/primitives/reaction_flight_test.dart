
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/reactions/glass_reactions.dart';
import 'package:manhwamaniacs/skins/glass/primitives/reactions/reaction_flight.dart';
import 'package:manhwamaniacs/skins/glass/primitives/reactions/reaction_picker.dart';

void main() {
  test('flight time is distance / 1400, clamped to 0.28 to 0.6 s', () {
    expect(flightTime(100), 0.28);
    expect(flightTime(700), closeTo(0.5, 1e-9));
    expect(flightTime(5000), 0.6);
  });

  test('the arc lands exactly on the slot at T under gravity 2,400 px/s^2', () {
    const from = Offset(300, 700), to = Offset(60, 520);
    final v = flightVelocity(from, to);
    expect(v.t, closeTo((to - from).distance / 1400, 1e-9));
    expect(v.vx, closeTo(-240 / v.t, 1e-9));
    expect(v.vy, closeTo((-180 - 0.5 * 2400 * v.t * v.t) / v.t, 1e-9));
    final end = flightAt(from, to, v.t);
    expect(end.dx, closeTo(to.dx, 1e-6));
    expect(end.dy, closeTo(to.dy, 1e-6));
    // it rises above the straight line first (the arc)
    final mid = flightAt(from, to, v.t / 2);
    final line = Offset.lerp(from, to, 0.5)!;
    expect(mid.dy, lessThan(line.dy));
  });

  test('the burst is six 4 px dots radiating 24 px while fading', () {
    final b = burstParticles(const Offset(100, 100), 1);
    expect(b.length, 6);
    for (final p in b) {
      expect((p.at - const Offset(100, 100)).distance, closeTo(24, 1e-9));
      expect(p.opacity, 0);
    }
    expect(burstParticles(const Offset(100, 100), 0).first.opacity, 1);
    expect(kBurst, const Duration(milliseconds: 300));
  });

  test('six named reactions in bloom order; laughed is stored but never offered', () {
    expect([for (final r in kGlassReactions) r.name], ['Hype', 'Love', 'Wrecked', 'Tears', 'Twist', 'Masterpiece']);
    expect([for (final r in kGlassReactions) r.kind.name], ['hype', 'loved', 'wrecked', 'tears', 'shook', 'chefsKiss']);
    expect(kGlassReactions[0].action, 'React with Hype');
    expect(glassReaction(kGlassLaughed.kind).name, 'Laughed');
    expect(isOffered(kGlassLaughed.kind), isFalse);
  });

  test('the bubbles sit on a 120 degree arc above the finger', () {
    const c = Offset(200, 500);
    final centres = bubbleCentres(c);
    expect(centres.length, 6);
    for (final p in centres) {
      expect((p - c).distance, closeTo(96, 1e-9));
      expect(p.dy, lessThan(c.dy));
    }
    expect(centres.first.dx, lessThan(centres.last.dx));
    expect(bubbleAt(centres, centres[3]), 3);
    expect(bubbleAt(centres, c), isNull);
  });
}
