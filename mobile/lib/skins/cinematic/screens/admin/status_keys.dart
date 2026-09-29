import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';

/// System status keys, registered under the masthead title: `r` refreshes every card, `c` runs
/// Check now, `j` / `k` move through the source rows (`Enter` opens the focused row's error).
class StatusKeys extends StatelessWidget {
  const StatusKeys({super.key, required this.onRefresh, required this.onCheck, required this.onNext, required this.onPrevious, required this.child});
  final VoidCallback onRefresh, onCheck, onNext, onPrevious;
  final Widget child;

  static const String group = 'System status';

  @override
  Widget build(BuildContext context) {
    ShortcutEntry e(LogicalKeyboardKey k, String d, VoidCallback f) =>
        ShortcutEntry(group: group, activator: SingleActivator(k), description: d, singleKey: true, onInvoke: f);
    return RegisteredShortcuts(
      group: group,
      entries: [
        e(LogicalKeyboardKey.keyR, 'Refresh every card', onRefresh),
        e(LogicalKeyboardKey.keyC, 'Check now', onCheck),
        e(LogicalKeyboardKey.keyJ, 'Next source', onNext),
        e(LogicalKeyboardKey.keyK, 'Previous source', onPrevious),
      ],
      child: child,
    );
  }
}
