import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart' show ShortcutEntry;

/// The Search keys listed in the shortcuts sheet under "Search" (glass 8.9). The handlers live on [SearchKeys] itself.
List<ShortcutEntry> searchShortcutEntries() {
  const a = SingleActivator(LogicalKeyboardKey.abort);
  ShortcutEntry e(String d, List<String> keys, {bool single = false}) => ShortcutEntry(group: 'Search', activator: a, description: d, onInvoke: () {}, keys: keys, singleKey: single);
  return [
    e('Focus the field', ['/'], single: true),
    e('Into the results', ['↓']),
    e('Change scope', ['[', ']'], single: true),
    e('Next / previous group', ['Shift+J', 'Shift+K']),
    e('Search now', ['Enter']),
    e('Clear, then leave', ['Esc']),
  ];
}

/// Wraps the results with the scope and group keys.
class SearchKeys extends StatelessWidget {
  const SearchKeys({super.key, required this.onScope, required this.onGroup, required this.child});
  final ValueChanged<int> onScope;
  final ValueChanged<int> onGroup;
  final Widget child;

  @override
  Widget build(BuildContext context) => Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          // Never steal keys while a text field has focus.
          final primary = FocusManager.instance.primaryFocus?.context;
          if (primary?.findAncestorWidgetOfExactType<EditableText>() != null) return KeyEventResult.ignored;
          final k = event.logicalKey;
          final shift = HardwareKeyboard.instance.isShiftPressed;
          if (k == LogicalKeyboardKey.bracketLeft) {
            onScope(-1);
            return KeyEventResult.handled;
          }
          if (k == LogicalKeyboardKey.bracketRight) {
            onScope(1);
            return KeyEventResult.handled;
          }
          if (shift && k == LogicalKeyboardKey.keyJ) {
            onGroup(1);
            return KeyEventResult.handled;
          }
          if (shift && k == LogicalKeyboardKey.keyK) {
            onGroup(-1);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: child,
      );
}
