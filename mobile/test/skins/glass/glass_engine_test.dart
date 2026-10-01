import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/cinematic_skin.dart';
import 'package:manhwamaniacs/skins/glass/glass/liquid.dart';
import 'package:manhwamaniacs/skins/glass/glass_skin.dart';

void main() {
  late int calls;
  setUp(() {
    calls = 0;
    resetLiquidGlassReadyForTest();
    liquidGlassInitializer = () async => calls++;
  });

  test('a cinematic boot never initialises the liquid shaders', () async {
    await const CinematicSkin().prepare();
    expect(calls, 0);
  });

  test('a Glass boot initialises them once per process', () async {
    await const GlassSkin().prepare();
    await const GlassSkin().prepare();
    await ensureLiquidGlassReady();
    expect(calls, 1);
  });

  test('only GlassSkin.prepare and the gate page reach ensureLiquidGlassReady, and only glass code imports the package', () {
    final callers = <String>[];
    final importers = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      final src = f.readAsStringSync();
      final path = f.path.replaceAll('\\', '/');
      if (src.contains('ensureLiquidGlassReady(') && !path.endsWith('glass/liquid.dart')) callers.add(path);
      if (src.contains('package:liquid_glass_widgets')) importers.add(path);
      if (src.contains('LiquidGlassWidgets.wrap(')) fail('$path uses LiquidGlassWidgets.wrap()');
    }
    expect(callers.toSet(), {'lib/skins/glass/glass_skin.dart', 'lib/skins/glass/glass/gate_demo.dart'});
    expect(importers.every((p) => p.startsWith('lib/skins/glass/')), isTrue, reason: '$importers');
  });
}
