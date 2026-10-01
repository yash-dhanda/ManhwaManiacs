import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// What a key does in the Glass novel reader (glass 8.15.8). `mobile/37` and `mobile/44` extend the reader through
/// [novelKeyBindings]' `extra` list with their own actions; they never edit this table.
enum NovelKeyAction {
  previousChapter,
  nextChapter,
  forward,
  back,
  screenForward,
  screenBack,
  chapterStart,
  chapterEnd,
  larger,
  smaller,
  resetSize,
  typeSheet,
  contents,
  bookmark,
  playPause,
  previousSentence,
  nextSentence,
  back15,
  forward15,
  slower,
  faster,
  voices,
  goTo,
  shortcuts,
  selectionMenu,
  panelNext,
  panelPrevious,
  cruise,
  cruiseSlower,
  cruiseFaster,
  soundscape,
  escape,
}

/// One binding: its activator, the `?` sheet's line, and whether it is a printable single key (the Single-key shortcuts switch
/// disables those).
class NovelKeyBinding {
  const NovelKeyBinding(this.activator, this.action, this.description, {this.printable = true, this.keys, this.desktopOnly = false});
  final SingleActivator activator;
  final NovelKeyAction action;
  final String description;
  final bool printable;
  final List<String>? keys;
  final bool desktopOnly;
}

/// The reader's table (K). `c` does nothing here (cinema is manga-only). `[`, `]`, `v` and narration `<` / `>` are `mobile/37`;
/// `a`, cruise `<` / `>` and `Shift+S` are `mobile/44`.
const List<NovelKeyBinding> kNovelKeyBindings = [
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.keyH), NovelKeyAction.previousChapter, 'Previous chapter'),
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.keyL), NovelKeyAction.nextChapter, 'Next chapter'),
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.keyJ), NovelKeyAction.forward, 'Page or screen forward'),
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.keyK), NovelKeyAction.back, 'Page or screen back'),
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.space), NovelKeyAction.screenForward, 'Page or screen forward'),
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.space, shift: true), NovelKeyAction.screenBack, 'Page or screen back', printable: false, keys: ['Shift', 'Space']),
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.arrowRight), NovelKeyAction.forward, 'Next page (paged)', printable: false),
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.arrowLeft), NovelKeyAction.back, 'Previous page (paged)', printable: false),
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.home), NovelKeyAction.chapterStart, 'Chapter start', printable: false),
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.end), NovelKeyAction.chapterEnd, 'Chapter end', printable: false),
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.equal), NovelKeyAction.larger, 'Larger text'),
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.add), NovelKeyAction.larger, 'Larger text'),
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.numpadAdd), NovelKeyAction.larger, 'Larger text'),
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.equal, shift: true), NovelKeyAction.larger, 'Larger text', keys: ['+']),
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.minus), NovelKeyAction.smaller, 'Smaller text'),
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.numpadSubtract), NovelKeyAction.smaller, 'Smaller text'),
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.digit0), NovelKeyAction.resetSize, 'Reset text size'),
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.comma), NovelKeyAction.typeSheet, 'Type and page'),
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.keyT), NovelKeyAction.contents, 'Contents'),
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.keyB), NovelKeyAction.bookmark, 'Bookmark the paragraph'),
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.keyP), NovelKeyAction.playPause, 'Play or pause the narration'),
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.keyG), NovelKeyAction.goTo, 'Go to a percentage'),
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.slash, shift: true), NovelKeyAction.shortcuts, 'Keyboard shortcuts', keys: ['?']),
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.f10, shift: true), NovelKeyAction.selectionMenu, 'Selection menu', printable: false, keys: ['Shift', 'F10']),
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.f6), NovelKeyAction.panelNext, 'Next panel', printable: false, desktopOnly: true),
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.f6, shift: true), NovelKeyAction.panelPrevious, 'Previous panel', printable: false, desktopOnly: true, keys: ['Shift', 'F6']),
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.keyA), NovelKeyAction.cruise, 'Cruise (scroll mode)'),
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.comma, shift: true), NovelKeyAction.cruiseSlower, 'Cruise slower', keys: ['<']),
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.period, shift: true), NovelKeyAction.cruiseFaster, 'Cruise faster', keys: ['>']),
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.keyS, shift: true), NovelKeyAction.soundscape, 'Soundscape', keys: ['Shift', 'S']),
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.escape), NovelKeyAction.escape, 'Close, then back to the book', printable: false),
];

/// `mobile/37`'s Listen group (glass 8.16.8, 8.15.8): `[` / `]` previous / next sentence, Shift+`[` / Shift+`]` back / forward 15 s,
/// `<` / `>` speed -/+ 0.05 while narrating (cruise speed otherwise, `mobile/44`), `v` voices. `p` is in the main table.
const List<NovelKeyBinding> kListenKeyBindings = [
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.bracketLeft), NovelKeyAction.previousSentence, 'Previous sentence'),
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.bracketRight), NovelKeyAction.nextSentence, 'Next sentence'),
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.bracketLeft, shift: true), NovelKeyAction.back15, 'Back 15 seconds', printable: false, keys: ['Shift', '[']),
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.bracketRight, shift: true), NovelKeyAction.forward15, 'Forward 15 seconds', printable: false, keys: ['Shift', ']']),
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.comma, shift: true), NovelKeyAction.slower, 'Narration slower', keys: ['<']),
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.period, shift: true), NovelKeyAction.faster, 'Narration faster', keys: ['>']),
  NovelKeyBinding(SingleActivator(LogicalKeyboardKey.keyV), NovelKeyAction.voices, 'Voices'),
];

/// The bindings live for this frame: desktop-only ones only in the desktop frame, printable ones only with Single-key shortcuts on;
/// [extra] (later steps) first, so they can claim a key.
List<NovelKeyBinding> novelKeyBindings({required bool desktopFrame, required bool singleKeys, List<NovelKeyBinding> extra = const []}) => [
      for (final b in [...extra, ...kListenKeyBindings, ...kNovelKeyBindings])
        if ((!b.desktopOnly || desktopFrame) && (!b.printable || singleKeys)) b,
    ];

/// The action [event] triggers, or null (the pure reducer the widget tests drive).
NovelKeyAction? novelKeyAction(KeyEvent event, {required bool desktopFrame, required bool singleKeys, HardwareKeyboard? keyboard}) {
  if (event is KeyUpEvent) return null;
  final kb = keyboard ?? HardwareKeyboard.instance;
  for (final b in novelKeyBindings(desktopFrame: desktopFrame, singleKeys: singleKeys)) {
    if (b.activator.accepts(event, kb)) return b.action;
  }
  return null;
}

/// The Esc order (glass 8.15.8): a menu or popover first, then a sheet or side panel, then back to the book.
enum NovelEscapeStep { closeMenu, closeSheetOrPanel, toBook }

NovelEscapeStep novelEscapeStep({required bool menuOrPopover, required bool sheetOrPanel}) =>
    menuOrPopover ? NovelEscapeStep.closeMenu : (sheetOrPanel ? NovelEscapeStep.closeSheetOrPanel : NovelEscapeStep.toBook);

/// Android back (glass 8.0.5): text selected, then a menu or popover, then the stack overview, then pop.
enum NovelBackStep { clearSelection, closeMenu, closeOverview, pop }

NovelBackStep novelBackStep({required bool selection, required bool menuOrPopover, required bool overview}) => selection
    ? NovelBackStep.clearSelection
    : menuOrPopover
        ? NovelBackStep.closeMenu
        : overview
            ? NovelBackStep.closeOverview
            : NovelBackStep.pop;

/// Whether a key event belongs to the reader (any other key restores hidden chrome, E1).
bool isReaderKey(KeyEvent e, {required bool desktopFrame, required bool singleKeys}) =>
    novelKeyAction(e, desktopFrame: desktopFrame, singleKeys: singleKeys) != null;

/// A `Shortcuts`-free dispatcher used by the screen: maps the action to [run].
KeyEventResult dispatchNovelKey(KeyEvent e, {required bool desktopFrame, required bool singleKeys, required bool Function(NovelKeyAction a) run}) {
  final a = novelKeyAction(e, desktopFrame: desktopFrame, singleKeys: singleKeys);
  if (a == null) return KeyEventResult.ignored;
  return run(a) ? KeyEventResult.handled : KeyEventResult.ignored;
}
