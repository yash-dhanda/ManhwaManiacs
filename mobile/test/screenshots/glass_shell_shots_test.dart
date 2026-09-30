@Tags(['screenshots'])
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/models/auth_user.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/auth/providers/session_end_reason_provider.dart';
import 'package:manhwamaniacs/features/settings/models/app_changelog.dart';
import 'package:manhwamaniacs/features/settings/models/app_version.dart';
import 'package:manhwamaniacs/features/settings/providers/app_changelog_provider.dart';
import 'package:manhwamaniacs/features/settings/providers/app_update_provider.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/routes/nav_extra.dart';
import 'package:manhwamaniacs/skins/glass/shell/accessory_controller.dart';
import 'package:manhwamaniacs/skins/glass/shell/glass_back_button.dart';
import 'package:manhwamaniacs/skins/glass/shell/handoff_layer.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell.dart';
import 'package:manhwamaniacs/skins/glass/shell/skin_switch_flow.dart';
import 'package:manhwamaniacs/skins/glass/splash/glass_splash.dart';

import 'glass_shell_shots_support.dart';
import 'support/shot_harness.dart';
import 'support/skin_shots.dart';

/// The mobile/29 proof captures (glass 15.8): the shell, the dock and its moves, the sheet routes, the depth stack, the palette, the
/// overlays, the flows and the Droplet frames. Written only when `MM_PROOF_DIR` is set; otherwise rasterised and discarded.

void main() {
  setUpAll(loadAppFonts);
  tearDown(() => GlassSplash.pending = false);

  testWidgets('shell at rest: phone, tablet, desktop, collapsed tablet-wide and its overlay', (t) async {
    final sem = t.ensureSemantics();
    var s = await openShell(t, kSkinShotSizes[0], start: '/dev/glass/shell');
    await s.snap('shell', kSkinShotSizes[0]);
    s = await openShell(t, kSkinShotSizes[1], start: '/dev/glass/shell');
    await s.snap('shell', kSkinShotSizes[1]);
    s = await openShell(t, kSkinShotDesktop, start: '/dev/glass/shell');
    await s.snap('shell', kSkinShotDesktop);
    s = await openShell(t, kSkinShotTabletWide, start: '/dev/glass/shell');
    await s.snap('shell-collapsed', kSkinShotTabletWide);
    await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.keyB);
    await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await s.settle(900);
    await s.snap('sidebar-overlay', kSkinShotTabletWide);
    sem.dispose();
  });

  testWidgets('dock: title capsule, minimised, drag, merge, menu, accessories, search', (t) async {
    final sem = t.ensureSemantics();
    final size = kSkinShotSizes[0];
    var s = await openShell(t, size, start: '/dev/glass/shell');
    await t.dragFrom(const Offset(200, 640), const Offset(0, -200));
    await s.settle(900);
    await s.snap('title-capsule', size);
    await s.snap('dock-minimised', size);
    await t.dragFrom(const Offset(200, 640), const Offset(0, 300));
    await s.settle(900);
    // A drag across the dock, caught mid-way.
    final r = t.getRect(find.bySemanticsLabel('Main'));
    final g = await t.startGesture(Offset(r.left + 30, r.center.dy));
    for (var i = 0; i < 8; i++) {
      await g.moveBy(const Offset(18, 0));
      await t.pump(const Duration(milliseconds: 16));
    }
    await s.snap('dock-drag', size);
    for (var i = 0; i < 6; i++) {
      await g.moveBy(const Offset(22, 0));
      await t.pump(const Duration(milliseconds: 16));
    }
    await s.snap('dock-merge', size);
    await g.moveBy(const Offset(-260, 0));
    await t.pump(const Duration(milliseconds: 16));
    await g.up();
    await s.settle(900);
    await t.longPress(find.bySemanticsLabel(RegExp('^Library, tab')));
    await s.settle(900);
    await s.snap('dock-menu-library', size);
    await t.binding.handlePopRoute();
    await s.settle(600);
    final acc = s.container.read(glassAccessoryProvider.notifier);
    acc.setNarration(GlassNarrationAccessory(title: 'Chapter 12 · Aurora', playing: true, progress: 0.42, onPlayPause: () {}, openPlayer: (_) {}));
    await s.settle();
    await s.snap('accessory-narrating', size);
    acc
      ..setNarration(null)
      ..setDownloading(GlassDownloadingAccessory(chapters: 3, progress: 0.42, paused: false, onToggle: () {}));
    await s.settle();
    await s.snap('accessory-downloading', size);
    acc
      ..setDownloading(null)
      ..setContinue(GlassContinueAccessory(title: 'Continue Solo Leveling', subtitle: 'Ch 143', coverUrl: null, onOpen: (_) {}));
    await s.settle();
    await s.snap('accessory-continue', size);
    await t.dragFrom(const Offset(200, 640), const Offset(0, -200));
    await s.settle(900);
    await s.snap('accessory-inline', size);
    s = await openShell(t, size);
    await t.tap(find.bySemanticsLabel('Search').first);
    await s.settle(1000);
    await s.snap('search-field', size);
    sem.dispose();
  });

  testWidgets('sheet routes, the detail window, the stack overview and its flat menu', (t) async {
    final sem = t.ensureSemantics();
    final size = kSkinShotSizes[0];
    var s = await openShell(t, size, start: '/dev/glass/shell');
    // ignore: unawaited_futures
    s.router.push<void>('/sources/demo/series/x', extra: const GlassNavExtra());
    await s.settle(1200);
    await s.snap('sheet-route-medium', size);
    s = await openShell(t, size, start: '/dev/glass/shell');
    // ignore: unawaited_futures
    s.router.push<void>('/recap/demo/x', extra: const GlassNavExtra());
    await s.settle(1200);
    await t.dragFrom(const Offset(195, 500), const Offset(0, -320));
    await s.settle(900);
    await s.snap('sheet-route-large-recession', size);
    s = await openShell(t, kSkinShotDesktop, start: '/dev/glass/shell');
    // ignore: unawaited_futures
    s.router.push<void>('/sources/demo/series/x', extra: const GlassNavExtra());
    await s.settle(1200);
    await s.snap('detail-window', kSkinShotDesktop);
    s = await openShell(t, size, start: '/dev/glass/shell');
    for (var i = 0; i < 3; i++) {
      await t.tap(find.text('Push a level').first);
      await s.settle(900);
    }
    await t.longPress(find.byType(GlassBackButton));
    await s.settle(1000);
    await s.snap('stack-overview', size);
    s = await openShell(t, size, start: '/dev/glass/shell');
    s.container.read(glassInAppPrefsProvider.notifier).setReduceMotion(true);
    await s.settle(300);
    for (var i = 0; i < 3; i++) {
      await t.tap(find.text('Push a level').first);
      await s.settle(500);
    }
    await t.longPress(find.byType(GlassBackButton));
    await s.settle();
    await s.snap('stack-flat', size);
    sem.dispose();
  });

  testWidgets('palette, shortcuts, What\'s new, app update, account menu', (t) async {
    final sem = t.ensureSemantics();
    var s = await openShell(t, kSkinShotDesktop, start: '/dev/glass/shell');
    await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.keyK);
    await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await s.settle(900);
    await s.snap('palette', kSkinShotDesktop);
    s = await openShell(t, kSkinShotDesktop, start: '/dev/glass/shell?sheet=shortcuts');
    await s.settle(1200);
    await s.snap('shortcuts', kSkinShotDesktop);
    s = await openShell(t, kSkinShotSizes[0], start: '/?sheet=whats-new', extra: [
      appChangelogProvider.overrideWith((ref) async => const [
            ChangelogRelease(version: '3.5.1', build: 58, date: '2026-09-28', highlights: ['Glass edition behind the debug switch', 'Faster chapter start']),
            ChangelogRelease(version: '3.5.0', build: 57, date: '2026-09-20', highlights: ['Narration rebuilt']),
          ],),
    ],);
    await s.settle(1300);
    await s.snap('whats-new', kSkinShotSizes[0]);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    s = await openShell(t, kSkinShotSizes[0], start: '/?sheet=app-update', extra: [
      appUpdateProvider.overrideWith((ref) async => const AppVersionInfo(localVersion: '3.5.0', localBuild: 57, remoteVersion: '3.5.1', remoteBuild: 58, downloadUrl: 'https://example.invalid/app.apk', channel: AppUpdateChannel.apk)),
    ],);
    await s.settle(1300);
    await s.snap('app-update-sheet', kSkinShotSizes[0]);
    debugDefaultTargetPlatformOverride = null;
    s = await openShell(t, kSkinShotDesktop);
    await t.tap(find.bySemanticsLabel(RegExp('^Account')));
    await s.settle(900);
    await s.snap('account-menu', kSkinShotDesktop);
    sem.dispose();
  });

  testWidgets('flows: signed out, skin switch, melt, not found, route error', (t) async {
    final sem = t.ensureSemantics();
    final size = kSkinShotSizes[0];
    var s = await openShell(t, size, extra: [authControllerProvider.overrideWith(_ExpiringAuth.new)]);
    (s.container.read(authControllerProvider.notifier) as _ExpiringAuth).expire();
    await s.settle(900);
    await s.snap('signed-out-alert', size);
    s = await openShell(t, size);
    final ref = t.element(find.byType(GlassShell)) as ConsumerStatefulElement;
    // ignore: unawaited_futures
    startSkinSwitch(ref, ref, sourceRect: const Rect.fromLTWH(180, 400, 30, 30));
    await s.settle(900);
    await s.snap('skin-switch-alert', size);
    s = await openShell(t, size, start: '/dev/glass/shell');
    // ignore: unawaited_futures
    s.container.read(glassEffectsProvider).playMelt();
    await s.settle(320);
    await s.snap('melt-midway', size);
    s = await openShell(t, size, start: '/nowhere/at/all');
    await s.settle(900);
    await s.snap('not-found', size);
    s = await openShell(t, size, start: '/dev/glass/route-error');
    await s.snap('route-error', size);
    sem.dispose();
  });

  testWidgets('the Droplet at 0, 200, 450, 900 and 1150 ms', (t) async {
    final sem = t.ensureSemantics();
    final size = kSkinShotSizes[0];
    GlassSplash.pending = true;
    final s = await openShell(t, size, settle: false, forceKind: false);
    var at = 0;
    for (final ms in const [0, 200, 450, 900, 1150]) {
      if (ms > at) await t.pump(Duration(milliseconds: ms - at));
      at = ms;
      await s.snap('splash-${ms}ms', size);
    }
    await t.pump(const Duration(milliseconds: 400));
    sem.dispose();
  });

  testWidgets('Solid glass and Increase contrast', (t) async {
    final sem = t.ensureSemantics();
    final size = kSkinShotSizes[0];
    var s = await openShell(t, size, start: '/dev/glass/shell');
    s.container.read(glassInAppPrefsProvider.notifier).setSolidGlass(true);
    await s.settle(600);
    await s.snap('shell-solid', size);
    s = await openShell(t, size, start: '/dev/glass/shell');
    s.container.read(glassInAppPrefsProvider.notifier).setIncreaseContrast(true);
    await s.settle(600);
    await s.snap('shell-contrast', size);
    sem.dispose();
  });
}

class _ExpiringAuth extends AuthController {
  @override
  AuthState build() => AuthAuthenticated(AuthUser(id: 1, username: 'tester', isAdmin: true, createdAt: DateTime.utc(2024)));

  void expire() {
    ref.read(sessionEndReasonProvider.notifier).state = SessionEndReason.signedOut;
    state = const AuthUnauthenticated();
  }
}
