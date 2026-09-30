import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide ShortcutRegistry;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/keycap.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/routes/sheet_registry.dart';
import 'package:manhwamaniacs/skins/glass/shell/command_palette.dart';
import 'package:manhwamaniacs/skins/glass/shell/g_sequence.dart';
import 'package:manhwamaniacs/skins/glass/shell/palette_commands.dart';
import 'package:manhwamaniacs/skins/glass/shell/search_orb.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';
import 'package:manhwamaniacs/skins/glass/shell/stack_overview_host.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// `r` refreshes the screen: lists and pull-to-refresh subscribe here (glass 8.0.6).
abstract final class GlassRefreshBus {
  static final List<VoidCallback> _handlers = [];
  static void fire() {
    if (_handlers.isNotEmpty) _handlers.last();
  }
}

/// Subscribes [handler] to the refresh key while the caller is mounted. Returns the disposer; call it from `dispose`.
VoidCallback useGlassRefresh(VoidCallback handler) {
  GlassRefreshBus._handlers.add(handler);
  return () => GlassRefreshBus._handlers.remove(handler);
}

final List<FocusNode> _searchFocus = [];

/// The screen's search or filter field for the `/` key. Returns the disposer.
VoidCallback registerSearchFocus(FocusNode node) {
  _searchFocus.add(node);
  return () => _searchFocus.remove(node);
}

/// One row of the key map.
class GlassKeyBinding {
  const GlassKeyBinding({required this.id, required this.group, required this.description, required this.keys, required this.matches, required this.action, this.alwaysOn = false, this.singleKey = false});
  final String id;
  final String group;
  final String description;
  final List<String> keys;
  final bool Function(KeyEvent e, bool mod, bool shift) matches;
  final void Function() action;

  /// Fires while a text field has focus (only `mod+K` and `mod+B`).
  final bool alwaysOn;

  /// A printable-character binding: skipped when "Single-key shortcuts" is off.
  final bool singleKey;
}

/// Whether [binding] may fire now (glass 8.0.6 rules), pure.
bool glassKeyMayFire(GlassKeyBinding b, {required bool typing, required bool singleKeyOn}) {
  if (typing && !b.alwaysOn) return false;
  if (b.singleKey && !singleKeyOn) return false;
  return true;
}

/// Installs the Glass hardware-keyboard map above the router (glass 8.0.6): `mod+K`, `mod+B`, `?`, `/`, the `g` chords, `shift+R`,
/// `mod+\`, `mod+Enter`, `r`, `u` and `mod+Z`. `mod` is Meta on iOS keyboards and Control elsewhere.
class GlassGlobalKeys extends ConsumerStatefulWidget {
  const GlassGlobalKeys({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<GlassGlobalKeys> createState() => _GlassGlobalKeysState();
}

class _GlassGlobalKeysState extends ConsumerState<GlassGlobalKeys> {
  final GlassGSequence _g = GlassGSequence();
  final Object _token = Object();
  late final ShortcutRegistry _registry = ref.read(shortcutRegistryProvider.notifier);
  late List<GlassKeyBinding> _bindings = _build();

  bool get _ios => defaultTargetPlatform == TargetPlatform.iOS;

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
    Future.microtask(() => r.unregister(_token));
    super.dispose();
  }

  void _publish() {
    if (!mounted) return;
    _registry.register(_token, [
      for (final b in _bindings)
        ShortcutEntry(group: b.group, activator: const SingleActivator(LogicalKeyboardKey.abort), description: b.description, onInvoke: b.action, singleKey: b.singleKey, keys: b.keys),
    ]);
  }

  GoRouter get _router => ref.read(skinRouterProvider);

  String _location() => _router.routerDelegate.currentConfiguration.uri.toString();

  void _openSheet(String id) {
    final uri = Uri.parse(_location());
    _router.go(uri.replace(queryParameters: {...uri.queryParameters, 'sheet': id}).toString());
  }

  bool _isChar(KeyEvent e, String c) => e.character == c;

  List<GlassKeyBinding> _build() {
    final modLabel = _ios ? '⌘' : 'Ctrl';
    return [
      GlassKeyBinding(
        id: 'palette',
        group: 'Navigate',
        description: 'Command palette',
        keys: [modLabel, 'K'],
        alwaysOn: true,
        matches: (e, mod, shift) => mod && e.logicalKey == LogicalKeyboardKey.keyK,
        action: () {
          final ctx = ref.read(glassNavigatorsProvider)?.root.currentContext;
          if (ctx == null) return;
          if (GlassFrame.of(ctx) == GlassFrameKind.phone) {
            openGlassSearch(ctx, ref);
          } else {
            unawaited(openGlassPalette(ctx, ref));
          }
        },
      ),
      GlassKeyBinding(
        id: 'sidebar',
        group: 'Navigate',
        description: 'Collapse or expand the sidebar',
        keys: [modLabel, 'B'],
        alwaysOn: true,
        matches: (e, mod, shift) => mod && e.logicalKey == LogicalKeyboardKey.keyB,
        action: () => ref.read(glassSidebarToggleProvider)?.call(),
      ),
      GlassKeyBinding(id: 'shortcuts', group: 'Navigate', description: 'Keyboard shortcuts', keys: const ['?'], singleKey: true, matches: (e, mod, shift) => !mod && _isChar(e, '?'), action: () => _openSheet('shortcuts')),
      GlassKeyBinding(
        id: 'focus-search',
        group: 'Navigate',
        description: 'Focus search or filter',
        keys: const ['/'],
        singleKey: true,
        matches: (e, mod, shift) => !mod && _isChar(e, '/'),
        action: () {
          if (_searchFocus.isNotEmpty) _searchFocus.last.requestFocus();
        },
      ),
      GlassKeyBinding(
        id: 'g',
        group: 'Go to',
        description: 'Go to… (g then h l b s u d c t f p ,)',
        keys: const ['g', 'l'],
        singleKey: true,
        matches: (e, mod, shift) => false,
        action: () {},
      ),
      GlassKeyBinding(
        id: 'recommend',
        group: 'Series',
        description: 'Recommend the focused series',
        keys: const ['⇧', 'R'],
        singleKey: true,
        matches: (e, mod, shift) => !mod && shift && e.logicalKey == LogicalKeyboardKey.keyR,
        action: () {
          if (glassSheetRegistered('recommend')) _openSheet('recommend');
        },
      ),
      GlassKeyBinding(
        id: 'overview',
        group: 'Navigate',
        description: 'All levels (stack overview)',
        keys: [modLabel, '\\'],
        matches: (e, mod, shift) => mod && e.logicalKey == LogicalKeyboardKey.backslash,
        action: () {
          final ctx = ref.read(glassNavigatorsProvider)?.root.currentContext;
          if (ctx != null) unawaited(openGlassOverviewFor(ctx, ref, backButtonRect: Rect.zero));
        },
      ),
      GlassKeyBinding(
        id: 'continue',
        group: 'Series',
        description: 'Continue the most recent read',
        keys: [modLabel, '↵'],
        matches: (e, mod, shift) => mod && (e.logicalKey == LogicalKeyboardKey.enter || e.logicalKey == LogicalKeyboardKey.numpadEnter),
        action: () {
          final ctx = ref.read(glassNavigatorsProvider)?.root.currentContext;
          if (ctx != null) unawaited(continueMostRecent(ctx, ref));
        },
      ),
      GlassKeyBinding(id: 'refresh', group: 'Screen', description: 'Refresh', keys: const ['r'], singleKey: true, matches: (e, mod, shift) => !mod && !shift && _isChar(e, 'r'), action: GlassRefreshBus.fire),
      GlassKeyBinding(id: 'undo-u', group: 'Screen', description: 'Undo the last destructive action', keys: const ['u'], singleKey: true, matches: (e, mod, shift) => !mod && !shift && _isChar(e, 'u'), action: () => ref.read(glassToastProvider.notifier).undoLast()),
      GlassKeyBinding(id: 'undo', group: 'Screen', description: 'Undo', keys: [modLabel, 'Z'], matches: (e, mod, shift) => mod && !shift && e.logicalKey == LogicalKeyboardKey.keyZ, action: () => ref.read(glassToastProvider.notifier).undoLast()),
    ];
  }

  bool _onKey(KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return false;
    final hk = HardwareKeyboard.instance;
    final mod = _ios ? hk.isMetaPressed : hk.isControlPressed;
    final shift = hk.isShiftPressed;
    final typing = textFieldHasFocus();
    final single = ref.read(glassSingleKeyProvider);
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // The g chords: printable, no modifier, never while typing.
    if (!mod && !hk.isAltPressed && single && e.character != null && e.character!.length == 1 && (e.character == 'g' || _g.armed)) {
      final effect = _g.key(e.character!.toLowerCase(), nowMs, textFocus: typing);
      if (effect is GlassGJump) {
        _router.go(effect.location);
        return true;
      }
      if (effect is GlassGConsumed) return true;
    }
    for (final b in _bindings) {
      if (b.id == 'g') continue;
      if (b.matches(e, mod, shift) && glassKeyMayFire(b, typing: typing, singleKeyOn: single)) {
        b.action();
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    _bindings = _build();
    return widget.child;
  }
}

/// The keycap parts of a shortcut for a label list (kept for the shortcuts sheet).
List<Widget> keycapsOf(List<String> parts) => [GlassKeycaps(parts)];
