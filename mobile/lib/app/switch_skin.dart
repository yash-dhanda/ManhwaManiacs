import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/app/app_restart.dart';
import 'package:manhwamaniacs/app/skin_boot.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/profiles/providers/skin_outbox.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which device key [restartInto] writes.
enum SkinMirror { active, debug, clearDebug }

/// The one restart path every caller uses: mirror, return route, session flag,
/// `prepare()`, then [AppRestartState.restart].
Future<void> restartInto(
  BuildContext context,
  WidgetRef ref, {
  required SkinId skin,
  required String returnRoute,
  SkinMirror mirror = SkinMirror.active,
}) async {
  final prefs = ref.read(sharedPrefsProvider);
  final restart = AppRestart.of(context);
  switch (mirror) {
    case SkinMirror.active:
      await prefs.setString(kSkinActiveKey, skin.name);
    case SkinMirror.debug:
      await prefs.setString(kSkinDebugKey, skin.name);
    case SkinMirror.clearDebug:
      await prefs.remove(kSkinDebugKey);
  }
  await prefs.setString(kSkinReturnKey, returnRoute);
  if (ref.read(profileSessionReadyProvider)) await prefs.setString(kSkinSessionKey, '1');
  await skinFor(skin).prepare();
  restart.restart();
}

String currentLocation(BuildContext context) =>
    GoRouter.of(context).routerDelegate.currentConfiguration.uri.toString();

/// Stack §2.5 mobile steps 1-5. The `PATCH` is queued, never awaited: the
/// outbox wins at the next boot (S12). [outgoing] is the skin's own exit
/// animation (Stop the press, the melt), which also plays the haptic.
Future<void> switchSkin(
  BuildContext context,
  WidgetRef ref, {
  required SkinId to,
  required Future<void> Function() outgoing,
}) async {
  final prefs = ref.read(sharedPrefsProvider);
  await prefs.setInt(kSkinT0Key, DateTime.now().millisecondsSinceEpoch);
  final profile = ref.read(activeProfileProvider);
  if (profile != null) {
    final outbox = ref.read(skinOutboxProvider);
    await outbox.enqueue(profile.id, to);
    unawaited(outbox.flush());
  }
  await outgoing();
  if (!context.mounted) return;
  await restartInto(context, ref, skin: to, returnRoute: currentLocation(context));
}

/// The pre-flip debug row (§8.0.7): a device override, never the outbox and
/// never `reading_profiles.skin`. A null [to] clears the override.
Future<void> debugSwitchSkin(BuildContext context, WidgetRef ref, SkinId? to) async {
  final prefs = ref.read(sharedPrefsProvider);
  await prefs.setInt(kSkinT0Key, DateTime.now().millisecondsSinceEpoch);
  if (!context.mounted) return;
  await showRestartCurtain(context);
  if (!context.mounted) return;
  await restartInto(
    context,
    ref,
    skin: to ?? SkinBoot.resolveSkinWithoutDebug(prefs),
    returnRoute: '/settings/diagnostics',
    mirror: to == null ? SkinMirror.clearDebug : SkinMirror.debug,
  );
}

/// The pending screen's button.
Future<void> leavePreview(BuildContext context, WidgetRef ref) =>
    debugSwitchSkin(context, ref, null);

/// Full-screen black that fades in over 200 ms (`dur.clip`), linear, absorbing taps.
class RestartCurtain extends StatefulWidget {
  const RestartCurtain({super.key});

  @override
  State<RestartCurtain> createState() => _RestartCurtainState();
}

class _RestartCurtainState extends State<RestartCurtain> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AbsorbPointer(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _c, curve: Curves.linear),
          child: const SizedBox.expand(child: ColoredBox(color: Color(0xFF000000))),
        ),
      );
}

Future<void> showRestartCurtain(BuildContext context) async {
  final entry = OverlayEntry(builder: (_) => const RestartCurtain());
  Overlay.of(context, rootOverlay: true).insert(entry);
  await Future<void>.delayed(const Duration(milliseconds: 200));
}

class SkinRestartTiming {
  /// Called once, on the first frame after boot. One read when nothing is pending.
  static void logFirstFrame(SharedPreferences prefs, {DateTime Function() now = DateTime.now}) {
    final t0 = prefs.getInt(kSkinT0Key);
    if (t0 == null) return;
    final ms = now().millisecondsSinceEpoch - t0;
    prefs.remove(kSkinT0Key);
    prefs.setInt(kSkinRestartLastKey, ms);
    debugPrint('SKIN RESTART  confirm → first frame  ${_thousands(ms)} MS');
    if (ms > 1500) debugPrint('SKIN RESTART $ms ms > 1500 ms');
  }

  static String _thousands(int n) => n.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => ',',
      );
}
