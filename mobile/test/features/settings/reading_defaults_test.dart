import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/storage/json_record.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_profile_settings.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_profile_settings.dart';

void main() {
  group('manga', () {
    test('built-in seriesDefaults are strip, ltr, width, 100, 1.00', () {
      final d = const JsonRecord().seriesDefaults;
      expect((d.layout, d.direction, d.fit, d.zoom, d.autoScrollSpeed), ('strip', 'ltr', 'width', 100, 1.0));
    });

    test('a series with no own value follows the profile default, an own value wins', () {
      const defaults = SeriesDefaults(layout: 'single', direction: 'rtl', fit: 'height', zoom: 120, autoScrollSpeed: 1.5);
      final none = resolveSeriesReaderPrefs(null, defaults);
      expect((none.layout, none.direction, none.fit, none.zoom, none.autoScrollSpeed), ('single', 'rtl', 'height', 120, 1.5));
      final some = resolveSeriesReaderPrefs(const JsonRecord({'layout': 'double', 'zoom': 200}), defaults);
      expect((some.layout, some.direction, some.zoom), ('double', 'rtl', 200));
    });

    test('junk falls back and ranges clamp', () {
      final d = const JsonRecord({'seriesDefaults': {'layout': 'bogus', 'zoom': 9000, 'autoScrollSpeed': 0.01}}).seriesDefaults;
      expect((d.layout, d.zoom, d.autoScrollSpeed), ('strip', 300, 0.5));
    });

    test('record defaults: tap zones, brightness, ambient fields', () {
      const r = JsonRecord();
      expect((r.tapZone('left'), r.tapZone('center'), r.tapZone('right')), ('previous', 'menu', 'next'));
      expect((r.swipeSideways, r.autoNextChapter, r.resumeAfterRelease, r.pageTint), (true, true, true, true));
      expect((r.soundscape, r.pauseSoundscapeForNarration, r.paceByDialogue), ('off', false, false));
      final g = r.guidedAutoAdvance;
      expect((g.on, g.mode, g.fixedMs), (false, 'PACE_BY_WORDS', 3500));
      expect(const JsonRecord({'brightness': -200}).brightness, -75);
    });
  });

  group('novels', () {
    test('built-in book defaults', () {
      final d = readBookDefaults(const JsonRecord(), legible: false);
      expect((d.face, d.fontSize, d.lineHeight, d.measure), ('newsreader', 18, 1.6, 64));
      final l = readBookDefaults(const JsonRecord(), legible: true);
      expect((l.face, l.fontSize, l.lineHeight), ('atkinson', 18, 1.7));
      expect(builtInBookDefaults(legible: false, face: 'archivo').fontSize, 17);
    });

    test('a book with no own value follows the profile default', () {
      const defaults = BookDefaults(face: 'literata', fontSize: 22, lineHeight: 1.8, measure: 60);
      final r = resolveBookPrefs(const JsonRecord({'fontSize': 30}), defaults);
      expect((r.face, r.fontSize, r.lineHeight, r.measure), ('literata', 30, 1.8, 60));
    });

    test('with no stored default the size follows the system scale, clamped 14-40', () {
      const defaults = BookDefaults(face: 'newsreader', fontSize: 18, lineHeight: 1.6, measure: 64);
      expect(resolveBookPrefs(null, defaults, systemScale: 1.5, hasStoredDefaults: false).fontSize, 27);
      expect(resolveBookPrefs(null, defaults, systemScale: 3, hasStoredDefaults: false).fontSize, 40);
      expect(resolveBookPrefs(null, defaults, systemScale: 0.5, hasStoredDefaults: false).fontSize, 14);
    });

    test('listen defaults', () {
      const r = JsonRecord();
      expect((r.sleepDefault, r.autoPlayNext, r.keepPlayerVisible, r.shakeToExtend, r.speed), ('off', true, false, true, 1.0));
    });
  });
}
