import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// What the series page's hardware keys call. The page and its panels fill the
/// callbacks they own; a null one makes its key do nothing.
class FeatureCommands {
  VoidCallback? continueReading; // Enter, C
  VoidCallback? previouslyOn; // P (only while a recap is available)
  VoidCallback? readAll; // A
  VoidCallback? listen; // L (Book)
  VoidCallback? viewCover; // V
  VoidCallback? favorite; // F
  VoidCallback? notify; // N
  VoidCallback? toggleFollow; // +
  VoidCallback? download; // D
  VoidCallback? select; // X
  VoidCallback? goTo; // /
  VoidCallback? toggleOrder; // O
  VoidCallback? move; // M
  void Function(int index)? tab; // 1..n
  void Function(int delta)? tabBy; // [ ]
  void Function(int delta)? chapterBy; // J K
}

/// The "Series" key group (DESIGN §11). Never fires while a text field has
/// focus, or with a Ctrl / Meta / Alt chord.
class FeatureShortcuts extends StatelessWidget {
  const FeatureShortcuts({super.key, required this.commands, required this.child, this.book = false});

  final FeatureCommands commands;
  final Widget child;
  final bool book;

  static bool typing() {
    final ctx = FocusManager.instance.primaryFocus?.context;
    if (ctx == null) return false;
    return ctx.widget is EditableText || ctx.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  KeyEventResult _key(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final k = HardwareKeyboard.instance;
    if (k.isControlPressed || k.isMetaPressed || k.isAltPressed) return KeyEventResult.ignored;
    if (typing()) return KeyEventResult.ignored;
    final key = e.logicalKey;
    final c = commands;
    VoidCallback? run;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.keyC) {
      run = c.continueReading;
    } else if (key == LogicalKeyboardKey.keyP) {
      run = c.previouslyOn;
    } else if (key == LogicalKeyboardKey.keyV) {
      run = c.viewCover;
    } else if (key == LogicalKeyboardKey.add ||
        key == LogicalKeyboardKey.numpadAdd ||
        (key == LogicalKeyboardKey.equal && k.isShiftPressed)) {
      run = c.toggleFollow;
    } else if (key == LogicalKeyboardKey.keyD) {
      run = c.download;
    } else if (key == LogicalKeyboardKey.slash) {
      run = c.goTo;
    } else if (key == LogicalKeyboardKey.keyO) {
      run = c.toggleOrder;
    } else if (book) {
      if (key == LogicalKeyboardKey.keyL) run = c.listen;
    } else {
      if (key == LogicalKeyboardKey.keyA) {
        run = c.readAll;
      } else if (key == LogicalKeyboardKey.keyF) {
        run = c.favorite;
      } else if (key == LogicalKeyboardKey.keyN) {
        run = c.notify;
      } else if (key == LogicalKeyboardKey.keyX) {
        run = c.select;
      } else if (key == LogicalKeyboardKey.keyM) {
        run = c.move;
      } else if (key == LogicalKeyboardKey.keyJ) {
        run = c.chapterBy == null ? null : () => c.chapterBy!(1);
      } else if (key == LogicalKeyboardKey.keyK) {
        run = c.chapterBy == null ? null : () => c.chapterBy!(-1);
      } else if (key == LogicalKeyboardKey.bracketRight) {
        run = c.tabBy == null ? null : () => c.tabBy!(1);
      } else if (key == LogicalKeyboardKey.bracketLeft) {
        run = c.tabBy == null ? null : () => c.tabBy!(-1);
      } else {
        final digit = int.tryParse(key.keyLabel);
        if (digit != null && digit >= 1 && c.tab != null) run = () => c.tab!(digit - 1);
      }
    }
    if (run == null) return KeyEventResult.ignored;
    run();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) =>
      Focus(autofocus: true, onKeyEvent: _key, child: child);
}
