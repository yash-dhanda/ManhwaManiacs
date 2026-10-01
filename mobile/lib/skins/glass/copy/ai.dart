// The Glass AI copy (glass 9.1.5): one short and one long line per server `reason`, and the partial, timeout and stale
// lines. Exact wording; no surface invents its own.

class GlassAiLines {
  const GlassAiLines(this.short, this.long);

  /// Rails and badges.
  final String short;

  /// For you, recaps and More like this.
  final String long;

  GlassAiLines withSeconds(int n) => GlassAiLines(short.replaceAll('{n}', '$n'), long.replaceAll('{n}', '$n'));
}

/// Keyed by the server's `reason` (`aiState()` maps `ai_budget_exhausted` and `ai_not_configured` onto these keys).
/// The long lines that the error copy (`copy/errors.dart`) also shows, so there is one wording.
const String kAiNotConfiguredLong = "AI isn't set up on this server. Everything else works as usual.";
const String kAiBudgetLong = "You've used today's AI asks. They reset at midnight UTC.";
const String kAiUpstreamLong = "The AI service didn't answer. Try again in a moment.";

const Map<String, GlassAiLines> glassAiReasons = {
  'not_configured': GlassAiLines('AI picks are off on this server', kAiNotConfiguredLong),
  'budget_exhausted': GlassAiLines("Today's AI asks are used up", kAiBudgetLong),
  'rate_limited': GlassAiLines('AI is busy, retrying in {n} s', 'Too many requests in a row. Trying again in {n} s.'),
  'offline': GlassAiLines('AI picks need a connection', "You're offline. AI picks come back when you reconnect."),
  'upstream_error': GlassAiLines("AI picks didn't load", kAiUpstreamLong),
};

const String glassAiPartialLine = "Some picks didn't come through.";
const String glassAiTimeoutLine = 'That took too long. Try again.';

/// "Picked 1 day ago", "Picked 3 days ago".
String glassAiStaleLine(int days) => 'Picked $days ${days == 1 ? 'day' : 'days'} ago';

/// The lines for [reason]; an unknown reason reads as an upstream error. `{n}` is filled from [retrySeconds].
GlassAiLines glassAiLines(String? reason, {int? retrySeconds}) {
  final l = glassAiReasons[reason] ?? glassAiReasons['upstream_error']!;
  return retrySeconds == null ? l : l.withSeconds(retrySeconds);
}

/// The administrator-only line under `not_configured`.
const String glassAiAdminHint = 'Add an AI API key on the server to turn it on.';
