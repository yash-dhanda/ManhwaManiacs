import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/storage/json_record.dart';
import 'package:manhwamaniacs/features/reader/models/reader_prefs.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_prefs_migration.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _a = 'mm.reader-settings.u1p1';
const _b = 'mm.reader-settings.u1p2';

Future<SharedPreferences> _prefs(Map<String, Object> v) async {
  SharedPreferences.setMockInitialValues(v);
  return SharedPreferences.getInstance();
}

Map<String, dynamic> _rec(SharedPreferences p, String k) => jsonDecode(p.getString(k)!) as Map<String, dynamic>;

void main() {
  test('K09 brightness formula at its end points and a middle value', () {
    expect(brightnessFromLegacy(0.2), -75);
    expect(brightnessFromLegacy(0.6), -38);
    expect(brightnessFromLegacy(1.0), 0);
  });

  test('K10 warmth, K11 ground, K12 colour', () {
    expect(warmthFromLegacy(0), 0);
    expect(warmthFromLegacy(0.5), 50);
    expect(warmthFromLegacy(1), 100);
    expect(groundFromLegacy('dark'), 'ink');
    expect(groundFromLegacy('black'), 'black');
    expect(groundFromLegacy('white'), 'slate');
    expect(colourFromLegacy('grayscale'), 'grey');
    expect(colourFromLegacy('sepia'), 'sepia');
    expect(colourFromLegacy('normal'), 'normal');
  });

  test('K01, K02, K03 and K06 map to the profile defaults', () async {
    final p = await _prefs({
      LegacyReaderKeys.direction: 'rightToLeft',
      LegacyReaderKeys.fit: 'screen',
      LegacyReaderKeys.tapZones: 'retreat,toggle,advance',
      LegacyReaderKeys.autoNext: false,
    });
    final d = legacyDefaultsOf(p);
    expect(d['seriesDefaults'], {'layout': 'single', 'direction': 'rtl', 'fit': 'height'});
    expect(d['tapZone.left'], 'previous');
    expect(d['tapZone.center'], 'menu');
    expect(d['tapZone.right'], 'next');
    expect(d['autoNextChapter'], false);
    expect(legacyDefaultsOf(await _prefs({LegacyReaderKeys.direction: 'vertical', LegacyReaderKeys.fit: 'width'}))['seriesDefaults'],
        {'layout': 'strip', 'fit': 'width'});
    expect(legacyDefaultsOf(await _prefs({LegacyReaderKeys.direction: 'leftToRight'}))['seriesDefaults'], {'layout': 'single', 'direction': 'ltr'});
    expect(legacyDefaultsOf(await _prefs({})).containsKey('tapZone.left'), isFalse, reason: 'unset stays automatic');
  });

  test('copies into every profile once, keeps unknown fields and profile values, never touches legacy keys', () async {
    final p = await _prefs({
      LegacyReaderKeys.brightness: 0.6,
      LegacyReaderKeys.background: 'dark',
      LegacyReaderKeys.direction: 'vertical',
      _a: jsonEncode({'brightness': -10, 'future': 'kept'}),
    });
    expect(await migrateReaderPrefs(p, profileKeys: [_a, _b]), isTrue);
    final a = _rec(p, _a), b = _rec(p, _b);
    expect(a['brightness'], -10, reason: 'profile value wins');
    expect(a['future'], 'kept');
    expect(a['ground'], 'ink');
    expect(b['brightness'], -38);
    expect(b['seriesDefaults'], {'layout': 'strip'});
    expect(p.getDouble(LegacyReaderKeys.brightness), 0.6);
    expect(p.getString(LegacyReaderKeys.background), 'dark');
    expect(readerPrefsSeed(p)['brightness'], -38);
  });

  test('idempotent: a second run changes nothing, and profiles stay isolated', () async {
    final p = await _prefs({LegacyReaderKeys.warmth: 0.25});
    await migrateReaderPrefs(p, profileKeys: [_a, _b]);
    await p.setString(_a, jsonEncode({..._rec(p, _a), 'warmth': 80}));
    final before = {for (final k in [_a, _b]) k: p.getString(k)};
    expect(await migrateReaderPrefs(p, profileKeys: [_a, _b]), isFalse);
    expect({for (final k in [_a, _b]) k: p.getString(k)}, before);
    expect(_rec(p, _a)['warmth'], 80);
    expect(_rec(p, _b)['warmth'], 25);
  });

  test('ReaderPrefs resolves series over profile over built-ins', () {
    final profile = const JsonRecord({
      'seriesDefaults': {'layout': 'single', 'direction': 'rtl', 'zoom': 120},
      'brightness': -40,
      'ground': 'slate',
      'sideMargin': 10,
      'tapZone.left': 'menu',
      'panels': {'left': true, 'lastOpened': 'left'},
    });
    final p = ReaderPrefs.resolve(profile, const JsonRecord({'zoom': 200, 'direction': 'ltr'}));
    expect(p.layout, 'single');
    expect(p.direction, 'ltr');
    expect(p.zoom, 2.0);
    expect(p.brightness, -40);
    expect(p.ground, 'slate');
    expect(p.sideMarginPct, 10);
    expect(p.tapZones, ['menu', 'menu', 'next']);
    expect(p.panels.left, isTrue);
    expect(p.panels.lastOpened, 'left');
    final d = ReaderPrefs.resolve(const JsonRecord(), null);
    expect(d.layout, 'strip');
    expect(d.zoom, 1.0);
    expect(d.tapZones, isNull);
    expect(d.swipeChapter, isTrue);
    expect(d.autoNextChapter, isTrue);
  });
}
