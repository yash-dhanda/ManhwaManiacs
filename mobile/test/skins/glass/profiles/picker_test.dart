import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/dev/auth_fixtures.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/screens/auth/lens_split_handoff.dart';
import 'package:manhwamaniacs/skins/glass/screens/profiles/restart_into.dart';
import 'package:manhwamaniacs/skins/glass/shell/dock_geometry.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';
import 'package:manhwamaniacs/skins/glass/shell/sidebar_geometry.dart';
import 'package:manhwamaniacs/skins/skins.dart';

import '../../../screenshots/support/shot_harness.dart';
import '../auth/auth_rig.dart';

GlassAuthFixture _fx({int n = 4, List<Profile>? profiles}) => GlassAuthFixture(signedIn: true, profiles: profiles ?? fixtureProfiles(n));

Finder _orb(String name) => find.bySemanticsLabel('Read as $name');

/// Tabs until an orb has focus (the nav row's buttons come first in reading order).
Future<void> _focusOrb(WidgetTester t) async {
  for (var i = 0; i < 8; i++) {
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pump();
    if (FocusManager.instance.primaryFocus?.debugLabel?.startsWith('orb-') ?? false) return;
  }
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('the title, the subline, the orbs with their names and the Add orb', (t) async {
    final h = t.ensureSemantics();
    await pumpAuth(t, '/profiles', _fx());
    await settleFor(t, 2500);
    expect(find.text("Who's reading?"), findsWidgets);
    expect(find.text('Your library, progress and mood follow the profile you pick.'), findsOneWidget);
    expect(find.text('Yash'), findsOneWidget);
    expect(find.text('Late-night reads'), findsOneWidget);
    expect(_orb('Yash'), findsOneWidget);
    expect(find.bySemanticsLabel('Add profile'), findsOneWidget);
    h.dispose();
  });

  testWidgets('arrows move focus between orbs', (t) async {
    await pumpAuth(t, '/profiles', _fx());
    await settleFor(t, 2500);
    await _focusOrb(t);
    final first = FocusManager.instance.primaryFocus?.debugLabel;
    expect(first, startsWith('orb-'));
    await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await t.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, isNot(first));
  });

  testWidgets('Enter runs the hand-off and commits within 1,300 ms of fake time', (t) async {
    final rig = await pumpAuth(t, '/profiles', _fx());
    await settleFor(t, 2500);
    await _focusOrb(t);
    final epoch0 = rig.container.read(glassRouterEpochProvider).epoch;
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pump();
    await settleFor(t);
    expect(rig.container.read(glassRouterEpochProvider).epoch, epoch0, reason: 'not yet at 1,000 ms');
    await settleFor(t, 300);
    expect(rig.container.read(glassRouterEpochProvider).epoch, epoch0 + 1);
    expect(rig.container.read(glassRouterEpochProvider).destination, '/');
    await settleFor(t, 2000);
  });

  testWidgets('the dock target is the You tab at 390 x 844 and the sidebar capsule at 1366 x 1024', (t) async {
    expect(GlassDockGeometry.of(const Size(390, 844), EdgeInsets.zero).tabRect(GlassTab.you).center.dy, greaterThan(700));
    final g = GlassSidebarGeometry.of(const Size(1366, 1024), expanded: true);
    expect(g.profileCapsule.bottom, lessThan(1024));
    expect(g.profileCapsule.left, greaterThan(0));
  });

  testWidgets('a second tap before 450 ms changes the choice', (t) async {
    final rig = await pumpAuth(t, '/profiles', _fx());
    await settleFor(t, 2500);
    await t.tap(_orb('Yash'));
    await t.pump(const Duration(milliseconds: 16));
    await t.tap(_orb('Late-night reads'), warnIfMissed: false);
    await settleFor(t, 100);
    await settleFor(t, 2000);
    expect(rig.container.read(activeProfileProvider)?.id, 2);
  });

  testWidgets('a profile whose skin is Cinematic melts and restarts with no alert', (t) async {
    final asked = <SkinId>[];
    restartIntoSkinTestHook = (skin, route) async => asked.add(skin);
    addTearDown(() => restartIntoSkinTestHook = null);
    await pumpAuth(t, '/profiles', _fx(profiles: [fixtureProfile(1, 'Yash', skin: 'cinematic'), fixtureProfile(2, 'Sunday')]));
    await settleFor(t, 2500);
    await t.tap(_orb('Yash'));
    await t.pump();
    await settleFor(t, 1300);
    await settleFor(t);
    expect(asked, [SkinId.cinematic]);
    expect(find.textContaining('Restart in'), findsNothing);
  });

  testWidgets('e opens the form as a sheet route, n adds', (t) async {
    final rig = await pumpAuth(t, '/profiles', _fx());
    await settleFor(t, 2500);
    await _focusOrb(t);
    await t.sendKeyEvent(LogicalKeyboardKey.keyE);
    await settleFor(t, 1200);
    expect(rig.at, startsWith('/profiles/'));
    expect(rig.at, endsWith('/edit'));
    await t.binding.handlePopRoute();
    await settleFor(t);
    await t.sendKeyEvent(LogicalKeyboardKey.keyN);
    await settleFor(t, 1200);
    expect(rig.at, '/profiles/new');
  });

  testWidgets('manage mode shows the pencil badges and Done leaves it', (t) async {
    await pumpAuth(t, '/profiles', _fx());
    await settleFor(t, 2500);
    expect(find.text('Edit'), findsOneWidget);
    await t.tap(find.text('Edit'));
    await settleFor(t, 400);
    expect(find.text('Done'), findsOneWidget);
    await t.tap(find.text('Done'));
    await settleFor(t, 400);
    expect(find.text('Edit'), findsOneWidget);
  });

  testWidgets('switch mode has a back button', (t) async {
    final h = t.ensureSemantics();
    await pumpAuth(t, '/profiles', _fx(), sessionReady: true);
    await settleFor(t, 2500);
    expect(find.bySemanticsLabel(RegExp('^Back')), findsWidgets);
    h.dispose();
  });

  testWidgets('the session gate has no back button', (t) async {
    final h = t.ensureSemantics();
    await pumpAuth(t, '/profiles', _fx());
    await settleFor(t, 2500);
    expect(find.bySemanticsLabel(RegExp('^Back')), findsNothing);
    h.dispose();
  });

  testWidgets('the lens split arrival consumes the hand-off value', (t) async {
    final rig = await pumpAuth(t, '/profiles', _fx(), settle: false, extra: [glassLensSplitProvider.overrideWith((ref) => const GlassLensSplit(centre: Offset(195, 150), radius: 28))]);
    await settleFor(t, 300);
    await settleFor(t, 700);
    expect(rig.container.read(glassLensSplitProvider), isNull);
    await settleFor(t, 2000);
  });

  testWidgets('empty state', (t) async {
    await pumpAuth(t, '/profiles', const GlassAuthFixture(signedIn: true, profiles: []));
    await settleFor(t, 2500);
    expect(find.text('Create your first profile'), findsWidgets);
    expect(find.text('Add profile'), findsWidgets);
  });

  testWidgets('error state with no cache', (t) async {
    await pumpAuth(t, '/profiles', const GlassAuthFixture(signedIn: true, profilesError: ApiError(statusCode: 500, code: 'x', message: 'It broke.')));
    await settleFor(t, 2500);
    expect(find.text('Profiles are unavailable'), findsOneWidget);
    expect(find.text('It broke.'), findsOneWidget);
  });

  testWidgets('unreachable with a cached profile', (t) async {
    await pumpAuth(t, '/profiles', const GlassAuthFixture(signedIn: true, profilesError: NetworkError(message: 'x'), active: ActiveProfile(id: 1, name: 'Yash', avatarKey: 'violet', mood: Mood.fantasy)));
    await settleFor(t, 2500);
    expect(find.text("The server isn't answering."), findsOneWidget);
    expect(find.text('Continue as Yash'), findsWidgets);
    expect(find.text('Try again'), findsWidgets);
    await t.pumpWidget(const SizedBox.shrink());
    await t.pump(const Duration(seconds: 30));
  });

  testWidgets('at the limit', (t) async {
    await pumpAuth(t, '/profiles', _fx(n: 5));
    await settleFor(t, 2500);
    expect(find.text('Up to 5 profiles'), findsOneWidget);
    expect(find.text('Add profile'), findsNothing);
  });

  testWidgets('a profile with a closed gate gives the picker no 18+ hint', (t) async {
    await pumpAuth(t, '/profiles', _fx());
    await settleFor(t, 2500);
    expect(find.textContaining('18'), findsNothing);
  });

  testWidgets('the haptic on landing is profile.select', (t) async {
    GlassHaptics.debugLog.clear();
    await pumpAuth(t, '/profiles', _fx());
    await settleFor(t, 2500);
    await t.tap(_orb('Yash'));
    await t.pump();
    await settleFor(t, 1400);
    await settleFor(t, 2000);
    expect(GlassHaptics.debugLog.map((e) => e.event), contains(HapticEvent.profileSelect));
  });
}
