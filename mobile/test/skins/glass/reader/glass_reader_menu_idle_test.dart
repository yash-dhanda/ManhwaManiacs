import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/scrub_rail.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/glass_manga_reader.dart';

import 'glass_reader_rig.dart';

// The owner's rule on Glass: the reading menu, once open, stays 5 s untouched, then hides.
// Touching it restarts the 5 s; the scrubber in a drag, a sheet or the go-to popover hold it; scrolling
// hides it at once; a screen reader keeps it up. Both entry points (library and source reader).

GlassMangaReaderState _s(WidgetTester t) => t.state<GlassMangaReaderState>(find.byType(GlassMangaReader));
bool _up(WidgetTester t) => _s(t).engine.value.chromeVisible;
const _centre = Offset(195, 420);
final _scrubber = find.byType(GlassScrubRail);

Future<void> _after(WidgetTester t, int ms) async {
  for (var e = 0; e < ms; e += 100) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

/// Waits out the menu shown at open, then taps it open; the clock starts on return.
Future<void> _open(WidgetTester t) async {
  await _after(t, 5600);
  expect(_up(t), isFalse, reason: 'idle-hidden after open');
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 350)));
  await t.tapAt(_centre);
  await t.pump();
  expect(_up(t), isTrue, reason: 'a tap opens (Open menu with: Tap)');
}

Future<void> _idlesFromNow(WidgetTester t, String why) async {
  await _after(t, 4900);
  expect(_up(t), isTrue, reason: '$why: up at 4.9 s');
  await _after(t, 200);
  expect(_up(t), isFalse, reason: '$why: hidden at 5.1 s');
}

void main() {
  for (final origin in [GlassReaderOrigin.manifest, GlassReaderOrigin.source]) {
    group(origin.name, () {
      testWidgets('opened, it is up at 4.9 s and hidden at 5.1 s', (t) async {
        await pumpGlassReader(t, origin: origin);
        await _open(t);
        await _idlesFromNow(t, 'untouched');
        await disposeGlassReader(t);
      });

      testWidgets('tapping a control restarts the 5 s', (t) async {
        await pumpGlassReader(t, origin: origin);
        await _open(t);
        await _after(t, 4000);
        await t.tapAt(t.getCenter(_scrubber));
        await t.pump();
        await _idlesFromNow(t, 'after the tap');
        await disposeGlassReader(t);
      });

      testWidgets('scrolling the page hides it at once', (t) async {
        await pumpGlassReader(t, origin: origin);
        await _open(t);
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 900)));
        await t.dragFrom(const Offset(195, 600), const Offset(0, -200));
        await t.pump(const Duration(milliseconds: 100));
        expect(_up(t), isFalse);
        await disposeGlassReader(t);
      });

      testWidgets('a scrubber drag never runs out; letting go restarts the 5 s', (t) async {
        await pumpGlassReader(t, origin: origin);
        await _open(t);
        final g = await t.startGesture(t.getCenter(_scrubber));
        await t.pump();
        await g.moveBy(const Offset(0, 30));
        await t.pump();
        await _after(t, 8000);
        expect(_up(t), isTrue, reason: 'held by the drag');
        await g.up();
        await t.pump();
        await _idlesFromNow(t, 'after the drag');
        await disposeGlassReader(t);
      });

      testWidgets('a sheet from it holds it; closing it restarts the 5 s', (t) async {
        await pumpGlassReader(t, origin: origin);
        await _open(t);
        _s(t).openSettings();
        await _after(t, 800);
        await _after(t, 8000);
        expect(_up(t), isTrue, reason: 'held by the sheet');
        Navigator.of(t.element(find.byType(GlassMangaReader)), rootNavigator: true).pop();
        await t.pump();
        await _after(t, 4900);
        expect(_up(t), isTrue, reason: 'within 5 s of the close');
        await _after(t, 1000);
        expect(_up(t), isFalse, reason: 'idle after the close');
        await disposeGlassReader(t);
      });

      testWidgets('the go-to popover holds it', (t) async {
        await pumpGlassReader(t, origin: origin);
        await _open(t);
        _s(t).setGoTo(true);
        await _after(t, 8000);
        expect(_up(t), isTrue, reason: 'held by go-to');
        _s(t).setGoTo(false);
        await _after(t, 5400);
        expect(_up(t), isFalse, reason: 'idle after go-to closes');
        await disposeGlassReader(t);
      });

      testWidgets('a screen reader keeps it up', (t) async {
        await pumpGlassReader(t, origin: origin, accessible: true);
        await _after(t, 12000);
        expect(_up(t), isTrue);
        await disposeGlassReader(t);
      });
    });
  }
}
