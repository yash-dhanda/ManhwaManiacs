import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/cruise_engage.dart';

void main() {
  test('engageSpeed', () {
    expect(engageSpeed(14), isNull);
    expect(engageSpeed(15), 0.25);
    expect(engageSpeed(60), 1.0);
    expect(engageSpeed(240), 4.0);
    expect(engageSpeed(241), isNull);
    expect(engageSpeed(-100), isNull);
  });
}
