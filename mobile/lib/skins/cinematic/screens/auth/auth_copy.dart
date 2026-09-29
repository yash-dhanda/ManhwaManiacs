import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/setup/utils/server_check.dart';

/// Pure copy maps for Setup, Login and Register (cinematic 8.1, 8.3, 8.4, 12.5). No widgets.

const String kSetupRelease = 'HTTPS is required in release builds.';

/// The field's error line for a failed server check; null for [ServerCheckOk].
String? setupErrorLine(ServerCheck c) => switch (c) {
      ServerCheckOk() => null,
      ServerCheckOffline() => 'This phone is offline. Connect, then try again.',
      ServerCheckNotManhwaManiacs() => "That address isn't a ManhwaManiacs server.",
      ServerCheckTls() => "The server's certificate isn't valid, so the connection was refused.",
      ServerCheckHttpInRelease() => "Use an https:// address. Plain http isn't allowed in release builds.",
      ServerCheckTimeout() => 'The server took too long to answer.',
      ServerCheckUnreachable() => 'No ManhwaManiacs server answered at this address.',
    };

/// What a failed sign-in or registration means for the screen.
enum AuthLineKind { message, rateLimited, unreachable, registrationClosed, inviteRequired, invalidUsername, claimedSwitchToSignIn }

class AuthLine {
  const AuthLine(this.kind, this.text, {this.retryAfter});
  final AuthLineKind kind;
  final String text;

  /// The server's `Retry-After` for [AuthLineKind.rateLimited].
  final Duration? retryAfter;

  bool get isNetwork => kind == AuthLineKind.unreachable;
}

const String kEmptyCredentials = 'Enter your username and password.';
const String kSignedOutToast = "You've been signed out. Sign in to carry on.";
const String kProfileGoneToast = "That profile isn't available any more. Choose another.";
const String kBootstrapExpired =
    'The window to claim this server has closed. Whoever runs the server has to create the first account.';
const String kBootstrapClaimed = 'Someone has already claimed this server. Sign in instead.';

/// "Try again in 12 s" for the live countdown.
String rateLimitLine(int seconds) => 'Try again in $seconds s';

Duration _retry(ApiError e) => e.retryAfter ?? const Duration(seconds: 30);

AuthLine? _shared(AppError e) {
  if (e is NetworkError || e is TimeoutError) {
    return AuthLine(AuthLineKind.unreachable, e.userMessage);
  }
  if (e is ApiError) {
    if (e.code == 'rate_limited' || e.statusCode == 429) {
      return AuthLine(AuthLineKind.rateLimited, 'SLOW DOWN', retryAfter: _retry(e));
    }
    if (e.code == 'bootstrap_window_expired') return const AuthLine(AuthLineKind.message, kBootstrapExpired);
    if (e.code == 'bootstrap_already_claimed') {
      return const AuthLine(AuthLineKind.claimedSwitchToSignIn, kBootstrapClaimed);
    }
  }
  return null;
}

/// Sign-in failures by `ApiError.code`.
AuthLine loginLine(AppError e) {
  final s = _shared(e);
  if (s != null) return s;
  if (e is ApiError) {
    switch (e.code) {
      case 'invalid_credentials':
        return const AuthLine(AuthLineKind.message, "That username and password don't match.");
      case 'account_disabled':
        return const AuthLine(AuthLineKind.message, 'This account has been turned off by the owner.');
    }
  }
  return const AuthLine(AuthLineKind.message, "Couldn't sign in. Try again.");
}

/// Registration failures by `ApiError.code`.
AuthLine registerLine(AppError e) {
  final s = _shared(e);
  if (s != null) return s;
  if (e is ApiError) {
    switch (e.code) {
      case 'username_taken':
        return const AuthLine(AuthLineKind.message, 'That username is taken.');
      case 'invalid_username':
        return const AuthLine(AuthLineKind.invalidUsername, "That username isn't allowed.");
      case 'invite_code_invalid':
        return const AuthLine(AuthLineKind.message, "That invite code isn't valid.");
      case 'invite_code_required':
        return const AuthLine(AuthLineKind.inviteRequired, 'This library needs an invite code.');
      case 'registration_disabled':
        return const AuthLine(AuthLineKind.registrationClosed, 'Registration is closed.');
      case 'weak_password':
        return const AuthLine(AuthLineKind.message, 'Choose a longer password: at least 8 characters.');
    }
  }
  return const AuthLine(AuthLineKind.message, "Couldn't create the account. Try again.");
}

// Register field rules.
const String kUsernameHelper = '3–64 letters, digits, dots, dashes or underscores, starting with a letter or digit.';
final RegExp kUsernameRe = RegExp(r'^[A-Za-z0-9][A-Za-z0-9_.\-]{2,63}$');
const String kPasswordHelper = 'At least 8 characters';
const String kPasswordMismatch = "Passwords don't match.";
const String kEmailError = "That email address doesn't look right.";
final RegExp _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

bool usernameValid(String v) => kUsernameRe.hasMatch(v);
bool emailValid(String v) => v.isEmpty || _emailRe.hasMatch(v);
bool passwordsMismatch(String a, String b) => a.isNotEmpty && b.isNotEmpty && a != b;

const List<String> kWeekdays = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];
const List<String> kMonths = [
  'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE', 'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER',
];

/// `TUESDAY 29 SEPTEMBER 2026 · No. 1` from the local date.
String mastheadDateLine(DateTime d) => '${kWeekdays[d.weekday - 1]} ${d.day} ${kMonths[d.month - 1]} ${d.year} · No. 1';

const List<String> kCoverLines = [
  'Every source, one shelf.',
  'Novels, read aloud by thirty-one voices.',
  'Your year in chapters.',
];
