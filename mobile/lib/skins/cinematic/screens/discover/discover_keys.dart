import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart' show ShortcutEntry, shortcutRegistryProvider;

/// One hardware-keyboard binding. A binding with [whenTextFieldFree] stays
/// out of the way while a text field owns the keyboard, so `1` or `[` still
/// type into the search field.
class CineKey {
  const CineKey(this.activator, this.run, {this.whenTextFieldFree = false, this.label = ''});

  /// Shown in the shell's shortcut sheet; empty falls back to the key's own name.
  final String label;

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

/// Wraps [child] in Shortcuts + Actions for [keys] and registers them under
/// the screen's masthead [group].
class CineKeys extends ConsumerStatefulWidget {
  const CineKeys(
      {super.key,
      required this.group,
      required this.keys,
      required this.child,});

  final String group;
  final List<CineKey> keys;
  final Widget child;

  @override
  ConsumerState<CineKeys> createState() => _CineKeysState();
}

class _CineKeysState extends ConsumerState<CineKeys> {
  final Object _token = Object();
  late final _registry = ref.read(shortcutRegistryProvider.notifier);
  bool _alive = true;

  @override
  void initState() {
    super.initState();
    // After the first frame: the registry notifies listeners, which must not
    // rebuild during this build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  void _sync() {
    if (!mounted || !_alive) return;
    _registry.register(_token, [
      for (final k in widget.keys)
        ShortcutEntry(
          group: widget.group,
          activator: k.activator,
          description: k.label.isNotEmpty ? k.label : k.activator.debugDescribeKeys(),
          onInvoke: k.run,
        ),
    ]);
  }

  @override
  void didUpdateWidget(CineKeys old) {
    super.didUpdateWidget(old);
    if (!identical(old.keys, widget.keys)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
    }
  }

  @override
  void dispose() {
    _alive = false;
    Future.microtask(() => _registry.unregister(_token));
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
