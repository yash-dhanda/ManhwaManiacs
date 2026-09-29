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
import 'package:manhwamaniacs/skins/glass/primitives/scrub_rail.dart';

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

final Override noSensor =
    glassAccelerometerProvider.overrideWithValue(() => const Stream.empty());

Override prefs(GlassInAppPrefs p) =>
    glassInAppPrefsProvider.overrideWith(() => _Fixed(p));

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
        await captureSkinWidget(tester,
            name: section,
            size: size,
            child: page(GlassGallery(section: section)),
            overrides: [noSensor],
            settle: (t) => settleFor(t, 1500),);
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
    testWidgets('$section contrast', (tester) async {
      await captureSkinWidget(
        tester,
        name: '$section-contrast',
        size: phone,
        child: page(GlassGallery(section: section)),
        overrides: [
          noSensor,
          prefs(const GlassInAppPrefs(increaseContrast: true)),
        ],
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
    ('sheet-large-recession', 'sheets', 'Open large'),
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

  final size = phone;

  /// Opens [section], taps [taps] in order (each followed by [gap] ms), then runs [after] and captures.
  void shot(String name, String section, List<String> taps,
      {SkinShotSize? at,
      int gap = 700,
      int hold = 0,
      Future<void> Function(WidgetTester t)? after,}) {
    testWidgets('shot $name', (tester) async {
      await captureSkinWidget(
        tester,
        name: name,
        size: at ?? size,
        child: page(GlassGallery(section: section)),
        overrides: [noSensor],
        settle: (t) async {
          await settleFor(t, 600);
          for (final label in taps) {
            await t.tap(find.text(label).first, warnIfMissed: false);
            await settleFor(t, gap);
          }
          if (after != null) await after(t);
          if (hold > 0) await settleFor(t, hold);
        },
      );
    });
  }

  // Sheets.
  shot('sheet-stacked', 'sheets', ['Stacked', 'Open another'], gap: 900);
  shot('sheet-rubberband', 'sheets', ['Open large'], gap: 900,
      after: (t) async {
    final g = await t.startGesture(t.getCenter(find.text('Sheet large').first));
    await g.moveBy(const Offset(0, -20));
    await g.moveBy(const Offset(0, -40));
    await settleFor(t, 100);
  },);
  shot('sheet-keyboard', 'sheets', ['Keyboard field'], gap: 900,
      after: (t) async {
    await t.tap(find.byType(EditableText).first, warnIfMissed: false);
    await settleFor(t, 700);
  },);
  shot('panel', 'sheets', ['Panel'], at: tablet, gap: 900);
  shot('window', 'sheets', ['Window'], at: tablet, gap: 900);
  shot('detail-window', 'sheets', ['Detail window'], at: tablet, gap: 900);
  shot('offer-popover', 'sheets', ['Popover'], at: tablet, gap: 900);

  // Alerts, toasts and menus.
  shot('alert-from-source', 'alerts', ['Confirm'], gap: 110);
  shot('alert-error', 'alerts', ['Error', 'Delete'], gap: 500);
  shot('toasts-stacked', 'toasts', ['info', 'error']);
  shot('toast-undo-rim', 'toasts', ['Undo'], gap: 3000);
  shot('menu-bloom', 'menus', ['Menu'], gap: 90);
  shot('context-lift', 'menus', ['Context lift'], gap: 900);

  // Image viewer.
  shot('image-viewer-zoomed', 'image-viewer', ['Open image'], gap: 900,
      after: (t) async {
    final c = t.getCenter(find.byType(Image).first);
    await t.tapAt(c);
    await t.pump(const Duration(milliseconds: 90));
    await t.tapAt(c);
    await settleFor(t, 700);
  },);
  shot('image-viewer-dismiss-drag', 'image-viewer', ['Open image'], gap: 900,
      after: (t) async {
    final g = await t.startGesture(t.getCenter(find.byType(Image).first));
    await g.moveBy(const Offset(0, 40));
    await g.moveBy(const Offset(0, 80));
    await settleFor(t, 100);
  },);

  // Pull to refresh.
  Future<void> pull(WidgetTester t, double px) async {
    final start = t.getCenter(find.text('Row 2').first);
    final g = await t.startGesture(start);
    var y = 0.0;
    for (var i = 0; i < 60; i++) {
      final box = find.byKey(const ValueKey('glass-pull'));
      if (box.evaluate().isNotEmpty && t.getSize(box.first).height >= px) break;
      y += 12;
      await g.moveTo(start + Offset(0, y));
      await t.pump(const Duration(milliseconds: 16));
    }
  }

  shot('pull-droplet-60px', 'pull-to-refresh', [], after: (t) => pull(t, 60));
  shot('pull-snapped', 'pull-to-refresh', [], after: (t) => pull(t, 100));

  // Scrub lens and speed dial.
  shot('scrub-lens', 'sliders', [], after: (t) async {
    final rail = find.byType(GlassScrubRail).first;
    await t.ensureVisible(rail);
    await settleFor(t, 300);
    final g = await t.startGesture(t.getCenter(rail));
    await g.moveBy(const Offset(0, 24));
    await g.moveBy(const Offset(0, 24));
    await settleFor(t, 400);
  },);
  shot('speed-dial', 'sliders', [], after: (t) async {
    final dial = find.byKey(const ValueKey('glass-dial-capsule')).first;
    await t.ensureVisible(dial);
    await settleFor(t, 300);
    final g = await t.startGesture(t.getCenter(dial));
    for (var i = 0; i < 6; i++) {
      await g.moveBy(const Offset(0, -6));
      await t.pump(const Duration(milliseconds: 16));
    }
    await settleFor(t, 300);
  },);
}
