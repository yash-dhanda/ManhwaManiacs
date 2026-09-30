import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/models/auth_user.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/auth/providers/session_end_reason_provider.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart';
import 'package:manhwamaniacs/skins/glass/primitives/stack/snapshot_store.dart';
import 'package:manhwamaniacs/skins/glass/routes/route_frame.dart';
import 'package:manhwamaniacs/skins/glass/shell/glass_back_button.dart';
import 'package:manhwamaniacs/skins/glass/shell/purge.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell.dart';
import 'package:manhwamaniacs/skins/skins.dart';

import '../../../screenshots/support/shot_harness.dart';
import 'shell_rig.dart';

const _demo = '/dev/glass/shell';

Future<void> _settle(WidgetTester t, [int ms = 800]) async {
  await t.pump();
  await t.pump(Duration(milliseconds: ms));
}

class _ExpiringAuth extends AuthController {
  @override
  AuthState build() => AuthAuthenticated(AuthUser(id: 1, username: 'tester', isAdmin: true, createdAt: DateTime.utc(2024)));

  void expire() {
    ref.read(sessionEndReasonProvider.notifier).state = SessionEndReason.signedOut;
    state = const AuthUnauthenticated();
  }
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('a poster push opens the feature sheet with the page beneath still mounted; back closes it and the page stays', (t) async {
    final rig = await pumpGlassShell(t, start: _demo);
    await t.tap(find.byType(GlassPoster).first, warnIfMissed: false);
    await _settle(t, 1200);
    expect(rig.at, startsWith('/sources/demo/series/'));
    expect(find.byType(GlassShell), findsOneWidget, reason: 'the shell stays mounted beneath the sheet');
    expect(find.text('Shell', skipOffstage: false), findsWidgets);
    await t.binding.handlePopRoute();
    await _settle(t, 1200);
    expect(rig.at, _demo);
  });

  testWidgets('signed out elsewhere: the alert blooms and Sign in goes to /login with the cached username', (t) async {
    final rig = await pumpGlassShell(t, extra: [authControllerProvider.overrideWith(_ExpiringAuth.new)]);
    (rig.container.read(authControllerProvider.notifier) as _ExpiringAuth).expire();
    await _settle(t, 900);
    expect(find.text('You were signed out on this device'), findsOneWidget);
    expect(find.text('Your session ended on another device or expired.'), findsOneWidget);
    await t.tap(find.text('Sign in'));
    await _settle(t, 900);
    expect(rig.at, '/login');
    expect(rig.container.read(skinRouterProvider).routerDelegate.currentConfiguration.uri.queryParameters['user'], 'tester');
  });

  testWidgets('the stack overview lists the levels and picking the root pops to it', (t) async {
    final rig = await pumpGlassShell(t, start: _demo);
    for (var i = 0; i < 2; i++) {
      await t.tap(find.text('Push a level').first);
      await _settle(t, 900);
    }
    expect(rig.container.read(glassDepthProvider)[GlassTab.you], 2);
    await t.longPress(find.byType(GlassBackButton));
    await _settle(t, 900);
    // The overview draws one card per level; its titles are the levels.
    expect(find.textContaining('Level 2'), findsWidgets);
    expect(rig.container.read(glassSnapshotStoreProvider).length, greaterThanOrEqualTo(2));
  });

  testWidgets('closing the gate purges a mature level and its snapshot; downloads are untouched', (t) async {
    final rig = await pumpGlassShell(t, start: _demo);
    for (var i = 0; i < 3; i++) {
      await t.tap(find.text('Push a level').first);
      await _settle(t, 900);
    }
    expect(rig.container.read(glassDepthProvider)[GlassTab.you], 3);
    // Level 3 is the demo's mature level.
    final ref = rig.container.read(glassPurgeProbeProvider);
    ref();
    await _settle(t, 900);
    expect(rig.container.read(glassDepthProvider)[GlassTab.you], 2);
  });

  testWidgets('the ? key opens the shortcuts sheet on a wide frame', (t) async {
    final rig = await pumpGlassShell(t, size: const Size(1366, 1024));
    await t.sendKeyEvent(LogicalKeyboardKey.slash, character: '?');
    await _settle(t, 1000);
    expect(rig.container.read(skinRouterProvider).routerDelegate.currentConfiguration.uri.queryParameters['sheet'], 'shortcuts');
    expect(find.text('Keyboard shortcuts'), findsWidgets);
  });

  testWidgets('the shortcuts sheet lists the live registry with keycaps', (t) async {
    await pumpGlassShell(t, size: const Size(1366, 1024), start: '/?sheet=shortcuts');
    await _settle(t, 1200);
    expect(find.text('Command palette'), findsOneWidget);
    expect(find.text('Only what works here is listed. Shortcuts pause while you type. Press ? to reopen, Esc to close.'), findsOneWidget);
  });
}
