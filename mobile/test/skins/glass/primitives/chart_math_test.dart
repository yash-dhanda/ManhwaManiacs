import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/chart_math.dart';

void main() {
  test('bar width is min(16, available / n - 3)', () {
    expect(barWidth(300, 7), 16);
    expect(barWidth(300, 30), 7);
    expect(barWidth(300, 100), 1, reason: 'never below 1');
    expect(barWidth(0, 0), 0);
  });

  test('heat level: 0 at zero, ceil(4 v / max) up to 4', () {
    expect(heatLevel(0, 10), 0);
    expect(heatLevel(-1, 10), 0);
    expect(heatLevel(0.1, 10), 1);
    expect(heatLevel(2.5, 10), 1);
    expect(heatLevel(2.6, 10), 2);
    expect(heatLevel(5, 10), 2);
    expect(heatLevel(7.5, 10), 3);
    expect(heatLevel(10, 10), 4);
    expect(heatLevel(99, 10), 4);
    expect(heatLevel(3, 0), 0);
  });

  test('clock geometry: bars from 40 to 40 + 40 v / max, opacity 0.25 to 1, midnight at the top', () {
    expect(clockBarEnd(0, 10), 40);
    expect(clockBarEnd(5, 10), 60);
    expect(clockBarEnd(10, 10), 80);
    expect(clockOpacity(0, 10), 0.25);
    expect(clockOpacity(10, 10), 1);
    expect(clockAngle(0), closeTo(-math.pi / 2, 1e-9));
    expect(clockAngle(6), closeTo(0, 1e-9));
    expect(clockAngle(12), closeTo(math.pi / 2, 1e-9));
  });

  test('peak hour and band words', () {
    final hours = List<double>.filled(24, 0)
      ..[23] = 9
      ..[8] = 4;
    expect(peakHour(hours), 23);
    expect(peakHour(List<double>.filled(24, 0)), isNull);
    expect(peakLine(23), 'You read most around 23:00');
    expect(bandWord(22), 'Night owl');
    expect(bandWord(23), 'Night owl');
    expect(bandWord(0), 'Night owl');
    expect(bandWord(4), 'Night owl');
    expect(bandWord(5), 'Early reader');
    expect(bandWord(8), 'Early reader');
    expect(bandWord(9), 'Daytime reader');
    expect(bandWord(16), 'Daytime reader');
    expect(bandWord(17), 'Evening reader');
    expect(bandWord(21), 'Evening reader');
  });

  test('radar vertices for 6 and 8 axes, normalised to the maximum, first axis at the top', () {
    for (final n in [6, 8]) {
      final values = [for (var i = 0; i < n; i++) (i + 1).toDouble()];
      final v = radarVertices(values, 100);
      expect(v.length, n);
      expect(v.last.distance, closeTo(100, 1e-9), reason: 'the maximum sits on the outer ring');
      expect(v.first.dx, closeTo(0, 1e-9));
      expect(v.first.dy, closeTo(-100 / n, 1e-9));
    }
    final six = radarVertices([6, 6, 6, 6, 6, 6], 50);
    expect(six[1].dx, closeTo(50 * math.cos(-math.pi / 2 + math.pi / 3), 1e-9));
    expect(six[3].dy, closeTo(50 * math.sin(-math.pi / 2 + math.pi), 1e-9));
  });

  test('heatmap cells: Monday at the top, weeks as columns', () {
    expect(heatCell(0, 0), (col: 0, row: 0));
    expect(heatCell(6, 0), (col: 0, row: 6));
    expect(heatCell(7, 0), (col: 1, row: 0));
    expect(heatCell(0, 3), (col: 0, row: 3));
    expect(heatCell(4, 3), (col: 1, row: 0));
  });

  test('keyboard stepping clamps and Home and End jump', () {
    expect(stepSelection(null, 1, 30), 0);
    expect(stepSelection(null, -1, 30), 29);
    expect(stepSelection(0, -1, 30), 0);
    expect(stepSelection(29, 1, 30), 29);
    expect(stepSelection(10, 7, 30), 17);
    expect(stepSelection(25, 7, 30), 29);
    expect(homeIndex(), 0);
    expect(endIndex(30), 29);
  });

  test('bars rise in a wave from the left: delay min(x / 1.6, 240) ms', () {
    expect(riseDelayMs(0), 0);
    expect(riseDelayMs(160), 100);
    expect(riseDelayMs(1000), 240);
    expect(riseProgress(0, 0), 0);
    expect(riseProgress(0, 431), closeTo(1, 1e-9));
    expect(riseProgress(300, 100), 0, reason: 'still waiting for its turn');
    expect(riseProgress(300, 700), closeTo(1, 1e-9));
  });
}
