import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/skins/contract.g.dart' show HapticEvent;
import 'package:manhwamaniacs/skins/glass/copy/errors.dart';

ApiError _api(String code, {int status = 400, Duration? retry}) => ApiError(statusCode: status, code: code, message: 'server says $code', retryAfter: retry);

void main() {
  const codes = [
    'invalid_credentials', 'account_disabled', 'weak_password', 'username_taken', 'invalid_username', 'registration_disabled',
    'invite_code_required', 'invite_code_invalid', 'bootstrap_window_expired', 'bootstrap_already_claimed', 'not_authenticated',
    'profile_required', 'profile_not_found', 'profile_limit_reached', 'invalid_profile_name', 'invalid_mood', 'cannot_manage_self',
    'forbidden', 'not_found', 'series_not_found', 'source_not_found', 'source_not_browsable', 'follow_limit_reached',
    'invalid_reading_status', 'bookmark_deleted', 'batch_too_large', 'check_already_running', 'db_busy', 'rate_limited',
    'narration_unavailable', 'audio_preparing', 'audio_convert_failed', 'suggest_shelf_empty', 'ai_no_matches',
    'ai_budget_exhausted', 'ai_not_configured', 'ai_failed', 'recipient_unavailable', 'circle_member_not_sharing',
  ];

  test('every code of 8.0.10 has an entry', () {
    for (final c in codes) {
      expect(glassErrors.containsKey(c), isTrue, reason: c);
    }
  });

  test('surfaces, exact copy and haptics', () {
    expect(glassErrors['profile_limit_reached']!.copy, 'This account already has 5 profiles, the most it can have. Delete one to add another.');
    expect(glassErrors['profile_limit_reached']!.recoveryLabel, 'Manage profiles');
    expect(glassErrors['forbidden']!.surface, GlassErrorSurface.lens);
    expect(glassErrors['forbidden']!.body, "It's for the server's administrators or its owner.");
    expect(glassErrors['forbidden']!.haptic, isNull);
    expect(glassErrors['follow_limit_reached']!.copy, 'You follow 1,000 series, the most a profile can. Remove some to add more.');
    expect(glassErrors['batch_too_large']!.surface, GlassErrorSurface.toast);
    expect(glassErrors['invalid_profile_name']!.shake, isTrue);
    expect(glassErrors['profile_required']!.haptic, HapticEvent.warning);
    expect(glassErrors['db_busy']!.surface, GlassErrorSurface.capsule);
    expect(glassErrors['source_not_browsable']!.copy, contains('search or your library'));
    expect(glassErrors['source_not_browsable']!.copy.toLowerCase(), isNot(contains('18')));
  });

  test('only rate_limited and db_busy auto-retry; a 429 with any other code never does', () {
    final retrying = glassErrors.entries.where((e) => e.value.autoRetry).map((e) => e.key).toSet();
    expect(retrying, {'rate_limited', 'db_busy'});
    expect(errorEntry(_api('ai_budget_exhausted', status: 429)).autoRetry, isFalse);
    expect(errorEntry(_api('some_unknown_code', status: 429)).autoRetry, isFalse);
    expect(errorEntry(_api('rate_limited', status: 429)).autoRetry, isTrue);
    expect(errorEntry(_api('db_busy', status: 503)).autoRetry, isTrue);
    expect(errorEntry(_api('rate_limited', status: 429), site: 'MangaDex').autoRetry, isTrue);
  });

  test('{n} is filled from Retry-After', () {
    expect(errorEntry(_api('rate_limited', status: 429, retry: const Duration(seconds: 7))).copy, 'Slow down a little. Trying again in 7 s');
    expect(errorEntry(_api('db_busy', status: 503, retry: const Duration(milliseconds: 1500))).copy, 'The server is busy. Trying again in 2 s');
    expect(errorEntry(_api('rate_limited', status: 429, retry: const Duration(seconds: 30)), site: 'MangaDex').copy, 'The source is busy; retrying in 30 s');
    expect(errorEntry(_api('rate_limited', status: 429)).copy, 'Slow down a little. Trying again in $kDefaultRetrySeconds s');
  });

  test('names and sites are filled in', () {
    expect(errorEntry(_api('recipient_unavailable'), name: 'Aiko').copy, "Aiko isn't taking recommendations any more.");
    expect(externalLinkFailure('MangaDex').copy, "Couldn't open MangaDex");
  });

  test('network, timeout and unknown codes fall back', () {
    expect(errorEntry(const NetworkError(message: 'x')).copy, "Couldn't reach the server.");
    expect(errorEntry(const TimeoutError()).copy, "Couldn't reach the server.");
    expect(errorEntry(const TimeoutError()).haptic, HapticEvent.error);
    final generic = errorEntry(_api('brand_new_code'));
    expect(generic.copy, 'Something went wrong. Try again.');
    expect(generic.recoveryLabel, 'Try again');
  });

  test('a form entry carries the server message; mid-session account_disabled is the alert', () {
    expect(errorEntry(_api('invalid_credentials', status: 401)).copy, 'server says invalid_credentials');
    expect(errorEntry(_api('invalid_credentials', status: 401)).shake, isTrue);
    expect(errorEntry(_api('account_disabled', status: 403), midSession: true).surface, GlassErrorSurface.alert);
    expect(errorEntry(_api('account_disabled', status: 403)).surface, GlassErrorSurface.form);
  });
}
