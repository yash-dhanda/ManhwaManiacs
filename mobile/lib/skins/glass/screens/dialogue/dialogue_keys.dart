import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart' show ShortcutEntry;

List<ShortcutEntry> dialogueShortcutEntries() {
  const a = SingleActivator(LogicalKeyboardKey.abort);
  ShortcutEntry e(String d, List<String> keys, {bool single = false}) => ShortcutEntry(group: 'Search', activator: a, description: d, onInvoke: () {}, keys: keys, singleKey: single);
  return [
    e('Focus the field', ['/'], single: true),
    e('Into the results', ['↓']),
    e('Open the hit', ['Enter']),
    e('Move between hits', ['↑', '↓']),
  ];
}
