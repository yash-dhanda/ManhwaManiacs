import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_keys.dart';

void main() {
  test('the escape order is sheet, panel, cinema, exit', () {
    expect(escapeStep(sheetOpen: true, panelOpen: true, cinema: true), ReaderEscape.closeSheet);
    expect(escapeStep(sheetOpen: false, panelOpen: true, cinema: true), ReaderEscape.closePanel);
    expect(escapeStep(sheetOpen: false, panelOpen: false, cinema: true), ReaderEscape.leaveCinema);
    expect(escapeStep(sheetOpen: false, panelOpen: false, cinema: false), ReaderEscape.exitReader);
  });

  test('only g , [ ] ? reveal the chrome', () {
    for (final k in ['g', ',', '[', ']', '?']) {
      expect(keyRevealsChrome(k), isTrue);
    }
    for (final k in ['j', 'k', 'c', 'm', 'b', 'p', 'a', 'd', ' ']) {
      expect(keyRevealsChrome(k), isFalse);
    }
  });

  test('arrows follow the reading direction', () {
    expect(arrowGoesForward(rightArrow: true, rtl: false), isTrue);
    expect(arrowGoesForward(rightArrow: false, rtl: false), isFalse);
    expect(arrowGoesForward(rightArrow: true, rtl: true), isFalse);
    expect(arrowGoesForward(rightArrow: false, rtl: true), isTrue);
  });
}
