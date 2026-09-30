// ignore_for_file: unawaited_futures
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/glass/dev/gallery_sections.dart';
import 'package:manhwamaniacs/skins/glass/dev/lists_sections.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/test_overrides.dart';
import 'support.dart';

Future<void> _pumpSection(WidgetTester tester, String name, TargetPlatform platform) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(390 * 3, 9000 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    primHost(
      GlassBudgetScope(exempt: true, label: 'gallery', child: SingleChildScrollView(child: SizedBox(width: 390, child: GlassGallerySection(name: name)))),
      platform: platform,
      align: false,
      overrides: [sharedPrefsProvider.overrideWithValue(prefs), authenticatedAuthOverride(), activeProfileOverride()],
    ),
  );
  await pumpFor(tester, 1200);
}

void main() {
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    for (final name in kGlassListsSections) {
      testWidgets('$name on ${platform.name}: tap targets and labels at 390 x 844', (tester) async {
        final handle = tester.ensureSemantics();
        await _pumpSection(tester, name, platform);
        expect(tester.takeException(), isNull);
        await expectLater(tester, meetsGuideline(platform == TargetPlatform.iOS ? iOSTapTargetGuideline : androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    }
  }

  testWidgets('every new section is reachable from a hardware keyboard: Tab moves through more than one stop and never throws', (tester) async {
    for (final name in ['lists', 'swipe', 'reorder', 'download', 'gate', 'reactions', 'charts']) {
      await tester.pumpWidget(const SizedBox.shrink());
      await _pumpSection(tester, name, TargetPlatform.iOS);
      final seen = <FocusNode?>{};
      for (var i = 0; i < 8; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump(const Duration(milliseconds: 16));
        seen.add(FocusManager.instance.primaryFocus);
      }
      expect(seen.length, greaterThan(1), reason: '$name has focusable stops');
      expect(tester.takeException(), isNull);
    }
  });
}
