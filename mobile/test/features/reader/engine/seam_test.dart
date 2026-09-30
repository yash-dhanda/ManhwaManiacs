import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/seam.dart';

void main() {
  test('progress', () {
    expect(seamProgress(844, 96, 844), isNull);
    expect(seamProgress(-96, 96, 844), isNull);
    expect(seamProgress(843, 96, 844)!, closeTo(1 / 940, 1e-9));
    expect(seamProgress(-95, 96, 844)!, closeTo(939 / 940, 1e-9));
    expect(seamProgress(374, 96, 844)!, closeTo(0.5, 1e-9));
  });
  test('reading line crossing forward and back, once under wobble', () {
    final w = SeamWatcher();
    const line = 320.0;
    final ev = <SeamEvent>[];
    // centre starts below the line
    ev.addAll(w.update('c', 500, 96, line));
    // seam moves up past the line: centre 548 -> 300
    for (var top = 500.0; top >= 252; top -= 4) { ev.addAll(w.update('c', top, 96, line)); }
    expect(ev.where((e) => e.kind == SeamEventKind.readingLine).length, 1);
    expect(ev.last.direction, SeamDirection.forward);
    // wobble +-2 around the line: no events
    ev.clear();
    for (var i = 0; i < 10; i++) { ev.addAll(w.update('c', 272 + (i.isEven ? 2 : -2), 96, line)); }
    expect(ev, isEmpty);
    // back
    for (var top = 272.0; top <= 400; top += 4) { ev.addAll(w.update('c', top, 96, line)); }
    expect(ev.single.direction, SeamDirection.back);
  });
  test('top event when bottom passes the viewport top going forward', () {
    final w = SeamWatcher();
    final ev = <SeamEvent>[];
    for (var top = 100.0; top >= -110; top -= 5) { ev.addAll(w.update('c', top, 96, 320)); }
    expect(ev.where((e) => e.kind == SeamEventKind.top).length, 1);
  });
}
