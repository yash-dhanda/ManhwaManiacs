import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/storage/json_record.dart';
import 'package:manhwamaniacs/features/novels/models/glass_novel_prefs.dart';
import 'package:manhwamaniacs/features/novels/providers/glass_novel_prefs_provider.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_overrides.dart';

class _Profile extends ActiveProfileNotifier {
  _Profile(this.id);
  final int id;
  @override
  ActiveProfile? build() => ActiveProfile(id: id, name: 'P$id', avatarKey: null, mood: Mood.neutral);
}

GlassNovelValues _resolve({
  Map<String, dynamic> book = const {},
  Map<String, dynamic> settings = const {},
  Map<String, dynamic> defaults = const {},
  String? k26,
  bool legible = false,
  bool desktop = false,
  double scale = 1,
}) =>
    resolveGlassNovel(
      book: book,
      settings: JsonRecord(settings),
      defaults: JsonRecord(defaults),
      k26: k26,
      legible: legible,
      desktopFrame: desktop,
      scale: (d) => d * scale,
    );

const _book = (sourceId: 'src', seriesKey: 'ser');

Future<ProviderContainer> _container({int profile = 1, Map<String, Object> prefs = const {}}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final p = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [
    sharedPrefsProvider.overrideWithValue(p),
    authenticatedAuthOverride(),
    activeProfileProvider.overrideWith(() => _Profile(profile)),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('K26 palette to paper', () {
    const table = {
      'paper': GlassPaper.nightPaper,
      'sepia': GlassPaper.nightPaper,
      'cream': GlassPaper.nightPaper,
      'solarized-light': GlassPaper.dusk,
      'soft-grey': GlassPaper.ink,
      'dawn': GlassPaper.rosewood,
      'solarized-dark': GlassPaper.dusk,
      'forest': GlassPaper.moss,
      'rose-pine': GlassPaper.rosewood,
      'black': GlassPaper.voidPaper,
      'midnight': GlassPaper.dusk,
      'app': GlassPaper.glass,
      'dusk': GlassPaper.nightPaper, // the old warm dark swatch, #1E1B18
    };
    for (final e in table.entries) {
      test('${e.key} -> ${e.value.wire}', () => expect(_resolve(k26: e.key).paper, e.value));
    }
    test('nothing stored -> void', () => expect(_resolve().paper, GlassPaper.voidPaper));
    test('a Glass paper wins over K26; Cinematic stock is never read', () {
      expect(_resolve(k26: 'forest', settings: {'paper': 'rosewood'}).paper, GlassPaper.rosewood);
      expect(_resolve(settings: {'stock': 'moss'}).paper, GlassPaper.voidPaper);
    });

    test('every stored K26 value opens its paper and stays unchanged', () async {
      for (final e in table.entries) {
        final c = await _container(prefs: {'mm.novel-palette.u1p1': e.key});
        expect(c.read(glassNovelPrefsProvider(_book)).values(desktopFrame: false).paper, e.value, reason: e.key);
        await c.read(glassNovelPrefsProvider(_book)).setProfile({'glassPageTurn': 'lift'});
        expect(c.read(sharedPrefsProvider).getString('mm.novel-palette.u1p1'), e.key);
      }
    });
  });

  group('K25 face fallbacks', () {
    test('glassFace wins', () => expect(_resolve(book: {'glassFace': 'sans', 'face': 'atkinson'}).face, GlassFace.sans));
    test('Cinematic face', () {
      expect(_resolve(book: {'face': 'atkinson'}).face, GlassFace.atkinson);
      expect(_resolve(book: {'face': 'archivo'}).face, GlassFace.sans);
      for (final f in ['newsreader', 'literata', 'source-serif']) {
        expect(_resolve(book: {'face': f}).face, GlassFace.literata, reason: f);
      }
    });
    test('legacy fontFamily', () {
      expect(_resolve(book: {'fontFamily': 'sans'}).face, GlassFace.sans);
      expect(_resolve(book: {'fontFamily': 'serif'}).face, GlassFace.literata);
    });
    test('profile default, then Legible text, then Literata', () {
      expect(_resolve(defaults: {'glassFace': 'sans'}).face, GlassFace.sans);
      expect(_resolve(legible: true).face, GlassFace.atkinson);
      expect(_resolve().face, GlassFace.literata);
    });
  });

  group('clamps at both ends', () {
    test('size 15-30 step 1', () {
      expect(_resolve(book: {'fontSize': 3}).fontSize, 15);
      expect(_resolve(book: {'fontSize': 40}).fontSize, 30);
      expect(_resolve(book: {'fontSize': 21.4}).fontSize, 21);
    });
    test('line height 1.40-2.10 step 0.05', () {
      expect(_resolve(book: {'lineHeight': 1.3}).lineHeight, 1.40);
      expect(_resolve(book: {'lineHeight': 2.4}).lineHeight, 2.10);
      expect(_resolve(book: {'lineHeight': 1.62}).lineHeight, 1.60);
    });
    test('measure 48-88 step 2', () {
      expect(_resolve(book: {'measure': 30}).measure, 48);
      expect(_resolve(book: {'measure': 100}).measure, 88);
      expect(_resolve(book: {'measure': 63}).measure, anyOf(62, 64));
    });
    test('paragraph spacing 0-1.2 step 0.1', () {
      expect(_resolve(book: {'paragraphSpacing': -1}).paragraphSpacing, 0);
      expect(_resolve(book: {'paragraphSpacing': 2}).paragraphSpacing, 1.2);
    });
    test('character spacing -0.02 to +0.10 step 0.01', () {
      expect(_resolve(book: {'letterSpacing': -0.5}).letterSpacing, -0.02);
      expect(_resolve(book: {'letterSpacing': 0.5}).letterSpacing, 0.10);
    });
  });

  group('fallback order book -> profile default -> Glass default', () {
    test('book value', () => expect(_resolve(book: {'lineHeight': 1.5}, defaults: {'lineHeight': 1.9}).lineHeight, 1.5));
    test('profile default', () {
      final v = _resolve(defaults: {'size': 23, 'lineHeight': 1.9, 'measure': 60});
      expect(v.fontSize, 23);
      expect(v.lineHeight, 1.9);
      expect(v.measure, 60);
      expect(v.defaultSize, 23);
    });
    test('Glass defaults: 19 phone, 20 desktop frame, 1.75, 68, 0.6, 0', () {
      final p = _resolve();
      expect(p.fontSize, 19);
      expect(p.lineHeight, 1.75);
      expect(p.measure, 68);
      expect(p.paragraphSpacing, 0.6);
      expect(p.letterSpacing, 0);
      expect(_resolve(desktop: true).fontSize, 20);
      expect(p.paged, isFalse);
      expect(p.tapZones, GlassTapZones.standard);
      expect(p.pageTurn, GlassPageTurn.slide);
      expect(p.lineGuide, isFalse);
    });
  });

  group('text-scale first open', () {
    test('a book with no stored size opens at round(scale x default)', () {
      expect(_resolve(scale: 1.3).fontSize, 25);
      expect(_resolve(scale: 2).fontSize, 30);
      expect(_resolve(scale: 1.3, desktop: true).fontSize, 26);
    });
    test('a stored size is absolute', () => expect(_resolve(book: {'fontSize': 18}, scale: 2).fontSize, 18));
    test('a profile default is absolute too', () => expect(_resolve(defaults: {'size': 17}, scale: 2).fontSize, 17));
  });

  test('a Glass write keeps unknown and Cinematic fields', () async {
    final c = await _container(prefs: {
      'mm.novel-prefs.u1p1': jsonEncode({'src:ser': {'face': 'archivo', 'autoScrollSpeedX': 1.5, 'x-future': 1}}),
      'mm.novel-settings.u1p1': jsonEncode({'stock': 'moss', 'pageTurn': 'cut', 'layout': 'scroll'}),
    });
    final prefs = c.read(glassNovelPrefsProvider(_book));
    await prefs.setBook({'glassFace': 'literata', 'fontSize': 22});
    await prefs.setProfile({'paper': 'dusk', 'glassPageTurn': 'lift'});
    final sp = c.read(sharedPrefsProvider);
    final book = (jsonDecode(sp.getString('mm.novel-prefs.u1p1')!) as Map)['src:ser'] as Map;
    expect(book['face'], 'archivo');
    expect(book['autoScrollSpeedX'], 1.5);
    expect(book['x-future'], 1);
    expect(book['glassFace'], 'literata');
    final settings = jsonDecode(sp.getString('mm.novel-settings.u1p1')!) as Map;
    expect(settings['stock'], 'moss');
    expect(settings['pageTurn'], 'cut');
    expect(settings['paper'], 'dusk');
    final v = c.read(glassNovelPrefsProvider(_book)).values(desktopFrame: false);
    expect(v.face, GlassFace.literata);
    expect(v.fontSize, 22);
    expect(v.pageTurn, GlassPageTurn.lift);

    await c.read(glassNovelPrefsProvider(_book)).resetBook();
    final after = (jsonDecode(sp.getString('mm.novel-prefs.u1p1')!) as Map)['src:ser'] as Map;
    expect(after.containsKey('glassFace'), isFalse);
    expect(after.containsKey('fontSize'), isFalse);
    expect(after['face'], 'archivo');
    expect(after['x-future'], 1);
  });

  test('two profiles are isolated', () async {
    final a = await _container(profile: 1);
    await a.read(glassNovelPrefsProvider(_book)).setBook({'fontSize': 27});
    await a.read(glassNovelPrefsProvider(_book)).setProfile({'paper': 'moss'});
    final stored = Map<String, Object>.fromEntries(
      a.read(sharedPrefsProvider).getKeys().map((k) => MapEntry(k, a.read(sharedPrefsProvider).get(k)!)),
    );
    final b = await _container(profile: 2, prefs: stored);
    final vb = b.read(glassNovelPrefsProvider(_book)).values(desktopFrame: false);
    expect(vb.fontSize, 19);
    expect(vb.paper, GlassPaper.voidPaper);
    expect(stored.keys, containsAll(['mm.novel-prefs.u1p1', 'mm.novel-settings.u1p1']));
  });

  test('profile defaults live in mm.novel-defaults', () async {
    final c = await _container(prefs: {'mm.novel-defaults.u1p1': jsonEncode({'size': 24, 'glassFace': 'atkinson'})});
    final v = c.read(glassNovelPrefsProvider(_book)).values(desktopFrame: false);
    expect(v.fontSize, 24);
    expect(v.face, GlassFace.atkinson);
  });
}
