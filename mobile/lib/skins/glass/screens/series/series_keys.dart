import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart' show ShortcutEntry, singleKeyShortcutsProvider;
import 'package:manhwamaniacs/skins/glass/screens/series/series_actions.dart';

List<ShortcutEntry> seriesShortcutEntries({bool book = false}) {
  const a = SingleActivator(LogicalKeyboardKey.abort);
  ShortcutEntry e(String d, List<String> keys, {bool single = true}) => ShortcutEntry(group: book ? 'Book' : 'Series', activator: a, description: d, onInvoke: () {}, keys: keys, singleKey: single);
  return [
    e('Continue', ['C']),
    if (!book) e('Read all', ['A']),
    e('Add or remove from library', ['F']),
    e('Favourite', ['*']),
    e('Newest or oldest first', ['N']),
    e('Go to chapter', ['/']),
    e('Select chapters', ['X']),
    e('Download the focused chapter', ['D']),
    e('Download next 10', ['Shift', 'D'], single: false),
    e('Mark the focused chapter read', ['M']),
    e('Previously on', ['P']),
    e('Tags…', ['Shift', 'T'], single: false),
    e('Copy the share link', ['Shift', 'S'], single: false),
    e('Recommend to…', ['Shift', 'R'], single: false),
    e('Close', ['Esc'], single: false),
  ];
}

/// The series page's hardware keys (glass 8.12 Keys, 8.13 Keys). Printable keys follow the Single-key switch; keys typed into a field
/// stay in the field. Esc clears select mode first, then closes.
class SeriesKeys extends ConsumerWidget {
  const SeriesKeys({super.key, required this.commands, required this.onEscape, required this.child, this.onFocusedRow});
  final SeriesCommands commands;
  final bool Function() onEscape;
  final Widget child;

  /// `d` and `m` on the focused chapter row: 'download' or 'read'.
  final void Function(String action)? onFocusedRow;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (node, e) {
          if (e is! KeyDownEvent) return KeyEventResult.ignored;
          final k = e.logicalKey;
          KeyEventResult hit(VoidCallback? f) {
            if (f == null) return KeyEventResult.ignored;
            f();
            return KeyEventResult.handled;
          }

          if (k == LogicalKeyboardKey.escape) return onEscape() ? KeyEventResult.handled : KeyEventResult.ignored;
          if (FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<EditableText>() != null) return KeyEventResult.ignored;
          final shift = HardwareKeyboard.instance.isShiftPressed;
          if (shift && k == LogicalKeyboardKey.keyT) return hit(commands.tags);
          if (shift && k == LogicalKeyboardKey.keyS) return hit(commands.share);
          if (shift && k == LogicalKeyboardKey.keyD) return hit(commands.downloadNext10);
          if (shift && k == LogicalKeyboardKey.keyR) return hit(commands.recommend);
          if (!ref.read(singleKeyShortcutsProvider)) return KeyEventResult.ignored;
          if (e.character == '*') return hit(commands.favorite);
          if (shift || HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed || HardwareKeyboard.instance.isAltPressed) return KeyEventResult.ignored;
          if (k == LogicalKeyboardKey.keyC) return hit(commands.continueReading);
          if (k == LogicalKeyboardKey.keyA) return hit(commands.readAll);
          if (k == LogicalKeyboardKey.keyF) return hit(commands.toggleFollow);
          if (k == LogicalKeyboardKey.keyN) return hit(commands.toggleSort);
          if (k == LogicalKeyboardKey.slash) return hit(commands.focusGoTo);
          if (k == LogicalKeyboardKey.keyX) return hit(commands.select);
          if (k == LogicalKeyboardKey.keyP) return hit(commands.previouslyOn);
          if (k == LogicalKeyboardKey.keyD && onFocusedRow != null) return hit(() => onFocusedRow!('download'));
          if (k == LogicalKeyboardKey.keyM && onFocusedRow != null) return hit(() => onFocusedRow!('read'));
          return KeyEventResult.ignored;
        },
        child: child,
      );
}
