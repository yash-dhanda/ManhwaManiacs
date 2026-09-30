import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/page_analysis.dart';
import 'package:manhwamaniacs/features/reader/engine/panels.dart';

void main() {
  test('runAnalysis picks the seed and detects panels in one pass', () {
    final tint = Uint8List(16 * 16 * 4);
    for (var i = 0; i < 256; i++) {
      tint.setRange(i * 4, i * 4 + 4, [200, 40, 40, 255]);
    }
    const w = 120, h = 120;
    final rgba = Uint8List(w * h * 4);
    for (var i = 0; i < w * h; i++) {
      rgba.setRange(i * 4, i * 4 + 4, [255, 255, 255, 255]);
    }
    final r = runAnalysis(AnalysisRequest(tint, rgba, w, h, PanelDirection.ltr));
    expect(r.seed, '#C82828');
    expect(r.panelsFailed, isFalse);
    expect(r.panels, isNotNull);
  });

  test('a 10 s continuous scroll makes at most 17 sampled calls', () {
    final t = SampleThrottle(const Duration(milliseconds: 600));
    var calls = 0;
    for (var ms = 0; ms <= 10000; ms += 8) {
      if (t.tryAcquire(Duration(milliseconds: ms))) calls++;
    }
    expect(calls, lessThanOrEqualTo(17));
    expect(calls, greaterThan(10));
  });
}
