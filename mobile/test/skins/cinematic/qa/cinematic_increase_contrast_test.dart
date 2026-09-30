// ignore_for_file: directives_ordering, require_trailing_commas, prefer_const_constructors, avoid_redundant_argument_values, unnecessary_lambdas, unnecessary_await_in_return
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

import 'qa_screens.dart';

/// C4 (14.4, 14.7): with Increase Contrast the skin root applies `ink.45` -> `ink.80` and
/// `rule.1` -> `rule.2`: on Tonight, Library and Settings no paragraph is `ink.45` and no box
/// paints `rule.1`.
void main() {
  for (final id in const [ScreenId.tonight, ScreenId.library, ScreenId.settings]) {
    testWidgets('increase contrast: ${id.id} has no ink.45 text and no rule.1', (t) async {
      t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(highContrast: true);
      addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final rig = await pumpQaScreen(t, kQaScreens.firstWhere((s) => s.id == id));
      final ink45 = <String>[];
      for (final e in find.byType(RichText).evaluate()) {
        final w = e.widget as RichText;
        w.text.visitChildren((sp) {
          if (sp is TextSpan && sp.text != null && sp.text!.trim().isNotEmpty && sp.style?.color?.toARGB32() == CineColors.ink45.toARGB32()) ink45.add(sp.text!);
          return true;
        });
        final root = w.text;
        if (root is TextSpan && (root.text ?? '').trim().isNotEmpty && root.style?.color?.toARGB32() == CineColors.ink45.toARGB32()) ink45.add(root.text!);
      }
      expect(ink45, isEmpty, reason: 'ink.45 text under Increase Contrast: $ink45');
      final rule1s = <String>[];
      for (final e in find.byType(DecoratedBox).evaluate()) {
        final d = (e.widget as DecoratedBox).decoration;
        if (d is BoxDecoration) {
          final b = d.border;
          if (b is Border && [b.top, b.bottom, b.left, b.right].any((s) => s.style == BorderStyle.solid && s.width > 0 && s.color.toARGB32() == CineColors.rule1.toARGB32())) rule1s.add('DecoratedBox border ${e.debugGetCreatorChain(8)}');
        }
      }
      for (final e in find.byType(ColoredBox).evaluate()) {
        if ((e.widget as ColoredBox).color.toARGB32() == CineColors.rule1.toARGB32()) rule1s.add('ColoredBox ${e.debugGetCreatorChain(8)}');
      }
      expect(rule1s, isEmpty, reason: 'rule.1 painted under Increase Contrast');
      await disposeQa(t, rig);
    });
  }
}
