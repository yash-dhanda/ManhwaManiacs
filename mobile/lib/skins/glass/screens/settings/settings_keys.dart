import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';

/// The "Settings" shortcuts (glass 8.25 M2): `/` searches, Up and Down move between sections, Enter opens one, Esc goes back to
/// the section list.
class SettingsKeys extends StatelessWidget {
  const SettingsKeys({super.key, required this.onSearch, required this.onMove, required this.onOpen, required this.onEscape, required this.child});
  final VoidCallback onSearch, onOpen, onEscape;
  final ValueChanged<int> onMove;
  final Widget child;

  @override
  Widget build(BuildContext context) => RegisteredShortcuts(
        group: 'Settings',
        entries: [
          ShortcutEntry(group: 'Settings', activator: const SingleActivator(LogicalKeyboardKey.slash), description: 'Search settings', onInvoke: onSearch, singleKey: true, keys: const ['/']),
          ShortcutEntry(group: 'Settings', activator: const SingleActivator(LogicalKeyboardKey.arrowUp), description: 'Previous section', onInvoke: () => onMove(-1), keys: const ['↑']),
          ShortcutEntry(group: 'Settings', activator: const SingleActivator(LogicalKeyboardKey.arrowDown), description: 'Next section', onInvoke: () => onMove(1), keys: const ['↓']),
          ShortcutEntry(group: 'Settings', activator: const SingleActivator(LogicalKeyboardKey.enter), description: 'Open section', onInvoke: onOpen, keys: const ['Enter']),
          ShortcutEntry(group: 'Settings', activator: const SingleActivator(LogicalKeyboardKey.escape), description: 'Back to the section list', onInvoke: onEscape, keys: const ['Esc']),
        ],
        child: child,
      );
}
