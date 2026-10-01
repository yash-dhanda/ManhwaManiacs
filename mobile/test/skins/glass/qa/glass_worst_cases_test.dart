// ignore_for_file: require_trailing_commas, avoid_redundant_argument_values, prefer_const_declarations, directives_ordering, prefer_function_declarations_over_variables
// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/glass/tier_math.dart' show foldDim;
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

import '../primitives/support.dart';

/// mobile/45 C3: the three worst glass cases of 2.1.7 in widgets (the contrast gate asserts the same three in `design/check-contrast.mjs`).
/// Where the prompt and glass/DESIGN.md disagree DESIGN.md wins: the legibility dim is `clamp(0.22 + 0.42 x Lb, floor, ceiling)`, so a
/// white backdrop (Lb 1.0) is 0.64 in both modes, and Increase Contrast raises the FLOOR to 0.40 and the CEILING to 0.72 (qa.md, open issues).
void main() {
  final frostFill = find.descendant(of: find.byType(BackdropFilter), matching: find.byType(ColoredBox));

  Future<void> pumpGlass(WidgetTester t, {required double lb, List<Override> overrides = const [], Widget? child}) async {
    await t.pumpWidget(primHost(
      Container(color: Colors.white, child: Center(child: SkinGlass(size: const Size(120, 44), materialize: false, lb: lb, child: child ?? const SizedBox()))),
      overrides: overrides,
    ));
    await t.pump();
  }

  testWidgets('the reader top group over a white page (Lb 1.0) settles at dim 0.64 and GRAD 40', (t) async {
    await pumpGlass(t, lb: 1.0, child: Builder(builder: (c) {
      final axes = GlassTextAxes.of(c);
      return Text('grad ${axes?.grad}');
    },),);
    expect(dimFor(1.0), closeTo(0.64, 1e-9));
    expect(gradFor(1.0), 40);
    expect(t.widget<ColoredBox>(frostFill).color.a, closeTo(foldDim(glassTokens.glassT3.fill, 0.64).a, 0.02));
    expect(find.text('grad 40'), findsOneWidget);
  });

  testWidgets('under Increase Contrast (the in-app switch) the dim floor is 0.40 and the ceiling 0.72; Lb 1.0 stays at 0.64 by the formula', (t) async {
    await pumpGlass(t, lb: 0, overrides: [glassA11yProvider.overrideWith((ref) => const GlassA11y(increaseContrast: true))]);
    expect(t.widget<ColoredBox>(frostFill).color.a, closeTo(foldDim(glassTokens.glassT3.fill, 0.40).a, 0.02), reason: 'the floor');
    expect(dimFor(0, highContrast: true), 0.40);
    expect(glassTokens.dimMaxHc, 0.72);
    expect(dimFor(1.0, highContrast: true), closeTo(0.64, 1e-9));
    for (var lb = 0.0; lb <= 1.0; lb += 0.1) {
      expect(dimFor(lb, highContrast: true), inInclusiveRange(0.40, 0.72));
    }
  });

  testWidgets('the dock over a list of white covers: the bar sits under the 0.72 plateau and its dim stays in 0.22 to 0.64', (t) async {
    expect(GlassColors.coverDisc, const Color(0xB8000000)); // the 0.72 black the edgeSoft plateau also uses (scroll_edge_test asserts the plateau itself)
    for (var lb = 0.0; lb <= 1.0; lb += 0.05) {
      expect(dimFor(lb), inInclusiveRange(0.22, 0.64));
    }
    expect(glassTokens.dimEdgePlateau, 0.72);
  });

  testWidgets('the tinted action keeps its label at onTint #FFFFFF over a white page', (t) async {
    await t.pumpWidget(primHost(Container(color: Colors.white, child: Center(child: GlassButton(label: 'Start reading', variant: GlassButtonVariant.primary, onPressed: () {})))));
    await t.pump(const Duration(milliseconds: 300));
    final rich = t.widget<RichText>(find.descendant(of: find.byType(GlassButton), matching: find.byType(RichText)).first);
    expect(rich.text.style?.color ?? (rich.text as TextSpan).children?.first.style?.color, GlassColors.onTint);
    expect(GlassColors.onTint, const Color(0xFFFFFFFF));
  });
}
