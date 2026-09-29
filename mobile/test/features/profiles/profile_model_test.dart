// ignore_for_file: require_trailing_commas
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';

void main() {
  final base = {'id': 1, 'name': 'A', 'avatar_key': 'k', 'mood': 'default', 'sort_order': 0};
  test('parses the new fields', () {
    final p = Profile.fromJson({...base, 'onboarding_step': 'done', 'notify_enabled': false, 'daily_goal_minutes': 20});
    expect(p.onboardingStep, 'done');
    expect(p.notifyEnabled, isFalse);
    expect(p.dailyGoalMinutes, 20);
  });
  test('an old server keeps the defaults', () {
    final p = Profile.fromJson(base);
    expect(p.onboardingStep, isNull);
    expect(p.notifyEnabled, isTrue);
    expect(p.dailyGoalMinutes, isNull);
  });
}
