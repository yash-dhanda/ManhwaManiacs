import 'package:flutter_test/flutter_test.dart';

import '../../../screenshots/support/shot_harness.dart';
import 'auth_rig.dart';
import 'auth_screens.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('reduced motion: Login shows its heading at once, with no caret', (t) async {
    await authCases.firstWhere((c) => c.name == 'login').pump(t, reduced: true);
    await t.pump(const Duration(milliseconds: 50));
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('reduced motion: the picker shows its orbs at once and does not drift', (t) async {
    await authCases.firstWhere((c) => c.name == 'picker').pump(t, reduced: true);
    await settleFor(t, 700);
    expect(find.text('Yash'), findsOneWidget);
    final a = t.getTopLeft(find.text('Yash'));
    await settleFor(t, 2000);
    expect(t.getTopLeft(find.text('Yash')), a);
  });

  testWidgets('reduced motion: onboarding step 1 shows its text at once', (t) async {
    await authCases.firstWhere((c) => c.name == 'onboarding-1').pump(t, reduced: true);
    await settleFor(t, 400);
    expect(find.text('Hi, Yash.'), findsOneWidget);
  });
}
