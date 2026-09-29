@Tags(['screenshots'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/dev/gallery_sections.dart';
import 'package:manhwamaniacs/skins/glass/dev/glass_gallery.dart';
import 'package:manhwamaniacs/skins/glass/glass/light_angle.dart';
import 'package:manhwamaniacs/skins/glass/glass_skin.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/hold_to_confirm.dart';
import 'package:manhwamaniacs/skins/glass/primitives/letter_reveal.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart';
import 'package:manhwamaniacs/skins/glass/primitives/reveal_slots.dart';

import 'support/shot_harness.dart';
import 'support/skin_shots.dart';

/// The mobile/26 proof captures: one per gallery section at phone and tablet, again with Solid glass and
/// Increase contrast, plus four mid-motion frames. Written only when `MM_PROOF_DIR` is set. The test
/// renderer draws the frost path, because shader backdrop filters do not run under `flutter test`.

class _Fixed extends GlassInAppPrefsController {
  _Fixed(this.value);
  final GlassInAppPrefs value;

  @override
  GlassInAppPrefs build() => value;
}

final Override noSensor = glassAccelerometerProvider.overrideWithValue(() => const Stream.empty());

Override prefs(GlassInAppPrefs p) => glassInAppPrefsProvider.overrideWith(() => _Fixed(p));

Widget page(Widget child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      home: GlassRoot(child: Material(type: MaterialType.transparency, child: child)),
    );

Future<void> settleFor(WidgetTester tester, int ms) async {
  var left = ms;
  while (left > 0) {
    final step = left < 16 ? left : 16;
    await tester.pump(Duration(milliseconds: step));
    left -= step;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);
  setUp(glassRevealSlots.reset);

  final phone = kSkinShotSizes.firstWhere((s) => s.name == 'phone');
  final tablet = kSkinShotSizes.firstWhere((s) => s.name == 'tablet');

  for (final section in kGlassGallerySections) {
    for (final size in [phone, tablet]) {
      testWidgets('$section ${size.name}', (tester) async {
        await captureSkinWidget(tester, name: section, size: size, child: page(GlassGallery(section: section)), overrides: [noSensor], settle: (t) => settleFor(t, 1500));
      });
    }
    testWidgets('$section solid', (tester) async {
      await captureSkinWidget(tester, name: '$section-solid', size: phone, child: page(GlassGallery(section: section)), overrides: [noSensor, prefs(const GlassInAppPrefs(solidGlass: true))], settle: (t) => settleFor(t, 1500));
    });
    testWidgets('$section contrast', (tester) async {
      await captureSkinWidget(tester, name: '$section-contrast', size: phone, child: page(GlassGallery(section: section)), overrides: [noSensor, prefs(const GlassInAppPrefs(increaseContrast: true))], settle: (t) => settleFor(t, 1500));
    });
  }

  testWidgets('typing at 200 ms', (tester) async {
    await captureSkinWidget(tester, name: 'reveals-typing-200ms', size: phone, child: page(const GlassGallery(section: 'reveals')), overrides: [noSensor], settle: (t) => settleFor(t, 200));
  });

  testWidgets('two letter reveals running, the third waiting', (tester) async {
    await captureSkinWidget(
      tester,
      name: 'reveals-rails-running',
      size: phone,
      child: page(
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, t) in ['Because you read Solo Leveling', 'Fresh from your sources', 'Quiet picks for tonight'].indexed)
                Padding(padding: const EdgeInsets.only(bottom: 24), child: LetterReveal(t, role: gt.typeTitle2, revealKey: 'shot-$i', screenId: 'shots')),
            ],
          ),
        ),
      ),
      overrides: [noSensor],
      settle: (t) => settleFor(t, 350),
    );
  });

  testWidgets('poster lift at 450 ms', (tester) async {
    await captureSkinWidget(
      tester,
      name: 'poster-lift',
      size: phone,
      child: page(Center(child: GlassPoster(cover: const GalleryCover(3), title: 'The Ninth Regression', width: 160, meta: const GlassPosterMeta(newCount: 3), onTap: () {}, onContextPreview: () {}))),
      overrides: [noSensor],
      settle: (t) async {
        await settleFor(t, 400);
        final g = await t.startGesture(t.getCenter(find.byType(GlassPoster)));
        await settleFor(t, 450);
        await t.pump();
        addTearDown(g.up);
      },
    );
  });

  testWidgets('hold aborted', (tester) async {
    await captureSkinWidget(
      tester,
      name: 'hold-aborted',
      size: phone,
      child: page(Center(child: HoldToConfirm(label: 'Hold to delete', onConfirm: () {}, onRequestConfirm: () {}))),
      overrides: [noSensor],
      settle: (t) async {
        await settleFor(t, 400);
        final g = await t.startGesture(t.getCenter(find.text('Hold to delete')));
        await settleFor(t, 700);
        await g.up();
        await settleFor(t, 200);
      },
    );
  });
}
