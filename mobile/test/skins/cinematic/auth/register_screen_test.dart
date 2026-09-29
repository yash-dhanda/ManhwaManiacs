// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/auth/models/bootstrap_status.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/typed_headline.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/auth/auth_copy.dart';

import 'auth_test_support.dart';

ApiError _api(String code, {int status = 400}) => ApiError(statusCode: status, code: code, message: 'm');
Finder _headline(String text) => find.byWidgetPredicate((w) => w is TypedHeadline && w.text == text);
Finder _field(int i) => find.byType(TextField).at(i);

Future<void> _valid(WidgetTester t) async {
  await t.enterText(_field(0), 'yash.d');
  await t.enterText(_field(1), 'long-enough-pw');
  await t.enterText(_field(2), 'long-enough-pw');
  await t.pump();
}

void main() {
  testWidgets('Open variant: JOIN, the fields with their autofill hints, and the sign-in link', (t) async {
    await pumpAuth(t, start: '/register');
    await settle(t, 300);
    expect(find.text('JOIN'), findsOneWidget);
    expect(_headline('Join this library.'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Already have an account?'), findsOneWidget);
    expect(t.widget<TextField>(_field(0)).autofillHints, contains(AutofillHints.newUsername));
    expect(t.widget<TextField>(_field(1)).autofillHints, contains(AutofillHints.newPassword));
    expect(find.text('INVITE CODE'), findsNothing);
    expect(find.text('DISPLAY NAME'), findsOneWidget);
    expect(find.text('EMAIL'), findsOneWidget);
  });

  testWidgets('the username helper turns proof on "ab" and calm on a valid name', (t) async {
    await pumpAuth(t, start: '/register');
    await settle(t, 300);
    expect(find.text(kUsernameHelper), findsOneWidget, reason: 'the calm helper');
    await t.enterText(_field(0), 'ab');
    await t.pump();
    expect(find.text('‸ $kUsernameHelper'), findsOneWidget, reason: 'the proof-coloured error form');
    await t.enterText(_field(0), 'abc');
    await t.pump();
    expect(find.text(kUsernameHelper), findsOneWidget);
  });

  testWidgets("Passwords don't match once both have content", (t) async {
    await pumpAuth(t, start: '/register');
    await settle(t, 300);
    await t.enterText(_field(1), 'one-password');
    await t.pump();
    expect(find.textContaining(kPasswordMismatch), findsNothing);
    await t.enterText(_field(2), 'two-password');
    await t.pump();
    expect(find.text('‸ $kPasswordMismatch'), findsOneWidget);
  });

  testWidgets('a bad email is called out', (t) async {
    await pumpAuth(t, start: '/register');
    await settle(t, 300);
    await t.enterText(find.byType(TextField).last, 'nope');
    await t.pump();
    expect(find.text('‸ $kEmailError'), findsOneWidget);
  });

  testWidgets('registration_disabled switches to the Closed variant', (t) async {
    final auth = FakeAuth()..registerError = _api('registration_disabled', status: 403);
    await pumpAuth(t, start: '/register', auth: auth);
    await settle(t, 300);
    await _valid(t);
    await t.ensureVisible(find.text('Create account'));
    await t.tap(find.text('Create account'));
    await settle(t, 300);
    expect(find.text('REGISTRATION CLOSED'), findsOneWidget);
    expect(_headline("This library isn't taking new readers."), findsOneWidget);
    expect(find.text('Back to sign in'), findsOneWidget);
  });

  testWidgets('Closed variant from the start', (t) async {
    await pumpAuth(t, start: '/register', status: const BootstrapStatus(needsBootstrap: false, registrationEnabled: false));
    await settle(t, 300);
    expect(find.text('REGISTRATION CLOSED'), findsOneWidget);
    expect(find.text('Create account'), findsNothing);
  });

  testWidgets('invite_code_required reveals the Invite code field; username_taken reads its line', (t) async {
    final auth = FakeAuth()..registerError = _api('invite_code_required', status: 403);
    await pumpAuth(t, start: '/register', auth: auth);
    await settle(t, 300);
    await _valid(t);
    await t.ensureVisible(find.text('Create account'));
    await t.tap(find.text('Create account'));
    await settle(t, 300);
    expect(find.text('INVITE CODE'), findsOneWidget);
    expect(find.text('This library needs an invite code.'), findsOneWidget);
  });

  testWidgets('username_taken reads: That username is taken.', (t) async {
    final auth = FakeAuth()..registerError = _api('username_taken', status: 409);
    await pumpAuth(t, start: '/register', auth: auth);
    await settle(t, 300);
    await _valid(t);
    await t.ensureVisible(find.text('Create account'));
    await t.tap(find.text('Create account'));
    await settle(t, 300);
    expect(find.text('That username is taken.'), findsOneWidget);
  });

  testWidgets('Invite variant shows the field with its hint from the start', (t) async {
    await pumpAuth(t, start: '/register', status: const BootstrapStatus(needsBootstrap: false, registrationEnabled: true, inviteCodeRequired: true));
    await settle(t, 300);
    expect(find.text('INVITE CODE'), findsOneWidget);
    expect(find.text('Ask whoever invited you'), findsOneWidget);
  });

  testWidgets('Bootstrap variant: FIRST ISSUE and the administrator button', (t) async {
    await pumpAuth(t, start: '/register', status: const BootstrapStatus(needsBootstrap: true, registrationEnabled: true));
    await settle(t, 300);
    expect(find.text('FIRST ISSUE'), findsOneWidget);
    expect(_headline('Claim this server.'), findsOneWidget);
    expect(find.text('Create the administrator account'), findsOneWidget);
  });

  testWidgets('a network failure shows the unreachable notice and Try again returns to the form', (t) async {
    final auth = FakeAuth()..registerError = const NetworkError(message: 'x');
    await pumpAuth(t, start: '/register', auth: auth);
    await settle(t, 300);
    await _valid(t);
    await t.ensureVisible(find.text('Create account'));
    await t.tap(find.text('Create account'));
    await settle(t, 300);
    expect(find.text('CORRECTION'), findsOneWidget);
    await t.ensureVisible(find.text('Try again'));
    await t.tap(find.text('Try again'));
    await t.pump();
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('a good registration signs in and the router lands on the picker', (t) async {
    final auth = FakeAuth();
    final rig = await pumpAuth(t, start: '/register', auth: auth, gated: true);
    await settle(t, 300);
    await _valid(t);
    await t.ensureVisible(find.text('Create account'));
    await t.tap(find.text('Create account'));
    await settle(t, 600);
    expect(auth.registers, ['yash.d']);
    expect(rig.at, '/profiles');
  });

  testWidgets('the back arrow returns to Login', (t) async {
    final rig = await pumpAuth(t);
    await settle(t, 300);
    await t.tap(find.text('Create one'));
    await settle(t, 600);
    expect(rig.at, '/register');
    await t.tap(find.bySemanticsLabel('Back').first);
    await settle(t, 600);
    expect(rig.at, '/login');
  });

  testWidgets('the submit button is disabled while the rate limit runs', (t) async {
    final auth = FakeAuth()..registerError = _api('rate_limited', status: 429);
    await pumpAuth(t, start: '/register', auth: auth);
    await settle(t, 300);
    await _valid(t);
    await t.ensureVisible(find.text('Create account'));
    await t.tap(find.text('Create account'));
    await t.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('SLOW DOWN'), findsOneWidget);
    expect(t.widget<CineButton>(find.widgetWithText(CineButton, 'Create account')).onPressed, isNull);
    await settle(t, 31000);
  });
}
