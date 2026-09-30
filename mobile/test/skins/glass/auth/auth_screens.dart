import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/auth/models/bootstrap_status.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/skins/glass/dev/auth_fixtures.dart';

import '../shell/shell_rig.dart';
import 'auth_rig.dart';

/// One screen of `mobile/30` and what it needs to mount: the shared list of the accessibility, budget, reduced and solid tests.
class AuthCase {
  const AuthCase(this.name, this.path, this.fixture, {this.setupDone = true, this.sessionReady = false});
  final String name;
  final String path;
  final GlassAuthFixture fixture;
  final bool setupDone;
  final bool sessionReady;

  Future<ShellRig> pump(WidgetTester t, {Size size = const Size(390, 844), bool android = false, bool reduced = false}) =>
      pumpAuth(t, path, fixture, size: size, setupDone: setupDone, sessionReady: sessionReady, android: android, reduced: reduced);
}

const _active = ActiveProfile(id: 1, name: 'Yash', avatarKey: 'violet', mood: Mood.fantasy);

GlassAuthFixture _signed({List<Profile>? profiles}) => GlassAuthFixture(signedIn: true, profiles: profiles ?? fixtureProfiles(), active: _active);

final List<AuthCase> authCases = [
  const AuthCase('setup', '/setup', GlassAuthFixture(), setupDone: false),
  const AuthCase('login', '/login', GlassAuthFixture()),
  const AuthCase('register', '/register', GlassAuthFixture()),
  const AuthCase('register-bootstrap', '/register', GlassAuthFixture(bootstrap: BootstrapStatus(needsBootstrap: true, registrationEnabled: true))),
  AuthCase('picker', '/profiles', _signed()),
  AuthCase('picker-switch', '/profiles', _signed(), sessionReady: true),
  AuthCase('profile-form', '/profiles/new', _signed()),
  AuthCase('profile-edit', '/profiles/2/edit', _signed()),
  AuthCase('manage', '/profiles/manage', _signed()),
  AuthCase('onboarding-1', '/welcome?step=1', GlassAuthFixture(signedIn: true, profiles: [fixtureProfile(1, 'Yash', step: null)], active: _active)),
  AuthCase('onboarding-3', '/welcome?step=3', GlassAuthFixture(signedIn: true, profiles: [fixtureProfile(1, 'Yash', step: '3')], active: _active)),
  AuthCase('onboarding-4', '/welcome?step=4', GlassAuthFixture(signedIn: true, profiles: [fixtureProfile(1, 'Yash', step: '4')], active: _active)),
  AuthCase('onboarding-5', '/welcome?step=5', GlassAuthFixture(signedIn: true, profiles: [fixtureProfile(1, 'Yash', step: '5')], active: _active)),
  AuthCase('onboarding-6', '/welcome?step=6', GlassAuthFixture(signedIn: true, profiles: [fixtureProfile(1, 'Yash', step: '6')], active: _active)),
];
