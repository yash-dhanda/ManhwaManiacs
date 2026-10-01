import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/parts/recommend/orb_flight.dart';

void main() {
  test('an orb left of centre leaves 40 px further left; right of centre 40 px right', () {
    final l = orbFlightPath(const Offset(100, 400), sheetCentreX: 195, topY: 0);
    expect(l.p1, const Offset(100, 280));
    expect(l.p2, const Offset(60, 0));
    final r = orbFlightPath(const Offset(195, 400), sheetCentreX: 195, topY: 0);
    expect(r.p2, const Offset(235, 0));
  });
  test('the Bezier starts at the orb and ends on the top edge', () {
    final c = orbFlightPath(const Offset(100, 400), sheetCentreX: 195, topY: 10);
    expect(bezierAt(c, 0), const Offset(100, 400));
    expect(bezierAt(c, 1), const Offset(60, 10));
    final mid = bezierAt(c, 0.5);
    expect(mid.dx, closeTo(0.25 * 100 + 0.5 * 100 + 0.25 * 60, 1e-9));
    expect(mid.dy, closeTo(0.25 * 400 + 0.5 * 280 + 0.25 * 10, 1e-9));
  });
  test('orbs leave 40 ms apart', () => expect([for (var i = 0; i < 3; i++) orbFlightDelay(i).inMilliseconds], [0, 40, 80]));
}
