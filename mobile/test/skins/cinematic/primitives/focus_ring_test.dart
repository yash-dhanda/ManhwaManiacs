import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';

import 'gallery_host.dart';

Iterable<CineFocusRingPainter> _rings(WidgetTester t) => [
      for (final p in t.widgetList<CustomPaint>(find.descendant(of: find.byKey(const Key('g-button-primary-md')), matching: find.byType(CustomPaint))))
        if (p.foregroundPainter is CineFocusRingPainter) p.foregroundPainter! as CineFocusRingPainter,
    ];

void main() {
  tearDown(() => FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic);

  testWidgets('a focused CineButton paints the ring on a hardware keyboard, and nothing on touch', (t) async {
    await pumpGallery(t, section: 'buttons');
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    // Focus the button through its own detector.
    final detector = find.descendant(of: find.byKey(const Key('g-button-primary-md')), matching: find.byType(FocusableActionDetector));
    Focus.of(t.element(find.descendant(of: detector, matching: find.byType(CustomPaint)).first)).requestFocus();
    await t.pump();
    expect(_rings(t).any((p) => p.visible), isTrue);

    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
    await t.pump();
    expect(_rings(t).where((p) => p.visible), isEmpty);
  });

  test('the ring paints a 6 px black band with the 2 px bone ring 2 px out', () {
    const p = CineFocusRingPainter(visible: true, round: false, ink: Color(0xFFF3F0E8));
    expect((p.width, p.offset, p.halo), (2.0, 2.0, 6.0));
    const off = CineFocusRingPainter(visible: false, round: true, ink: Color(0xFFF3F0E8));
    expect(off.shouldRepaint(p), isTrue);
  });
}
