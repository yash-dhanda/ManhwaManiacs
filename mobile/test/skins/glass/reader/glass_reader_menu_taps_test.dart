import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/glass_manga_reader.dart';

import 'glass_reader_rig.dart';

// Only a deliberate double tap opens the reading menu, never a touch that catches a moving strip;
// both entry points (library and source reader).

GlassMangaReaderState _s(WidgetTester t) => t.state<GlassMangaReaderState>(find.byType(GlassMangaReader));

Future<void> _hide(WidgetTester t) async {
  await settleReader(t, ms: 1000);
  _s(t).engine.hideChrome();
  await settleReader(t, ms: 600);
}

Future<void> _double(WidgetTester t) async {
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 350)));
  await t.tapAt(const Offset(195, 420));
  await t.pump(const Duration(milliseconds: 60));
  await t.tapAt(const Offset(195, 420));
  await settleReader(t, ms: 600);
}

void main() {
  for (final origin in [GlassReaderOrigin.manifest, GlassReaderOrigin.source]) {
    group(origin.name, () {
      testWidgets('a single tap does not open the menu; a double tap does', (t) async {
        await pumpGlassReader(t, origin: origin);
        await _hide(t);
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 350)));
        await t.tapAt(const Offset(195, 420));
        await settleReader(t, ms: 600);
        expect(_s(t).engine.value.chromeVisible, isFalse, reason: 'a single tap');
        await _double(t);
        expect(_s(t).engine.value.chromeVisible, isTrue, reason: 'a double tap');
        await disposeGlassReader(t);
      });

      testWidgets('a tap that stops a fling does not open the menu', (t) async {
        await pumpGlassReader(t, origin: origin);
        await _hide(t);
        await t.flingFrom(const Offset(195, 650), const Offset(0, -300), 2500);
        await t.pump(const Duration(milliseconds: 16));
        await t.pump(const Duration(milliseconds: 16));
        final g = await t.startGesture(const Offset(195, 420));
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 320)));
        await g.up();
        await t.pump(const Duration(milliseconds: 200));
        await t.tapAt(const Offset(195, 420));
        await settleReader(t, ms: 600);
        expect(_s(t).engine.value.chromeVisible, isFalse);
        await disposeGlassReader(t);
      });
    });
  }
}
