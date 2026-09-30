/// The four states every AI surface is in (cinematic 9.1.8), plus `ready`.
enum AiSurfaceState { thinking, ready, unavailable, partial, stale }

typedef AiSurface = ({AiSurfaceState state, String? reason});

/// Whole days since [generatedAt] once it is at least 24 h old (min 1), else null.
int? staleDays(DateTime? generatedAt, DateTime now) {
  if (generatedAt == null) return null;
  final h = now.difference(generatedAt).inHours;
  return h < 24 ? null : (h ~/ 24).clamp(1, 1 << 30);
}

/// The error `code` a failure reads as: a bare 429 is [errorCode] `rate_limited` only when the
/// server said so; `ai_budget_exhausted` stays its own. Branch on the code, never the status.
String? _reason(String? reason, String? errorCode) {
  final c = errorCode ?? reason;
  return switch (c) {
    'ai_budget_exhausted' => 'budget_exhausted',
    'ai_not_configured' => 'not_configured',
    _ => c,
  };
}

/// Which state a surface is in. Order: thinking, then a closed desk or an error, then partial,
/// then stale, else ready.
AiSurface aiState({
  bool loading = false,
  bool available = true,
  String? reason,
  String? errorCode,
  DateTime? generatedAt,
  DateTime? now,
  bool partial = false,
}) {
  if (loading) return (state: AiSurfaceState.thinking, reason: null);
  if (!available || errorCode != null) return (state: AiSurfaceState.unavailable, reason: _reason(reason, errorCode));
  if (partial) return (state: AiSurfaceState.partial, reason: null);
  if (staleDays(generatedAt, now ?? DateTime.now()) != null) return (state: AiSurfaceState.stale, reason: null);
  return (state: AiSurfaceState.ready, reason: null);
}
