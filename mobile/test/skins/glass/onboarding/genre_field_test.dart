import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/copy/genres.dart';
import 'package:manhwamaniacs/skins/glass/screens/onboarding/genre_field.dart';

GenreField _field({bool mature = false}) => GenreField(size: const Size(358, 560), names: glassGenres(matureOpen: mature));

GenreField _fitted() => GenreField(size: const Size(358, 480), names: glassGenres(matureOpen: false), radiusScale: GenreField.fitScale(const Size(358, 480), 24));

void main() {
  test('24 bodies with and without the gate, with the rank radii', () {
    expect(_field().bodies, hasLength(24));
    expect(_field(mature: true).bodies, hasLength(24));
    final f = _field();
    expect(f.bodies.first.baseRadius, 52);
    expect(f.bodies.last.baseRadius, closeTo(36, 1e-9));
  });

  test('the fit scale keeps the bodies at 62 % of a small field and leaves a roomy one alone', () {
    expect(GenreField.fitScale(const Size(358, 480), 24), lessThan(1));
    expect(GenreField.fitScale(const Size(1200, 1200), 24), 1);
  });

  test('overlaps resolve after a few frames', () {
    final f = _fitted();
    for (var i = 0; i < 60; i++) {
      f.step(1 / 60);
    }
    for (var i = 0; i < f.bodies.length; i++) {
      for (var j = i + 1; j < f.bodies.length; j++) {
        final a = f.bodies[i], b = f.bodies[j];
        expect((a.p - b.p).distance, greaterThan(a.radius + b.radius - 4), reason: '${a.name} / ${b.name}');
      }
    }
  });

  test('a wall returns 40 % of the speed', () {
    final f = GenreField(size: const Size(400, 400), names: const ['Action']);
    final b = f.bodies.single;
    b.p = Offset(b.radius + 1, 200);
    b.v = const Offset(-500, 0);
    f.step(1 / 60);
    expect(b.v.dx, greaterThan(0));
    expect(b.v.dx, lessThan(500 * GenreField.restitution + 20));
    expect(b.p.dx, greaterThanOrEqualTo(b.radius - 0.001));
  });

  test('the centre pull draws a lone body back', () {
    final f = GenreField(size: const Size(400, 400), names: const ['Action']);
    final b = f.bodies.single;
    b.p = const Offset(300, 200);
    final start = (b.p - f.centre).distance;
    for (var i = 0; i < 20; i++) {
      f.step(1 / 60);
    }
    expect((b.p - f.centre).distance, lessThan(start));
  });

  test('bodies sleep after 30 quiet frames and wake on input', () {
    final f = GenreField(size: const Size(400, 400), names: const ['Action']);
    final b = f.bodies.single;
    b.p = f.centre;
    for (var i = 0; i < 29; i++) {
      f.step(1 / 60);
    }
    expect(b.asleep, isFalse);
    f.step(1 / 60);
    expect(b.asleep, isTrue);
    expect(f.allAsleep, isTrue);
    f.setWeight('Action', 1);
    expect(b.asleep, isFalse);
  });

  test('a gravity change above 0.02 g wakes; a smaller one does not', () {
    final f = GenreField(size: const Size(400, 400), names: const ['Action']);
    final b = f.bodies.single;
    b.p = f.centre;
    for (var i = 0; i < 40; i++) {
      f.step(1 / 60);
    }
    expect(b.asleep, isTrue);
    f.setGravity(const Offset(4, 0));
    expect(b.asleep, isTrue);
    f.setGravity(const Offset(400, 0));
    expect(b.asleep, isFalse);
  });

  test('weights cycle 0, 1, 2, 0 and set the sizes', () {
    expect(nextGenreWeight(0), 1);
    expect(nextGenreWeight(1), 2);
    expect(nextGenreWeight(2), 0);
    expect(genreScaleFor(1), 1.25);
    expect(genreScaleFor(2), 1.5);
    expect(genreScaleFor(-1), 0.8);
  });

  test('the grid form rests without physics', () {
    final f = _field();
    f.layoutGrid(4);
    expect(f.allAsleep, isTrue);
    expect(f.bodies.first.p.dy, lessThan(f.bodies.last.p.dy));
    f.setWeight('Action', 2);
    f.layoutGrid(4);
    expect(f.bodies.first.radius, greaterThan(f.bodies[1].radius));
  });

  test('arrow navigation picks the nearest body within 45 degrees', () {
    final f = GenreField(size: const Size(600, 600), names: const ['A', 'B', 'C']);
    f.byName('A')!.p = const Offset(100, 100);
    f.byName('B')!.p = const Offset(300, 110);
    f.byName('C')!.p = const Offset(110, 400);
    expect(f.nearest(f.byName('A')!, 0)!.name, 'B');
    expect(f.nearest(f.byName('A')!, 1.5708)!.name, 'C');
    expect(f.nearest(f.byName('A')!, 3.1416), isNull);
  });
}
