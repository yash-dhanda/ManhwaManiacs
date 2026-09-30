// ignore_for_file: directives_ordering, unawaited_futures, avoid_dynamic_calls, library_private_types_in_public_api, inference_failure_on_collection_literal
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/models/auth_user.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/auth/repositories/auth_repository.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_checkbox.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/pages/security_page.dart';

import '../downloads/downloads_rig.dart' show settle;
import 'settings_rig.dart';

class _Auth extends AuthController {
  static AppError? next;
  static final log = <String>[];

  @override
  AuthState build() => AuthAuthenticated(AuthUser(id: 1, username: 'tester', isAdmin: true, createdAt: DateTime.utc(2024)));

  @override
  Future<AppError?> changePassword({required String currentPassword, required String newPassword}) async {
    log.add('change $currentPassword $newPassword');
    return next;
  }

  @override
  Future<void> logout() async => log.add('logout');

  @override
  Future<AppError?> logoutEverywhere() async {
    log.add('logoutAll');
    return null;
  }
}

class _Repo implements AuthRepository {
  final revoked = <int>[];
  @override
  Future<Result<void>> revokeSession(int sessionId) async {
    revoked.add(sessionId);
    return const Ok(null);
  }

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

Finder field(String label) => find.byWidgetPredicate((w) => w is EditableText).at(['Current', 'New', 'Confirm'].indexOf(label));

Future<void> fill(WidgetTester t, {String cur = 'old-password', String nw = 'new-password', String? conf}) async {
  await t.enterText(field('Current'), cur);
  await t.enterText(field('New'), nw);
  await t.enterText(field('Confirm'), conf ?? nw);
}

Future<void> submit(WidgetTester t) async {
  final b = find.widgetWithText(CineButton, 'Change password');
  Scrollable.ensureVisible(t.element(b), alignment: 0.5);
  await t.pump();
  await t.tap(b);
  await settle(t, ms: 400);
}

void main() {
  setUp(() {
    _Auth.next = null;
    _Auth.log.clear();
  });

  group('validation lines', () {
    test('each rule has its sentence', () {
      expect(validatePasswordChange(current: '', next: 'abcdefgh', confirm: 'abcdefgh').current, 'Enter your current password.');
      expect(validatePasswordChange(current: 'x', next: '', confirm: '').next, 'Enter a new password.');
      expect(validatePasswordChange(current: 'x', next: 'short', confirm: 'short').next, 'Password must be at least 8 characters.');
      expect(validatePasswordChange(current: 'x', next: 'a' * 4097, confirm: 'a' * 4097).next, 'Password is too long.');
      expect(validatePasswordChange(current: 'abcdefgh', next: 'abcdefgh', confirm: 'abcdefgh').next, 'Your new password must be different from your current one.');
      expect(validatePasswordChange(current: 'x', next: 'abcdefgh', confirm: 'abcdefgi').confirm, "The new passwords don't match.");
      final ok = validatePasswordChange(current: 'x', next: 'abcdefgh', confirm: 'abcdefgh');
      expect((ok.current, ok.next, ok.confirm), (null, null, null));
    });
  });

  Future<ProviderContainerHolder> pump(WidgetTester t, {_Repo? repo}) async {
    final r = repo ?? _Repo();
    final c = await pumpPage(t, const SecurityPage(), more: [authControllerProvider.overrideWith(_Auth.new), authRepositoryProvider.overrideWithValue(r)]);
    return ProviderContainerHolder(c, r);
  }

  testWidgets('mismatch and empty fields show their lines and send nothing', (t) async {
    await pump(t);
    await submit(t);
    expect(find.textContaining('Enter your current password.'), findsOneWidget);
    expect(find.textContaining('Enter a new password.'), findsOneWidget);
    await fill(t, conf: 'different-one');
    await submit(t);
    expect(find.textContaining("The new passwords don't match."), findsOneWidget);
    expect(_Auth.log, isEmpty);
  });

  testWidgets('success clears the form and toasts', (t) async {
    final h = await pump(t);
    await fill(t);
    await submit(t);
    expect(_Auth.log, ['change old-password new-password']);
    expect(h.c.read(cineToastsProvider).any((x) => x.text == kToastChanged), isTrue);
    expect(find.text('Changing it signs out every other device. This one stays signed in.'), findsOneWidget);
  });

  testWidgets('invalid_credentials: the line is under Current and it never signs out', (t) async {
    _Auth.next = const ApiError(statusCode: 401, code: 'invalid_credentials', message: 'nope');
    await pump(t);
    await fill(t);
    await submit(t);
    expect(find.textContaining("That isn't your current password."), findsOneWidget);
    expect(_Auth.log.where((e) => e.startsWith('logout')), isEmpty);
  });

  testWidgets('weak_password shows the server line under New', (t) async {
    _Auth.next = const ApiError(statusCode: 422, code: 'weak_password', message: 'That password is too common.');
    await pump(t);
    await fill(t);
    await submit(t);
    expect(find.textContaining('That password is too common.'), findsOneWidget);
  });

  testWidgets('rate_limited: SLOW DOWN with a live countdown, the button off until 0', (t) async {
    _Auth.next = const ApiError(statusCode: 429, code: 'rate_limited', message: 'slow', retryAfter: Duration(seconds: 5));
    await pump(t);
    await fill(t);
    await submit(t);
    expect(find.text('SLOW DOWN'), findsOneWidget);
    expect(find.text('Try again in 5 s'), findsOneWidget);
    final b = find.widgetWithText(CineButton, 'Change password');
    expect(t.widget<CineButton>(b).onPressed, isNull);
    await t.pump(const Duration(seconds: 2));
    expect(find.text('Try again in 3 s'), findsOneWidget);
    await t.pump(const Duration(seconds: 4));
    expect(find.textContaining('SLOW DOWN'), findsNothing);
    expect(t.widget<CineButton>(b).onPressed, isNotNull);
  });

  testWidgets('sessions: labels, THIS DEVICE, folios; Revoke asks first', (t) async {
    final h = await pump(t);
    expect(find.text('ManhwaManiacs app'), findsOneWidget);
    expect(find.text('Firefox on Linux'), findsOneWidget);
    expect(find.text('THIS DEVICE'), findsOneWidget);
    expect(find.textContaining('LAST USED 3 H AGO · 10.0.0.2'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^SIGNED IN \d')), findsNWidgets(2));
    expect(find.text('Sign out'), findsOneWidget, reason: "the current row's own sign out");
    final revoke = find.widgetWithText(CineButton, 'Revoke');
    Scrollable.ensureVisible(t.element(revoke), alignment: 0.5);
    await t.pump();
    await t.tap(revoke);
    await settle(t, ms: 600);
    expect(find.text('Sign out Firefox on Linux?'), findsOneWidget);
    expect(find.text('It will have to sign in again.'), findsOneWidget);
    await t.tap(find.text('Sign out').last, warnIfMissed: false);
    await settle(t, ms: 200);
    expect(h.repo.revoked, isEmpty, reason: 'armed for 1000 ms');
    await settle(t, ms: 1200);
    await t.tap(find.text('Sign out').last);
    await settle(t, ms: 600);
    expect(h.repo.revoked, [2]);
  });

  testWidgets('sessions failure shows a CORRECTION strip with Retry', (t) async {
    await pumpPage(t, const SecurityPage(), rig: SettingsRig(sessionsError: true), more: [authControllerProvider.overrideWith(_Auth.new)]);
    expect(find.text('CORRECTION'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('Sign out everywhere needs the checkbox and the arm', (t) async {
    await pump(t);
    final btn = find.widgetWithText(CineButton, 'Sign out everywhere');
    Scrollable.ensureVisible(t.element(btn), alignment: 0.5);
    await t.pump();
    await t.tap(btn);
    await settle(t, ms: 1400);
    expect(find.text('I understand this signs me out here too'), findsOneWidget);
    await t.tap(find.text('Sign out everywhere').last, warnIfMissed: false);
    await settle(t, ms: 300);
    expect(_Auth.log, isEmpty, reason: 'the checkbox is not ticked');
    await t.tap(find.byType(CineCheckbox));
    await settle(t, ms: 300);
    await t.tap(find.text('Sign out everywhere').last);
    await settle(t, ms: 600);
    expect(_Auth.log, ['logoutAll']);
  });
}

class ProviderContainerHolder {
  ProviderContainerHolder(this.c, this.repo);
  final ProviderContainer c;
  final _Repo repo;
}
