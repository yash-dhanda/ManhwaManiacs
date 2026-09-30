import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';

/// Pure copy and error mapping of Login and Register (glass 8.3, 8.4, 12.5). No widgets.
enum AuthLineKind { message, rateLimited, unreachable, registrationClosed, claimedSwitchToSignIn, bootstrapExpired }

/// Which register field a server code lands on.
enum AuthField { username, password, invite, general }

class AuthLine {
  const AuthLine(this.kind, this.text, {this.field = AuthField.general, this.retryAfter});
  final AuthLineKind kind;
  final String text;
  final AuthField field;

  /// The server's `Retry-After` for [AuthLineKind.rateLimited].
  final Duration? retryAfter;
}

const String kLoginHeading = 'Welcome back';
const String kLoginSubtitle = 'Sign in to your library.';
const String kBootstrapHeading = 'Welcome to ManhwaManiacs';
const String kBootstrapSubtitle = 'This server has no accounts yet. Create the first one; it becomes the administrator.';
const String kUnreachableHeading = "We couldn't reach the server";
const String kUnreachableDetail = 'Could not load the sign-in page. Check that the server is running.';
const String kNetworkLine = "Couldn't reach the server.";
const String kInvalidCredentials = "That username and password don't match.";
const String kAccountDisabled = "This account is deactivated. Ask the server's owner.";
const String kBootstrapExpired = 'The time to claim this server from the app has run out. Its operator has to create the first account on the server.';
const String kBootstrapClaimed = 'Someone already claimed this server. Sign in instead.';

/// "Try again in 42 s" for the countdown.
String rateLimitLine(int seconds) => 'Too many attempts. Try again in $seconds s.';
String rateLimitButton(int seconds) => 'Try again in $seconds s';

Duration _retry(ApiError e) => e.retryAfter ?? const Duration(seconds: 30);

AuthLine? _shared(AppError e) {
  if (e is NetworkError || e is TimeoutError) return const AuthLine(AuthLineKind.unreachable, kNetworkLine);
  if (e is ApiError) {
    if (e.code == 'rate_limited' || e.statusCode == 429) return AuthLine(AuthLineKind.rateLimited, '', retryAfter: _retry(e));
    if (e.code == 'bootstrap_window_expired') return const AuthLine(AuthLineKind.bootstrapExpired, kBootstrapExpired);
    if (e.code == 'bootstrap_already_claimed') return const AuthLine(AuthLineKind.claimedSwitchToSignIn, kBootstrapClaimed);
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
        return const AuthLine(AuthLineKind.message, kInvalidCredentials, field: AuthField.username);
      case 'account_disabled':
        return const AuthLine(AuthLineKind.message, kAccountDisabled);
    }
  }
  return const AuthLine(AuthLineKind.message, "Couldn't sign in. Try again.");
}

const String kUsernameHelper = '3–64 letters, digits, dots, dashes or underscores, starting with a letter or digit.';
const String kPasswordHelper = 'At least 8 characters';
const String kPasswordMismatch = "Passwords don't match.";
const String kEmailError = 'Enter a valid email address, or leave it blank.';

/// Registration failures by `ApiError.code`, each with its field.
AuthLine registerLine(AppError e) {
  final s = _shared(e);
  if (s != null) return s;
  if (e is ApiError) {
    switch (e.code) {
      case 'username_taken':
        return const AuthLine(AuthLineKind.message, 'That username is taken.', field: AuthField.username);
      case 'invalid_username':
        return const AuthLine(AuthLineKind.message, kUsernameHelper, field: AuthField.username);
      case 'weak_password':
        return AuthLine(AuthLineKind.message, e.message.isEmpty ? kPasswordHelper : e.message, field: AuthField.password);
      case 'invite_code_required':
        return const AuthLine(AuthLineKind.message, 'This server needs an invite code.', field: AuthField.invite);
      case 'invite_code_invalid':
        return const AuthLine(AuthLineKind.message, "That invite code didn't work. Check it with whoever invited you.", field: AuthField.invite);
      case 'registration_disabled':
        return const AuthLine(AuthLineKind.registrationClosed, "This server isn't accepting new accounts.");
    }
  }
  return const AuthLine(AuthLineKind.message, "Couldn't create the account. Try again.");
}

/// The rate-limit countdown of Login and Register: `seconds` counts down once a second and `active` turns false at 0.
class RateCountdown extends ChangeNotifier {
  Timer? _timer;
  int _seconds = 0;

  int get seconds => _seconds;
  bool get active => _seconds > 0;

  void start(Duration d) {
    _timer?.cancel();
    _seconds = d.inSeconds < 1 ? 1 : d.inSeconds;
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      _seconds--;
      if (_seconds <= 0) {
        _seconds = 0;
        t.cancel();
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
