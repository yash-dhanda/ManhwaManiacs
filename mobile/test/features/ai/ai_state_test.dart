import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/ai/utils/ai_state.dart';

void main() {
  final now = DateTime.utc(2026, 9, 30, 12);
  test('states', () {
    expect(aiState(loading: true).state, AiSurfaceState.thinking);
    expect(aiState(available: false, reason: 'not_configured').reason, 'not_configured');
    expect(aiState(partial: true).state, AiSurfaceState.partial);
    expect(aiState(generatedAt: now.subtract(const Duration(days: 3)), now: now).state, AiSurfaceState.stale);
    expect(aiState(generatedAt: now.subtract(const Duration(hours: 23)), now: now).state, AiSurfaceState.ready);
    expect(aiState().state, AiSurfaceState.ready);
  });
  test('codes, never statuses', () {
    expect(aiState(errorCode: 'rate_limited').reason, 'rate_limited');
    expect(aiState(errorCode: 'ai_budget_exhausted').reason, 'budget_exhausted');
    expect(aiState(errorCode: 'ai_budget_exhausted').state, AiSurfaceState.unavailable);
  });
  test('staleDays', () {
    expect(staleDays(null, now), isNull);
    expect(staleDays(now.subtract(const Duration(hours: 24)), now), 1);
    expect(staleDays(now.subtract(const Duration(hours: 80)), now), 3);
  });
}
