import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/screens/onboarding/seed_counter.dart';

void main() {
  test('the counter pluralises', () {
    expect(seedCounterLine(0, 0), 'Your home has 0 titles to start with');
    expect(seedCounterLine(1, 0), 'Your home has 1 title to start with');
    expect(seedCounterLine(4, 3), 'Your home has 7 titles to start with');
  });
}
