
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/screens/profiles/avatar_arc.dart';

void main() {
  test('the arc lands on the preview centre after 280 ms under 3,000 px/s2', () {
    final arc = AvatarArc.solve(from: const Offset(40, 500), to: const Offset(195, 120));
    expect(arc.gravity, 3000);
    expect(arc.flightMs, 280);
    final end = arc.at(280);
    expect(end.dx, closeTo(195, 1e-6));
    expect(end.dy, closeTo(120, 1e-6));
    expect(arc.at(0), const Offset(40, 500));
  });

  test('the path is a parabola: the middle is above the chord for an upward throw', () {
    final arc = AvatarArc.solve(from: const Offset(0, 300), to: const Offset(200, 100));
    final mid = arc.at(140);
    const chordY = 200.0;
    expect(mid.dy, lessThan(chordY));
  });

  test('a flight past the end stays on the target', () {
    final arc = AvatarArc.solve(from: Offset.zero, to: const Offset(50, 50));
    expect(arc.at(1000), arc.at(280));
  });
}
