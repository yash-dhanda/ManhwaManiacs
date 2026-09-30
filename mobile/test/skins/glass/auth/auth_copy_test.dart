import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/skins/glass/screens/auth/auth_copy.dart';

ApiError _e(String code, {int status = 400, Duration? retry, String message = 'server says'}) => ApiError(statusCode: status, code: code, message: message, retryAfter: retry);

void main() {
  group('login', () {
    test('credentials focus Username', () {
      final l = loginLine(_e('invalid_credentials', status: 401));
      expect(l.text, "That username and password don't match.");
      expect(l.field, AuthField.username);
    });
    test('deactivated', () => expect(loginLine(_e('account_disabled')).text, "This account is deactivated. Ask the server's owner."));
    test('rate limit carries Retry-After', () {
      final l = loginLine(_e('rate_limited', status: 429, retry: const Duration(seconds: 42)));
      expect(l.kind, AuthLineKind.rateLimited);
      expect(l.retryAfter, const Duration(seconds: 42));
      expect(rateLimitLine(42), 'Too many attempts. Try again in 42 s.');
      expect(rateLimitButton(42), 'Try again in 42 s');
    });
    test('network', () {
      final l = loginLine(const NetworkError(message: 'x'));
      expect(l.kind, AuthLineKind.unreachable);
      expect(l.text, "Couldn't reach the server.");
      expect(loginLine(const TimeoutError()).kind, AuthLineKind.unreachable);
    });
    test('bootstrap codes', () {
      expect(loginLine(_e('bootstrap_window_expired')).text, kBootstrapExpired);
      expect(loginLine(_e('bootstrap_already_claimed')).kind, AuthLineKind.claimedSwitchToSignIn);
    });
  });

  group('register', () {
    test('each code lands on its field', () {
      expect(registerLine(_e('username_taken')).field, AuthField.username);
      expect(registerLine(_e('username_taken')).text, 'That username is taken.');
      expect(registerLine(_e('invalid_username')).field, AuthField.username);
      expect(registerLine(_e('weak_password', message: 'Too short.')).text, 'Too short.');
      expect(registerLine(_e('weak_password')).field, AuthField.password);
      expect(registerLine(_e('invite_code_required')).field, AuthField.invite);
      expect(registerLine(_e('invite_code_required')).text, 'This server needs an invite code.');
      expect(registerLine(_e('invite_code_invalid')).text, "That invite code didn't work. Check it with whoever invited you.");
    });
    test('closed, claimed, rate limit, network', () {
      expect(registerLine(_e('registration_disabled')).kind, AuthLineKind.registrationClosed);
      expect(registerLine(_e('bootstrap_already_claimed')).text, 'Someone already claimed this server. Sign in instead.');
      expect(registerLine(_e('rate_limited', status: 429)).kind, AuthLineKind.rateLimited);
      expect(registerLine(const NetworkError(message: 'x')).text, "Couldn't reach the server.");
    });
  });

  test('the countdown ticks down to zero and turns inactive', () async {
    final c = RateCountdown();
    addTearDown(c.dispose);
    c.start(const Duration(seconds: 2));
    expect(c.active, isTrue);
    expect(c.seconds, 2);
  });
}
