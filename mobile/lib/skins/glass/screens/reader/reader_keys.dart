import 'package:flutter/services.dart';

/// What a hardware key does in the manga reader (glass 8.14.7).
enum ReaderKeyAction {
  pageForward,
  pageBack,
  nextPage,
  previousPage,
  screenDown,
  screenUp,
  firstPage,
  lastPage,
  previousChapter,
  nextChapter,
  goToPage,
  unlock,
  cinema,
  toggleChrome,
  cruise,
  cruiseSlower,
  cruiseFaster,
  bookmark,
  chapterList,
  settings,
  series,
  zoomIn,
  zoomOut,
  zoomReset,
  layoutStrip,
  layoutSingle,
  layoutRtl,
  dialogue,
  dialoguePanel,
  shortcuts,
  nextMatch,
  previousMatch,
  stackOverview,
  panelsNext,
  panelsPrevious,
  pageMenu,
  escape,
}

/// The key a binding names. [char] is matched against the event's character (so `?`, `<`, `+` and `N` work on any layout;
/// [shift] then only documents the binding).
class ReaderKey {
  const ReaderKey({this.key, this.char, this.shift = false, this.ctrl = false, this.printable = false});
  final LogicalKeyboardKey? key;
  final String? char;
  final bool shift, ctrl;

  /// A single-character binding the Single-key switch turns off.
  final bool printable;
}

ReaderKey _c(String c, {bool shift = false}) => ReaderKey(char: c, shift: shift, printable: true);

/// The binding table. `ctrl` means Ctrl or Cmd.
final Map<ReaderKeyAction, List<ReaderKey>> kReaderBindings = {
  ReaderKeyAction.pageForward: [const ReaderKey(key: LogicalKeyboardKey.arrowRight), _c('d')],
  ReaderKeyAction.pageBack: [const ReaderKey(key: LogicalKeyboardKey.arrowLeft), _c('a')],
  ReaderKeyAction.nextPage: [_c('j')],
  ReaderKeyAction.previousPage: [_c('k')],
  ReaderKeyAction.screenDown: [const ReaderKey(key: LogicalKeyboardKey.space)],
  ReaderKeyAction.screenUp: [const ReaderKey(key: LogicalKeyboardKey.space, shift: true)],
  ReaderKeyAction.firstPage: [const ReaderKey(key: LogicalKeyboardKey.home)],
  ReaderKeyAction.lastPage: [const ReaderKey(key: LogicalKeyboardKey.end)],
  ReaderKeyAction.previousChapter: [_c('h'), const ReaderKey(key: LogicalKeyboardKey.arrowLeft, ctrl: true, shift: true)],
  ReaderKeyAction.nextChapter: [_c('l'), const ReaderKey(key: LogicalKeyboardKey.arrowRight, ctrl: true, shift: true)],
  ReaderKeyAction.goToPage: [_c('g')],
  ReaderKeyAction.unlock: [_c('u')],
  ReaderKeyAction.cinema: [_c('c')],
  ReaderKeyAction.toggleChrome: [_c('m')],
  ReaderKeyAction.cruise: [_c('p')],
  ReaderKeyAction.cruiseSlower: [_c('<', shift: true)],
  ReaderKeyAction.cruiseFaster: [_c('>', shift: true)],
  ReaderKeyAction.bookmark: [_c('b')],
  ReaderKeyAction.chapterList: [_c('t')],
  ReaderKeyAction.settings: [_c(',')],
  ReaderKeyAction.series: [_c('s')],
  ReaderKeyAction.zoomIn: [_c('='), _c('+', shift: true)],
  ReaderKeyAction.zoomOut: [_c('-')],
  ReaderKeyAction.zoomReset: [_c('0')],
  ReaderKeyAction.layoutStrip: [_c('w')],
  ReaderKeyAction.layoutSingle: [_c('v')],
  ReaderKeyAction.layoutRtl: [_c('r')],
  ReaderKeyAction.dialogue: [_c('o')],
  ReaderKeyAction.dialoguePanel: [_c('O', shift: true)],
  ReaderKeyAction.shortcuts: [_c('?', shift: true)],
  ReaderKeyAction.nextMatch: [_c('n')],
  ReaderKeyAction.previousMatch: [_c('N', shift: true)],
  ReaderKeyAction.stackOverview: [const ReaderKey(key: LogicalKeyboardKey.backslash, ctrl: true)],
  ReaderKeyAction.panelsNext: [const ReaderKey(key: LogicalKeyboardKey.f6)],
  ReaderKeyAction.panelsPrevious: [const ReaderKey(key: LogicalKeyboardKey.f6, shift: true)],
  ReaderKeyAction.pageMenu: [const ReaderKey(key: LogicalKeyboardKey.contextMenu), const ReaderKey(key: LogicalKeyboardKey.f10, shift: true)],
  ReaderKeyAction.escape: [const ReaderKey(key: LogicalKeyboardKey.escape)],
};

/// The action of a key down: [char] is the event's character, [shift] and [ctrl] the modifiers (Ctrl or Cmd).
/// [singleKeys] false skips every printable binding.
ReaderKeyAction? readerKeyAction(LogicalKeyboardKey key, String? char, {bool shift = false, bool ctrl = false, bool singleKeys = true}) {
  for (final e in kReaderBindings.entries) {
    for (final b in e.value) {
      if (b.printable && !singleKeys) continue;
      if (b.ctrl != ctrl) continue;
      // A character binding matches the character typed: the case and the symbol already carry shift.
      if (b.char != null) {
        if (char == b.char) return e.key;
        continue;
      }
      if (b.key == key && b.shift == shift) return e.key;
    }
  }
  return null;
}

/// What the reader has open, for the Esc and Android back order.
class ReaderLayers {
  const ReaderLayers({this.menu = false, this.dialogue = false, this.panel = false, this.cinema = false, this.sheet = false});

  /// A menu, popover or picker.
  final bool menu;

  /// The dialogue overlay or the hit lens.
  final bool dialogue;

  /// A desktop-frame side panel.
  final bool panel;
  final bool cinema;

  /// A reader sheet (Android back only: the sheet route pops first).
  final bool sheet;
}

enum ReaderEscape { closeMenu, closeDialogue, closePanel, exitCinema, closeSheet, leave }

/// Esc (glass 8.14.7): menu or popover, then the dialogue overlay and hit lens, then a side panel, then cinema, then leave.
ReaderEscape escapeStep(ReaderLayers l) {
  if (l.menu) return ReaderEscape.closeMenu;
  if (l.dialogue) return ReaderEscape.closeDialogue;
  if (l.panel) return ReaderEscape.closePanel;
  if (l.cinema) return ReaderEscape.exitCinema;
  return ReaderEscape.leave;
}

/// Android back (glass 8.0.5 rows 2, 6 and 8): an open menu, popover or picker, then the dialogue overlay and hit lens, then
/// cinema, then the route pops (sheets first).
ReaderEscape backStep(ReaderLayers l) {
  if (l.menu) return ReaderEscape.closeMenu;
  if (l.dialogue) return ReaderEscape.closeDialogue;
  if (l.cinema) return ReaderEscape.exitCinema;
  if (l.sheet) return ReaderEscape.closeSheet;
  return ReaderEscape.leave;
}
