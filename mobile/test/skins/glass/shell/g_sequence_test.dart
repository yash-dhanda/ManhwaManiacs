import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/shell/g_sequence.dart';

void main() {
  test('g then l jumps to Library', () {
    final g = GlassGSequence();
    expect(g.key('g', 0), isA<GlassGConsumed>());
    final e = g.key('l', 400);
    expect(e, isA<GlassGJump>());
    expect((e as GlassGJump).location, '/library');
    expect(g.armed, isFalse);
  });

  test('every chord target resolves', () {
    for (final e in gGlassTargets.entries) {
      final g = GlassGSequence()..key('g', 0);
      expect((g.key(e.key, 10) as GlassGJump).location, e.value);
    }
  });

  test('the window is 1 s', () {
    final g = GlassGSequence()..key('g', 0);
    expect(g.key('l', 1001), isA<GlassGIgnored>());
  });

  test('other keys cancel, text focus ignores', () {
    final g = GlassGSequence()..key('g', 0);
    expect(g.key('x', 10), isA<GlassGConsumed>());
    expect(g.armed, isFalse);
    expect(GlassGSequence().key('g', 0, textFocus: true), isA<GlassGIgnored>());
    expect(GlassGSequence().key('l', 0), isA<GlassGIgnored>());
  });
}
