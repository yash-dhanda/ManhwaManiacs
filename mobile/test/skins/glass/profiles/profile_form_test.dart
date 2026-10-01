import 'package:flutter/material.dart' show TextField;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/skins/glass/dev/auth_fixtures.dart';
import 'package:manhwamaniacs/skins/glass/glass/ambient_field.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/profile_orb.dart';
import 'package:manhwamaniacs/skins/glass/primitives/switch.dart';

import '../../../screenshots/support/shot_harness.dart';
import '../auth/auth_rig.dart';

GlassAuthFixture _fx({List<Profile>? profiles, ActiveProfile? active}) => GlassAuthFixture(signedIn: true, profiles: profiles ?? fixtureProfiles(), active: active);

Future<void> _open(WidgetTester t, String path, {GlassAuthFixture? f, List<Override> extra = const []}) async {
  await pumpAuth(t, path, f ?? _fx(), extra: extra);
  await settleFor(t, 1500);
}

Future<void> _name(WidgetTester t, String v) async {
  await t.enterText(find.byType(TextField).first, v);
  await t.pump();
}

/// Scrolls the form's vertical scrollable until [f] is on screen (`ensureVisible` leaves the page variant's far rows below the fold).
Future<void> _reveal(WidgetTester t, Finder f) async {
  await t.scrollUntilVisible(f, 300, scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axis == Axis.vertical).first, maxScrolls: 30);
  await t.pump(const Duration(milliseconds: 100));
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('a new profile: the name limit, the counter and a primary that waits for a name', (t) async {
    await _open(t, '/profiles/new');
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Create profile'), findsWidgets);
    GlassButton primary() => t.widget<GlassButton>(find.widgetWithText(GlassButton, 'Create profile'));
    expect(primary().onPressed, isNull);
    await _name(t, 'a' * 40);
    expect(t.widget<TextField>(find.byType(TextField).first).controller!.text.length, 30);
    expect(find.text('30/30'), findsOneWidget);
    expect(primary().onPressed, isNotNull);
    await _name(t, 'Reader');
    expect(find.text('6/30'), findsNothing, reason: 'the counter starts at 24');
  });

  testWidgets('the avatar radio group names the presets and one is checked', (t) async {
    final h = t.ensureSemantics();
    await _open(t, '/profiles/new');
    expect(find.bySemanticsLabel('Violet Spark'), findsWidgets);
    expect(find.bySemanticsLabel('Cyan Rocket'), findsOneWidget);
    await _reveal(t, find.bySemanticsLabel('Cyan Rocket'));
    await t.tap(find.bySemanticsLabel('Cyan Rocket'));
    await settleFor(t, 100);
    await settleFor(t, 400);
    expect(find.byWidgetPredicate((w) => w is GlassProfileOrb && w.size == 96 && w.preset == GlassAvatarPreset.cyanRocket), findsOneWidget);
    h.dispose();
  });

  testWidgets('the mood chips retint the sheet field', (t) async {
    await _open(t, '/profiles/new');
    final chips = find.byType(GlassChoiceChips<Mood>);
    await _reveal(t, chips);
    await t.ensureVisible(find.text('Horror'));
    await t.pump(const Duration(milliseconds: 100));
    await t.tap(find.text('Horror'));
    await settleFor(t, 1200);
    final painter = t.widgetList<CustomPaint>(find.byType(CustomPaint)).map((w) => w.painter).whereType<GlassFieldPainter>().last;
    expect(painter.blobs.colors.first, moodColour(Mood.horror));
  });

  testWidgets('a new profile is created with the skin written explicitly', (t) async {
    await _open(t, '/profiles/new');
    await _name(t, 'Reader');
    await _reveal(t, find.widgetWithText(GlassButton, 'Create profile'));
    await t.tap(find.widgetWithText(GlassButton, 'Create profile'));
    await settleFor(t, 800);
    expect(FakeProfiles.calls, ['create:Reader']);
    expect(FakeProfiles.lastExtras!.skin, 'glass');
  });

  testWidgets('the daily goal: Off after a value sends an explicit null', (t) async {
    await _open(t, '/profiles/1/edit', f: _fx(profiles: [fixtureProfile(1, 'Yash', goal: 30), fixtureProfile(2, 'B')]));
    expect(find.text('30 min'), findsOneWidget);
    await _reveal(t, find.text('Daily goal'));
    await t.tap(find.text('Daily goal'));
    await settleFor(t, 700);
    await t.tap(find.text('Off').last);
    await settleFor(t, 700);
    await _reveal(t, find.widgetWithText(GlassButton, 'Save changes'));
    await t.tap(find.widgetWithText(GlassButton, 'Save changes'));
    await settleFor(t, 800);
    expect(FakeProfiles.lastExtras!.dailyGoal!.minutes, isNull);
    expect(FakeProfiles.lastExtras!.dailyGoal, isNotNull);
  });

  testWidgets('the Skin row is present with the flag on', (t) async {
    await _open(t, '/profiles/new');
    expect(find.text('Cinematic'), findsOneWidget);
  });

  testWidgets("the active profile's skin change opens the restart alert after the other fields save", (t) async {
    await _open(t, '/profiles/1/edit', f: _fx(active: const ActiveProfile(id: 1, name: 'Yash', avatarKey: 'violet', mood: Mood.fantasy)));
    await _reveal(t, find.text('Cinematic'));
    await t.tap(find.text('Cinematic'));
    await settleFor(t, 300);
    await _reveal(t, find.widgetWithText(GlassButton, 'Save changes'));
    await t.tap(find.widgetWithText(GlassButton, 'Save changes'));
    await settleFor(t, 1200);
    expect(FakeProfiles.calls, ['edit:1']);
    expect(find.text('Restart in Cinematic?'), findsOneWidget);
    await t.tap(find.text('Stay in Glass'));
    await settleFor(t, 800);
    expect(find.text('Restart in Cinematic?'), findsNothing);
  });

  testWidgets('the 18+ switch opens the alert with the enable button visible', (t) async {
    await _open(t, '/profiles/new');
    await _reveal(t, find.byType(GlassSwitch).last);
    await t.tap(find.byType(GlassSwitch).last);
    await settleFor(t);
    expect(find.text('Show mature content?'), findsOneWidget);
    expect(find.text('I am 18 or older, enable'), findsOneWidget);
  });

  testWidgets('offline: the primary is disabled with the reason under it', (t) async {
    await pumpAuth(t, '/profiles/new', _fx(), online: false);
    await settleFor(t, 1500);
    await _name(t, 'Reader');
    expect(find.text('Profiles need a connection to save'), findsWidgets);
    expect(t.widget<GlassButton>(find.widgetWithText(GlassButton, 'Create profile')).onPressed, isNull);
  });

  testWidgets('delete goes through the alert and its visible fallback', (t) async {
    await _open(t, '/profiles/2/edit');
    await _reveal(t, find.widgetWithText(GlassButton, 'Delete profile'));
    await t.tap(find.widgetWithText(GlassButton, 'Delete profile'));
    await settleFor(t);
    expect(find.text('Delete Late-night reads?'), findsOneWidget);
    expect(find.text('Hold to delete'), findsOneWidget);
    await t.tap(find.text('Delete profile').last);
    await settleFor(t);
    expect(FakeProfiles.calls, contains('delete:2'));
  });

  testWidgets('opened from the picker with an origin it is a sheet over the picker', (t) async {
    final rig = await pumpAuth(t, '/profiles', _fx());
    await settleFor(t, 2500);
    await t.tap(find.bySemanticsLabel('Add profile').first, warnIfMissed: false);
    await settleFor(t, 1400);
    expect(rig.at, '/profiles/new');
    expect(find.text("Who's reading?"), findsWidgets, reason: 'the picker stays mounted under the sheet');
    expect(find.text('Add profile'), findsWidgets);
  });

  testWidgets('Esc closes the form', (t) async {
    final rig = await pumpAuth(t, '/profiles', _fx());
    await settleFor(t, 2500);
    await t.tap(find.bySemanticsLabel('Add profile').first, warnIfMissed: false);
    await settleFor(t, 1400);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await settleFor(t);
    expect(rig.at, '/profiles');
  });

  testWidgets('the mobile alias /profiles/create resolves to /profiles/new', (t) async {
    final rig = await pumpAuth(t, '/profiles/create', _fx());
    await settleFor(t, 800);
    expect(rig.at, '/profiles/new');
  });

  testWidgets('the mobile alias /profiles/edit/2 resolves to /profiles/2/edit', (t) async {
    final rig = await pumpAuth(t, '/profiles/edit/2', _fx());
    await settleFor(t, 800);
    expect(rig.at, '/profiles/2/edit');
  });
}
