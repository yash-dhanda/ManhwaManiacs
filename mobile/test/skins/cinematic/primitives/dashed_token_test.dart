import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/dashed_token.dart';

import 'cine_harness.dart';

void main() {
  double opacity(WidgetTester t) => t.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;
  double painted(WidgetTester t) => t.widget<FadeTransition>(find.descendant(of: find.byType(AnimatedOpacity), matching: find.byType(FadeTransition)).first).opacity.value;

  testWidgets('reject fades the token over 160 ms, then removes it', (t) async {
    var rejected = 0;
    await pumpCine(t, Center(child: DashedToken(label: 'rivals', onReject: () => rejected++)));
    await t.tap(find.byTooltip('Reject tag rivals'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 80));
    expect(find.text('RIVALS'), findsOneWidget);
    expect(opacity(t), 0);
    expect(painted(t), inExclusiveRange(0, 1));
    expect(rejected, 0);
    await t.pump(const Duration(milliseconds: 120));
    expect(find.text('RIVALS'), findsNothing);
    expect(rejected, 1);
  });

  testWidgets('reduced motion removes a rejected token at once', (t) async {
    var rejected = 0;
    await pumpCine(t, Center(child: DashedToken(label: 'rivals', onReject: () => rejected++)), reduced: true);
    await t.tap(find.byTooltip('Reject tag rivals'));
    await t.pump();
    expect(find.text('RIVALS'), findsNothing);
    expect(rejected, 1);
  });
}
