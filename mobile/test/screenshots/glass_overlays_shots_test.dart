@Tags(['screenshots'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/dev/glass_gallery.dart';
import 'package:manhwamaniacs/skins/glass/dev/overlay_sections.dart';
import 'package:manhwamaniacs/skins/glass/glass/light_angle.dart';
import 'package:manhwamaniacs/skins/glass/glass_skin.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/reveal_slots.dart';

import 'support/shot_harness.dart';
import 'support/skin_shots.dart';

/// The mobile/27 proof captures: one per gallery section at phone and tablet, again with Solid glass and
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
      builder: (context, home) => GlassRoot(child: home!),
      home: Material(type: MaterialType.transparency, child: child),
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

  for (final section in kGlassOverlaySections) {
    for (final size in [phone, tablet]) {
      testWidgets('$section ${size.name}', (tester) async {
        await captureSkinWidget(tester, name: section, size: size, child: page(GlassGallery(section: section)), overrides: [noSensor], settle: (t) => settleFor(t, 1500));
      });
    }
    testWidgets('$section solid', (tester) async {
      await captureSkinWidget(
        tester,
        name: '$section-solid',
        size: phone,
        child: page(GlassGallery(section: section)),
        overrides: [noSensor, prefs(const GlassInAppPrefs(solidGlass: true))],
        settle: (t) => settleFor(t, 1500),
      );
    });
    testWidgets('$section reduced', (tester) async {
      await captureSkinWidget(
        tester,
        name: '$section-reduced',
        size: phone,
        child: page(GlassGallery(section: section)),
        overrides: [noSensor, prefs(const GlassInAppPrefs(reduceMotion: true))],
        settle: (t) => settleFor(t, 1500),
      );
    });
  }

  // Held open: tap the first button of a section and capture after the present has run.
  for (final (name, section, label) in const [
    ('sheet-medium', 'sheets', 'Open medium'),
    ('sheet-peek', 'sheets', 'Open peek'),
    ('sheet-monolith', 'sheets', 'Open monolith'),
    ('alert-confirm', 'alerts', 'Confirm'),
    ('alert-three', 'alerts', 'Three actions'),
    ('toast-error', 'toasts', 'error'),
    ('toast-undo', 'toasts', 'Undo'),
    ('menu-open', 'menus', 'Menu'),
  ]) {
    testWidgets('open $name', (tester) async {
      await captureSkinWidget(
        tester,
        name: name,
        size: phone,
        child: page(GlassGallery(section: section)),
        overrides: [noSensor],
        settle: (t) async {
          await settleFor(t, 600);
          await t.tap(find.text(label).first, warnIfMissed: false);
          await settleFor(t, 900);
        },
      );
    });
  }
}
