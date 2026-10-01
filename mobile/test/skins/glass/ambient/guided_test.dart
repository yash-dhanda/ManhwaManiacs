import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/ambient/guided.dart';

void main() {
  const vp = Size(390, 844);

  test('frameRect: a wide panel is width-bound, a tall one height-bound, a tiny one clamps at 3x', () {
    final wide = frameRect(const Rect.fromLTWH(0, 100, 390, 120), vp);
    expect(wide.scale, closeTo((390 - 48) / 390, 1e-9));
    final tall = frameRect(const Rect.fromLTWH(50, 0, 100, 800), vp);
    expect(tall.scale, closeTo((844 - 48) / 800, 1e-9));
    final tiny = frameRect(const Rect.fromLTWH(10, 10, 20, 20), vp);
    expect(tiny.scale, 3);
    // Centred: the panel's centre lands on the viewport's centre.
    final c = const Rect.fromLTWH(50, 0, 100, 800).center;
    expect(c.dx * tall.scale + tall.dx, closeTo(195, 1e-9));
    expect(c.dy * tall.scale + tall.dy, closeTo(422, 1e-9));
  });

  test('walkSteps: a panel that fits stops once; 2.5 viewports tall gives 0, 0.8 and 1.5 viewports', () {
    expect(walkSteps(0.9 * 844, 844), [0]);
    expect(walkSteps(844, 844), [0]);
    final steps = walkSteps(2.5 * 844, 844);
    expect(steps.length, 3);
    expect(steps[0], 0);
    expect(steps[1], closeTo(0.8 * 844, 1e-9));
    expect(steps[2], closeTo(1.5 * 844, 1e-9));
  });

  test('nextPanel crosses from the last panel of page 3 to the first of page 4; previous goes back across', () {
    const counts = [3, 2, 4, 1, 0];
    expect(nextPanel(const GuidedPos(3, 3), counts), const GuidedPos(4, 0));
    expect(nextPanel(const GuidedPos(3, 1), counts), const GuidedPos(3, 2));
    expect(nextPanel(const GuidedPos(4, 0), counts), const GuidedPos(5, 0));
    expect(nextPanel(const GuidedPos(5, 0), counts), isNull);
    expect(previousPanel(const GuidedPos(4, 0), counts), const GuidedPos(3, 3));
    expect(previousPanel(const GuidedPos(1, 0), counts), isNull);
    expect(previousPanel(const GuidedPos(5, 0), counts), const GuidedPos(4, 0));
  });

  test('swipes and bands mirror for right-to-left', () {
    expect(swipeStep(-80, 0, rtl: false), 1);
    expect(swipeStep(80, 0, rtl: false), -1);
    expect(swipeStep(-80, 0, rtl: true), -1);
    expect(swipeStep(80, 0, rtl: true), 1);
    expect(swipeStep(-20, 0, rtl: false), 0);
    expect(bandStep(350, 390, rtl: false), 1);
    expect(bandStep(350, 390, rtl: true), -1);
    expect(bandStep(20, 390, rtl: false), -1);
    expect(bandStep(195, 390, rtl: false), 0);
  });

  test('swipeCommits: 50 px or 500 px/s', () {
    expect(swipeCommits(49, 100), isFalse);
    expect(swipeCommits(50, 0), isTrue);
    expect(swipeCommits(10, 500), isTrue);
  });

  test('direction lock needs dx over twice dy', () {
    expect(horizontalLocked(30, 10), isTrue);
    expect(horizontalLocked(30, 20), isFalse);
  });

  test('exitByProjection: 60 px at 150 px/s projects to 134.9', () {
    expect(exitByProjection(60, 150), isTrue);
    expect(exitByProjection(60, 0), isFalse);
    expect(exitByProjection(100, 20), isFalse);
  });

  test('the counter reads as specified in every state', () {
    expect(counterText(page: 7, panel: 3, panelsBefore: 0, total: 38, finding: false, whole: false), 'Panel 4 of 38 · Page 7');
    expect(counterText(page: 7, panel: 3, panelsBefore: 0, finding: false, whole: false), 'Panel 4 · Page 7');
    expect(counterText(page: 7, panel: 0, panelsBefore: 0, finding: true, whole: false), 'Finding panels…');
    expect(counterText(page: 7, panel: 0, panelsBefore: 0, finding: false, whole: true), 'Page 7 · whole page');
    expect(announcement(page: 7, panel: 3, panelsBefore: 0, total: 38), 'Panel 4 of 38, page 7');
  });
}
