import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/reader_keys.dart';

void main() {
  ReaderKeyAction? k(LogicalKeyboardKey key, [String? c, bool shift = false, bool ctrl = false, bool single = true]) =>
      readerKeyAction(key, c, shift: shift, ctrl: ctrl, singleKeys: single);

  test('the binding table', () {
    expect(k(LogicalKeyboardKey.arrowRight), ReaderKeyAction.pageForward);
    expect(k(LogicalKeyboardKey.keyD, 'd'), ReaderKeyAction.pageForward);
    expect(k(LogicalKeyboardKey.arrowLeft), ReaderKeyAction.pageBack);
    expect(k(LogicalKeyboardKey.keyJ, 'j'), ReaderKeyAction.nextPage);
    expect(k(LogicalKeyboardKey.keyK, 'k'), ReaderKeyAction.previousPage);
    expect(k(LogicalKeyboardKey.space, ' '), ReaderKeyAction.screenDown);
    expect(k(LogicalKeyboardKey.space, ' ', true), ReaderKeyAction.screenUp);
    expect(k(LogicalKeyboardKey.home), ReaderKeyAction.firstPage);
    expect(k(LogicalKeyboardKey.end), ReaderKeyAction.lastPage);
    expect(k(LogicalKeyboardKey.keyH, 'h'), ReaderKeyAction.previousChapter);
    expect(k(LogicalKeyboardKey.keyL, 'l'), ReaderKeyAction.nextChapter);
    expect(k(LogicalKeyboardKey.arrowRight, null, true, true), ReaderKeyAction.nextChapter);
    expect(k(LogicalKeyboardKey.arrowLeft, null, true, true), ReaderKeyAction.previousChapter);
    expect(k(LogicalKeyboardKey.keyG, 'g'), ReaderKeyAction.goToPage);
    expect(k(LogicalKeyboardKey.keyU, 'u'), ReaderKeyAction.unlock);
    expect(k(LogicalKeyboardKey.keyC, 'c'), ReaderKeyAction.cinema);
    expect(k(LogicalKeyboardKey.keyM, 'm'), ReaderKeyAction.toggleChrome);
    expect(k(LogicalKeyboardKey.keyP, 'p'), ReaderKeyAction.cruise);
    expect(k(LogicalKeyboardKey.comma, '<', true), ReaderKeyAction.cruiseSlower);
    expect(k(LogicalKeyboardKey.period, '>', true), ReaderKeyAction.cruiseFaster);
    expect(k(LogicalKeyboardKey.keyB, 'b'), ReaderKeyAction.bookmark);
    expect(k(LogicalKeyboardKey.keyT, 't'), ReaderKeyAction.chapterList);
    expect(k(LogicalKeyboardKey.comma, ','), ReaderKeyAction.settings);
    expect(k(LogicalKeyboardKey.keyS, 's'), ReaderKeyAction.series);
    expect(k(LogicalKeyboardKey.equal, '='), ReaderKeyAction.zoomIn);
    expect(k(LogicalKeyboardKey.equal, '+', true), ReaderKeyAction.zoomIn);
    expect(k(LogicalKeyboardKey.minus, '-'), ReaderKeyAction.zoomOut);
    expect(k(LogicalKeyboardKey.digit0, '0'), ReaderKeyAction.zoomReset);
    expect(k(LogicalKeyboardKey.keyW, 'w'), ReaderKeyAction.layoutStrip);
    expect(k(LogicalKeyboardKey.keyV, 'v'), ReaderKeyAction.layoutSingle);
    expect(k(LogicalKeyboardKey.keyR, 'r'), ReaderKeyAction.layoutRtl);
    expect(k(LogicalKeyboardKey.keyO, 'o'), ReaderKeyAction.dialogue);
    expect(k(LogicalKeyboardKey.keyO, 'O', true), ReaderKeyAction.dialoguePanel);
    expect(k(LogicalKeyboardKey.slash, '?', true), ReaderKeyAction.shortcuts);
    expect(k(LogicalKeyboardKey.keyN, 'n'), ReaderKeyAction.nextMatch);
    expect(k(LogicalKeyboardKey.keyN, 'N', true), ReaderKeyAction.previousMatch);
    expect(k(LogicalKeyboardKey.backslash, null, false, true), ReaderKeyAction.stackOverview);
    expect(k(LogicalKeyboardKey.f6), ReaderKeyAction.panelsNext);
    expect(k(LogicalKeyboardKey.f6, null, true), ReaderKeyAction.panelsPrevious);
    expect(k(LogicalKeyboardKey.contextMenu), ReaderKeyAction.pageMenu);
    expect(k(LogicalKeyboardKey.f10, null, true), ReaderKeyAction.pageMenu);
    expect(k(LogicalKeyboardKey.escape), ReaderKeyAction.escape);
    expect(k(LogicalKeyboardKey.keyZ, 'z'), isNull);
  });

  test('the Single-key switch off skips every printable binding', () {
    expect(k(LogicalKeyboardKey.keyJ, 'j', false, false, false), isNull);
    expect(k(LogicalKeyboardKey.comma, ',', false, false, false), isNull);
    expect(k(LogicalKeyboardKey.arrowRight, null, false, false, false), ReaderKeyAction.pageForward);
    expect(k(LogicalKeyboardKey.escape, null, false, false, false), ReaderKeyAction.escape);
  });

  test('the Esc order, step by step', () {
    var l = const ReaderLayers(menu: true, dialogue: true, panel: true, cinema: true);
    expect(escapeStep(l), ReaderEscape.closeMenu);
    l = const ReaderLayers(dialogue: true, panel: true, cinema: true);
    expect(escapeStep(l), ReaderEscape.closeDialogue);
    l = const ReaderLayers(panel: true, cinema: true);
    expect(escapeStep(l), ReaderEscape.closePanel);
    l = const ReaderLayers(cinema: true);
    expect(escapeStep(l), ReaderEscape.exitCinema);
    expect(escapeStep(const ReaderLayers()), ReaderEscape.leave);
  });

  test('the Android back order: menu, dialogue, cinema, then the sheet, then the route', () {
    expect(backStep(const ReaderLayers(menu: true, dialogue: true, cinema: true, sheet: true)), ReaderEscape.closeMenu);
    expect(backStep(const ReaderLayers(dialogue: true, cinema: true, sheet: true)), ReaderEscape.closeDialogue);
    expect(backStep(const ReaderLayers(cinema: true, sheet: true)), ReaderEscape.exitCinema);
    expect(backStep(const ReaderLayers(sheet: true)), ReaderEscape.closeSheet);
    expect(backStep(const ReaderLayers(panel: true)), ReaderEscape.leave, reason: 'panels are not in the back order');
  });
}
