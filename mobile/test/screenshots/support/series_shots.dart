import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'shot_harness.dart';
import 'skin_shots.dart';

/// Writes the frame under [kSkinShotKey] as `<MM_PROOF_DIR>/<name>-<size.name>.png`
/// at [size]'s pixel ratio, after the caller has driven the page to the state
/// it wants proved (taps, sheets, scrolls: what `captureSkinWidget` cannot do).
/// With no proof directory the frame is still rasterised and thrown away.
Future<void> captureSeriesShot(WidgetTester tester, String name, SkinShotSize size) async {
  final dir = proofDir;
  if (dir == null) {
    final box = tester.renderObject<RenderRepaintBoundary>(find.byKey(kSkinShotKey));
    await tester.runAsync(() async {
      (await box.toImage(pixelRatio: size.pixelRatio)).dispose();
    });
    return;
  }
  Directory(dir).createSync(recursive: true);
  await writeShot(tester, find.byKey(kSkinShotKey), '$dir/$name-${size.name}.png',
      pixelRatio: size.pixelRatio,);
}

/// A shot with no size suffix (`download-marks-gallery.png`).
Future<void> captureSeriesShotPlain(WidgetTester tester, String name) async {
  final dir = proofDir;
  if (dir == null) return;
  Directory(dir).createSync(recursive: true);
  await writeShot(tester, find.byKey(kSkinShotKey), '$dir/$name.png');
}
