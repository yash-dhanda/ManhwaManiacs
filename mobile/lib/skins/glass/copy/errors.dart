import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/skins/contract.g.dart' show HapticEvent;
import 'package:manhwamaniacs/skins/glass/copy/ai.dart';

// The one error-copy module of the Glass skin (glass 8.0.10). Every server code has a surface, its copy, an optional
// recovery label and a haptic; no screen invents wording.

enum GlassErrorSurface { toast, inline, lens, alert, capsule, form }

/// Where a code shows and what it says. [copy] may hold `{n}` (seconds from `Retry-After`), `{name}` and `{site}`.
class GlassErrorEntry {
  const GlassErrorEntry(this.surface, this.copy, {this.body, this.recoveryLabel, this.haptic, this.autoRetry = false, this.shake = false});
  final GlassErrorSurface surface;
  final String copy;
  final String? body;
  final String? recoveryLabel;
  final HapticEvent? haptic;

  /// Only `rate_limited` and `db_busy` retry by themselves (8.0.10's last line).
  final bool autoRetry;

  /// A form field springs back with the shake.
  final bool shake;

  GlassErrorEntry filled({int? n, String? name, String? site}) {
    String f(String s) => s.replaceAll('{n}', '${n ?? kDefaultRetrySeconds}').replaceAll('{name}', name ?? 'They').replaceAll('{site}', site ?? 'the link');
    return GlassErrorEntry(surface, f(copy), body: body == null ? null : f(body!), recoveryLabel: recoveryLabel, haptic: haptic, autoRetry: autoRetry, shake: shake);
  }
}

/// The wait when the server sent no `Retry-After` (the request limiter's own fallback).
const int kDefaultRetrySeconds = 12;

const GlassErrorEntry _form = GlassErrorEntry(GlassErrorSurface.form, '', haptic: HapticEvent.error, shake: true);

/// `rate_limited` on a source ("The source is busy; retrying in {n} s"); [errorEntry] picks it when a `site` is given.
const GlassErrorEntry kSourceBusy = GlassErrorEntry(GlassErrorSurface.capsule, 'The source is busy; retrying in {n} s', autoRetry: true, haptic: HapticEvent.warning);

/// Every code of glass 8.0.10, by the server's `error.code`.
const Map<String, GlassErrorEntry> glassErrors = {
  // Forms: their copy lives with Login, Register and Change password (mobile/30, mobile/39); [errorEntry] passes the
  // server's own message through.
  'invalid_credentials': _form,
  'account_disabled': _form,
  'weak_password': _form,
  'username_taken': _form,
  'invalid_username': _form,
  'registration_disabled': _form,
  'invite_code_required': _form,
  'invite_code_invalid': _form,
  'bootstrap_window_expired': _form,
  'bootstrap_already_claimed': _form,
  // Mid-session, the account flow of 8.0.9 (mobile/29).
  'not_authenticated': GlassErrorEntry(GlassErrorSurface.alert, 'Sign in again', haptic: HapticEvent.warning),
  'profile_required': GlassErrorEntry(GlassErrorSurface.toast, 'That profile is no longer available', haptic: HapticEvent.warning),
  'profile_not_found': GlassErrorEntry(GlassErrorSurface.toast, 'That profile is no longer available', haptic: HapticEvent.warning),
  'profile_limit_reached': GlassErrorEntry(GlassErrorSurface.inline, 'This account already has 5 profiles, the most it can have. Delete one to add another.', recoveryLabel: 'Manage profiles', haptic: HapticEvent.error),
  'invalid_profile_name': GlassErrorEntry(GlassErrorSurface.inline, 'Use 1 to 30 characters for the name.', haptic: HapticEvent.error, shake: true),
  'invalid_mood': GlassErrorEntry(GlassErrorSurface.inline, 'Pick one of the moods.', haptic: HapticEvent.error),
  'cannot_manage_self': GlassErrorEntry(GlassErrorSurface.inline, "You can't deactivate or delete your own account.", haptic: HapticEvent.error),
  'forbidden': GlassErrorEntry(GlassErrorSurface.lens, "You don't have access to this", body: "It's for the server's administrators or its owner.", recoveryLabel: 'Back'),
  'not_found': GlassErrorEntry(GlassErrorSurface.lens, "This isn't here any more", body: 'It may have been removed on another device.', recoveryLabel: 'Back'),
  'series_not_found': GlassErrorEntry(GlassErrorSurface.lens, "The source doesn't have this series any more."),
  'source_not_found': GlassErrorEntry(GlassErrorSurface.lens, 'This source was removed from the server.'),
  'source_not_browsable': GlassErrorEntry(GlassErrorSurface.lens, "This source can't be browsed; open its series from search or your library."),
  'follow_limit_reached': GlassErrorEntry(GlassErrorSurface.toast, 'You follow 1,000 series, the most a profile can. Remove some to add more.', recoveryLabel: 'Open library', haptic: HapticEvent.error),
  'invalid_reading_status': GlassErrorEntry(GlassErrorSurface.toast, "Couldn't set that reading status. Try again.", haptic: HapticEvent.error),
  'bookmark_deleted': GlassErrorEntry(GlassErrorSurface.toast, 'That bookmark was removed on another device'),
  'batch_too_large': GlassErrorEntry(GlassErrorSurface.toast, "That's too many at once. Select fewer and try again.", haptic: HapticEvent.error),
  'check_already_running': GlassErrorEntry(GlassErrorSurface.toast, 'A check is already running'),
  'db_busy': GlassErrorEntry(GlassErrorSurface.capsule, 'The server is busy. Trying again in {n} s', autoRetry: true),
  'rate_limited': GlassErrorEntry(GlassErrorSurface.capsule, 'Slow down a little. Trying again in {n} s', autoRetry: true, haptic: HapticEvent.warning),
  // The player's own copy lives in mobile/37.
  'narration_unavailable': GlassErrorEntry(GlassErrorSurface.inline, ''),
  'audio_preparing': GlassErrorEntry(GlassErrorSurface.inline, ''),
  'audio_convert_failed': GlassErrorEntry(GlassErrorSurface.inline, "This chapter's audio couldn't be prepared.", recoveryLabel: 'Try again', haptic: HapticEvent.error),
  // For you's copy lives in mobile/41.
  'suggest_shelf_empty': GlassErrorEntry(GlassErrorSurface.inline, ''),
  'ai_no_matches': GlassErrorEntry(GlassErrorSurface.inline, ''),
  // The AI long lines (copy/ai.dart); never auto-retried.
  'ai_budget_exhausted': GlassErrorEntry(GlassErrorSurface.inline, "You've used today's AI asks. They reset at midnight UTC."),
  'ai_not_configured': GlassErrorEntry(GlassErrorSurface.inline, "AI isn't set up on this server. Everything else works as usual."),
  'ai_failed': GlassErrorEntry(GlassErrorSurface.inline, "The AI service didn't answer. Try again in a moment."),
  'recipient_unavailable': GlassErrorEntry(GlassErrorSurface.toast, "{name} isn't taking recommendations any more.", haptic: HapticEvent.warning),
  'circle_member_not_sharing': GlassErrorEntry(GlassErrorSurface.inline, "{name} isn't sharing right now."),
};

/// `account_disabled` in the middle of a session is the sign-out alert of 8.0.9, not a form message.
const GlassErrorEntry kAccountDisabledSession = GlassErrorEntry(GlassErrorSurface.alert, 'Your account was deactivated', haptic: HapticEvent.warning);

/// An external link that would not open (`url_launcher` returned false).
GlassErrorEntry externalLinkFailure(String site) => const GlassErrorEntry(GlassErrorSurface.toast, "Couldn't open {site}", haptic: HapticEvent.error).filled(site: site);

const GlassErrorEntry _network = GlassErrorEntry(GlassErrorSurface.toast, "Couldn't reach the server.", haptic: HapticEvent.error);
const GlassErrorEntry _generic = GlassErrorEntry(GlassErrorSurface.toast, 'Something went wrong. Try again.', recoveryLabel: 'Try again');

/// What [error] shows: the entry of its code with `{n}` filled from `Retry-After`, `{name}` and `{site}`; a network or timeout
/// failure reads "Couldn't reach the server."; any other code "Something went wrong. Try again." A form entry with no copy
/// carries the server's own message. Only `rate_limited` and `db_busy` auto-retry; a 429 with any other code never does.
GlassErrorEntry errorEntry(AppError error, {String? site, String? name, bool midSession = false}) {
  switch (error) {
    case NetworkError():
    case TimeoutError():
      return _network;
    case ApiError():
      final n = error.retryAfter == null ? null : (error.retryAfter!.inMilliseconds / 1000).ceil();
      if (error.code == 'account_disabled' && midSession) return kAccountDisabledSession;
      if (error.code == 'rate_limited' && site != null) return kSourceBusy.filled(n: n, site: site);
      final e = glassErrors[error.code];
      if (e == null) return _generic;
      final filled = e.filled(n: n, name: name, site: site);
      if (filled.copy.isEmpty && filled.surface == GlassErrorSurface.form) {
        return GlassErrorEntry(filled.surface, error.message, haptic: filled.haptic, shake: filled.shake);
      }
      return filled;
    default:
      return _generic;
  }
}

/// The AI lines an `ai_*` code maps to, for surfaces that show the AI notice rather than the inline entry.
GlassAiLines? aiLinesForCode(String code, {int? retrySeconds}) => switch (code) {
      'ai_budget_exhausted' => glassAiLines('budget_exhausted'),
      'ai_not_configured' => glassAiLines('not_configured'),
      'ai_failed' => glassAiLines('upstream_error'),
      'rate_limited' => glassAiLines('rate_limited', retrySeconds: retrySeconds),
      _ => null,
    };
