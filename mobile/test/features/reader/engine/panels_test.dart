import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/panels.dart';

/// Test-only greyscale 8-bit PNG decoder (filter byte 0 on every row).
(int, int, Uint8List) _decode(Uint8List b) {
  const sig = [137, 80, 78, 71, 13, 10, 26, 10];
  for (var i = 0; i < 8; i++) {
    expect(b[i], sig[i]);
  }
  final bd = ByteData.sublistView(b);
  final w = bd.getUint32(16), h = bd.getUint32(20);
  final idat = BytesBuilder();
  var o = 8;
  while (o < b.length) {
    final n = bd.getUint32(o);
    if (String.fromCharCodes(b.sublist(o + 4, o + 8)) == 'IDAT') idat.add(b.sublist(o + 8, o + 8 + n));
    o += 12 + n;
  }
  final raw = ZLibCodec().decode(idat.toBytes());
  final g = Uint8List(w * h);
  for (var y = 0; y < h; y++) {
    expect(raw[y * (w + 1)], 0);
    g.setRange(y * w, (y + 1) * w, raw.sublist(y * (w + 1) + 1, (y + 1) * (w + 1)));
  }
  return (w, h, g);
}

void main() {
  final spec = jsonDecode(File('../design/panel-vectors.json').readAsStringSync()) as Map<String, dynamic>;
  for (final c in spec['cases'] as List) {
    test('panel vector ${c['id']}', () {
      final (w, h, g) = _decode(File('../design/${c['file']}').readAsBytesSync());
      final dir = c['direction'] == 'rtl' ? PanelDirection.rtl : PanelDirection.ltr;
      final got = detectPanels(g, w, h, dir).map((r) => [r.left, r.top, r.width, r.height]).toList();
      final want = [
        for (final e in c['expected'] as List) [e['x'].toDouble(), e['y'].toDouble(), e['w'].toDouble(), e['h'].toDouble()],
      ];
      expect(got, want);
    });
  }

  test('toPageFractions', () {
    final f = toPageFractions([const PanelRect.fromLTWH(36, 54, 180, 270)], 360, 540);
    expect([f[0].left, f[0].top, f[0].width, f[0].height], [0.1, 0.1, 0.5, 0.5]);
  });
}
