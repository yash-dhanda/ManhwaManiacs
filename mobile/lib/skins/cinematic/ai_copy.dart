import 'package:manhwamaniacs/core/error/app_error.dart';

/// §9.1.8 vocabulary for the ASK scope and the Ask-the-editors block.
/// TODO(mobile/08): reuse its module when it lands; mobile/19 extends this.
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
/// on other statuses. Carries the Retry-After the error interceptor folded
/// into `details`.
AiCopy aiCopyForError(Object error) {
  if (error is! ApiError) return aiCopyForCode(null);
  final d = error.details;
  final after = d is Map ? d['retry_after'] : null;
  return aiCopyForCode(
    error.statusCode == 429 ? 'rate_limited' : error.code,
    retryAfter: after is num ? after.toInt() : null,
  );
}
