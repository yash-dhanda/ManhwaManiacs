import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart' show ShortcutEntry;

List<ShortcutEntry> sourcesShortcutEntries() {
  const a = SingleActivator(LogicalKeyboardKey.abort);
  ShortcutEntry e(String d, List<String> keys, {bool single = false}) => ShortcutEntry(group: 'Sources', activator: a, description: d, onInvoke: () {}, keys: keys, singleKey: single);
  return [
    e('Filter sources', ['/'], single: true),
    e('Between rows', ['↑', '↓']),
    e('Open', ['Enter']),
    e('Pin or unpin', ['P'], single: true),
    e('Move a pin', ['Alt+↑', 'Alt+↓']),
    e('Refresh', ['R'], single: true),
  ];
}

/// `/` and `r` on the Sources screen, never while typing; `p` is handled by each row.
class SourcesKeys extends StatelessWidget {
  const SourcesKeys({super.key, required this.onFilter, required this.onRefresh, required this.child});
  final VoidCallback onFilter;
  final VoidCallback onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) => Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<EditableText>() != null) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.slash) {
            onFilter();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.keyR) {
            onRefresh();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: child,
      );
}
