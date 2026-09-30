import 'package:flutter/material.dart' show TextField;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/auth/models/bootstrap_status.dart';
import 'package:manhwamaniacs/skins/glass/dev/auth_fixtures.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/text_field.dart';
import 'package:manhwamaniacs/skins/glass/screens/auth/auth_copy.dart';

import '../../../screenshots/support/shot_harness.dart';
import 'auth_rig.dart';

Finder _field(int i) => find.byType(TextField).at(i);

Future<void> _valid(WidgetTester t) async {
  await t.enterText(_field(0), 'reader1');
  await t.enterText(_field(1), 'password1');
  await t.enterText(_field(2), 'password1');
  await t.pump();
}

GlassButton _submit(WidgetTester t, String label) => t.widget<GlassButton>(find.widgetWithText(GlassButton, label));

/// Scrolls the form's vertical scrollable until [f] is on screen (`ensureVisible` leaves the page variant's far rows below the fold).
Future<void> _reveal(WidgetTester t, Finder f) async {
  await t.scrollUntilVisible(f, 300, scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axis == Axis.vertical).first, maxScrolls: 30);
  await t.pump(const Duration(milliseconds: 100));
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('Open: the copy, and the primary stays disabled until the draft is valid', (t) async {
    await pumpAuth(t, '/register', const GlassAuthFixture());
    await settleFor(t, 800);
    expect(find.text('Join ManhwaManiacs'), findsOneWidget);
    expect(find.text('Create an account on this server.'), findsOneWidget);
    expect(find.text('Already have an account? '), findsOneWidget);
    expect(_submit(t, 'Create account').onPressed, isNull);
    await _valid(t);
    expect(_submit(t, 'Create account').onPressed, isNotNull);
  });

  testWidgets('Bootstrap: the administrator variant', (t) async {
    await pumpAuth(t, '/register', const GlassAuthFixture(bootstrap: BootstrapStatus(needsBootstrap: true, registrationEnabled: true)));
    await settleFor(t, 800);
    expect(find.text('Claim this server'), findsOneWidget);
    expect(find.text('This first account becomes the administrator.'), findsOneWidget);
    expect(find.text('Create the administrator account'), findsOneWidget);
  });

  testWidgets('Closed: the lens copy and the way back', (t) async {
    await pumpAuth(t, '/register', const GlassAuthFixture(bootstrap: BootstrapStatus(needsBootstrap: false, registrationEnabled: false)));
    await settleFor(t, 800);
    expect(find.text('Registration is closed'), findsOneWidget);
    expect(find.text("This server isn't accepting new accounts. Ask its owner for access."), findsOneWidget);
    expect(find.text('Back to sign in'), findsWidgets);
  });

  testWidgets('the invite field shows only when the server asks and it is not the bootstrap', (t) async {
    await pumpAuth(t, '/register', const GlassAuthFixture(bootstrap: BootstrapStatus(needsBootstrap: false, registrationEnabled: true, inviteCodeRequired: true)));
    await settleFor(t, 800);
    expect(find.text('Invite code'), findsOneWidget);
  });

  testWidgets('the username helper turns danger while the value fails the pattern', (t) async {
    await pumpAuth(t, '/register', const GlassAuthFixture());
    await settleFor(t, 800);
    GlassFieldMessage msg() => t.widget<GlassFieldMessage>(find.byType(GlassFieldMessage).first);
    expect(msg().error, isFalse);
    await t.enterText(_field(0), 'ab');
    await t.pump();
    expect(msg().error, isTrue);
    expect(msg().text, kUsernameHelper);
    await t.enterText(_field(0), 'a.b');
    await t.pump();
    expect(msg().error, isFalse);
  });

  testWidgets('"Passwords don\'t match." once both have text', (t) async {
    await pumpAuth(t, '/register', const GlassAuthFixture());
    await settleFor(t, 800);
    await t.enterText(_field(1), 'password1');
    await t.enterText(_field(2), 'password2');
    await t.pump();
    expect(find.text("Passwords don't match."), findsOneWidget);
    await t.enterText(_field(2), 'password1');
    await t.pump();
    expect(find.text("Passwords don't match."), findsNothing);
  });

  testWidgets('the email rule speaks on blur', (t) async {
    await pumpAuth(t, '/register', const GlassAuthFixture());
    await settleFor(t, 800);
    await t.enterText(_field(4), 'nope');
    await t.pump();
    expect(find.text('Enter a valid email address, or leave it blank.'), findsNothing);
    await t.tap(_field(0));
    await t.pump();
    expect(find.text('Enter a valid email address, or leave it blank.'), findsOneWidget);
  });

  testWidgets('a short password speaks on blur', (t) async {
    await pumpAuth(t, '/register', const GlassAuthFixture());
    await settleFor(t, 800);
    await t.enterText(_field(1), 'short');
    await t.tap(_field(0));
    await t.pump();
    expect(find.text('At least 8 characters'), findsWidgets);
  });

  for (final (code, expected) in [
    ('username_taken', 'That username is taken.'),
    ('invite_code_invalid', "That invite code didn't work. Check it with whoever invited you."),
  ]) {
    testWidgets('$code lands on its field', (t) async {
      await pumpAuth(t, '/register', GlassAuthFixture(registerError: ApiError(statusCode: 409, code: code, message: 'x'), bootstrap: const BootstrapStatus(needsBootstrap: false, registrationEnabled: true, inviteCodeRequired: true)));
      await settleFor(t, 800);
      await t.enterText(_field(0), 'reader1');
      await t.enterText(_field(1), 'password1');
      await t.enterText(_field(2), 'password1');
      await t.enterText(find.byType(TextField).at(3), 'code');
      await t.pump();
      await _reveal(t, find.widgetWithText(GlassButton, 'Create account'));
      await t.tap(find.widgetWithText(GlassButton, 'Create account'));
      await t.pump();
      await settleFor(t, 400);
      expect(find.text(expected), findsOneWidget);
    });
  }

  testWidgets('registration_disabled switches to Closed', (t) async {
    await pumpAuth(t, '/register', const GlassAuthFixture(registerError: ApiError(statusCode: 403, code: 'registration_disabled', message: 'x')));
    await settleFor(t, 800);
    await _valid(t);
    await _reveal(t, find.widgetWithText(GlassButton, 'Create account'));
    await t.tap(find.widgetWithText(GlassButton, 'Create account'));
    await t.pump();
    await settleFor(t, 400);
    expect(find.text('Registration is closed'), findsOneWidget);
  });

  testWidgets('success condenses into the picker', (t) async {
    final rig = await pumpAuth(t, '/register', const GlassAuthFixture(profiles: []));
    await settleFor(t, 800);
    await _valid(t);
    await _reveal(t, find.widgetWithText(GlassButton, 'Create account'));
    await t.tap(find.widgetWithText(GlassButton, 'Create account'));
    await t.pump();
    await settleFor(t, 250);
    expect(rig.at, '/register');
    await settleFor(t, 2000);
    expect(rig.at, '/profiles');
    await settleFor(t);
    expect(find.text('Create your first profile'), findsWidgets);
  });
}
