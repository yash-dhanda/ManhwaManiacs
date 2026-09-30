import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/lru.dart';

void main() {
  test('evicts least recently used', () {
    final l = Lru<int, int>(2);
    l[1] = 1; l[2] = 2;
    expect(l[1], 1);
    l[3] = 3;
    expect(l.containsKey(2), isFalse);
    expect(l.containsKey(1), isTrue);
    expect(l.length, 2);
  });
}
