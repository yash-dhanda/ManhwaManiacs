import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/page_turn.dart';

void main() {
  test('72 px commits, 71 does not', () {
    expect(shouldCommitTurn(-71, 0, 390), isFalse);
    expect(shouldCommitTurn(-72, 0, 390), isTrue);
  });
  test('600 px/s commits, 599 does not', () {
    expect(shouldCommitTurn(-10, -599, 390), isFalse);
    expect(shouldCommitTurn(-10, -600, 390), isTrue);
  });
  test('direction: LTR left swipe forwards, RTL mirrors', () {
    expect(turnDecision(-80, 0), 1);
    expect(turnDecision(80, 0), -1);
    expect(turnDecision(-80, 0, rtl: true), -1);
    expect(turnDecision(80, 0, rtl: true), 1);
    expect(turnDecision(-10, -700), 1);
    expect(turnDecision(-10, -700, rtl: true), -1);
  });
  test('a fast flick against a short drag follows the velocity', () {
    expect(turnDecision(10, -900), 1);
  });
  test('turn target steps a page or a spread and clamps', () {
    expect(turnTarget(3, 1, 10), 4);
    expect(turnTarget(10, 1, 10), 10);
    expect(turnTarget(1, -1, 10), 1);
    final leads = [1, 2, 4, 6];
    expect(turnTarget(1, 1, 7, viewLeads: leads), 2);
    expect(turnTarget(2, 1, 7, viewLeads: leads), 4);
    expect(turnTarget(5, 1, 7, viewLeads: leads), 6); // page 5 sits in the [4,5] view
    expect(turnTarget(6, 1, 7, viewLeads: leads), 6);
    expect(turnTarget(2, -1, 7, viewLeads: leads), 1);
  });
}
