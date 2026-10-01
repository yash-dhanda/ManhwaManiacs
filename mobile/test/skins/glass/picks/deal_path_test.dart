import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/thinking_phases.dart';
import 'package:manhwamaniacs/skins/glass/screens/picks/deal_path.dart';

void main() {
  test('the flight hits both ends and bows 48 px up', () {
    const a = Offset(100, 100), b = Offset(200, 500);
    expect(dealPoint(a, b, 0), a);
    expect(dealPoint(a, b, 1), b);
    final c = dealControl(a, b);
    final mid = (a + b) / 2;
    expect((c - mid).distance, closeTo(48, 1e-6));
    expect(c.dy, lessThan(mid.dy));
    expect(((c - mid).dx * (b - a).dx + (c - mid).dy * (b - a).dy).abs(),
        lessThan(1e-6),);
  });
  test('phase lines on the 0 / 1.5 / 4 / 15 s timers, abandon at 210 s', () {
    expect(phaseLineAt(Duration.zero), 'Reading your library');
    expect(phaseLineAt(const Duration(milliseconds: 1499)),
        'Reading your library',);
    expect(phaseLineAt(const Duration(milliseconds: 1500)), 'Asking for ideas');
    expect(phaseLineAt(const Duration(seconds: 4)),
        'Checking which of your sources have them',);
    expect(
        phaseLineAt(const Duration(seconds: 15)), startsWith('Still working'),);
    expect(abandoned(const Duration(seconds: 60)), isFalse);
    expect(abandoned(const Duration(seconds: 209)), isFalse);
    expect(abandoned(const Duration(seconds: 210)), isTrue);
  });
}
