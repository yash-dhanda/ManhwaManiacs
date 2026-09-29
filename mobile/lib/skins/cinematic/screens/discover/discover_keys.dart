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

/// The screens' key groups currently on screen, by masthead title
/// (`Discover`, `Sources`, `Catalogue`, `Dialogue`), with their bindings.
///
/// TODO(mobile/06): replace with the shell's key registry (the shell's
/// shortcut sheet reads it). Screens register through [CineKeys] only, so the
/// swap is inside this file.
abstract final class CineKeyRegistry {
  static final ValueNotifier<Map<String, List<CineKey>>> groups =
      ValueNotifier(const {});

  static void register(String group, List<CineKey> keys) {
    groups.value = {...groups.value, group: keys};
  }

  static void unregister(String group, List<CineKey> keys) {
    if (!identical(groups.value[group], keys)) return;
    groups.value = {...groups.value}..remove(group);
  }
}

/// Wraps [child] in Shortcuts + Actions for [keys] and registers them under
/// the screen's masthead [group].
class CineKeys extends StatefulWidget {
  const CineKeys({super.key, required this.group, required this.keys, required this.child});

  final String group;
  final List<CineKey> keys;
  final Widget child;

  @override
  State<CineKeys> createState() => _CineKeysState();
}

class _CineKeysState extends State<CineKeys> {
  List<CineKey>? _registered;

  @override
  void initState() {
    super.initState();
    // After the first frame: the registry notifies listeners, which must not
    // rebuild during this build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  void _sync() {
    if (!mounted) return;
    _registered = widget.keys;
    CineKeyRegistry.register(widget.group, widget.keys);
  }

  @override
  void didUpdateWidget(CineKeys old) {
    super.didUpdateWidget(old);
    if (_registered != null && !identical(old.keys, widget.keys)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
    }
  }

  @override
  void dispose() {
    final r = _registered;
    if (r != null) CineKeyRegistry.unregister(widget.group, r);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Shortcuts(
        shortcuts: {for (final k in widget.keys) k.activator: _Intent(k)},
        child: Actions(
          actions: {_Intent: _Act()},
          // Route focus: keys reach the screen before anything is focused.
          child: FocusScope(autofocus: true, child: widget.child),
        ),
      );
}

SingleActivator key(LogicalKeyboardKey k, {bool alt = false}) =>
    SingleActivator(k, alt: alt);

/// j / k / arrows: move keyboard focus from wherever it is (the level-1
/// heading right after a route lands, a control later), not from the route.
void focusStep(BuildContext context, {required bool forward}) {
  final node = FocusManager.instance.primaryFocus ?? FocusScope.of(context);
  if (forward) {
    node.nextFocus();
  } else {
    node.previousFocus();
  }
}
