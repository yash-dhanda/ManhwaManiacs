import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phone and tablet, the two sizes every skin screen is proved at.
/// TODO(shared/03): replaced by the harness's `kSkinShotSizes` when it lands.
const Map<String, Size> kSkinShotSizes = {
  'phone': Size(390, 844),
  'tablet': Size(834, 1194),
};

/// `MM_PROOF_DIR`: where proof PNGs go; unset means rasterise and discard.
String? get proofDir {
  final d = (Platform.environment['MM_PROOF_DIR'] ?? '').trim();
  return d.isEmpty ? null : d;
}

/// The Cinematic type families are not bundled in the app yet, so in a test
/// host every glyph would be a box. Registers Inter and a system serif under
/// their names so proofs are legible (the real faces land with the fonts).
Future<void> loadCinematicStandInFonts() async {
  Future<void> reg(List<String> families, List<String> paths) async {
    final bytes = <ByteData>[];
    for (final p in paths) {
      final f = File(p);
      if (f.existsSync()) bytes.add(ByteData.view(f.readAsBytesSync().buffer));
    }
    if (bytes.isEmpty) return;
    for (final family in families) {
      final loader = FontLoader(family);
      for (final b in bytes) {
        loader.addFont(Future.value(b));
      }
      await loader.load();
    }
  }

  await reg(
    ['Archivo', 'IBMPlexMono', 'AtkinsonHyperlegibleNext'],
    ['assets/fonts/Inter-Regular.ttf', 'assets/fonts/Inter-Medium.ttf'],
  );
  await reg(
    ['BodoniModa', 'Newsreader'],
    [
      '/usr/share/fonts/noto/NotoSerif-Regular.ttf',
      '/usr/share/fonts/truetype/noto/NotoSerif-Regular.ttf',
      '/usr/share/fonts/liberation/LiberationSerif-Regular.ttf',
      '/usr/share/fonts/truetype/liberation/LiberationSerif-Regular.ttf',
      '/usr/share/fonts/TTF/DejaVuSerif.ttf',
      '/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf',
    ],
  );
}

/// Rasterises [boundary] to `<MM_PROOF_DIR>/<name>.png` at [pixelRatio];
/// with no proof directory the frame is still rendered and thrown away, so a
/// screen that stops rendering fails the run either way.
Future<void> captureSkinScreen(
  WidgetTester tester,
  Finder boundary,
  String name, {
  double pixelRatio = 2,
}) async {
  final dir = proofDir;
  final box = tester.renderObject<RenderRepaintBoundary>(boundary);
  await tester.runAsync(() async {
    final image = await box.toImage(pixelRatio: pixelRatio);
    if (dir != null) {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('$dir/$name.png');
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(data!.buffer.asUint8List());
    }
    image.dispose();
  });
}
