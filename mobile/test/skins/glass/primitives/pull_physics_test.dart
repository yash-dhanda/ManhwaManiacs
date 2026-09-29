import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/pull_physics.dart';

void main() {
  test('the droplet radius at 30, 60 and 90 px', () {
    expect(dropletRadius(0), 0);
    expect(dropletRadius(30), 8);
    expect(dropletRadius(60), 16);
    expect(dropletRadius(90), 16);
  });

  test('the neck is 12 x (1 - progress) px and closes at 100', () {
    expect(neckWidth(0), 12);
    expect(neckWidth(50), 6);
    expect(neckWidth(100), 0);
    expect(neckWidth(140), 0);
  });

  test('the neck snaps at exactly 100 px', () {
    expect(pullArmed(99.9), isFalse);
    expect(pullArmed(100), isTrue);
    expect(pullRestLine, 60);
    expect(glyphTurns(100), 1);
    expect(glyphTurns(50), 0.5);
  });
}
