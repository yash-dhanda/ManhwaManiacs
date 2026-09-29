import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One hardware-keyboard binding, listed in the `?` sheet.
class KeyBinding {
  const KeyBinding(this.keys, this.description);
  final String keys;
  final String description;
}

/// A named group of bindings (mobile/06's shortcut registry lists these).
///
/// TODO(mobile/06): register these groups with the shortcut registry, which also
/// suppresses delivery while a `g` sequence is armed.
class KeyGroup {
  const KeyGroup(this.name, this.bindings);
  final String name;
  final List<KeyBinding> bindings;
}

const KeyGroup kNumbersKeys = KeyGroup('The Numbers', [
  KeyBinding('1 2 3 4', '7 days, 30 days, 90 days, year'),
  KeyBinding('← →', 'Move the selected day'),
  KeyBinding('↑ ↓', 'Move a week (year heatmap)'),
  KeyBinding('a', 'Open The Annual'),
  KeyBinding('s', 'Share'),
  KeyBinding('r', 'Reprint (refresh)'),
]);

const KeyGroup kAnnualKeys = KeyGroup('The Annual', [
  KeyBinding('← →', 'Previous or next page'),
  KeyBinding('Space', 'Pause or play'),
  KeyBinding('Esc', 'Close'),
]);

typedef KeyAction = void Function();

/// Focus that maps hardware keys to actions; unmatched keys pass through.
class KeyMap extends StatelessWidget {
  const KeyMap({super.key, required this.actions, required this.child, this.autofocus = true, this.focusNode, this.enabled = true});

  final Map<LogicalKeyboardKey, KeyAction> actions;
  final Widget child;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Focus(
        autofocus: autofocus,
        focusNode: focusNode,
        canRequestFocus: enabled,
        onKeyEvent: (node, event) {
          if (!enabled || event is! KeyDownEvent) return KeyEventResult.ignored;
          final a = actions[event.logicalKey];
          if (a == null) return KeyEventResult.ignored;
          a();
          return KeyEventResult.handled;
        },
        child: child,
      );
}
