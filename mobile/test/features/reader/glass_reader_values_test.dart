import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/storage/json_record.dart';
import 'package:manhwamaniacs/features/reader/utils/glass_reader_values.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  GlassReaderValueSet resolve(Map<String, dynamic> record, Map<String, Object?> legacy) =>
      GlassReaderValueSet.resolve(JsonRecord(record), (k) => legacy[k]);

  group('legacy fallbacks when the glass key is absent', () {
    test('K09 brightness at 0.2, 0.6 and 1.0 (kept as is), clamped below 0.2', () {
      for (final v in [0.2, 0.6, 1.0]) {
        expect(resolve({}, {'reader_brightness': v}).brightness, v);
      }
      expect(resolve({}, {'reader_brightness': 0.05}).brightness, 0.2);
      expect(resolve({}, {}).brightness, 1.0);
    });

    test('K10 warmth', () {
      expect(resolve({}, {'settings_reader_warmth': 0.0}).warmth, 0.0);
      expect(resolve({}, {'settings_reader_warmth': 0.5}).warmth, 0.5);
      expect(resolve({}, {'settings_reader_warmth': 1.0}).warmth, 1.0);
    });

    test('K11: dark is Graphite, black and white are Black, nothing is Black', () {
      expect(resolve({}, {'settings_reader_background': 'dark'}).background, 'graphite');
      expect(resolve({}, {'settings_reader_background': 'black'}).background, 'black');
      expect(resolve({}, {'settings_reader_background': 'white'}).background, 'black');
      expect(resolve({}, {}).background, 'black');
    });

    test('K05 keep awake and K07 lock controls', () {
      expect(resolve({}, {'settings_keep_screen_awake': true}).keepAwake, isTrue);
      expect(resolve({}, {}).keepAwake, isFalse);
      expect(resolve({}, {'settings_lock_reader_controls': true}).lockControls, isTrue);
    });

    test('the new-only values default per the table', () {
      final v = resolve({}, {});
      expect(v.pageTransition, 'none');
      expect(v.chapters, 'continuous');
      expect(v.tapToScroll, isFalse);
      expect(v.swipeChapter, isFalse);
      expect(v.hideCinemaProgress, isFalse);
      expect(v.pageTinted, isTrue);
    });
  });

  test('a present glass key wins over the legacy value', () {
    final v = resolve(
      {'glass': {'brightness': 0.4, 'background': 'graphite', 'keepAwake': false, 'lockControls': false, 'chapters': 'single'}},
      {'reader_brightness': 0.9, 'settings_reader_background': 'black', 'settings_keep_screen_awake': true, 'settings_lock_reader_controls': true},
    );
    expect(v.brightness, 0.4);
    expect(v.background, 'graphite');
    expect(v.keepAwake, isFalse);
    expect(v.lockControls, isFalse);
    expect(v.oneAtATime, isTrue);
  });

  test('a Glass write keeps unknown fields (Cinematic and future ones)', () {
    const record = JsonRecord({
      'gap': true,
      'pageTurn': 'slide',
      'glass': {'futureField': 7, 'brightness': 0.5},
    });
    final out = record.merge(GlassReaderValueSet.patch(record, {'warmth': 0.3}));
    expect(out.data['gap'], isTrue);
    expect(out.data['pageTurn'], 'slide');
    expect(out.glass.data, {'futureField': 7, 'brightness': 0.5, 'warmth': 0.3});
  });

  test('per-profile isolation and K01-K12 byte-identical after a Glass write', () async {
    final legacy = <String, Object>{
      'settings_reading_direction': 'rtl',
      'settings_reader_fit_mode': 'height',
      'settings_reader_tap_zones': 'retreat,toggle,advance',
      'settings_refresh_rate': 'hz120',
      'settings_keep_screen_awake': true,
      'settings_auto_next_chapter': false,
      'settings_lock_reader_controls': true,
      'settings_volume_key_navigation': true,
      'reader_brightness': 0.6,
      'settings_reader_warmth': 0.25,
      'settings_reader_background': 'dark',
      'settings_reader_color_mode': 'sepia',
    };
    SharedPreferences.setMockInitialValues(legacy);
    final prefs = await SharedPreferences.getInstance();
    final before = {for (final k in legacy.keys) k: prefs.get(k)};

    const p1 = 'mm.reader-settings.u1p1', p2 = 'mm.reader-settings.u1p2';
    final r1 = JsonRecord.decode(prefs.getString(p1));
    await prefs.setString(p1, r1.merge(GlassReaderValueSet.patch(r1, {'brightness': 0.3})).encode());

    final a = GlassReaderValueSet.resolve(JsonRecord.decode(prefs.getString(p1)), prefs.get);
    final b = GlassReaderValueSet.resolve(JsonRecord.decode(prefs.getString(p2)), prefs.get);
    expect(a.brightness, 0.3);
    expect(b.brightness, 0.6, reason: 'profile 2 still reads K09');
    expect(a.background, 'graphite');
    expect(a.keepAwake, isTrue);
    expect({for (final k in legacy.keys) k: prefs.get(k)}, before);
    expect(jsonDecode(prefs.getString(p1)!), {'glass': {'brightness': 0.3}});
  });

  test('cruise speed: per series, else the profile default, snapped to 0.05 in 0.25-4', () {
    const profile = JsonRecord({'glass': {'cruiseDefault': 1.5}});
    expect(glassCruiseSpeedOf(null, profile), 1.5);
    expect(glassCruiseSpeedOf(const JsonRecord({'cruiseSpeed': 0.1}), profile), 0.25);
    expect(glassCruiseSpeedOf(const JsonRecord({'cruiseSpeed': 2.02}), profile), 2.0);
    expect(glassCruiseSpeedOf(const JsonRecord({'cruiseSpeed': 9}), profile), 4.0);
    expect(glassCruiseSpeedOf(null, const JsonRecord()), 1.0);
    expect(cruiseMagnet(1.07), 1.0);
    expect(cruiseMagnet(1.10), 1.1);
  });
}
