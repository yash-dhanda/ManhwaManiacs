import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/shell/handoff_layer.dart';

/// glass 4.10 Skin melt: 615 ms, the blur on `smooth`, the mask on `page`, whose settle ends it.
void main() {
  test('the melt runs 615 ms; the mask is still open mid-way and closed at the end', () {
    expect(glassMeltAt(0), (blur: 0.0, mask: 0.0));
    expect(glassMeltAt(1).mask, 1.0);
    final mid = glassMeltAt(150 / 615);
    expect(mid.mask, inExclusiveRange(0.2, 0.9));
    expect(mid.blur, greaterThan(0));
    var last = 0.0;
    for (var i = 0; i <= 100; i++) {
      final m = glassMeltAt(i / 100).mask;
      expect(m, greaterThanOrEqualTo(last - 1e-9));
      last = m;
    }
    expect((glassMotionTable[MotionName.skinMelt]!.ms, glassMotionTable[MotionName.skinMelt]!.curve), (615, null), reason: 'a linear 615 ms clock');
  });
}
