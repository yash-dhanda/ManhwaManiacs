import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';

/// What the shelf's hardware keys call (cinematic 11, "Library" group). The screen fills the
/// callbacks; a null one makes its key do nothing.
class LibraryCommands {
  VoidCallback? search; // /
  void Function(int dx, int dy)? move; // H J K L and the arrows
  VoidCallback? home, end; // Home, End
  VoidCallback? selectMode; // X
  VoidCallback? favouriteFocused; // F
  void Function(int index)? status; // 1-7
  VoidCallback? cycleSort; // S
  VoidCallback? cycleDensity; // V
  VoidCallback? selectAll; // Ctrl/Cmd + A
  VoidCallback? reprint; // R
  void Function(int dx, int dy)? moveItem; // Alt + arrows (Manual order)
}

/// The "Library" group of the shortcut registry. Nothing fires while a text field has focus; the
/// single-key entries also obey the "Single-key shortcuts" preference. `Enter` and `Space` are the
/// focused poster's own activation (open, or toggle in select mode).
class LibraryShortcuts extends StatelessWidget {
  const LibraryShortcuts({super.key, required this.commands, required this.child});
  final LibraryCommands commands;
  final Widget child;

  static const _g = 'Library';

  ShortcutEntry _key(LogicalKeyboardKey k, String d, VoidCallback f, {List<String>? keys}) =>
      ShortcutEntry(group: _g, activator: SingleActivator(k), description: d, singleKey: true, keys: keys, onInvoke: f);

  ShortcutEntry _plain(LogicalKeyboardKey k, String d, VoidCallback f, {List<String>? keys}) =>
      ShortcutEntry(group: _g, activator: SingleActivator(k), description: d, keys: keys, onInvoke: f);

  @override
  Widget build(BuildContext context) {
    final c = commands;
    const digits = [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
      LogicalKeyboardKey.digit7,
    ];
    const words = ['All', 'Reading', 'Not started', 'Done', 'On hold', 'Plan to read', 'Dropped'];
    return RegisteredShortcuts(
      group: _g,
      entries: [
        _key(LogicalKeyboardKey.slash, 'Search your shelf', () => c.search?.call()),
        _key(LogicalKeyboardKey.keyH, 'Move left', () => c.move?.call(-1, 0)),
        _key(LogicalKeyboardKey.keyJ, 'Move down', () => c.move?.call(0, 1)),
        _key(LogicalKeyboardKey.keyK, 'Move up', () => c.move?.call(0, -1)),
        _key(LogicalKeyboardKey.keyL, 'Move right', () => c.move?.call(1, 0)),
        _plain(LogicalKeyboardKey.arrowLeft, 'Move left', () => c.move?.call(-1, 0), keys: const ['←']),
        _plain(LogicalKeyboardKey.arrowRight, 'Move right', () => c.move?.call(1, 0), keys: const ['→']),
        _plain(LogicalKeyboardKey.arrowUp, 'Move up', () => c.move?.call(0, -1), keys: const ['↑']),
        _plain(LogicalKeyboardKey.arrowDown, 'Move down', () => c.move?.call(0, 1), keys: const ['↓']),
        _plain(LogicalKeyboardKey.home, 'First series', () => c.home?.call()),
        _plain(LogicalKeyboardKey.end, 'Last series', () => c.end?.call()),
        _key(LogicalKeyboardKey.keyX, 'Select mode', () => c.selectMode?.call()),
        _key(LogicalKeyboardKey.keyF, 'Favourite the focused series', () => c.favouriteFocused?.call()),
        for (var i = 0; i < 7; i++) _key(digits[i], 'Show ${words[i].toLowerCase()}', () => c.status?.call(i)),
        _key(LogicalKeyboardKey.keyS, 'Cycle the sort', () => c.cycleSort?.call()),
        _key(LogicalKeyboardKey.keyV, 'Cycle the density', () => c.cycleDensity?.call()),
        _key(LogicalKeyboardKey.keyR, 'Reprint (refresh) the shelf', () => c.reprint?.call()),
        ShortcutEntry(
          group: _g,
          activator: const SingleActivator(LogicalKeyboardKey.keyA, control: true),
          description: 'Select all visible',
          keys: const ['Ctrl', 'A'],
          onInvoke: () => c.selectAll?.call(),
        ),
        ShortcutEntry(
          group: _g,
          activator: const SingleActivator(LogicalKeyboardKey.keyA, meta: true),
          description: 'Select all visible',
          keys: const ['⌘', 'A'],
          onInvoke: () => c.selectAll?.call(),
        ),
        for (final (k, dx, dy, label) in [
          (LogicalKeyboardKey.arrowLeft, -1, 0, '←'),
          (LogicalKeyboardKey.arrowRight, 1, 0, '→'),
          (LogicalKeyboardKey.arrowUp, 0, -1, '↑'),
          (LogicalKeyboardKey.arrowDown, 0, 1, '↓'),
        ])
          ShortcutEntry(
            group: _g,
            activator: SingleActivator(k, alt: true),
            description: 'Move the focused series (Manual order)',
            keys: ['Alt', label],
            onInvoke: () => c.moveItem?.call(dx, dy),
          ),
      ],
      child: child,
    );
  }
}
