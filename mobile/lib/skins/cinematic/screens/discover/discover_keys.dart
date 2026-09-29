import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One hardware-keyboard binding. A binding with [whenTextFieldFree] stays
/// out of the way while a text field owns the keyboard, so `1` or `[` still
/// type into the search field.
class CineKey {
  const CineKey(this.activator, this.run, {this.whenTextFieldFree = false});

  final ShortcutActivator activator;
  final VoidCallback run;
  final bool whenTextFieldFree;
}

class _Intent extends Intent {
  const _Intent(this.key);

  final CineKey key;
}

bool _typing() {
  final f = FocusManager.instance.primaryFocus;
  return f?.context?.findAncestorWidgetOfExactType<EditableText>() != null ||
      f?.context?.widget is EditableText;
}

class _Act extends Action<_Intent> {
  @override
  bool isEnabled(_Intent intent) => !intent.key.whenTextFieldFree || !_typing();

  @override
  Object? invoke(_Intent intent) {
    intent.key.run();
    return null;
  }
}

/// Wraps [child] in Shortcuts + Actions for [keys]. Registers under the
/// screen's masthead group (`Discover`, `Sources`, `Catalogue`, `Dialogue`).
// TODO(mobile/06): register [group] with the shell's key registry.
class CineKeys extends StatelessWidget {
  const CineKeys({super.key, required this.group, required this.keys, required this.child});

  final String group;
  final List<CineKey> keys;
  final Widget child;

  @override
  Widget build(BuildContext context) => Shortcuts(
        shortcuts: {for (final k in keys) k.activator: _Intent(k)},
        child: Actions(
          actions: {_Intent: _Act()},
          child: child,
        ),
      );
}

SingleActivator key(LogicalKeyboardKey k, {bool alt = false}) =>
    SingleActivator(k, alt: alt);
