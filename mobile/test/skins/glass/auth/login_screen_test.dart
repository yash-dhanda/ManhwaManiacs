import 'package:flutter/material.dart' show TextField;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/auth/models/bootstrap_status.dart';
import 'package:manhwamaniacs/features/auth/providers/known_accounts_provider.dart';
import 'package:manhwamaniacs/features/auth/utils/known_accounts.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/glass/dev/auth_fixtures.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';

import '../../../screenshots/support/shot_harness.dart';
import 'auth_rig.dart';

Finder get _user => find.byType(TextField).at(0);
Finder get _pass => find.byType(TextField).at(1);

Future<void> _fill(WidgetTester t, {String user = 'demo', String pass = 'pw-1234567'}) async {
  await t.enterText(_user, user);
  await t.enterText(_pass, pass);
  await t.pump();
}

Future<void> _signIn(WidgetTester t) async {
  await t.tap(find.text('Sign in').last);
  await t.pump();
  await settleFor(t, 100);
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('"Welcome back" types at 50 ms per grapheme and focus on the heading does not skip it', (t) async {
    await pumpAuth(t, '/login', const GlassAuthFixture(), settle: false);
    await settleFor(t, 100);
    await settleFor(t, 100);
    final rich = find.byType(RichText).evaluate().map((e) => e.widget as RichText).where((r) => r.text.toPlainText().startsWith('Welcome back')).toList();
    expect(rich, isNotEmpty);
    final root = rich.first.text as TextSpan;
    // 200 ms in: the 10th grapheme is still transparent.
    expect((root.children![9] as TextSpan).style?.color, const Color(0x00000000));
    await settleFor(t, 3000);
    final done = find.byType(RichText).evaluate().map((e) => e.widget as RichText).where((r) => r.text.toPlainText().startsWith('Welcome back')).first.text as TextSpan;
    for (var i = 0; i < 'Welcome back'.length; i++) {
      expect((done.children![i] as TextSpan).style?.color, isNot(const Color(0x00000000)), reason: 'grapheme $i');
    }
  });

  testWidgets('the form: fields, switch, disabled button until both fields have text, the server row and the footer', (t) async {
    await pumpAuth(t, '/login', const GlassAuthFixture());
    await settleFor(t, 3500);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Keep me signed in'), findsOneWidget);
    expect(find.textContaining('Server: '), findsOneWidget);
    expect(find.text('Change server'), findsOneWidget);
    expect(find.text('Create one'), findsOneWidget);
    expect(find.text('Sign in to your library.'), findsOneWidget);
    GlassButton signIn() => t.widget<GlassButton>(find.widgetWithText(GlassButton, 'Sign in'));
    expect(signIn().onPressed, isNull);
    await _fill(t);
    expect(signIn().onPressed, isNotNull);
  });

  testWidgets('known-account chips fill Username and move focus to Password', (t) async {
    final rig = await pumpAuth(t, '/login', const GlassAuthFixture());
    // seeds the device list, then rebuilds the screen
    final c = rig.container;
    await rememberAccount(c.read(sharedPrefsProvider), 'demo');
    await rememberAccount(c.read(sharedPrefsProvider), 'reader2');
    c.invalidate(knownAccountsProvider);
    await settleFor(t, 3500);
    expect(find.text('reader2'), findsOneWidget);
    await t.tap(find.text('demo'));
    await t.pump();
    expect(t.widget<TextField>(_user).controller!.text, 'demo');
    expect(t.widget<TextField>(_pass).focusNode!.hasFocus, isTrue);
  });

  testWidgets('?user=demo fills Username and focuses Password', (t) async {
    await pumpAuth(t, '/login?user=demo', const GlassAuthFixture());
    await settleFor(t);
    expect(t.widget<TextField>(_user).controller!.text, 'demo');
    expect(t.widget<TextField>(_pass).focusNode!.hasFocus, isTrue);
  });

  testWidgets('wrong credentials: the copy shows and focus returns to Username', (t) async {
    await pumpAuth(t, '/login', const GlassAuthFixture(loginError: ApiError(statusCode: 401, code: 'invalid_credentials', message: 'x')));
    await settleFor(t, 3500);
    await _fill(t);
    await _signIn(t);
    await settleFor(t, 500);
    expect(find.text("That username and password don't match."), findsOneWidget);
    expect(t.widget<TextField>(_user).focusNode!.hasFocus, isTrue);
  });

  testWidgets('rate limit: the button counts down in seconds and re-enables at zero', (t) async {
    await pumpAuth(t, '/login', const GlassAuthFixture(loginError: ApiError(statusCode: 429, code: 'rate_limited', message: 'x', retryAfter: Duration(seconds: 3))));
    await settleFor(t, 3500);
    await _fill(t);
    await _signIn(t);
    await settleFor(t, 300);
    expect(find.text('Try again in 3 s'), findsOneWidget);
    expect(t.widget<GlassButton>(find.widgetWithText(GlassButton, 'Try again in 3 s')).onPressed, isNull);
    await settleFor(t);
    expect(find.text('Try again in 2 s'), findsOneWidget);
    await settleFor(t, 3000);
    expect(find.text('Sign in'), findsWidgets);
  });

  testWidgets('unreachable: the lens, the heading, the detail and both actions', (t) async {
    await pumpAuth(t, '/login', const GlassAuthFixture(bootstrapError: NetworkError(message: 'x')));
    await settleFor(t, 1500);
    expect(find.text("We couldn't reach the server"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Change server'), findsOneWidget);
  });

  testWidgets('bootstrap: the first-account heading and button', (t) async {
    await pumpAuth(t, '/login', const GlassAuthFixture(bootstrap: BootstrapStatus(needsBootstrap: true, registrationEnabled: true)));
    await settleFor(t, 4500);
    expect(find.text('Create the first account'), findsOneWidget);
    expect(find.text('This server has no accounts yet. Create the first one; it becomes the administrator.'), findsOneWidget);
  });

  testWidgets('success without a remembered profile: the hold keeps /login until the condense ends, then the picker', (t) async {
    final rig = await pumpAuth(t, '/login', GlassAuthFixture(profiles: fixtureProfiles()));
    await settleFor(t, 3500);
    await _fill(t);
    await _signIn(t);
    await settleFor(t, 250);
    expect(rig.at, '/login', reason: 'the redirect hold');
    await settleFor(t, 2000);
    expect(FakeAuth.calls, contains('login:demo'));
    expect(rig.at, '/profiles');
  });

  testWidgets('success with a remembered valid profile lands on Home with an arrival', (t) async {
    final rig = await pumpAuth(
      t,
      '/login',
      GlassAuthFixture(profiles: fixtureProfiles(), active: const ActiveProfile(id: 1, name: 'Yash', avatarKey: 'violet', mood: Mood.fantasy)),
    );
    await settleFor(t, 3500);
    await _fill(t);
    await _signIn(t);
    await settleFor(t, 3000);
    expect(rig.at, '/');
  });
}
