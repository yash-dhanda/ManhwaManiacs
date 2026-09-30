import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/storage/json_record.dart';
import 'package:manhwamaniacs/features/novels/models/novel_typography.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_preferences_provider.dart';

NovelType resolve({Map<String, dynamic> book = const {}, Map<String, dynamic> profile = const {}, bool legible = false, double scale = 1, bool tablet = false, bool osBold = false}) =>
    resolveNovelType(
      book: NovelPreferences.fromJson(book),
      settings: JsonRecord(profile),
      legible: legible,
      systemScale: scale,
      tablet: tablet,
      osBold: osBold,
    );

void main() {
  test('faceDefaults: phone/tablet sizes and leading per face', () {
    expect(faceDefaults(NovelFace.newsreader, tablet: false), (size: 18.0, leading: 1.60));
    expect(faceDefaults(NovelFace.newsreader, tablet: true), (size: 19.0, leading: 1.60));
    expect(faceDefaults(NovelFace.archivo, tablet: false), (size: 17.0, leading: 1.60));
    expect(faceDefaults(NovelFace.archivo, tablet: true), (size: 18.0, leading: 1.60));
    expect(faceDefaults(NovelFace.atkinson, tablet: false), (size: 18.0, leading: 1.70));
  });

  test('no stored size opens at the system-scaled face default: 36 px at 2.0 in Newsreader, 34 in Archivo', () {
    expect(resolve(scale: 2).fontSize, 36);
    expect(resolve(book: {'face': 'archivo'}, scale: 2).fontSize, 34);
    expect(resolve(scale: 1).fontSize, 18);
    expect(resolve(scale: 3).fontSize, 40);
    expect(resolve(scale: 0.5).fontSize, 14);
  });

  test('a stored size is absolute and is never scaled again', () {
    expect(resolve(book: {'fontSize': 30}, scale: 2).fontSize, 30);
    // The legacy view still clamps to 15-26 but the stored 30 survives.
    final p = NovelPreferences.fromJson({'fontSize': 30});
    expect(p.fontSize, 26);
    expect(p.storedSize, 30);
    expect(p.copyWith(fontFamily: NovelFontFamily.sans).toJson()['fontSize'], 30);
  });

  test('face: stored, legacy fontFamily fallback, profile default, Hyperlegible default', () {
    expect(resolve(book: {'face': 'literata'}).face, NovelFace.literata);
    expect(resolve(book: {'fontFamily': 'serif'}).face, NovelFace.newsreader);
    expect(resolve(book: {'fontFamily': 'sans'}).face, NovelFace.archivo);
    expect(resolve().face, NovelFace.newsreader);
    expect(resolve(legible: true).face, NovelFace.atkinson);
    expect(resolve(book: {'face': 'newsreader'}, legible: true).face, NovelFace.newsreader);
    expect(resolve(profile: {'bookDefaults': {'face': 'literata', 'fontSize': 21}}).fontSize, 21);
  });

  test('range clamps', () {
    final t = resolve(book: {'fontSize': 99, 'lineHeight': 9, 'measure': 500, 'paragraphSpacing': 9, 'letterSpacing': -1});
    expect(t.fontSize, 40);
    expect(t.lineHeight, 2.10);
    expect(t.measure, 88);
    expect(t.paragraphSpacing, 1.2);
    expect(t.letterSpacing, -0.02);
    expect(resolve().measure, 64);
    expect(clampCineLeading(1.62), 1.6);
    expect(clampCineMeasure(65), 66);
  });

  test('profile flags: bold, OS bold, justify; wght axis', () {
    expect(resolve().wght, 400);
    expect(resolve(profile: {'bold': true}).wght, 520);
    expect(resolve(osBold: true).wght, 520);
    expect(resolve(profile: {'bold': true}, osBold: true).wght, 640);
    expect(resolve(profile: {'justify': true}).justify, isTrue);
    expect(resolve(book: {'face': 'newsreader'}, profile: {'bold': true}, osBold: true).wght, 640);
  });

  test('unknown fields survive a legacy write; resetType clears the per-book keys', () {
    final p = NovelPreferences.fromJson({'face': 'literata', 'mystery': 1, 'fontSize': 22});
    final w = p.copyWith(lineHeight: 1.8).toJson();
    expect(w['mystery'], 1);
    expect(w['face'], 'literata');
    expect(p.withRaw({'face': null, 'fontSize': null}).toJson().containsKey('face'), isFalse);
  });
}
