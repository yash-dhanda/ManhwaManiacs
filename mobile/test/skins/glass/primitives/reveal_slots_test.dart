import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/reveal_slots.dart';

void main() {
  test('at most two run; the third starts when one ends', () {
    final q = RevealSlotQueue();
    final started = <String>[];
    expect(q.acquire('a', () => started.add('a')), isTrue);
    expect(q.acquire('b', () => started.add('b')), isTrue);
    expect(q.acquire('c', () => started.add('c')), isFalse);
    expect(started, ['a', 'b']);
    q.release('a');
    expect(started, ['a', 'b', 'c']);
    expect(q.running, 2);
  });

  test('a waiter that left the screen is withdrawn and never starts', () {
    final q = RevealSlotQueue();
    final started = <String>[];
    q.acquire('a', () {});
    q.acquire('b', () {});
    q.acquire('c', () => started.add('c'));
    q.withdraw('c');
    q.release('a');
    expect(started, isEmpty);
    expect(q.running, 1);
  });

  test('duration is n x 24 + 345 + 120 + 500 ms', () {
    expect(revealDuration(10), const Duration(milliseconds: 240 + 965));
  });
}
