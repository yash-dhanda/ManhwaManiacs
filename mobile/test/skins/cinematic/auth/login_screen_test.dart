// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/auth/models/bootstrap_status.dart';
import 'package:manhwamaniacs/features/auth/providers/session_end_reason_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/typed_headline.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/auth/auth_copy.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/auth/auth_layout.dart';

import 'auth_test_support.dart';

ApiError _api(String code, {int status = 400, Duration? retry}) => ApiError(statusCode: status, code: code, message: 'm', retryAfter: retry);

Future<void> _fill(WidgetTester t, {String user = 'yash', String pass = 'secret-pw'}) async {
  await t.enterText(find.byType(TextField).at(0), user);
  await t.enterText(find.byType(TextField).at(1), pass);
}

Finder _headline(String text) => find.byWidgetPredicate((w) => w is TypedHeadline && w.text == text);

CineButton _signIn(WidgetTester t) => t.widget<CineButton>(find.widgetWithText(CineButton, 'Sign in'));

void main() {
  testWidgets('the form: kicker, headline, server line, fields, switch and button', (t) async {
    await pumpAuth(t);
    await settle(t, 200);
    expect(find.text('SIGN IN'), findsOneWidget);
    expect(_headline('Welcome back.'), findsOneWidget);
    expect(find.textContaining('Server: '), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Create one'), findsOneWidget, reason: 'registration is open');
    final user = t.widget<TextField>(find.byType(TextField).at(0));
    expect(user.autofillHints, contains(AutofillHints.username));
    expect(user.autocorrect, isFalse);
    final pass = t.widget<TextField>(find.byType(TextField).at(1));
    expect(pass.autofillHints, contains(AutofillHints.password));
    expect(pass.textInputAction, TextInputAction.go);
    expect(FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<EditableText>(), isNotNull, reason: 'the username is focused');
  });

  testWidgets('Create one is hidden when registration is closed', (t) async {
    await pumpAuth(t, status: const BootstrapStatus(needsBootstrap: false, registrationEnabled: false));
    await settle(t, 200);
    expect(find.text('Create one'), findsNothing);
  });

  testWidgets('one cover line on phones, three on tablets', (t) async {
    await pumpAuth(t);
    await settle(t, 200);
    expect(find.byType(AuthCoverLine), findsOneWidget);
  });

  testWidgets('three cover lines on tablets', (t) async {
    await pumpAuth(t, size: const Size(834, 1194));
    await settle(t, 200);
    expect(find.byType(AuthCoverLine), findsNWidgets(3));
  });

  testWidgets('Tab walks username, password, Show, switch, Sign in, Create one in order', (t) async {
    await pumpAuth(t);
    await settle(t, 200);
    final order = <FocusNode?>[FocusManager.instance.primaryFocus];
    for (var i = 0; i < 5; i++) {
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pump();
      order.add(FocusManager.instance.primaryFocus);
    }
    expect(order.toSet().length, 6, reason: 'six different controls in six steps');
    // The last two are the primary button and the footer link.
    final labels = [
      for (final n in order.skip(4)) n?.context?.findAncestorWidgetOfExactType<CineButton>()?.label,
    ];
    expect(labels, ['Sign in', 'Create one']);
  });

  testWidgets('empty fields say so', (t) async {
    await pumpAuth(t);
    await settle(t, 200);
    await t.tap(find.text('Sign in'));
    await t.pump();
    expect(find.text(kEmptyCredentials), findsOneWidget);
  });

  testWidgets('a wrong password reads as the spec says and the fields come back', (t) async {
    final auth = FakeAuth()..loginError = _api('invalid_credentials', status: 401);
    await pumpAuth(t, auth: auth);
    await settle(t, 200);
    await _fill(t);
    await t.tap(find.text('Sign in'));
    await t.pump(const Duration(milliseconds: 50));
    expect(find.text("That username and password don't match."), findsOneWidget);
    expect(auth.logins.single.user, 'yash');
    expect(auth.logins.single.remember, isTrue);
    expect(t.widget<TextField>(find.byType(TextField).at(0)).enabled, isTrue);
  });

  for (final e in {
    'account_disabled': 'This account has been turned off by the owner.',
    'bootstrap_window_expired': kBootstrapExpired,
    'anything_else': "Couldn't sign in. Try again.",
  }.entries) {
    testWidgets('${e.key} reads: ${e.value}', (t) async {
      final auth = FakeAuth()..loginError = _api(e.key);
      await pumpAuth(t, auth: auth);
      await settle(t, 200);
      await _fill(t);
      await t.tap(find.text('Sign in'));
      await t.pump(const Duration(milliseconds: 50));
      expect(find.text(e.value), findsOneWidget);
    });
  }

  testWidgets('the rate limit counts down from Retry-After and disables Sign in until zero', (t) async {
    final auth = FakeAuth()..loginError = _api('rate_limited', status: 429, retry: const Duration(seconds: 12));
    await pumpAuth(t, auth: auth);
    await settle(t, 200);
    await _fill(t);
    await t.tap(find.text('Sign in'));
    await t.pump(const Duration(milliseconds: 50));
    expect(find.text('SLOW DOWN · Try again in 12 s'), findsOneWidget);
    expect(_signIn(t).onPressed, isNull);
    await t.pump(const Duration(seconds: 5));
    expect(find.text('SLOW DOWN · Try again in 7 s'), findsOneWidget);
    await t.pump(const Duration(seconds: 7));
    expect(find.textContaining('SLOW DOWN'), findsNothing);
    expect(_signIn(t).onPressed, isNotNull);
  });

  testWidgets('a successful sign-in finishes the autofill context, then the router Dips to the picker', (t) async {
    final calls = <String>[];
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.textInput, (call) async {
      calls.add(call.method);
      return null;
    });
    addTearDown(() => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.textInput, null));
    final auth = FakeAuth();
    final rig = await pumpAuth(t, auth: auth, gated: true);
    await settle(t, 200);
    await _fill(t);
    await t.tap(find.text('Sign in'));
    await settle(t, 600);
    expect(calls, contains('TextInput.finishAutofillContext'));
    expect(rig.at, '/profiles', reason: 'signed in without an active profile');
  });

  testWidgets('the signed-out toast shows once and clears the reason', (t) async {
    final rig = await pumpAuth(t, extra: [sessionEndReasonProvider.overrideWith((ref) => SessionEndReason.signedOut)]);
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text(kSignedOutToast), findsOneWidget);
    expect(rig.container.read(sessionEndReasonProvider), isNull);
    await settle(t, 5000);
    expect(find.text(kSignedOutToast), findsNothing);
  });

  testWidgets('Keep me signed in off is sent as remember: false', (t) async {
    final auth = FakeAuth();
    await pumpAuth(t, auth: auth);
    await settle(t, 200);
    await t.tap(find.bySemanticsLabel('Keep me signed in'));
    await t.pump();
    await _fill(t);
    await t.tap(find.text('Sign in'));
    await t.pump(const Duration(milliseconds: 50));
    expect(auth.logins.single.remember, isFalse);
  });

  testWidgets('bootstrap variant: claim this server, the register form inline', (t) async {
    await pumpAuth(t, status: const BootstrapStatus(needsBootstrap: true, registrationEnabled: true));
    await settle(t, 300);
    expect(find.text('FIRST ISSUE'), findsOneWidget);
    expect(_headline('Claim this server.'), findsOneWidget);
    expect(find.text('Create the first account. It becomes the administrator.'), findsOneWidget);
    expect(find.text('Create the administrator account'), findsOneWidget);
    expect(find.text('Create one'), findsNothing);
  });

  testWidgets('unreachable variant: the notice, Try again and Change server address', (t) async {
    await pumpAuth(t, statusError: const NetworkError(message: 'x'));
    await settle(t, 300);
    expect(find.text('CORRECTION'), findsOneWidget);
    expect(_headline("We couldn't reach the server."), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Change server address'), findsOneWidget);
  });

  testWidgets('Change server address sends the app back to Setup', (t) async {
    final rig = await pumpAuth(t, statusError: const NetworkError(message: 'x'), gated: true);
    await settle(t, 300);
    await t.tap(find.text('Change server address'));
    await settle(t, 600);
    expect(rig.at, '/setup');
  });

  testWidgets('Create one pushes Register', (t) async {
    final rig = await pumpAuth(t);
    await settle(t, 200);
    await t.tap(find.text('Create one'));
    await settle(t, 600);
    expect(rig.at, '/register');
  });
}
