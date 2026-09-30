import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart' show ShortcutEntry;

List<ShortcutEntry> catalogueShortcutEntries() {
  const a = SingleActivator(LogicalKeyboardKey.abort);
  ShortcutEntry e(String d, List<String> keys, {bool single = false}) => ShortcutEntry(group: 'Sources', activator: a, description: d, onInvoke: () {}, keys: keys, singleKey: single);
  return [
    e('Search this source', ['/'], single: true),
    e('Through the grid', ['H', 'J', 'K', 'L'], single: true),
    e('Change browse mode', ['[', ']'], single: true),
    e('Refresh', ['R'], single: true),
    e('Top / bottom', ['Home', 'End']),
  ];
}

class CatalogueKeys extends StatelessWidget {
  const CatalogueKeys({super.key, required this.onSearch, required this.onMode, required this.onRefresh, required this.onEdge, required this.child});
  final VoidCallback onSearch;
  final ValueChanged<int> onMode;
  final VoidCallback onRefresh;
  final ValueChanged<bool> onEdge;
  final Widget child;

  @override
  Widget build(BuildContext context) => Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (node, e) {
          if (e is! KeyDownEvent) return KeyEventResult.ignored;
          if (FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<EditableText>() != null) return KeyEventResult.ignored;
          final k = e.logicalKey;
          KeyEventResult hit(VoidCallback f) {
            f();
            return KeyEventResult.handled;
          }

          if (k == LogicalKeyboardKey.slash) return hit(onSearch);
          if (k == LogicalKeyboardKey.bracketRight) return hit(() => onMode(1));
          if (k == LogicalKeyboardKey.bracketLeft) return hit(() => onMode(-1));
          if (k == LogicalKeyboardKey.keyR) return hit(onRefresh);
          if (k == LogicalKeyboardKey.home) return hit(() => onEdge(true));
          if (k == LogicalKeyboardKey.end) return hit(() => onEdge(false));
          if (k == LogicalKeyboardKey.keyJ || k == LogicalKeyboardKey.keyL) return hit(() => FocusScope.of(context).nextFocus());
          if (k == LogicalKeyboardKey.keyK || k == LogicalKeyboardKey.keyH) return hit(() => FocusScope.of(context).previousFocus());
          return KeyEventResult.ignored;
        },
        child: child,
      );
}
