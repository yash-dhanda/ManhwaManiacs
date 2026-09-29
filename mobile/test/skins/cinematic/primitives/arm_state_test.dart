import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/arm.dart';

void main() {
  const arm = ArmState();
  test('dead until 1000 ms', () {
    expect(arm.isArmed(const Duration(milliseconds: 999)), isFalse);
    expect(arm.isArmed(const Duration(milliseconds: 1000)), isTrue);
    expect(arm.press(const Duration(milliseconds: 500)), isFalse);
  });
  test('progress fills linearly and clamps', () {
    expect(arm.progress(Duration.zero), 0);
    expect(arm.progress(const Duration(milliseconds: 250)), closeTo(0.25, 1e-9));
    expect(arm.progress(const Duration(seconds: 5)), 1);
  });
  test('a heavy confirm also needs its condition', () {
    const t = Duration(milliseconds: 1500);
    expect(arm.canConfirm(t, conditionMet: false), isFalse);
    expect(arm.canConfirm(t), isTrue);
    expect(arm.canConfirm(const Duration(milliseconds: 100)), isFalse);
  });
}
