import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid.dart';
import 'package:manhwamaniacs/skins/cinematic/wipe_geometry.dart';

void main() {
  test('4 blades below 600 px, 8 from 600 px', () {
    expect(wipeBladeCount(390), 4);
    expect(wipeBladeCount(599.9), 4);
    expect(wipeBladeCount(600), 8);
    expect(wipeBladeCount(834), 8);
  });

  test('wipeTotalMs is 616 for 4 and 744 for 8', () {
    expect(wipeTotalMs(4), 616);
    expect(wipeTotalMs(8), 744);
    expect((wipeCloseMs(4), kWipeHoldMs, wipeOpenMs(4)), (248, 40, 328));
    expect((wipeCloseMs(8), kWipeHoldMs, wipeOpenMs(8)), (312, 40, 392));
  });

  for (final w in [390.0, 834.0]) {
    test('blades cover the width at $w, edges on column edges', () {
      final b = wipeBlades(w);
      final g = CineGrid.resolve(w);
      expect(b.length, g.columns);
      expect(b.first.left, 0);
      expect(b.last.right, w);
      for (var i = 0; i < b.length - 1; i++) {
        expect(b[i].right, b[i + 1].left, reason: 'no gap at $i');
        expect(b[i + 1].left, closeTo(g.col(i + 1), 1e-9));
      }
    });
  }

  test('horizontal safe areas widen the outer margins', () {
    final plain = wipeBlades(844);
    final notch = wipeBlades(844, viewLeft: 59, viewRight: 59);
    expect(notch.first.left, 0);
    expect(notch.last.right, 844);
    expect(notch[1].left, greaterThan(plain[1].left));
    expect(notch.length, plain.length);
  });

  test('a blade closes from the top, holds, then opens toward the bottom', () {
    const n = 4;
    expect(wipeBladeAt(0, n, 0).scale, 0);
    expect(wipeBladeAt(0, n, 0).fromTop, isTrue);
    expect(wipeBladeAt(0, n, 200).scale, closeTo(1, 1e-9));
    // The last blade starts 3 x 16 ms later.
    expect(wipeBladeAt(3, n, 48).scale, 0);
    expect(wipeBladeAt(3, n, 100).scale, greaterThan(0));
    // Hold: fully closed.
    expect(wipeBladeAt(3, n, wipeCloseMs(n) + 20).scale, closeTo(1, 1e-9));
    final open = wipeBladeAt(0, n, wipeCloseMs(n) + kWipeHoldMs + 100);
    expect(open.fromTop, isFalse);
    expect(open.scale, inExclusiveRange(0, 1));
    expect(wipeBladeAt(3, n, wipeTotalMs(n).toDouble()).scale, closeTo(0, 1e-9));
  });

  test('phase of the clock', () {
    expect(wipePhaseAt(0, 4), WipePhase.close);
    expect(wipePhaseAt(248, 4), WipePhase.hold);
    expect(wipePhaseAt(288, 4), WipePhase.open);
  });
}
