import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/g_sequence.dart';

void main() {
  late GSequenceMachine m;
  setUp(() => m = GSequenceMachine());

  test('a key outside the sequence is ignored', () {
    expect(m.key('2', 0), isA<GIgnored>());
    expect(m.phase, GPhase.idle);
  });

  test('g arms, g 2 jumps at once', () {
    expect(m.key('g', 0), isA<GConsumed>());
    expect(m.chip, 'G _');
    final e = m.key('2', 100);
    expect(e, isA<GJump>());
    expect((e as GJump).number, 2);
    expect(m.phase, GPhase.idle);
  });

  test('g 0 jumps to Settings', () {
    m.key('g', 0);
    expect((m.key('0', 10) as GJump).number, 0);
    expect(gTargets[0], '/settings');
  });

  test('every target of 2..9 jumps at once', () {
    for (final n in [2, 3, 4, 5, 6, 7, 8, 9]) {
      m.key('g', 0);
      expect((m.key('$n', 5) as GJump).number, n);
    }
  });

  test('the arm times out after 1500 ms', () {
    m.key('g', 0);
    expect(m.deadlineMs, 1500);
    expect(m.tick(1499), isA<GIgnored>());
    expect(m.tick(1500), isA<GCancelled>());
    expect(m.phase, GPhase.idle);
  });

  test('g 1 waits 600 ms for 0, 1 or 2', () {
    m.key('g', 0);
    expect(m.key('1', 100), isA<GConsumed>());
    expect(m.chip, 'G 1_');
    expect(m.deadlineMs, 700);
    expect((m.key('1', 300) as GJump).number, 11);
    m.key('g', 1000);
    m.key('1', 1010);
    expect((m.key('0', 1100) as GJump).number, 10);
    m.key('g', 2000);
    m.key('1', 2010);
    expect((m.key('2', 2100) as GJump).number, 12);
  });

  test('g 1 then 600 ms jumps to 01', () {
    m.key('g', 0);
    m.key('1', 100);
    expect(m.tick(699), isA<GIgnored>());
    final e = m.tick(700);
    expect((e as GJump).number, 1);
    expect(gTargets[1], '/');
  });

  test('g 1 then another key cancels', () {
    m.key('g', 0);
    m.key('1', 100);
    final e = m.key('5', 200);
    expect(e, isA<GCancelled>());
    expect((e as GCancelled).consumed, isTrue);
  });

  test('Enter jumps to 01 at once', () {
    m.key('g', 0);
    expect((m.key('enter', 50) as GJump).number, 1);
  });

  test('Esc and any other key cancel and are consumed', () {
    m.key('g', 0);
    expect((m.key('escape', 5) as GCancelled).consumed, isTrue);
    m.key('g', 10);
    expect((m.key('other', 20) as GCancelled).consumed, isTrue);
    expect(m.phase, GPhase.idle);
  });

  test('in novels mode g 9 cancels', () {
    m.novelsMode = true;
    m.key('g', 0);
    expect(m.key('9', 10), isA<GCancelled>());
    m.key('g', 20);
    expect((m.key('4', 30) as GJump).number, 4);
  });

  test('targets', () {
    expect(gTargets, {
      1: '/',
      2: '/library',
      3: '/updates',
      4: '/search',
      5: '/downloads',
      6: '/library/collections',
      7: '/library/history',
      8: '/library/bookmarks',
      9: '/ocr',
      10: '/library/statistics',
      11: '/circle',
      12: '/library/recommendations',
      0: '/settings',
    });
  });
}
