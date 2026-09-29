// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/motion_names.g.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_motion.dart';

void main() {
  test('the motion-timings rows carry the planned figures', () {
    int ms(MotionName m, String where) =>
        featureMotionRows.firstWhere((r) => r.move == m && r.where.contains(where)).plannedMs;
    expect(ms(MotionName.matchCut, 'in'), 480);
    expect(ms(MotionName.matchCut, 'out'), 336);
    expect(ms(MotionName.dissolve, 'ambient'), 800);
    expect(ms(MotionName.columnWipe, 'phone'), 616);
    expect(ms(MotionName.columnWipe, 'tablet'), 744);
  });
}
