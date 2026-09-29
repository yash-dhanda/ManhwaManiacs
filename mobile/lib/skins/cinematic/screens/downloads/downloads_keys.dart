import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';

/// The Downloads screen's keys, registered under its masthead title (the `?` sheet lists them).
/// `Enter` (expand) and `Delete` (remove) and the arrow keys live on the focused block and row;
/// this owns the single-key ones.
class DownloadsKeys extends StatelessWidget {
  const DownloadsKeys({super.key, required this.onNext, required this.onPrevious, required this.onTogglePause, required this.child});
  final VoidCallback onNext, onPrevious, onTogglePause;
  final Widget child;

  static const String group = 'Downloads';

  @override
  Widget build(BuildContext context) => RegisteredShortcuts(
        group: group,
        entries: [
          ShortcutEntry(
            group: group,
            activator: const SingleActivator(LogicalKeyboardKey.keyJ),
            description: 'Next series',
            singleKey: true,
            onInvoke: onNext,
          ),
          ShortcutEntry(
            group: group,
            activator: const SingleActivator(LogicalKeyboardKey.keyK),
            description: 'Previous series',
            singleKey: true,
            onInvoke: onPrevious,
          ),
          ShortcutEntry(
            group: group,
            activator: const SingleActivator(LogicalKeyboardKey.keyP),
            description: 'Pause or resume all',
            singleKey: true,
            onInvoke: onTogglePause,
          ),
        ],
        child: child,
      );
}
