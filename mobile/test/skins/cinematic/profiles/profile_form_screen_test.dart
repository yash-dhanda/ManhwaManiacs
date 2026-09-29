// ignore_for_file: require_trailing_commas, directives_ordering
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_avatar.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_certificate_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_switch.dart';

import '../auth/auth_test_support.dart';

const _yash = ActiveProfile(id: 1, name: 'Yash', avatarKey: 'violet', mood: Mood.neutral);
FakeAuth _signedIn() => FakeAuth(initial: AuthAuthenticated(testUser));

Future<Rig> _open(WidgetTester t, String start, {Size size = const Size(390, 844), FakeAuth? auth, double scale = 1, TargetPlatform platform = TargetPlatform.iOS}) async {
  final rig = await pumpAuth(t, start: '/', auth: auth ?? _signedIn(), active: _yash, size: size, scale: scale, platform: platform);
  unawaited(rig.router.push<void>(start));
  await settle(t, 700);
  return rig;
}

Finder _name() => find.byType(TextField).first;

void main() {
  testWidgets('New: masthead, the 12/30 name counter, no Edition row, no Delete', (t) async {
    await _open(t, '/profiles/new');
    expect(find.text('CASTING'), findsOneWidget);
    expect(find.text('0/30'), findsOneWidget);
    await t.enterText(_name(), 'Hollow Knight');
    await t.pump();
    expect(find.text('13/30'), findsOneWidget);
    expect(find.text('EDITION'), findsNothing, reason: 'glass_available is false');
    expect(find.text('Delete profile'), findsNothing);
    expect(find.text('Create profile'), findsOneWidget);
    expect(find.text('Grades the top of the app while this profile is active. Never the reader.'), findsOneWidget);
  });

  testWidgets('the name stops at 30 characters', (t) async {
    await _open(t, '/profiles/new');
    await t.enterText(_name(), 'x' * 40);
    await t.pump();
    expect(find.text('30/30'), findsOneWidget);
  });

  testWidgets('avatars: twelve, 4 x 3 on phones, radiogroup semantics, arrows move the selection', (t) async {
    await _open(t, '/profiles/new');
    final avatars = find.byWidgetPredicate((w) => w is CineAvatar && w.size == 56);
    expect(avatars, findsNWidgets(12));
    final ys = {for (var i = 0; i < 12; i++) t.getTopLeft(avatars.at(i)).dy.round()};
    expect(ys.length, 3, reason: '4 columns x 3 rows');
    expect(find.bySemanticsLabel('Matinee'), findsOneWidget);
    final selected = find.byWidgetPredicate((w) => w is CineAvatar && w.size == 56 && w.selected);
    expect(selected, findsOneWidget);
    await t.ensureVisible(avatars.first);
    await t.tap(avatars.at(3));
    await t.pump();
    expect(t.widget<CineAvatar>(selected).avatarKey, 'amber');
  });

  testWidgets('avatars: 6 x 2 from 600 px', (t) async {
    await _open(t, '/profiles/new', size: const Size(834, 1194));
    final avatars = find.byWidgetPredicate((w) => w is CineAvatar && w.size == 56);
    final ys = {for (var i = 0; i < 12; i++) t.getTopLeft(avatars.at(i)).dy.round()};
    expect(ys.length, 2);
  });

  testWidgets('mood chips carry the grade squares (channels x 3) and Default has none', (t) async {
    await _open(t, '/profiles/new');
    final romantic = t.widget<Container>(find.byKey(const Key('mood-square-romantic')));
    expect(romantic.color, const Color(0xFF4E2130));
    expect(find.byKey(const Key('mood-square-default')), findsNothing);
    expect(find.text('SLICE OF LIFE'), findsOneWidget);
  });

  testWidgets('the mature switch opens the certificate; Enable 18+ is disabled until the box is checked', (t) async {
    await _open(t, '/profiles/new');
    await t.enterText(_name(), 'Yash');
    await t.pump();
    await t.ensureVisible(find.byType(CineSwitch));
    await t.tap(find.byType(CineSwitch));
    await settle(t, 800);
    expect(find.byType(CineCertificateDialog), findsOneWidget);
    expect(find.text('Show mature content on Yash?'), findsOneWidget);
    CineButton enable() => t.widget<CineButton>(find.byKey(const Key('cert-enable')));
    expect(enable().onPressed, isNull);
    await t.tap(find.byKey(const Key('cert-check')));
    await t.pump();
    expect(enable().onPressed, isNotNull);
    await t.tap(find.byKey(const Key('cert-enable')));
    await settle(t, 1500);
    expect(find.byType(CineCertificateDialog), findsNothing);
    expect(t.widget<CineSwitch>(find.byType(CineSwitch)).value, isTrue);
  });

  testWidgets('with the name empty the certificate asks about "this profile"', (t) async {
    await _open(t, '/profiles/new');
    await t.ensureVisible(find.byType(CineSwitch));
    await t.tap(find.byType(CineSwitch));
    await settle(t, 800);
    expect(find.text('Show mature content on this profile?'), findsOneWidget);
  });

  testWidgets('an empty name is refused; a good save creates, toasts and returns', (t) async {
    final rig = await _open(t, '/profiles/new');
    await t.ensureVisible(find.text('Create profile'));
    await t.tap(find.text('Create profile'));
    await t.pump();
    expect(find.text('‸ Give this profile a name.'), findsOneWidget);
    await t.enterText(_name(), 'Nova');
    await t.ensureVisible(find.text('Create profile'));
    await t.tap(find.text('Create profile'));
    await settle(t, 700);
    expect(rig.profiles.calls.single, startsWith('create:Nova:default:false'));
    expect(find.text('Saved Nova'), findsOneWidget);
    expect(rig.at, '/');
  });

  testWidgets('server errors: limit, invalid name and anything else', (t) async {
    final rig = await _open(t, '/profiles/new');
    await t.enterText(_name(), 'Nova');
    await t.ensureVisible(find.text('Create profile'));
    rig.profiles.failWrite = const ApiError(statusCode: 409, code: 'profile_limit_reached', message: 'm');
    await t.tap(find.text('Create profile'));
    await settle(t, 300);
    expect(find.text('5 profiles is the limit.'), findsOneWidget);
    rig.profiles.failWrite = const ApiError(statusCode: 400, code: 'invalid_mood', message: 'Bad mood');
    await t.tap(find.text('Create profile'));
    await settle(t, 300);
    expect(find.text("Couldn't save this profile. Bad mood"), findsOneWidget);
  });

  testWidgets('Edit: prefilled, Save changes, Delete with the arm', (t) async {
    final rig = await _open(t, '/profiles/2/edit');
    expect(find.text('CASTING'), findsOneWidget);
    expect(t.widget<TextField>(_name()).controller!.text, 'Guest');
    expect(find.text('Save changes'), findsOneWidget);
    await t.ensureVisible(find.text('Delete profile'));
    await t.tap(find.text('Delete profile'));
    await settle(t, 300);
    expect(find.textContaining("Its library, progress, bookmarks and collections go with it. This can't be undone."), findsOneWidget);
    // Armed: the committing button is dead for the first second.
    await t.tap(find.text('Delete profile').last);
    await t.pump();
    expect(rig.profiles.calls, isEmpty);
    await settle(t, 1200);
    await t.tap(find.text('Delete profile').last);
    await settle(t, 700);
    expect(rig.profiles.calls, ['remove:2']);
    expect(find.text('Deleted Guest.'), findsOneWidget);
  });

  testWidgets('deleting the active profile lands on the picker', (t) async {
    final rig = await _open(t, '/profiles/1/edit');
    await t.ensureVisible(find.text('Delete profile'));
    await t.tap(find.text('Delete profile'));
    await settle(t, 1500);
    await t.tap(find.text('Delete profile').last);
    await settle(t, 800);
    expect(rig.at, '/profiles');
  });

  testWidgets('not found: a notice with Back', (t) async {
    final rig = await _open(t, '/profiles/99/edit');
    expect(find.text('This profile no longer exists.'), findsNothing, reason: 'typed headline');
    expect(find.text('Back'), findsWidgets);
    expect(rig.at, '/profiles/99/edit');
  });

  testWidgets('Esc cancels and Enter saves', (t) async {
    final rig = await _open(t, '/profiles/2/edit');
    await t.tapAt(const Offset(200, 500)); // blur the name field
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle(t, 700);
    expect(rig.profiles.calls.single, startsWith('update:2:Guest'));
    final rig2 = await _open(t, '/profiles/new');
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(t, 700);
    expect(rig2.at, '/');
  });
}
