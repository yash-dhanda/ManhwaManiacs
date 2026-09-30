import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/depth_glyph.dart';

import 'support.dart';

void main() {
  test('the back button label names the previous screen and the depth', () {
    expect(depthLabel('Solo Leveling', 3), 'Back to Solo Leveling, 3 levels deep');
    expect(depthLabel('Library', 2), 'Back to Library, 2 levels deep');
    expect(depthLabel('Library', 1), 'Back to Library, 1 level deep');
  });

  test('lit bars run from the bottom up and stop at four', () {
    expect([for (final d in [0, 1, 2, 3, 4, 7]) litBars(d)], [0, 1, 2, 3, 4, 4]);
    expect(kStrataY, [56, 100, 144, 188]);
    expect(kStrataWidth, [124, 136, 148, 160]);
  });

  testWidgets('the painter lights depth bars with their tints, newest last', (tester) async {
    await tester.pumpWidget(primHost(const DepthGlyph(depth: 2, tints: [Color(0xFFFF0000), Color(0xFF00FF00)])));
    await pumpFor(tester, 200);
    final custom = tester.widget<CustomPaint>(find.descendant(of: find.byType(DepthGlyph), matching: find.byType(CustomPaint)).first);
    final p = custom.painter! as DepthGlyphPainter;
    expect(p.fills, [1, 1, 0, 0]);
    expect(p.tints, [const Color(0xFFFF0000), const Color(0xFF00FF00)]);
    expect(custom.size, const Size.square(22));
    // rising to depth 3 fills the third bar after the stagger
    await tester.pumpWidget(primHost(const DepthGlyph(depth: 3, tints: [Color(0xFFFF0000), Color(0xFF00FF00), Color(0xFF0000FF)])));
  });
}
