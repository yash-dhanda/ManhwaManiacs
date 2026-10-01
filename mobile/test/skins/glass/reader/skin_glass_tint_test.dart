import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/glass/rim_painter.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

Widget _host(Widget child, {List<Override> overrides = const []}) => ProviderScope(
      overrides: overrides,
      child: MediaQuery(
        data: const MediaQueryData(size: Size(390, 844), devicePixelRatio: 3),
        child: Directionality(textDirection: TextDirection.ltr, child: SkinGlassRoot(child: Center(child: child))),
      ),
    );

Color _fill(WidgetTester tester) => tester
    .widget<ColoredBox>(find.descendant(of: find.byType(BackdropFilter), matching: find.byType(ColoredBox)).first)
    .color;

void main() {
  testWidgets('tint folds an 18 % layer into the fill; a surface without it is unchanged', (tester) async {
    await tester.pumpWidget(_host(const SkinGlass(size: Size(100, 50), materialize: false, child: SizedBox())));
    await tester.pumpAndSettle();
    final plain = _fill(tester);
    await tester.pumpWidget(_host(const SkinGlass(size: Size(100, 50), materialize: false, tint: Color(0xFFCC2020), child: SizedBox())));
    await tester.pumpAndSettle();
    final tinted = _fill(tester);
    expect(tinted, isNot(plain));
    expect(tinted.r, greaterThan(plain.r), reason: 'a red tint warms the fill');
    await tester.pumpWidget(_host(const SkinGlass(size: Size(100, 50), materialize: false, child: SizedBox())));
    await tester.pumpAndSettle();
    expect(_fill(tester), plain);
  });

  testWidgets('solid path: the fill stays solid and only the rim keeps the tint', (tester) async {
    final solid = glassA11yProvider.overrideWith((ref) => const GlassA11y(solid: true));
    await tester.pumpWidget(_host(
      const SkinGlass(size: Size(100, 50), materialize: false, tint: Color(0xFF3A4A80), rimTint: Color(0xFFC8D0F0), child: SizedBox()),
      overrides: [solid],
    ),);
    await tester.pump();
    expect(find.byWidgetPredicate((w) => w is ColoredBox && w.color == const Color(0xFF1C1C22)), findsOneWidget);
    final rims = tester.widgetList<CustomPaint>(find.byType(CustomPaint)).map((c) => c.painter).whereType<GlassRimPainter>();
    expect(rims.any((p) => p.rimTint == const Color(0xFFC8D0F0)), isTrue);

    // Without the reader tint the solid path keeps dropping the rim tint, as before.
    await tester.pumpWidget(_host(
      const SkinGlass(size: Size(100, 50), materialize: false, rimTint: Color(0xFFC8D0F0), child: SizedBox()),
      overrides: [solid],
    ),);
    await tester.pump();
    final rims2 = tester.widgetList<CustomPaint>(find.byType(CustomPaint)).map((c) => c.painter).whereType<GlassRimPainter>();
    expect(rims2.every((p) => p.rimTint == null), isTrue);
  });
}
