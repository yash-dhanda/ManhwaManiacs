import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/diagnostics/debug_overlays.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/skins/cinematic/g_sequence.dart';
import 'package:manhwamaniacs/skins/cinematic/navigation.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toast_host.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/command_palette.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/keyboard_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// `mod` is `meta` on iOS (iPad keyboards) and `control` on Android.
bool get _metaIsMod => defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;

SingleActivator modActivator(LogicalKeyboardKey key, {bool shift = false}) =>
    SingleActivator(key, meta: _metaIsMod, control: !_metaIsMod, shift: shift);

/// Whether [path] is one of the reader routes, where `g` means "go to page".
bool isReaderPath(String path) =>
    path.startsWith('/reader/') ||
    path.startsWith('/read-all/') ||
    path.startsWith('/novels/') ||
    path.startsWith('/library/read/') ||
    (path.startsWith('/sources/') && path.endsWith('/read'));

/// The frame's hardware keys (cinematic 8.0.6): the `General` and `Navigation` groups of the
/// shortcut registry, the `g` sequence with its `G 1_` chip, and the global handler.
class CineGlobalKeys extends ConsumerStatefulWidget {
  const CineGlobalKeys({super.key, required this.child, required this.toastKey, required this.chipBottom});

  final Widget child;
  final GlobalKey<CineToastHostState> toastKey;

  /// The toast anchor: the chip sits there.
  final double chipBottom;

  @override
  ConsumerState<CineGlobalKeys> createState() => _CineGlobalKeysState();
}

class _CineGlobalKeysState extends ConsumerState<CineGlobalKeys> {
  late final GSequenceController _g;
  final FocusNode _focus = FocusNode(debugLabel: 'cine-frame');

  GoRouter get _router => ref.read(skinRouterProvider);
  BuildContext? get _navContext => cineRouterNavigatorContext(_router);
  String get _path => Uri.parse(cineLocationOf(_router)).path;

  @override
  void initState() {
    super.initState();
    _g = GSequenceController(
      enabled: () => !textFieldHasFocus() && ref.read(singleKeyShortcutsProvider) && !isReaderPath(_path),
      novelsMode: () => ref.read(contentModeControllerProvider) == ContentMode.novel,
      onJump: (path) => _router.go(path),
    )
      ..attach()
      ..addListener(() {
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _g.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _palette() {
    final ctx = _navContext;
    if (ctx == null) return;
    togglePalette(ctx, ref);
  }

  void _sheet() {
    final ctx = _navContext;
    if (ctx != null) showCineKeyboardSheet(ctx, ref);
  }

  void _escape() {
    final nav = cineRootNavigator(_router);
    if (nav == null) return;
    Route<dynamic>? top;
    nav.popUntil((r) {
      top = r;
      return true;
    });
    if (top is PopupRoute || top is CineSheetRoute) nav.maybePop();
  }

  List<ShortcutEntry> _entries() {
    void noop() {}
    return [
      ShortcutEntry(group: 'General', activator: modActivator(LogicalKeyboardKey.keyK), description: 'Open the command palette', onInvoke: _palette),
      ShortcutEntry(
        group: 'General',
        activator: const SingleActivator(LogicalKeyboardKey.slash, shift: true),
        description: 'Show keyboard shortcuts',
        keys: const ['?'],
        onInvoke: _sheet,
      ),
      ShortcutEntry(
        group: 'General',
        activator: const SingleActivator(LogicalKeyboardKey.slash),
        description: 'Search',
        singleKey: true,
        onInvoke: () => ref.read(focusSearchSignalProvider.notifier).state++,
      ),
      ShortcutEntry(
        group: 'General',
        activator: const SingleActivator(LogicalKeyboardKey.keyT, alt: true),
        description: 'Go to notifications',
        onInvoke: () => widget.toastKey.currentState?.focusNewestAction(),
      ),
      ShortcutEntry(group: 'General', activator: const SingleActivator(LogicalKeyboardKey.escape), description: 'Close the top layer', onInvoke: _escape),
      if (!kReleaseMode) ...[
        ShortcutEntry(
          group: 'General',
          activator: modActivator(LogicalKeyboardKey.keyG, shift: true),
          description: 'Show the layout grid',
          onInvoke: () => ref.read(layoutGridOverlayProvider.notifier).state = !ref.read(layoutGridOverlayProvider),
        ),
        ShortcutEntry(
          group: 'General',
          activator: modActivator(LogicalKeyboardKey.keyM, shift: true),
          description: 'Show motion timings',
          onInvoke: () => ref.read(motionTimingsOverlayProvider.notifier).state = !ref.read(motionTimingsOverlayProvider),
        ),
      ],
      // Listed for the sheet; the sequence itself runs from the hardware handler.
      ShortcutEntry(
        group: 'Navigation',
        activator: const SingleActivator(LogicalKeyboardKey.keyG),
        description: 'Go to a numbered section',
        singleKey: true,
        keys: const ['G', '1…12'],
        onInvoke: noop,
      ),
      ShortcutEntry(
        group: 'Navigation',
        activator: const SingleActivator(LogicalKeyboardKey.keyG),
        description: 'Go to Settings',
        singleKey: true,
        keys: const ['G', '0'],
        onInvoke: noop,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final chip = _g.chip;
    return Focus(
      focusNode: _focus,
      autofocus: true,
      canRequestFocus: true,
      skipTraversal: true,
      child: RegisteredShortcuts(
        group: 'General',
        entries: _entries(),
        child: Stack(children: [
          widget.child,
          if (chip != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: widget.chipBottom,
              child: IgnorePointer(
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _g.machine.phase == GPhase.idle ? 0 : 1,
                    duration: const Duration(milliseconds: 160),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      constraints: const BoxConstraints(minWidth: 20, minHeight: 24),
                      decoration: BoxDecoration(color: c.colorPaper2, border: Border.all(color: c.colorInk30)),
                      alignment: Alignment.center,
                      child: Semantics(
                        liveRegion: true,
                        label: 'Go to section, waiting for a number',
                        excludeSemantics: true,
                        child: CineLit(chip, CineFace.plexMono, 12, 16, color: c.colorInk100),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],),
      ),
    );
  }
}

/// The root navigator of the router, for showing dialogs from the frame (which sits above it).
NavigatorState? cineRootNavigator(GoRouter router) => router.routerDelegate.navigatorKey.currentState;

/// A context under the root navigator.
BuildContext? cineRouterNavigatorContext(GoRouter router) => router.routerDelegate.navigatorKey.currentContext;
