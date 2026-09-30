import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';

/// Settings' hardware-keyboard keys (tablets), registered under the group `Settings`.
class SettingsKeys extends StatelessWidget {
  const SettingsKeys({
    super.key,
    required this.onSearch,
    required this.onNext,
    required this.onPrevious,
    required this.onOpen,
    required this.onEscape,
    required this.child,
  });

  final VoidCallback onSearch, onNext, onPrevious, onOpen, onEscape;
  final Widget child;

  static const String group = 'Settings';

  @override
  Widget build(BuildContext context) => RegisteredShortcuts(
        group: group,
        entries: [
          ShortcutEntry(group: group, activator: const SingleActivator(LogicalKeyboardKey.slash), description: 'Search settings', singleKey: true, onInvoke: onSearch),
          ShortcutEntry(group: group, activator: const SingleActivator(LogicalKeyboardKey.keyJ), description: 'Next section', singleKey: true, onInvoke: onNext),
          ShortcutEntry(group: group, activator: const SingleActivator(LogicalKeyboardKey.keyK), description: 'Previous section', singleKey: true, onInvoke: onPrevious),
          ShortcutEntry(group: group, activator: const SingleActivator(LogicalKeyboardKey.enter), description: 'Open the section', onInvoke: onOpen),
          ShortcutEntry(group: group, activator: const SingleActivator(LogicalKeyboardKey.escape), description: 'Back to the sections', onInvoke: onEscape),
        ],
        child: child,
      );
}
