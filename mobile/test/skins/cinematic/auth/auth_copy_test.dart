import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/setup/utils/server_check.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/auth/auth_copy.dart';

ApiError _api(String code, {int status = 400, Duration? retry}) =>
    ApiError(statusCode: status, code: code, message: 'm', retryAfter: retry);

void main() {
  test('setup lines cover every check outcome', () {
    expect(setupErrorLine(const ServerCheck.ok('https://x')), isNull);
    expect(setupErrorLine(const ServerCheck.offline()), 'This phone is offline. Connect, then try again.');
    expect(setupErrorLine(const ServerCheck.notManhwaManiacs()), "That address isn't a ManhwaManiacs server.");
    expect(setupErrorLine(const ServerCheck.tls()), contains('certificate'));
    expect(setupErrorLine(const ServerCheck.httpInRelease()), startsWith('Use an https:// address.'));
    expect(setupErrorLine(const ServerCheck.timeout()), 'The server took too long to answer.');
    expect(setupErrorLine(const ServerCheck.unreachable('x')), 'No ManhwaManiacs server answered at this address.');
  });

  test('login lines by code', () {
    expect(loginLine(_api('invalid_credentials', status: 401)).text, "That username and password don't match.");
    expect(loginLine(_api('account_disabled', status: 403)).text, 'This account has been turned off by the owner.');
    expect(loginLine(_api('bootstrap_window_expired')).text, kBootstrapExpired);
    final claimed = loginLine(_api('bootstrap_already_claimed'));
    expect(claimed.kind, AuthLineKind.claimedSwitchToSignIn);
    expect(claimed.text, kBootstrapClaimed);
    expect(loginLine(_api('boom', status: 500)).text, "Couldn't sign in. Try again.");
    expect(loginLine(const NetworkError(message: 'x')).isNetwork, isTrue);
    expect(loginLine(const TimeoutError()).isNetwork, isTrue);
  });

  test('rate limiting carries the retry-after, by code or by 429', () {
    final a = loginLine(_api('rate_limited', status: 429, retry: const Duration(seconds: 12)));
    expect(a.kind, AuthLineKind.rateLimited);
    expect(a.text, 'SLOW DOWN');
    expect(a.retryAfter, const Duration(seconds: 12));
    expect(loginLine(_api('other', status: 429)).kind, AuthLineKind.rateLimited);
    expect(rateLimitLine(12), 'Try again in 12 s');
  });

  test('register lines by code', () {
    expect(registerLine(_api('username_taken')).text, 'That username is taken.');
    expect(registerLine(_api('invalid_username')).kind, AuthLineKind.invalidUsername);
    expect(registerLine(_api('invite_code_invalid')).text, "That invite code isn't valid.");
    expect(registerLine(_api('invite_code_required')).kind, AuthLineKind.inviteRequired);
    expect(registerLine(_api('registration_disabled')).kind, AuthLineKind.registrationClosed);
    expect(registerLine(_api('weak_password')).text, 'Choose a longer password: at least 8 characters.');
    expect(registerLine(_api('x')).text, "Couldn't create the account. Try again.");
  });

  test('field rules', () {
    expect(usernameValid('ab'), isFalse);
    expect(usernameValid('abc'), isTrue);
    expect(usernameValid('_abc'), isFalse);
    expect(usernameValid('a.b-c_d'), isTrue);
    expect(emailValid(''), isTrue);
    expect(emailValid('a@b'), isFalse);
    expect(emailValid('a@b.co'), isTrue);
    expect(passwordsMismatch('a', ''), isFalse);
    expect(passwordsMismatch('a', 'b'), isTrue);
  });

  test('the masthead date line is upper case with the literal issue number', () {
    expect(mastheadDateLine(DateTime(2026, 9, 29)), 'TUESDAY 29 SEPTEMBER 2026 · No. 1');
  });
}
