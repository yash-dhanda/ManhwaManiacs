// ignore_for_file: require_trailing_commas, avoid_redundant_argument_values, prefer_const_declarations, directives_ordering, prefer_function_declarations_over_variables
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// The harness's compose helper (mobile/45 E6): PNGs decoded with `ui.instantiateImageCodec`, painted onto a `PictureRecorder` canvas
/// (side by side, or cropped and scaled with `FilterQuality.none`) and written with `toByteData(format: ui.ImageByteFormat.png)`.
/// Real async work, so it runs inside `tester.runAsync`. No package.
Future<ui.Image> _decode(String path) async {
  final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
  final frame = await codec.getNextFrame();
  codec.dispose();
  return frame.image;
}

Future<void> _write(ui.Image image, String out) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  File(out)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(data!.buffer.asUint8List());
  image.dispose();
}

/// [left] and [right] side by side with a [gap] px black gutter, the shorter one centred; written to [out].
Future<void> composeSideBySide(WidgetTester t, String left, String right, String out, {int gap = 24}) => t.runAsync(() async {
      final a = await _decode(left);
      final b = await _decode(right);
      final h = a.height > b.height ? a.height : b.height;
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      final w = a.width + gap + b.width;
      c.drawRect(Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), Paint()..color = const Color(0xFF000000));
      c.drawImage(a, Offset(0, (h - a.height) / 2), Paint());
      c.drawImage(b, Offset((a.width + gap).toDouble(), (h - b.height) / 2), Paint());
      final img = await rec.endRecording().toImage(w, h);
      a.dispose();
      b.dispose();
      await _write(img, out);
    }) as Future<void>;

/// The [region] of [src] (source pixels), scaled by [scale] with nearest-neighbour filtering; written to [out].
Future<void> cropScaled(WidgetTester t, String src, Rect region, double scale, String out) => t.runAsync(() async {
      final a = await _decode(src);
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      final w = (region.width * scale).round(), h = (region.height * scale).round();
      c.drawImageRect(a, region, Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), Paint()..filterQuality = FilterQuality.none);
      final img = await rec.endRecording().toImage(w, h);
      a.dispose();
      await _write(img, out);
    }) as Future<void>;

/// The raw RGBA bytes of a PNG, for the pixel-for-pixel comparison of an OS-path capture with its in-app-switch twin.
Future<List<int>> rawRgba(WidgetTester t, String path) async => (await t.runAsync(() async {
      final a = await _decode(path);
      final data = await a.toByteData(format: ui.ImageByteFormat.rawRgba);
      a.dispose();
      return data!.buffer.asUint8List().toList(growable: false);
    }))!;
