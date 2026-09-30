import 'package:manhwamaniacs/core/error/app_error.dart';

/// §9.1.8 vocabulary for every AI surface (Tonight's rails, Picks, Discover's ASK, Similar, tags,
/// the recap). One module: extend it, never fork it.
class AiCopy {
  const AiCopy(this.kicker, this.text, {this.rateLimited = false});

  final String kicker;
  final String text;
  final bool rateLimited;
}

AiCopy aiCopyForCode(String? code, {int? retryAfter}) => switch (code) {
      'budget_exhausted' || 'ai_budget_exhausted' => const AiCopy(
          'NOTE',
          'The picks desk is closed tonight. Asks reset at midnight UTC.',
        ),
      'not_configured' || 'ai_not_configured' => const AiCopy(
          'NOTE',
          "The editors' desk isn't set up on this server.",
        ),
      'ai_no_matches' => const AiCopy('NOTE', 'Nothing fit that description. Try describing it differently.'),
      'rate_limited' => AiCopy(
          'SLOW DOWN',
          'Too many asks at once. Try again in ${retryAfter ?? 12} s.',
          rateLimited: true,
        ),
      _ => const AiCopy(
          'NOTE',
          "The editors couldn't answer that one. Try describing it differently.",
        ),
    };

/// Branches on the error `code` (a bare 429 counts as `rate_limited`), never
/// on other statuses. Carries the Retry-After wait.
AiCopy aiCopyForError(Object error) {
  if (error is! ApiError) return aiCopyForCode(null);
  return aiCopyForCode(
    error.statusCode == 429 ? 'rate_limited' : error.code,
    retryAfter: retryAfterSeconds(error),
  );
}

/// Seconds to wait after a 429: the interceptor's `ApiError.retryAfter`, else a `retry_after`
/// the server put in `details`.
int? retryAfterSeconds(ApiError e) {
  final d = e.details;
  final after = d is Map ? d['retry_after'] : null;
  return e.retryAfter?.inSeconds ?? (after is num ? after.toInt() : null);
}

/// The typed thinking lines (a leader dial follows after 1 s).
const kAiThinkingPicks = 'Reading your shelf…';
const kAiThinkingSimilar = 'Finding series like this one…';
const kAiThinkingRecap = 'Writing the recap…';

/// The unavailable line of a surface: the copy for [reason], then what is shown instead
/// ("Here is your shelf instead.", "Here are series from the same genres.").
String aiUnavailableLine(String? reason, String instead) => '${aiCopyForCode(reason).text} $instead';
