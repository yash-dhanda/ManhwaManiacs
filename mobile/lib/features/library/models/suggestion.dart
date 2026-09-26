/// Whether the feature can run at all, answered without running it.
///
/// A missing API key is a deployment state, not an error — so the screen hides
/// the prompt box rather than offering a button that fails on tap.
class SuggestionAvailability {
  const SuggestionAvailability({
    required this.available,
    required this.reason,
    required this.remainingToday,
  });

  final bool available;

  /// `ok` · `not_configured` · `budget_exhausted`.
  final String reason;
  final int remainingToday;

  bool get isBudgetExhausted => reason == 'budget_exhausted';

  factory SuggestionAvailability.fromJson(Map<String, dynamic> json) =>
      SuggestionAvailability(
        available: json['available'] as bool? ?? false,
        reason: json['reason'] as String? ?? 'not_configured',
        remainingToday: (json['remaining_today'] as num?)?.toInt() ?? 0,
      );
}
