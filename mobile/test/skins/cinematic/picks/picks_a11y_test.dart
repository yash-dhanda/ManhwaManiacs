import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/ai/providers/suggested_tags_provider.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/picks/picks_screen.dart';

import '../discover/harness.dart';
import 'picks_test_support.dart';

Future<void> pumpA11y(WidgetTester tester, {TargetPlatform platform = TargetPlatform.android}) async {
  await pumpScreen(
    tester,
    const PicksScreen(),
    size: const Size(390, 2400),
    platform: platform,
    extra: [libraryRepositoryProvider.overrideWithValue(PicksLibrary()), aiRepositoryProvider.overrideWithValue(FakeAi())],
  );
  await settle(tester, 3000);
}

void main() {
  testWidgets('Picks meets the Android tap target, labelled target and contrast guidelines', (tester) async {
    final h = tester.ensureSemantics();
    await pumpA11y(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    h.dispose();
  });

  testWidgets('Picks meets the iOS tap target guideline', (tester) async {
    final h = tester.ensureSemantics();
    await pumpA11y(tester, platform: TargetPlatform.iOS);
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    h.dispose();
  });
}
