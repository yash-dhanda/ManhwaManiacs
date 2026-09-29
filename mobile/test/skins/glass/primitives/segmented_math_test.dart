import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/segmented_math.dart';

void main() {
  test('equal widths unless the labels differ by more than 40 %', () {
    expect(segmentWidths(labelWidths: [50, 60, 55], total: 300), [100, 100, 100]);
    final fit = segmentWidths(labelWidths: [30, 90], total: 300);
    expect(fit[0] + fit[1], closeTo(300, 1e-9));
    expect(fit[1], greaterThan(fit[0]));
  });

  test('release projects to the nearest segment', () {
    const w = [100.0, 100.0, 100.0, 100.0];
    expect(projectedSegment(thumbCentre: 60, velocity: 0, widths: w), 0);
    expect(projectedSegment(thumbCentre: 140, velocity: 0, widths: w), 1);
    expect(projectedSegment(thumbCentre: 140, velocity: 300, widths: w), 2);
    expect(projectedSegment(thumbCentre: 260, velocity: -3000, widths: w), 0);
    expect(projectedSegment(thumbCentre: 260, velocity: 9000, widths: w), 3);
  });

  test('boundary crossings count one tick per boundary', () {
    const w = [100.0, 100.0, 100.0, 100.0];
    expect(boundaryCrossings(50, 60, w), 0);
    expect(boundaryCrossings(50, 150, w), 1);
    expect(boundaryCrossings(350, 50, w), 3);
  });
}
