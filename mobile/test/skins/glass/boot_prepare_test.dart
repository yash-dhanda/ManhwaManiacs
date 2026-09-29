import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/app/app_restart.dart';
import 'package:manhwamaniacs/skins/glass/glass/liquid.dart';
import 'package:manhwamaniacs/skins/skins.dart';

void main() {
  late int inits;
  setUp(() {
    inits = 0;
    resetLiquidGlassReadyForTest();
    liquidGlassInitializer = () async => inits++;
  });

  test('a Cinematic boot never loads the Glass shaders', () async {
    await skinFor(SkinId.cinematic).prepare();
    expect(inits, 0);
  });

  testWidgets('a Glass boot loads them once, across two AppRestart restarts', (tester) async {
    late AppRestartState restart;
    var builds = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: AppRestart(
          builder: () {
            builds++;
            return Builder(builder: (context) {
              restart = AppRestart.of(context);
              return const SizedBox();
            },);
          },
        ),
      ),
    );
    // main() and every restartInto() await prepare() before the (re)build.
    await tester.runAsync(() => skinFor(SkinId.glass).prepare());
    restart.restart();
    await tester.pump();
    await tester.runAsync(() => skinFor(SkinId.glass).prepare());
    restart.restart();
    await tester.pump();
    expect(builds, 3);
    expect(inits, 1);
  });

  test('main() no longer initialises the shaders unconditionally; only prepare() reaches them', () {
    final main = File('lib/main.dart').readAsStringSync();
    expect(main.contains('LiquidGlassWidgets.initialize'), isFalse);
    expect(main.contains('liquid_glass_widgets'), isFalse);
    expect(main, contains('.prepare()'));
    final restart = File('lib/app/switch_skin.dart').readAsStringSync();
    expect(restart, contains('skinFor(skin).prepare()'));
  });
}
