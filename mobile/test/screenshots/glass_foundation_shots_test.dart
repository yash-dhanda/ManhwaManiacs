@Tags(['screenshots'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/platform/gravity.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/skins/glass/dev/calibration_covers.dart';
import 'package:manhwamaniacs/skins/glass/dev/calibration_page.dart';
import 'package:manhwamaniacs/skins/glass/dev/glass_dev_index.dart';
import 'package:manhwamaniacs/skins/glass/glass/ambient_field.dart';
import 'package:manhwamaniacs/skins/glass/glass/caustic.dart';
import 'package:manhwamaniacs/skins/glass/glass/focus_ring.dart';
import 'package:manhwamaniacs/skins/glass/glass/lb.dart';
import 'package:manhwamaniacs/skins/glass/glass/palette.dart';
import 'package:manhwamaniacs/skins/glass/glass_skin.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

import 'support/shot_harness.dart';
import 'support/skin_shots.dart';

/// The mobile/25 proof captures: the calibration page in every material state, the legibility bar over a
/// dark and a pale cover, the caustic at rest and pressed, the focus ring, the ambient field and the
/// development index. Written only when `MM_PROOF_DIR` is set. The test renderer draws the frost path,
/// because shader backdrop filters do not run under `flutter test`.

class _Fixed extends GlassInAppPrefsController {
  _Fixed(this.value);
  final GlassInAppPrefs value;

  @override
  GlassInAppPrefs build() => value;
}

/// The test host has no accelerometer plugin.
final Override noSensor =
    gravitySensorProvider.overrideWithValue(() => const Stream.empty());

Override prefs(GlassInAppPrefs p) =>
    glassInAppPrefsProvider.overrideWith(() => _Fixed(p));

Widget page(Widget child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      home: GlassRoot(
          child: Material(type: MaterialType.transparency, child: child),),
    );

/// A stage with true black under a painted cover and glass over it.
Widget stage(Widget Function(BuildContext) glass, {CalibrationCover? cover}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      home: GlassRoot(
        child: Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              if (cover != null)
                Positioned.fill(
                    child:
                        CustomPaint(painter: CalibrationCoverPainter(cover)),),
              Builder(builder: glass),
            ],
          ),
        ),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);

  final phone = kSkinShotSizes.firstWhere((s) => s.name == 'phone');
  final tablet = kSkinShotSizes.firstWhere((s) => s.name == 'tablet');

  for (final size in [phone, tablet]) {
    testWidgets('calibration frosted ${size.name}', (tester) async {
      await captureSkinWidget(
        tester,
        name: 'calibration-frosted',
        size: size,
        child: page(const GlassCalibrationPage()),
        overrides: [
          noSensor,
          glassRendererOverrideProvider
              .overrideWith((ref) => GlassRenderer.frosted),
        ],
      );
    });

    testWidgets('calibration solid ${size.name}', (tester) async {
      await captureSkinWidget(
        tester,
        name: 'calibration-solid',
        size: size,
        child: page(const GlassCalibrationPage()),
        overrides: [noSensor, prefs(const GlassInAppPrefs(solidGlass: true))],
      );
    });
  }

  testWidgets('calibration increase contrast', (tester) async {
    await captureSkinWidget(
      tester,
      name: 'calibration-contrast',
      size: phone,
      child: page(const GlassCalibrationPage()),
      overrides: [
        noSensor,
        prefs(const GlassInAppPrefs(increaseContrast: true)),
      ],
    );
  });

  testWidgets('calibration reduced motion', (tester) async {
    await captureSkinWidget(
      tester,
      name: 'calibration-reduced',
      size: phone,
      child: page(const GlassCalibrationPage()),
      overrides: [noSensor, prefs(const GlassInAppPrefs(reduceMotion: true))],
    );
  });

  for (final pale in [false, true]) {
    testWidgets('legibility ${pale ? 'pale' : 'dark'}', (tester) async {
      final cover = pale ? kCalibrationCovers[22] : kCalibrationCovers[0];
      await captureSkinWidget(
        tester,
        name: 'legibility-${pale ? 'pale' : 'dark'}',
        size: phone,
        overrides: [noSensor],
        child: stage(
          cover: cover,
          (context) => Align(
            alignment: const Alignment(0, -0.3),
            child: SkinGlassGroup(
              lb: Lb.cover(cover.lMax),
              debugLabel: 'legibility',
              shapes: [
                SkinGlassShape(
                  size: const Size(320, 64),
                  child: Center(
                      child: GlassText('Legibility over art',
                          role: glassTokens.typeHeadline, onGlass: true,),),
                ),
              ],
            ),
          ),
        ),
      );
      expect(dimFor(Lb.cover(cover.lMax)),
          pale ? closeTo(0.64, 0.005) : lessThan(0.64),);
    });
  }

  for (final pressed in [false, true]) {
    testWidgets('caustic ${pressed ? 'pressed' : 'rest'}', (tester) async {
      await captureSkinWidget(
        tester,
        name: 'caustic-${pressed ? 'pressed' : 'rest'}',
        size: phone,
        overrides: [noSensor],
        child: stage(
          cover: kCalibrationCovers[2],
          (context) => Center(
            child: GlassCaustic(
              pressed: pressed,
              child: SkinGlass(
                tier: GlassTierId.t2,
                finish: GlassFinishKind.tinted,
                size: const Size(160, 56),
                materialize: false,
                child: Center(
                    child: GlassText('Read',
                        role: glassTokens.typeHeadline,
                        color: glassTokens.colorOnTint,),),
              ),
            ),
          ),
        ),
      );
    });
  }

  testWidgets('focus ring t2 tablet', (tester) async {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,);
    await captureSkinWidget(
      tester,
      name: 'focus-ring-t2',
      size: tablet,
      overrides: [noSensor],
      child: stage(
        cover: kCalibrationCovers[5],
        (context) => const Center(
          child: GlassFocusRing(
            shape: GlassShape.circle(),
            child: Focus(
              autofocus: true,
              child: SkinGlass(
                tier: GlassTierId.t2,
                shape: GlassShape.circle(),
                size: Size(88, 88),
                materialize: false,
                child: SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  });

  testWidgets('ambient mood', (tester) async {
    await captureSkinWidget(
      tester,
      name: 'ambient-mood',
      size: phone,
      overrides: [noSensor],
      child: stage(
        (context) => GlassAmbientScope(
          spec: const GlassAmbientSpec.mood(Mood.romantic),
          child: Align(
            alignment: const Alignment(0, -0.6),
            child: GlassText('Romantic', role: glassTokens.typeLargeTitle),
          ),
        ),
      ),
    );
  });

  testWidgets('ambient palette', (tester) async {
    final c = kCalibrationCovers[8];
    await captureSkinWidget(
      tester,
      name: 'ambient-palette',
      size: phone,
      overrides: [noSensor],
      child: stage(
        (context) => GlassAmbientScope(
          spec: GlassAmbientSpec.palette(
              CoverPalette(a: c.palette, l: c.l, lMax: c.lMax),
              opacity: 0.26,),
          child: Align(
            alignment: const Alignment(0, -0.6),
            child: GlassText(c.title, role: glassTokens.typeLargeTitle),
          ),
        ),
      ),
    );
  });

  testWidgets('dev index', (tester) async {
    await captureSkinWidget(tester,
        name: 'dev-index',
        size: phone,
        child: page(const GlassDevIndex()),
        overrides: [noSensor],);
  });
}
