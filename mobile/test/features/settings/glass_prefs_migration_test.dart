import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/utils/glass_reader_values.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_prefs_migration.dart';
import 'package:manhwamaniacs/features/settings/utils/glass_prefs_migration.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> _prefs(Map<String, Object> seed) async {
  SharedPreferences.setMockInitialValues(seed);
  return SharedPreferences.getInstance();
}

Map<String, Object?> _snapshot(SharedPreferences p, Iterable<String> keys) => {for (final k in keys) k: p.get(k)};

const _oldKeys = ['reader_brightness', 'settings_reader_warmth', 'settings_reader_background', 'settings_keep_screen_awake', 'settings_library_cover_scale'];

void main() {
  group('pure rows', () {
    test('K15 cover scale: under 0.85 is 4 columns, 0.85 to 1.25 is 3, over 1.25 is 2', () {
      expect(libraryColumnsFromCoverScale(0.5), 4);
      expect(libraryColumnsFromCoverScale(0.84), 4);
      expect(libraryColumnsFromCoverScale(0.85), 3);
      expect(libraryColumnsFromCoverScale(1.0), 3);
      expect(libraryColumnsFromCoverScale(1.25), 3);
      expect(libraryColumnsFromCoverScale(1.26), 2);
      expect(libraryColumnsFromCoverScale(1.6), 2);
    });

    test('K11 reader background: dark is Graphite, AMOLED and Paper are Black, unknown is nothing', () {
      expect(glassBackgroundFromLegacy('dark'), 'graphite');
      expect(glassBackgroundFromLegacy('black'), 'black');
      expect(glassBackgroundFromLegacy('white'), 'black');
      expect(glassBackgroundFromLegacy('sepia'), isNull);
      expect(glassBackgroundFromLegacy(null), isNull);
    });

    test('K01 and K02 seed each series entry through the shared seeding: leftToRight and rightToLeft open Single paged', () async {
      final ltr = await _prefs({LegacyReaderKeys.direction: 'leftToRight', LegacyReaderKeys.fit: 'height'});
      expect(legacyDefaultsOf(ltr)['seriesDefaults'], {'layout': 'single', 'direction': 'ltr', 'fit': 'height'});
      final rtl = await _prefs({LegacyReaderKeys.direction: 'rightToLeft'});
      expect(legacyDefaultsOf(rtl)['seriesDefaults'], {'layout': 'single', 'direction': 'rtl'});
    });

    test('cruise speed: a snap to the 0.05 grid, a log track with 1.0x inside it', () {
      expect(snapCruise(0.1), 0.25);
      expect(snapCruise(9), 4.0);
      expect(snapCruise(1.03), 1.05);
      expect(trackToCruise(cruiseToTrack(1.0)), 1.0);
      expect(trackToCruise(0), 0.25);
      expect(trackToCruise(1), 4.0);
      expect(cruiseToTrack(1.0), closeTo(0.5, 1e-9));
    });
  });

  group('runGlassPrefsMigration', () {
    test('brightness and warmth are kept as they are at both ends and in the middle', () async {
      for (final (b, w) in [(0.2, 0.0), (0.6, 0.5), (1.0, 1.0)]) {
        final p = await _prefs({'reader_brightness': b, 'settings_reader_warmth': w});
        expect(await runGlassPrefsMigration(p, userId: 1, profileId: 2), true);
        final g = readerRecordOf(p, 1, 2).glass;
        expect(g.doubleOf('brightness', -1), b);
        expect(g.doubleOf('warmth', -1), w);
      }
    });

    test('K11 and K05 land as the Graphite/Black background and the seeded keepAwake', () async {
      final a = await _prefs({'settings_reader_background': 'dark', 'settings_keep_screen_awake': true});
      await runGlassPrefsMigration(a, userId: 1, profileId: 1);
      expect(readerRecordOf(a, 1, 1).glassBackground, 'graphite');
      expect(readerRecordOf(a, 1, 1).glassKeepAwake, true);
      final b = await _prefs({'settings_reader_background': 'white', 'settings_keep_screen_awake': false});
      await runGlassPrefsMigration(b, userId: 1, profileId: 1);
      expect(readerRecordOf(b, 1, 1).glassBackground, 'black');
      expect(readerRecordOf(b, 1, 1).glassKeepAwake, false);
    });

    test('K15 writes the library columns through the threshold function', () async {
      for (final (scale, cols) in [(0.6, 4), (1.0, 3), (1.5, 2)]) {
        final p = await _prefs({'settings_library_cover_scale': scale});
        await runGlassPrefsMigration(p, userId: 1, profileId: 1);
        expect(jsonDecode(p.getString('mm.glass.prefs.u1p1')!)['libraryColumns'], cols);
      }
    });

    test('nothing stored on the device: nothing is written except the marker', () async {
      final p = await _prefs({});
      await runGlassPrefsMigration(p, userId: 1, profileId: 1);
      expect(p.getKeys(), {glassMigratedKey(1, 1)});
    });

    test('idempotent: a second run changes nothing, even after the device values change', () async {
      final p = await _prefs({'reader_brightness': 0.5, 'settings_library_cover_scale': 1.0});
      expect(await runGlassPrefsMigration(p, userId: 1, profileId: 1), true);
      final keys = p.getKeys().toList();
      final before = _snapshot(p, keys);
      await p.setDouble('reader_brightness', 0.9);
      expect(await runGlassPrefsMigration(p, userId: 1, profileId: 1), false);
      expect(_snapshot(p, keys)..remove('reader_brightness'), before..remove('reader_brightness'));
      expect(readerRecordOf(p, 1, 1).glassBrightness, 0.5);
    });

    test('two profiles are isolated: each has its own marker and record, and a profile created later starts from the device values', () async {
      final p = await _prefs({'reader_brightness': 0.4});
      await runGlassPrefsMigration(p, userId: 1, profileId: 1);
      await p.setDouble('reader_brightness', 0.8);
      await runGlassPrefsMigration(p, userId: 1, profileId: 2);
      expect(readerRecordOf(p, 1, 1).glassBrightness, 0.4);
      expect(readerRecordOf(p, 1, 2).glassBrightness, 0.8);
      expect(p.getBool(glassMigratedKey(1, 1)), true);
      expect(p.getBool(glassMigratedKey(1, 2)), true);
      expect(p.getBool(glassMigratedKey(2, 1)), isNull);
    });

    test('every old key is byte for byte unchanged and a Glass field the profile already holds is kept', () async {
      final p = await _prefs({
        'reader_brightness': 0.33,
        'settings_reader_warmth': 0.25,
        'settings_reader_background': 'black',
        'settings_keep_screen_awake': true,
        'settings_library_cover_scale': 1.4,
        'mm.reader-settings.u1p1': jsonEncode({'gap': true, 'glass': {'brightness': 0.9, 'other': 7}}),
      });
      final before = _snapshot(p, _oldKeys);
      await runGlassPrefsMigration(p, userId: 1, profileId: 1);
      expect(_snapshot(p, _oldKeys), before);
      final r = readerRecordOf(p, 1, 1);
      expect(r.boolOf('gap', false), true);
      expect(r.glass.doubleOf('brightness', 0), 0.9, reason: 'an existing Glass field wins');
      expect(r.glass.intOf('other', 0), 7);
      expect(r.glassWarmth, 0.25);
    });
  });
}
