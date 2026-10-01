import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/app/app_restart.dart';
import 'package:manhwamaniacs/app/skin_boot.dart';
import 'package:manhwamaniacs/core/logging/app_logger.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/profiles/providers/skin_outbox.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The one restart path every caller uses: mirror, return route, session flag,
/// `prepare()`, then [AppRestartState.restart].
Future<void> restartInto(
  BuildContext context,
  WidgetRef ref, {
  required SkinId skin,
  required String returnRoute,
}) async {
  final prefs = ref.read(sharedPrefsProvider);
  final restart = AppRestart.of(context);
  await prefs.setString(kSkinActiveKey, skin.name);
  await prefs.setString(kSkinReturnKey, returnRoute);
  if (ref.read(profileSessionReadyProvider)) await prefs.setString(kSkinSessionKey, '1');
  await skinFor(skin).prepare();
  restart.restart();
}

String currentLocation(BuildContext context) =>
    GoRouter.of(context).routerDelegate.currentConfiguration.uri.toString();

/// Stack §2.5 mobile steps 1-5, with everything injected. At t = 0 the `PATCH` is queued and
/// `mm.skin.t0` written; [outgoing] is the skin's own exit animation (Stop the press, the melt);
/// then the device mirror, the return route and, only when [undoable], `mm.skin.from` are written
/// and [restart] runs. The `PATCH` stays in the outbox and is never awaited: the outbox wins at
/// the next boot (S12).
Future<void> switchSkin({
  required SkinId to,
  required bool undoable,
  required Future<void> Function() outgoing,
  required String currentLocation,
  required SharedPreferences prefs,
  required SkinOutbox outbox,
  required VoidCallback restart,
  int? profileId,
  SkinId? from,
  bool carrySession = false,
  Future<void> Function()? prepare,
  DateTime Function() clock = DateTime.now,
}) async {
  await prefs.setInt(kSkinT0Key, clock().millisecondsSinceEpoch);
  if (profileId != null) {
    await outbox.enqueue(profileId, to);
    unawaited(outbox.flush());
  }
  await outgoing();
  await prefs.setString(kSkinActiveKey, to.name);
  await prefs.setString(kSkinReturnKey, currentLocation);
  if (undoable && from != null) await prefs.setString(kSkinFromKey, from.name);
  if (carrySession) await prefs.setString(kSkinSessionKey, '1');
  try {
    await (prepare ?? skinFor(to).prepare)();
  } catch (e, st) {
    // The new skin prepares again at boot, before its router is built.
    appLogger.w('Skin prepare before the restart failed', e, st);
  }
  restart();
}

/// [switchSkin] wired to the running app: the context's `AppRestart`, the shared prefs, the
/// outbox and the active profile.
Future<void> switchSkinFrom(
  BuildContext context,
  WidgetRef ref, {
  required SkinId to,
  required Future<void> Function() outgoing,
  bool undoable = true,
}) {
  final restart = AppRestart.of(context);
  return switchSkin(
    to: to,
    from: ref.read(skinIdProvider),
    undoable: undoable,
    outgoing: outgoing,
    currentLocation: currentLocation(context),
    prefs: ref.read(sharedPrefsProvider),
    outbox: ref.read(skinOutboxProvider),
    restart: restart.restart,
    profileId: ref.read(activeProfileProvider)?.id,
    carrySession: ref.read(profileSessionReadyProvider),
  );
}

/// The edition the user switched away from, once: the arrival toast reads it and it is gone.
String? takeSkinArrival(SharedPreferences prefs) {
  final from = prefs.getString(kSkinFromKey);
  if (from != null) unawaited(prefs.remove(kSkinFromKey));
  return from;
}

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
