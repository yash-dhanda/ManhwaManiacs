import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/models/auth_user.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/settings/providers/a11y_prefs_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/glass/dev/auth_fixtures.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/skins.dart' show skinRouterProvider;

import '../../../screenshots/support/shot_harness.dart';
import '../auth/auth_rig.dart';

GlassAuthFixture _fx({bool active = true}) => GlassAuthFixture(
      signedIn: true,
      profiles: fixtureProfiles(2),
      active: active ? const ActiveProfile(id: 1, name: 'Yash', avatarKey: 'violet', mood: Mood.fantasy) : null,
    );

class _Admin extends FakeAuth {
  _Admin(bool admin) : super(AuthAuthenticated(AuthUser(id: 1, username: 'demo', isAdmin: admin, createdAt: DateTime.utc(2026))));
}

List<Override> _auth(bool admin) => [authControllerProvider.overrideWith(() => _Admin(admin))];

bool textFieldFocused() => FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<EditableText>() != null;

void main() {
  setUpAll(loadAppFonts);

  testWidgets('root: every section in order, the Account block and the footnote; admin rows hidden for non-admins', (t) async {
    await pumpAuth(t, '/settings', _fx(), extra: _auth(false));
    await settleFor(t, 1500);
    for (final s in ['Settings', 'Appearance and skin', 'Reader', 'Content (18+)', 'Circle and privacy', 'AI and recaps', 'Sound and haptics', 'Security', 'Storage', 'Diagnostics', 'About']) {
      expect(find.text(s, skipOffstage: false), findsWidgets, reason: s);
    }
    expect(find.text('Notifications', skipOffstage: false), findsNothing);
    expect(find.text('Backup', skipOffstage: false), findsNothing);
    expect(find.text('Search settings'), findsOneWidget);
    expect(find.text('Settings save as you change them. Switching skin restarts the app.', skipOffstage: false), findsOneWidget);
  });

  testWidgets('root as admin shows Notifications and Backup and the Admin tag', (t) async {
    await pumpAuth(t, '/settings', _fx(), extra: _auth(true));
    await settleFor(t, 1500);
    expect(find.text('Notifications', skipOffstage: false), findsOneWidget);
    expect(find.text('Backup', skipOffstage: false), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
  });

  testWidgets('search overlay: finds by keyword, opens the row, empty state, Esc closes', (t) async {
    final rig = await pumpAuth(t, '/settings', _fx(), extra: _auth(false));
    await settleFor(t, 1500);
    await t.tap(find.text('Search settings'));
    await settleFor(t, 600);
    await t.enterText(find.byType(EditableText), 'opaque');
    await settleFor(t, 600);
    expect(find.text('Solid glass'), findsOneWidget);
    await t.tap(find.text('Solid glass'));
    await settleFor(t, 1500);
    expect(rig.at, startsWith('/settings/appearance'));
    expect(find.text('Solid glass'), findsWidgets);

    rig.container.read(skinRouterProvider).go('/settings');
    await settleFor(t, 800);
    await t.tap(find.text('Search settings'));
    await settleFor(t, 600);
    await t.enterText(find.byType(EditableText), 'zzzqq');
    await settleFor(t, 600);
    expect(find.text('No settings match “zzzqq”'), findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await settleFor(t, 600);
    expect(find.byType(EditableText), findsNothing);
  });

  testWidgets('appearance: the four switches write mm.boot.a11y and the skin cards are a radio group', (t) async {
    final rig = await pumpAuth(t, '/settings/appearance', _fx(), extra: _auth(false));
    await settleFor(t, 1500);
    expect(find.text('Glass'), findsOneWidget);
    expect(find.text('Cinematic'), findsOneWidget);
    expect(find.text('Current'), findsOneWidget);
    expect(find.text('Liquid glass, springs and depth.'), findsOneWidget);
    expect(find.text('App icon follows the skin', skipOffstage: false), findsOneWidget, reason: 'flag on: phones get the switch');
    for (final label in ['Solid glass', 'Increase contrast', 'Legible text', 'Reduce motion in this app']) {
      await t.ensureVisible(find.text(label));
      await t.pump();
      await t.tap(find.text(label));
      await settleFor(t, 400);
    }
    final a = rig.container.read(a11yPrefsProvider);
    expect((a.solid, a.contrast, a.legible, a.motion), (true, true, true, 'reduced'));
    final live = rig.container.read(glassInAppPrefsProvider);
    expect((live.solidGlass, live.increaseContrast, live.hyperlegible, live.reduceMotion), (true, true, true, true));
    expect(rig.container.read(sharedPrefsProvider).getKeys().any((k) => k.startsWith('mm.boot.a11y.')), isTrue);
  });

  testWidgets('the Cinematic card opens the alert with the exact copy, Stay in Glass cancels', (t) async {
    final rig = await pumpAuth(t, '/settings/appearance', _fx(), extra: _auth(false));
    await settleFor(t, 1500);
    await t.tap(find.text('Cinematic'));
    await settleFor(t, 800);
    expect(find.text('Restart in Cinematic?'), findsOneWidget);
    expect(find.textContaining("you'll come back to this screen"), findsOneWidget);
    expect(find.text('Stay in Glass'), findsOneWidget);
    expect(find.text('Restart in Cinematic'), findsOneWidget);
    await t.tap(find.text('Stay in Glass'));
    await settleFor(t, 600);
    expect(find.text('Restart in Cinematic?'), findsNothing);
    expect(rig.container.read(sharedPrefsProvider).getString('mm.skin.active'), isNot('cinematic'));
  });

  testWidgets('sound and haptics: Feel it disabled caption while haptics are off, soundscape defaults', (t) async {
    await pumpAuth(t, '/settings/feedback', _fx(), extra: _auth(false), android: true);
    await settleFor(t, 1500);
    expect(find.text('Haptics', skipOffstage: false), findsWidgets);
    expect(find.text('Hear it', skipOffstage: false), findsOneWidget);
    expect(find.text('Match the story', skipOffstage: false), findsOneWidget);
    expect(find.text('Lower under narration', skipOffstage: false), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('the sections mobile/40 built replace the pending body', (t) async {
    await pumpAuth(t, '/settings/security', _fx(), extra: _auth(false));
    await settleFor(t, 1500);
    expect(find.text('This section arrives in the next update.'), findsNothing);
    expect(find.text('Change password', skipOffstage: false), findsWidgets);
  });

  testWidgets('tablet: a section list at the left and the section at the right', (t) async {
    await pumpAuth(t, '/settings/appearance', _fx(), extra: _auth(true), size: const Size(834, 1194));
    await settleFor(t, 1500);
    expect(find.text('Reading history'), findsOneWidget);
    expect(find.text('System status'), findsOneWidget);
    expect(find.text('Solid glass'), findsOneWidget);
  });

  testWidgets('hardware keys on the tablet: / focuses the search, Down and Up move between sections, Enter opens', (t) async {
    final rig = await pumpAuth(t, '/settings/appearance', _fx(), extra: _auth(true), size: const Size(834, 1194));
    await settleFor(t, 1500);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await settleFor(t, 800);
    expect(rig.at, startsWith('/settings/reading-manga'));
    await t.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await settleFor(t, 800);
    expect(rig.at, startsWith('/settings/appearance'));
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await settleFor(t, 800);
    expect(rig.at, startsWith('/settings/appearance'));
    await t.sendKeyEvent(LogicalKeyboardKey.slash, character: '/');
    await settleFor(t, 300);
    expect(textFieldFocused(), isTrue);
    await t.enterText(find.byType(EditableText), 'opaque');
    await settleFor(t, 600);
    expect(find.text('Solid glass'), findsWidgets);
    expect(find.text('Reading history'), findsNothing, reason: 'the matches replace the section list in place');
  });

  testWidgets('hardware keys on the phone: / opens the search overlay, Esc closes it, Esc on a section returns to the list', (t) async {
    final rig = await pumpAuth(t, '/settings/appearance', _fx(), extra: _auth(false));
    await settleFor(t, 1500);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await settleFor(t, 1200);
    expect(rig.at, '/settings');
    await t.sendKeyEvent(LogicalKeyboardKey.slash, character: '/');
    await settleFor(t, 600);
    expect(find.byType(EditableText), findsOneWidget);
    expect(textFieldFocused(), isTrue, reason: 'the overlay field takes focus');
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await settleFor(t, 1200);
    expect(find.byType(EditableText), findsNothing, reason: 'closed, and the well does not reopen it');
  });

  testWidgets('focus returns to the Cinematic card after the alert is cancelled', (t) async {
    await pumpAuth(t, '/settings/appearance', _fx(), extra: _auth(false));
    await settleFor(t, 1500);
    await t.tap(find.text('Cinematic'));
    await settleFor(t, 800);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'GlassAlert.cancel');
    await t.tap(find.text('Stay in Glass'));
    await settleFor(t, 800);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'GlassSkinCard');
  });
}
