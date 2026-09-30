import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/screens/profiles/handoff_timeline.dart';

void main() {
  test('the pick lasts 1,100 ms, the flight starts at 450 ms and the pour takes 600 ms', () {
    final plan = Handoff.plan(mismatch: false);
    expect(Handoff.totalMs, 1100);
    expect(Handoff.at(plan, HandoffEventKind.flight), 450);
    expect(plan.firstWhere((e) => e.kind == HandoffEventKind.pour).durationMs, 600);
    expect(Handoff.at(plan, HandoffEventKind.commit), 1100);
    expect(plan.firstWhere((e) => e.kind == HandoffEventKind.inflate).atMs, 0);
    expect(Handoff.inflateScale, 1.35);
    expect(Handoff.repelSpeedPxPerS, 900);
  });

  test('the landing haptic follows the flight', () {
    final plan = Handoff.plan(mismatch: false);
    expect(Handoff.at(plan, HandoffEventKind.landHaptic), 450 + Handoff.flightMs);
  });

  test('a choice can change before 450 ms only', () {
    expect(Handoff.canInterrupt(0), isTrue);
    expect(Handoff.canInterrupt(449), isTrue);
    expect(Handoff.canInterrupt(450), isFalse);
  });

  test('the destination is onboarding while it is pending, else Home', () {
    expect(Handoff.destination(onboardingPending: true, tonight: '/', onboarding: '/welcome?step=2'), '/welcome?step=2');
    expect(Handoff.destination(onboardingPending: false, tonight: '/', onboarding: '/welcome?step=2'), '/');
  });

  test('a skin mismatch melts at 450 ms and restarts, with no flight', () {
    final plan = Handoff.plan(mismatch: true);
    expect(Handoff.at(plan, HandoffEventKind.melt), 450);
    expect(Handoff.at(plan, HandoffEventKind.flight), isNull);
    expect(Handoff.at(plan, HandoffEventKind.landHaptic), isNull);
    expect(Handoff.at(plan, HandoffEventKind.restart), 450 + Handoff.meltMs);
  });

  test('onboarding dematerialises the orb instead of the dock forming', () {
    final plan = Handoff.plan(mismatch: false, onboarding: true);
    expect(Handoff.at(plan, HandoffEventKind.dematerialiseOrb), isNotNull);
    expect(Handoff.plan(mismatch: false), isNot(contains(predicate<HandoffEvent>((e) => e.kind == HandoffEventKind.dematerialiseOrb))));
  });

  test('dueEvents returns each event once as time passes', () {
    final plan = Handoff.plan(mismatch: false);
    expect(dueEvents(plan, -1, 0).map((e) => e.kind), containsAll([HandoffEventKind.inflate, HandoffEventKind.repel, HandoffEventKind.pour]));
    expect(dueEvents(plan, 0, 449), isEmpty);
    expect(dueEvents(plan, 449, 450).single.kind, HandoffEventKind.flight);
    expect(dueEvents(plan, 450, 1100).map((e) => e.kind), contains(HandoffEventKind.commit));
  });
}
