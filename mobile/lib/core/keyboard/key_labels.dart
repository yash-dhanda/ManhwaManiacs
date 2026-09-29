import 'package:flutter/services.dart';

/// The label a hardware-keyboard combo is printed with: Mac glyphs on iOS
/// (`⌘K`), words on Android (`Ctrl K`).
String formatKeyCombo(List<LogicalKeyboardKey> keys, TargetPlatform platform) {
  final ios = platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
  String one(LogicalKeyboardKey k) {
    if (k == LogicalKeyboardKey.meta || k == LogicalKeyboardKey.metaLeft || k == LogicalKeyboardKey.metaRight) return ios ? '⌘' : 'Meta';
    if (k == LogicalKeyboardKey.control || k == LogicalKeyboardKey.controlLeft || k == LogicalKeyboardKey.controlRight) return ios ? '⌃' : 'Ctrl';
    if (k == LogicalKeyboardKey.alt || k == LogicalKeyboardKey.altLeft || k == LogicalKeyboardKey.altRight) return ios ? '⌥' : 'Alt';
    if (k == LogicalKeyboardKey.shift || k == LogicalKeyboardKey.shiftLeft || k == LogicalKeyboardKey.shiftRight) return ios ? '⇧' : 'Shift';
    if (k == LogicalKeyboardKey.delete || k == LogicalKeyboardKey.backspace) return ios ? '⌫' : 'Del';
    if (k == LogicalKeyboardKey.arrowUp) return '↑';
    if (k == LogicalKeyboardKey.arrowDown) return '↓';
    if (k == LogicalKeyboardKey.arrowLeft) return '←';
    if (k == LogicalKeyboardKey.arrowRight) return '→';
    if (k == LogicalKeyboardKey.escape) return 'Esc';
    if (k == LogicalKeyboardKey.enter) return '↵';
    if (k == LogicalKeyboardKey.space) return 'Space';
    if (k == LogicalKeyboardKey.tab) return 'Tab';
    final l = k.keyLabel;
    return l.length == 1 ? l.toUpperCase() : l;
  }

  return keys.map(one).join(ios ? '' : ' ');
}
