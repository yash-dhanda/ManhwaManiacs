import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/novel_keys.dart';

void main() {
  test('escape order: field, sheet, panel, book', () {
    expect(novelEscapeStep(progressFieldOpen: true, sheetOpen: true, panelOpen: true), NovelEscape.cancelProgressField);
    expect(novelEscapeStep(progressFieldOpen: false, sheetOpen: true, panelOpen: true), NovelEscape.closeSheet);
    expect(novelEscapeStep(progressFieldOpen: false, sheetOpen: false, panelOpen: true), NovelEscape.closePanel);
    expect(novelEscapeStep(progressFieldOpen: false, sheetOpen: false, panelOpen: false), NovelEscape.exitReader);
  });

  test('size keys clamp to 14-40 and 0 resets to the face default', () {
    expect(novelKeySize(40, step: 1, faceDefault: 18), 40);
    expect(novelKeySize(14, step: -1, faceDefault: 18), 14);
    expect(novelKeySize(30, reset: true, faceDefault: 18), 18);
  });

  test('single-key setting disables unmodified bindings only', () {
    expect(novelSingleKeyLive(singleKeyEnabled: false, modified: false), isFalse);
    expect(novelSingleKeyLive(singleKeyEnabled: false, modified: true), isTrue);
    expect(novelKeyRevealsChrome('g'), isTrue);
    expect(novelKeyRevealsChrome('j'), isFalse);
  });
}
