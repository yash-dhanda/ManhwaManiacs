// ignore_for_file: require_trailing_commas, directives_ordering
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/session_end_reason_provider.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart' show activeProfileProvider;
import 'package:manhwamaniacs/skins/cinematic/icons/cine_icon.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_badge.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/typed_headline.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/auth/auth_copy.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

import '../auth/auth_test_support.dart';

const _yash = ActiveProfile(id: 1, name: 'Yash', avatarKey: 'violet', mood: Mood.neutral);

FakeAuth _signedIn() => FakeAuth(initial: AuthAuthenticated(testUser));
Finder _question(String text) => find.byWidgetPredicate((w) => w is TypedHeadline && w.text == text);

void main() {
  testWidgets('the picker lists the profiles, marks NEW and never auto-skips', (t) async {
    final rig = await pumpAuth(t, start: '/profiles', auth: _signedIn(), active: _yash);
    await settle(t, 500);
    expect(find.bySemanticsLabel('Read as Yash'), findsOneWidget);
    expect(find.bySemanticsLabel('Read as Guest'), findsOneWidget);
    expect(find.text('NEW'), findsOneWidget, reason: 'the profile whose onboarding is not done');
    expect(find.bySemanticsLabel('New profile'), findsOneWidget);
    expect(rig.at, '/profiles');
  });

  for (final (hour, text) in [(8, "Who's reading this morning?"), (14, "Who's reading this afternoon?"), (21, "Who's reading tonight?")]) {
    testWidgets('the question at $hour:00 is "$text"', (t) async {
      await pumpAuth(t, start: '/profiles', auth: _signedIn(), clock: () => DateTime(2026, 9, 29, hour));
      await settle(t, 300);
      expect(_question(text), findsOneWidget);
    });
  }

  testWidgets('Right then Enter runs the Iris and lands on Tonight with the profile.select haptic', (t) async {
    final rig = await pumpAuth(t, start: '/profiles', auth: _signedIn(), active: _yash);
    await settle(t, 300);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pump(const Duration(milliseconds: 100));
    expect(rig.at, '/profiles', reason: 'the ring is still drawing');
    await settle(t, 2500);
    expect(rig.at, '/welcome?step=2', reason: 'Guest has not begun onboarding: the iris opens it (mobile/20)');
    expect(rig.haptics, contains(HapticEvent.profileSelect));
    expect(rig.container.read(activeProfileProvider)?.name, 'Guest');
  });

  testWidgets('a second tap during the ring skips to the open: home well before the full iris', (t) async {
    final rig = await pumpAuth(t, start: '/profiles', auth: _signedIn(), active: _yash);
    await settle(t, 300);
    await t.tap(find.bySemanticsLabel('Read as Yash'));
    await t.pump(const Duration(milliseconds: 100));
    await t.tap(find.bySemanticsLabel('Read as Yash'), warnIfMissed: false);
    // The ring is cut short; only the close remains before the route changes.
    await t.pump(const Duration(milliseconds: 20));
    await t.pump(const Duration(milliseconds: 600));
    expect(rig.at, '/');
    await settle(t, 1500);
  });

  testWidgets('a tap on an avatar picks it; reduced motion cross-fades in about 200 ms', (t) async {
    final rig = await pumpAuth(t, start: '/profiles', auth: _signedIn(), active: _yash, reduced: true);
    await settle(t, 300);
    await t.tap(find.bySemanticsLabel('Read as Yash'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 250));
    expect(rig.at, '/', reason: 'no ring, no iris travel: a 100 ms fade to black then the route');
    await settle(t, 800);
    expect(rig.container.read(activeProfileProvider)?.name, 'Yash');
  });

  testWidgets('m shows the pencils, e opens edit, n opens the new form', (t) async {
    final rig = await pumpAuth(t, start: '/profiles', auth: _signedIn(), active: _yash);
    await settle(t, 300);
    Finder pencils() => find.byWidgetPredicate((w) => w is CineIcon && w.role == CineIconRole.edit);
    expect(pencils(), findsNothing);
    await t.sendKeyEvent(LogicalKeyboardKey.keyM);
    await t.pump();
    expect(pencils(), findsNWidgets(2));
    await t.sendKeyEvent(LogicalKeyboardKey.keyM);
    await t.pump();
    expect(pencils(), findsNothing);
    await t.sendKeyEvent(LogicalKeyboardKey.keyE);
    await settle(t, 600);
    expect(rig.at, '/profiles/1/edit');
    rig.router.pop();
    await settle(t, 600);
    await t.sendKeyEvent(LogicalKeyboardKey.keyN);
    await settle(t, 600);
    expect(rig.at, '/profiles/new');
  });

  testWidgets('in manage mode a tap opens the edit form instead of picking', (t) async {
    final rig = await pumpAuth(t, start: '/profiles', auth: _signedIn(), active: _yash);
    await settle(t, 300);
    await t.tap(find.text('Manage'));
    await t.pump();
    await t.tap(find.bySemanticsLabel('Edit Guest'));
    await settle(t, 600);
    expect(rig.at, '/profiles/2/edit');
  });

  testWidgets('the sign-in picker has no back button; the Switch picker has one', (t) async {
    await pumpAuth(t, start: '/profiles', auth: _signedIn(), active: _yash);
    await settle(t, 300);
    expect(find.bySemanticsLabel('Back'), findsNothing);
  });

  testWidgets('Switch profile: a back button pops and the previous profile stays active', (t) async {
    final rig = await pumpAuth(t, start: '/', auth: _signedIn(), active: _yash);
    await settle(t, 100);
    unawaited(rig.router.push<void>('/profiles', extra: const <String, String>{'mode': 'switch'}));
    await settle(t, 600);
    expect(find.bySemanticsLabel('Back'), findsOneWidget);
    await t.tap(find.bySemanticsLabel('Back'));
    await settle(t, 600);
    expect(rig.at, '/');
    expect(rig.container.read(activeProfileProvider)?.name, 'Yash');
  });

  testWidgets('profile-gone: the toast shows and the reason clears', (t) async {
    final rig = await pumpAuth(t, start: '/profiles', auth: _signedIn(), extra: [sessionEndReasonProvider.overrideWith((ref) => SessionEndReason.profileGone)]);
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text(kProfileGoneToast), findsOneWidget);
    expect(rig.container.read(sessionEndReasonProvider), isNull);
  });

  testWidgets('an 18+ profile shows the certificate at its avatar; nothing else does', (t) async {
    await pumpAuth(t, start: '/profiles', auth: _signedIn(), profiles: [profile(1, 'Adult', mature: true), profile(2, 'Kid')]);
    await settle(t, 300);
    expect(find.byWidgetPredicate((w) => w is CineBadge && w.variant == CineBadgeVariant.certificate), findsOneWidget);
  });

  testWidgets('five profiles hide New profile', (t) async {
    await pumpAuth(t, start: '/profiles', auth: _signedIn(), profiles: [for (var i = 1; i <= 5; i++) profile(i, 'P$i')]);
    await settle(t, 300);
    expect(find.bySemanticsLabel('New profile'), findsNothing);
  });

  testWidgets('empty house: the notice with New profile', (t) async {
    await pumpAuth(t, start: '/profiles', auth: _signedIn(), profiles: const []);
    await settle(t, 300);
    expect(find.text('EMPTY HOUSE'), findsOneWidget);
    expect(find.text('New profile'), findsWidgets);
  });

  testWidgets('a failed list with no cached profile shows the correction notice and Retry', (t) async {
    await pumpAuth(t, start: '/profiles', auth: _signedIn(), listFails: true);
    await settle(t, 600);
    expect(find.text('CORRECTION'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('a failed list with a cached profile offers to continue as it', (t) async {
    await pumpAuth(t, start: '/profiles', auth: _signedIn(), active: _yash, listFails: true);
    await settle(t, 600);
    expect(find.textContaining('Continue as Yash, or retry.'), findsOneWidget);
    expect(find.bySemanticsLabel('Read as Yash'), findsOneWidget);
  });

  testWidgets('Switch account arms and then signs out', (t) async {
    final auth = _signedIn();
    await pumpAuth(t, start: '/profiles', auth: auth, active: _yash);
    await settle(t, 300);
    await t.tap(find.bySemanticsLabel('More'));
    await settle(t, 300);
    await t.tap(find.text('Switch account…'));
    await settle(t, 300);
    expect(find.text('Switch account?'), findsOneWidget);
    expect(find.text("You'll be signed out on this device; saved chapters stay."), findsOneWidget);
    await settle(t, 1200);
    await t.tap(find.text('Switch account'));
    await settle(t, 600);
    expect(auth.logouts, 1);
  });
}
