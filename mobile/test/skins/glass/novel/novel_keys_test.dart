import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/novel_keys.dart';

void main() {
  test('every printable binding obeys Single-key shortcuts', () {
    final on = novelKeyBindings(desktopFrame: true, singleKeys: true);
    final off = novelKeyBindings(desktopFrame: true, singleKeys: false);
    expect(off.where((b) => b.printable), isEmpty);
    expect(on.where((b) => b.printable).map((b) => b.action).toSet(), containsAll([
      NovelKeyAction.previousChapter,
      NovelKeyAction.nextChapter,
      NovelKeyAction.larger,
      NovelKeyAction.smaller,
      NovelKeyAction.resetSize,
      NovelKeyAction.typeSheet,
      NovelKeyAction.contents,
      NovelKeyAction.bookmark,
      NovelKeyAction.playPause,
      NovelKeyAction.goTo,
      NovelKeyAction.shortcuts,
    ]));
    expect(off.map((b) => b.action), contains(NovelKeyAction.escape));
  });

  test('F6 only in the desktop frame; c is never bound', () {
    expect(novelKeyBindings(desktopFrame: false, singleKeys: true).any((b) => b.action == NovelKeyAction.panelNext), isFalse);
    expect(novelKeyBindings(desktopFrame: true, singleKeys: true).any((b) => b.action == NovelKeyAction.panelNext), isTrue);
    expect(kNovelKeyBindings.any((b) => b.activator.trigger == LogicalKeyboardKey.keyC), isFalse);
  });

  test('Esc order: menu or popover, then sheet or panel, then the book', () {
    expect(novelEscapeStep(menuOrPopover: true, sheetOrPanel: true), NovelEscapeStep.closeMenu);
    expect(novelEscapeStep(menuOrPopover: false, sheetOrPanel: true), NovelEscapeStep.closeSheetOrPanel);
    expect(novelEscapeStep(menuOrPopover: false, sheetOrPanel: false), NovelEscapeStep.toBook);
  });

  test('Android back order: selection, menu, overview, pop', () {
    expect(novelBackStep(selection: true, menuOrPopover: true, overview: true), NovelBackStep.clearSelection);
    expect(novelBackStep(selection: false, menuOrPopover: true, overview: true), NovelBackStep.closeMenu);
    expect(novelBackStep(selection: false, menuOrPopover: false, overview: true), NovelBackStep.closeOverview);
    expect(novelBackStep(selection: false, menuOrPopover: false, overview: false), NovelBackStep.pop);
  });

  test('extra bindings from later steps come first', () {
    const extra = NovelKeyBinding(SingleActivator(LogicalKeyboardKey.keyV), NovelKeyAction.typeSheet, 'Voices');
    expect(novelKeyBindings(desktopFrame: false, singleKeys: true, extra: [extra]).first, same(extra));
  });
}
