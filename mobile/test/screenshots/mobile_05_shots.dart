// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/gallery/primitives_gallery.dart';

import 'support/shot_harness.dart';
import 'support/skin_shots.dart';

/// Screenshot group `mobile-05`: the overlays, controls, rows and states of the Cinematic
/// primitives, at phone (390 x 844) and tablet (834 x 1194), each overlay captured open.
///
/// Names are `<section>[-state][-reduced]`; the files land as
/// `docs/redesign/proof/mobile-05/<name>-<phone|tablet>.png`.
void mobile05Shots() {
  Future<void> tapKey(WidgetTester t, String key) async {
    final f = find.byKey(Key(key));
    await t.ensureVisible(f);
    await t.pump();
    await t.tap(f, warnIfMissed: false);
  }

  Future<void> settleFor(WidgetTester t, {int ms = 1200}) async {
    await t.pump();
    for (var i = 0; i < ms ~/ 50; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
  }

  // (name, section, page height, actions after the first frame)
  final shots = <(String, String, double, Future<void> Function(WidgetTester)?)>[
    ('tabs', 'tabs', 900, null),
    ('rows', 'rows', 4200, null),
    ('sliders', 'sliders', 900, null),
    ('toggles', 'toggles', 1100, null),
    ('notices', 'notices', 1900, null),
    ('certificate', 'certificate', 700, null),
    ('other', 'other', 2600, null),
    ('sheets', 'sheets', 800, null),
    ('dialogs', 'dialogs', 1000, null),
    ('toasts', 'toasts', 700, null),
    ('menus', 'menus', 700, null),
    ('lightbox', 'lightbox', 500, null),
    ('sheets-open', 'sheets', 900, (t) async {
      await tapKey(t, 'g-sheet-basic');
      await settleFor(t);
    }),
    ('sheets-live-half', 'sheets', 900, (t) async {
      await tapKey(t, 'g-sheet-live');
      await settleFor(t);
    }),
    ('sheets-live-full', 'sheets', 900, (t) async {
      await tapKey(t, 'g-sheet-live');
      await settleFor(t);
      await t.drag(find.byKey(const Key('cine-sheet-grabber')), const Offset(0, -400));
      await settleFor(t);
    }),
    ('sheets-loading', 'sheets', 900, (t) async {
      await tapKey(t, 'g-sheet-loading');
      await settleFor(t, ms: 1500);
    }),
    ('sheets-error', 'sheets', 900, (t) async {
      await tapKey(t, 'g-sheet-error');
      await settleFor(t);
    }),
    ('dialogs-arming', 'dialogs', 1000, (t) async {
      await tapKey(t, 'g-dialog-destructive');
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      await t.pump(const Duration(milliseconds: 300));
    }),
    ('dialogs-armed', 'dialogs', 1000, (t) async {
      await tapKey(t, 'g-dialog-destructive');
      await settleFor(t, ms: 1500);
    }),
    ('dialogs-heavy', 'dialogs', 1000, (t) async {
      await tapKey(t, 'g-dialog-heavy-phrase');
      await settleFor(t, ms: 1500);
    }),
    ('toasts-two', 'toasts', 700, (t) async {
      await tapKey(t, 'g-toast-two');
      await settleFor(t, ms: 500);
    }),
    ('toasts-banner', 'toasts', 700, (t) async {
      await tapKey(t, 'g-toast-banner');
      await settleFor(t, ms: 300);
      await tapKey(t, 'g-toast-two');
      await settleFor(t, ms: 500);
    }),
    ('menus-open', 'menus', 700, (t) async {
      await tapKey(t, 'g-menu-open');
      await settleFor(t, ms: 500);
    }),
    ('quicklook-mid', 'menus', 900, (t) async {
      await t.longPress(find.byKey(const Key('g-quicklook-poster')), warnIfMissed: false);
      await t.pump();
      await t.pump(const Duration(milliseconds: 200));
    }),
    ('lightbox-1x', 'lightbox', 500, (t) async {
      await tapKey(t, 'g-lightbox-open');
      await settleFor(t, ms: 900);
    }),
    ('lightbox-2_5x', 'lightbox', 500, (t) async {
      await tapKey(t, 'g-lightbox-open');
      await settleFor(t, ms: 900);
      final c = t.getCenter(find.byType(InteractiveViewer));
      await t.tapAt(c);
      await t.pump(const Duration(milliseconds: 60));
      await t.tapAt(c);
      await settleFor(t, ms: 450);
    }),
    ('certificate-dialog', 'certificate', 900, (t) async {
      await tapKey(t, 'g-certificate-dialog');
      await settleFor(t, ms: 800);
    }),
    ('certificate-stamp', 'certificate', 900, (t) async {
      await tapKey(t, 'g-certificate-dialog');
      await settleFor(t, ms: 800);
      await t.tap(find.byKey(const Key('cert-check')));
      await t.pump();
      await t.tap(find.byKey(const Key('cert-enable')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 640));
      await t.pump(const Duration(milliseconds: 60));
    }),
    // Reduced motion: opacity-only transitions, the arm rule appears full at 1000 ms.
    ('sheets-reduced', 'sheets', 900, (t) async {
      await tapKey(t, 'g-sheet-basic');
      await settleFor(t, ms: 400);
    }),
    ('dialogs-reduced', 'dialogs', 1000, (t) async {
      await tapKey(t, 'g-dialog-destructive');
      await settleFor(t);
    }),
    ('toasts-reduced', 'toasts', 700, (t) async {
      await tapKey(t, 'g-toast-two');
      await settleFor(t, ms: 500);
    }),
  ];

  for (final size in kSkinShotSizes) {
    for (final (name, section, height, act) in shots) {
      final reduced = name.endsWith('-reduced');
      testWidgets('mobile-05 $name ${size.name}', (t) async {
        final tall = SkinShotSize(size.name, Size(size.logical.width, height), size.pixelRatio, size.padding);
        await captureSkinWidget(
          t,
          name: name,
          size: tall,
          disableAnimations: reduced,
          settle: (t) async {
            await settleShot(t);
            await act?.call(t);
          },
          child: MaterialApp(debugShowCheckedModeBanner: false, home: CinePrimitivesGalleryPage(section: section)),
        );
        // Let every hold timer and route finish before the next capture.
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 12));
      });
    }
  }
}
