import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';

/// What Tonight's hardware keys call. The screen fills the callbacks; a null one makes its key do
/// nothing (cinematic 11, "Tonight" group).
class TonightCommands {
  VoidCallback? reprint; // R
  VoidCallback? continueReading; // C
  VoidCallback? previouslyOn; // P
  VoidCallback? viewCover; // V
  void Function(int delta)? sectionBy; // Down, Up
}

/// The "Tonight" group of the shortcut registry, so the `?` sheet lists it. Nothing fires while a
/// text field has focus; the single-key entries also obey the "Single-key shortcuts" preference.
class TonightShortcuts extends StatelessWidget {
  const TonightShortcuts({super.key, required this.commands, required this.child});
  final TonightCommands commands;
  final Widget child;

  @override
  Widget build(BuildContext context) => RegisteredShortcuts(
        group: 'Tonight',
        entries: [
          ShortcutEntry(
            group: 'Tonight',
            activator: const SingleActivator(LogicalKeyboardKey.keyR),
            description: 'Reprint (refresh) the issue',
            singleKey: true,
            onInvoke: () => commands.reprint?.call(),
          ),
          ShortcutEntry(
            group: 'Tonight',
            activator: const SingleActivator(LogicalKeyboardKey.keyC),
            description: 'Continue the cover story',
            singleKey: true,
            onInvoke: () => commands.continueReading?.call(),
          ),
          ShortcutEntry(
            group: 'Tonight',
            activator: const SingleActivator(LogicalKeyboardKey.keyP),
            description: 'Previously on…',
            singleKey: true,
            onInvoke: () => commands.previouslyOn?.call(),
          ),
          ShortcutEntry(
            group: 'Tonight',
            activator: const SingleActivator(LogicalKeyboardKey.keyV),
            description: 'View the cover',
            singleKey: true,
            onInvoke: () => commands.viewCover?.call(),
          ),
          ShortcutEntry(
            group: 'Tonight',
            activator: const SingleActivator(LogicalKeyboardKey.arrowDown),
            description: 'Next section',
            keys: const ['↓'],
            onInvoke: () => commands.sectionBy?.call(1),
          ),
          ShortcutEntry(
            group: 'Tonight',
            activator: const SingleActivator(LogicalKeyboardKey.arrowUp),
            description: 'Previous section',
            keys: const ['↑'],
            onInvoke: () => commands.sectionBy?.call(-1),
          ),
        ],
        child: child,
      );
}
