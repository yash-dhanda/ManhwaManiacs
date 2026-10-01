import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_profile_settings.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/glass_manga_reader.dart';

import 'glass_reader_rig.dart';

// 'Open menu with' on Glass: Tap (default) toggles on one tap, Double tap on a double, Top or bottom
// edge on a tap in the edge bands. A touch that catches a moving strip only stops it; a scroll the app
// made never eats a tap; the chapter end shows the menu. Both entry points (library and source reader).

GlassMangaReaderState _s(WidgetTester t) => t.state<GlassMangaReaderState>(find.byType(GlassMangaReader));
bool _up(WidgetTester t) => _s(t).engine.value.chromeVisible;
const _centre = Offset(195, 420);

Future<void> _put(WidgetTester t, Map<String, dynamic> fields) async {
  await ProviderScope.containerOf(t.element(find.byType(GlassMangaReader))).read(readerSettingsProvider.notifier).put(fields);
  await t.pump();
}

Future<void> _hide(WidgetTester t) async {
  await settleReader(t, ms: 1000);
  _s(t).engine.hideChrome();
  await settleReader(t, ms: 600);
}

Future<void> _single(WidgetTester t, [Offset at = _centre]) async {
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 350)));
  await t.tapAt(at);
  await settleReader(t, ms: 600);
}

Future<void> _double(WidgetTester t) async {
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 350)));
  await t.tapAt(_centre);
  await t.pump(const Duration(milliseconds: 60));
  await t.tapAt(_centre);
  await settleReader(t, ms: 600);
}

ScrollPosition _strip(WidgetTester t) => t.state<ScrollableState>(find.byType(Scrollable).first).position;

void main() {
  for (final origin in [GlassReaderOrigin.manifest, GlassReaderOrigin.source]) {
    group(origin.name, () {
      testWidgets('Tap (default): one tap opens at once, another closes', (t) async {
        await pumpGlassReader(t, origin: origin);
        await _hide(t);
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 350)));
        await t.tapAt(_centre);
        await t.pump();
        expect(_up(t), isTrue, reason: 'no double-tap wait');
        await _single(t);
        expect(_up(t), isFalse);
        await disposeGlassReader(t);
      });

      testWidgets('Double tap: a single tap does not open the menu; a double tap does', (t) async {
        await pumpGlassReader(t, origin: origin);
        await _put(t, {'menuOpen': 'doubleTap'});
        await _hide(t);
        await _single(t);
        expect(_up(t), isFalse, reason: 'a single tap');
        await _double(t);
        expect(_up(t), isTrue, reason: 'a double tap');
        await disposeGlassReader(t);
      });

      testWidgets('Top or bottom edge: the centre does nothing, the bottom band opens', (t) async {
        await pumpGlassReader(t, origin: origin);
        await _put(t, {'menuOpen': 'edge'});
        await _hide(t);
        await _single(t);
        expect(_up(t), isFalse, reason: 'the centre');
        await _single(t, const Offset(195, 760));
        expect(_up(t), isTrue, reason: 'the bottom band');
        await disposeGlassReader(t);
      });

      testWidgets('a tap that stops a fling does not open the menu', (t) async {
        await pumpGlassReader(t, origin: origin);
        await _hide(t);
        await t.flingFrom(const Offset(195, 650), const Offset(0, -300), 2500);
        await t.pump(const Duration(milliseconds: 16));
        await t.pump(const Duration(milliseconds: 16));
        // The catch, and a tap right after it: inside the 300 ms the stop starts.
        await t.tapAt(_centre);
        await t.pump(const Duration(milliseconds: 16));
        await t.tapAt(_centre);
        await settleReader(t, ms: 600);
        expect(_up(t), isFalse);
        await _single(t);
        expect(_up(t), isTrue, reason: 'a deliberate tap on the stopped strip');
        await disposeGlassReader(t);
      });

      testWidgets('a scroll the app made never eats the next tap', (t) async {
        await pumpGlassReader(t, origin: origin);
        await _hide(t);
        _s(t).engine.scrollByViewport(0.75, duration: const Duration(milliseconds: 200), curve: Curves.linear);
        await settleReader(t, ms: 400);
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
        await t.tapAt(_centre);
        await t.pump();
        expect(_up(t), isTrue);
        await disposeGlassReader(t);
      });

      testWidgets('reaching the chapter end shows the menu', (t) async {
        await pumpGlassReader(t, origin: origin, pages: 2);
        await _hide(t);
        _strip(t).jumpTo(_strip(t).maxScrollExtent);
        await t.pump();
        expect(_up(t), isTrue);
        await disposeGlassReader(t);
      });
    });
  }
}
