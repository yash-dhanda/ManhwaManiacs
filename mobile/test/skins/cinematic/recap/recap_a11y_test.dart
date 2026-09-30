import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/recap/models/recap_models.dart';

import '../discover/harness.dart';
import 'recap_test_support.dart';

Future<void> pumpDone(WidgetTester tester, {TargetPlatform platform = TargetPlatform.android, bool screenReader = true}) async {
  stubCovers();
  final repo = FakeRecapRepository();
  await pumpScreen(tester, recapScreen(screenReader: screenReader), extra: recapOverrides(repo), platform: platform);
  repo.script();
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('the recap meets the Android tap target, labelled target and contrast guidelines', (tester) async {
    final h = tester.ensureSemantics();
    await pumpDone(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    h.dispose();
  });

  testWidgets('the recap meets the iOS tap target guideline', (tester) async {
    final h = tester.ensureSemantics();
    await pumpDone(tester, platform: TargetPlatform.iOS);
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    h.dispose();
  });

  testWidgets('streamed text is one node when complete, excluded while streaming', (tester) async {
    final h = tester.ensureSemantics();
    final repo = FakeRecapRepository();
    await pumpScreen(tester, recapScreen(screenReader: true), extra: recapOverrides(repo));
    repo.events.add(const RecapMeta());
    repo.events.add(const RecapDelta('Once upon a time '));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.bySemanticsLabel(RegExp('Once upon a time')), findsNothing);
    repo.events.add(const RecapDone());
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.bySemanticsLabel(RegExp('Once upon a time')), findsOneWidget);
    h.dispose();
  });
}
