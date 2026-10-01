import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide ShortcutRegistry;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/library_section.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart' show glassSingleKeyProvider;

/// Does [e] match? `hk` carries the modifiers.
typedef LibraryKeyMatch = bool Function(KeyEvent e, HardwareKeyboard hk);

/// A printable key with no modifier ("x", "*", "["). Shift is ignored for symbols so "*" and "?" match where they need it, but a
/// letter never matches with Shift down (`shift+x` and `shift+m` are their own bindings).
LibraryKeyMatch kChar(String c) {
  final letter = RegExp('^[a-z]\$').hasMatch(c);
  return (e, hk) => e.character == c && !hk.isControlPressed && !hk.isMetaPressed && !hk.isAltPressed && !(letter && hk.isShiftPressed);
}

/// A named key with exact Alt and Shift state.
LibraryKeyMatch kKey(LogicalKeyboardKey k, {bool alt = false, bool shift = false}) =>
    (e, hk) => e.logicalKey == k && hk.isAltPressed == alt && hk.isShiftPressed == shift && !hk.isControlPressed && !hk.isMetaPressed;

/// A letter key with Shift and no other modifier (`shift+x`).
LibraryKeyMatch kShiftLetter(LogicalKeyboardKey k) => (e, hk) => e.logicalKey == k && hk.isShiftPressed && !hk.isControlPressed && !hk.isMetaPressed && !hk.isAltPressed;

/// One hardware-keyboard binding of a Library screen (glass 8.0.6). `single` bindings are printable: they are skipped while the
/// Single-key switch is off; no binding fires while a text field has focus.
class LibraryKey {
  const LibraryKey({required this.description, required this.keys, required this.match, required this.action, this.single = false});
  final String description;
  final List<String> keys;
  final LibraryKeyMatch match;
  final VoidCallback action;
  final bool single;
}

/// Installs a screen's [bindings] while the screen is the one on show (the hub keeps five sections alive: only [section], the active
/// one, answers) and lists them in the shortcuts sheet under [group].
class LibraryKeys extends ConsumerStatefulWidget {
  const LibraryKeys({super.key, required this.group, required this.bindings, required this.child, this.section, this.enabled = true});
  final String group;
  final List<LibraryKey> bindings;
  final LibrarySection? section;
  final bool enabled;
  final Widget child;

  @override
  ConsumerState<LibraryKeys> createState() => _LibraryKeysState();
}

class _LibraryKeysState extends ConsumerState<LibraryKeys> {
  final Object _token = Object();
  late final ShortcutRegistry _registry = ref.read(shortcutRegistryProvider.notifier);

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    Future.microtask(_publish);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    final r = _registry;
    final t = _token;
    Future.microtask(() => r.unregister(t));
    super.dispose();
  }

  void _publish() {
    if (!mounted) return;
    const a = SingleActivator(LogicalKeyboardKey.abort);
    _registry.register(_token, [for (final b in widget.bindings) ShortcutEntry(group: widget.group, activator: a, description: b.description, onInvoke: () {}, singleKey: b.single, keys: b.keys)]);
  }

  bool get _mine {
    if (!widget.enabled) return false;
    final active = LibraryChrome.maybeOf(context)?.active.value;
    if (widget.section != null && active != null && active != widget.section) return false;
    return ModalRoute.of(context)?.isCurrent ?? true;
  }

  bool _onKey(KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return false;
    if (!mounted || !_mine || textFieldHasFocus()) return false;
    final single = ref.read(glassSingleKeyProvider);
    final hk = HardwareKeyboard.instance;
    for (final b in widget.bindings) {
      if (b.single && !single) continue;
      if (b.match(e, hk)) {
        b.action();
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
