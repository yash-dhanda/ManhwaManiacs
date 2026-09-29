import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

/// One hardware-keyboard binding. Skin-neutral: Cinematic and Glass both register through it.
class ShortcutEntry {
  const ShortcutEntry({
    required this.group,
    required this.activator,
    required this.description,
    required this.onInvoke,
    this.singleKey = false,
    this.keys,
  });

  final String group;
  final ShortcutActivator activator;
  final String description;
  final VoidCallback onInvoke;

  /// A binding without a modifier; it obeys the "Single-key shortcuts" preference.
  final bool singleKey;

  /// Keycap labels for the `?` sheet when the activator does not print them (`?`, `g` then `1`).
  final List<String>? keys;
}

class ShortcutGroup {
  const ShortcutGroup(this.name, this.entries);
  final String name;
  final List<ShortcutEntry> entries;
}

/// Key consumers run before any page binding; the `g` sequence registers one (mobile/06) so keys
/// it swallowed never reach a page.
final List<bool Function(KeyEvent)> keyConsumers = [];

bool _consumed(KeyEvent e) {
  for (final c in keyConsumers) {
    if (c(e)) return true;
  }
  return false;
}

/// True while a text field has focus: bindings pause while the user types.
bool textFieldHasFocus() =>
    FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<EditableText>() != null;

class _Registration {
  _Registration(this.token, this.entries);
  final Object token;
  final List<ShortcutEntry> entries;
}

class ShortcutRegistry extends Notifier<List<Object>> {
  final List<_Registration> _regs = [];

  @override
  List<Object> build() => const [];

  void register(Object token, List<ShortcutEntry> entries) {
    _regs
      ..removeWhere((r) => r.token == token)
      ..add(_Registration(token, entries));
    state = [for (final r in _regs) r.token];
  }

  void unregister(Object token) {
    _regs.removeWhere((r) => r.token == token);
    state = [for (final r in _regs) r.token];
  }

  /// The groups of everything mounted right now, in registration order, merged by name.
  List<ShortcutGroup> registeredGroups() {
    final byName = <String, List<ShortcutEntry>>{};
    for (final r in _regs) {
      for (final e in r.entries) {
        byName.putIfAbsent(e.group, () => []).add(e);
      }
    }
    return [for (final e in byName.entries) ShortcutGroup(e.key, e.value)];
  }
}

final shortcutRegistryProvider = NotifierProvider<ShortcutRegistry, List<Object>>(
  ShortcutRegistry.new,
  name: 'shortcutRegistry',
);

/// "Single-key shortcuts" preference, per profile at `mm.shortcuts.single.u{user}p{profile}`
/// (`"on"` by default). The Settings switch is mobile/18.
final singleKeyShortcutsProvider = NotifierProvider<SingleKeyShortcuts, bool>(
  SingleKeyShortcuts.new,
  name: 'singleKeyShortcuts',
);

class SingleKeyShortcuts extends Notifier<bool> {
  static const String _prefix = 'mm.shortcuts.single.';
  static const String _deviceKey = 'mm.shortcuts.single.device';

  @override
  bool build() => ref.watch(sharedPrefsProvider).getString(_key(watch: true)) != 'off';

  Future<void> set(bool on) async {
    if (state == on) return;
    state = on;
    await ref.read(sharedPrefsProvider).setString(_key(watch: false), on ? 'on' : 'off');
  }

  String _key({required bool watch}) {
    int? userOf(AuthState a) => a is AuthAuthenticated ? a.user.id : null;
    final userId = watch
        ? ref.watch(authControllerProvider.select(userOf))
        : userOf(ref.read(authControllerProvider));
    final profileId =
        watch ? ref.watch(activeProfileProvider.select((p) => p?.id)) : ref.read(activeProfileProvider)?.id;
    if (userId == null || profileId == null) return _deviceKey;
    return '${_prefix}u${userId}p$profileId';
  }
}

/// Registers [entries] while mounted and dispatches them to the focused subtree (and, through the
/// focus chain, to everything below). Nothing fires while a text field has focus; single-key
/// entries also need the preference on. Consumed keys (the `g` sequence) are ignored.
class RegisteredShortcuts extends ConsumerStatefulWidget {
  const RegisteredShortcuts({super.key, required this.group, required this.entries, required this.child});

  final String group;
  final List<ShortcutEntry> entries;
  final Widget child;

  @override
  ConsumerState<RegisteredShortcuts> createState() => _RegisteredShortcutsState();
}

class _RegisteredShortcutsState extends ConsumerState<RegisteredShortcuts> {
  final Object _token = Object();
  late final ShortcutRegistry _registry = ref.read(shortcutRegistryProvider.notifier);
  bool _alive = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (_alive) _registry.register(_token, widget.entries);
    });
  }

  @override
  void didUpdateWidget(RegisteredShortcuts old) {
    super.didUpdateWidget(old);
    Future.microtask(() {
      if (_alive) _registry.register(_token, widget.entries);
    });
  }

  @override
  void dispose() {
    _alive = false;
    Future.microtask(() => _registry.unregister(_token));
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent || _consumed(event)) return KeyEventResult.ignored;
    if (textFieldHasFocus()) return KeyEventResult.ignored;
    final single = ref.read(singleKeyShortcutsProvider);
    for (final e in widget.entries) {
      if (e.singleKey && !single) continue;
      if (e.activator.accepts(event, HardwareKeyboard.instance)) {
        e.onInvoke();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) => Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _onKey,
        child: widget.child,
      );
}
