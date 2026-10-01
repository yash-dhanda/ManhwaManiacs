import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/app/skin_boot.dart';
import 'package:manhwamaniacs/app/switch_skin.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/profiles/providers/skin_outbox.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Boot resolution steps 2-5 (stack §2.4). Null means "stay".
SkinId? resolveBootRestart({
  required SkinId running,
  required bool profileKnown,
  required String? profileSkin,
  required String? queuedOutboxSkin,
  required bool glassAvailable,
  required SkinId defaultSkin,
}) {
  if (!profileKnown) return null; // step 5: keep the mirror
  if (queuedOutboxSkin != null) return null; // S12: the outbox flushes first
  var desired = skinIdFromName(profileSkin) ?? defaultSkin;
  if (desired == SkinId.legacy) desired = defaultSkin; // v1: legacy is retired
  if (desired == SkinId.glass && !glassAvailable) desired = SkinId.cinematic;
  return desired == running ? null : desired;
}

/// The loop guard: the same target attempted under 10 s ago must not restart.
bool bootRestartAllowed(SharedPreferences prefs, SkinId target, int nowMs) {
  final last = prefs.getString(kSkinBootRestartKey)?.split(':');
  if (last != null && last.length == 2 && last[0] == target.name) {
    final at = int.tryParse(last[1]);
    if (at != null && nowMs - at < 10000) return false;
  }
  return true;
}

class SkinBootCheck extends ConsumerStatefulWidget {
  const SkinBootCheck({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<SkinBootCheck> createState() => _SkinBootCheckState();
}

class _SkinBootCheckState extends ConsumerState<SkinBootCheck> {
  bool _curtain = false;
  bool _restarting = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual<ActiveProfile?>(activeProfileProvider, (_, __) => _check(), fireImmediately: true);
    ref.listenManual<AsyncValue<List<Profile>>>(profilesProvider, (_, __) => _check());
  }

  void _check() {
    if (_restarting) return;
    final active = ref.read(activeProfileProvider);
    final profiles = ref.read(profilesProvider).valueOrNull;
    if (active == null || profiles == null) return;
    Profile? row;
    for (final p in profiles) {
      if (p.id == active.id) row = p;
    }
    final prefs = ref.read(sharedPrefsProvider);
    final running = ref.read(skinIdProvider);
    final target = resolveBootRestart(
      running: running,
      profileKnown: row != null,
      profileSkin: row?.skin,
      queuedOutboxSkin: ref.read(skinOutboxProvider).pendingFor(active.id),
      glassAvailable: Flags.glassAvailable,
      defaultSkin: kDefaultSkin,
    );
    if (target == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!bootRestartAllowed(prefs, target, now)) {
      debugPrint('Skin boot: ${target.name} did not take; staying in ${running.name}');
      return;
    }
    _restarting = true;
    unawaited(_go(prefs, target, now));
  }

  Future<void> _go(SharedPreferences prefs, SkinId target, int now) async {
    await prefs.setString(kSkinBootRestartKey, '${target.name}:$now');
    if (!mounted) return;
    setState(() => _curtain = true);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    // MaterialApp.builder sits above the router's InheritedGoRouter, so the
    // location comes from the router object, not GoRouter.of(context).
    final route = ref.read(skinRouterProvider).routerDelegate.currentConfiguration.uri.toString();
    await restartInto(context, ref, skin: target, returnRoute: route);
  }

  @override
  Widget build(BuildContext context) => Stack(
        textDirection: TextDirection.ltr,
        children: [widget.child, if (_curtain) const Positioned.fill(child: RestartCurtain())],
      );
}
