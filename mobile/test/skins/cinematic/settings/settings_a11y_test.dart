// ignore_for_file: directives_ordering, unawaited_futures, avoid_dynamic_calls, library_private_types_in_public_api, inference_failure_on_collection_literal
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_registry.dart';

import 'settings_rig.dart';

const _slugs = [
  'profile', 'appearance', 'reading-manga', 'reading-novels', 'listen', 'ambient', 'storage', 'content', 'circle', 'feedback', 'notifications', 'server', 'admin', 'diagnostics', 'about',
  'security', 'members', 'backup',
];

void main() {
  for (final slug in _slugs) {
    testWidgets('$slug: tap targets, labels and contrast on Android', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpSettings(tester, path: '/settings/$slug');
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('$slug: tap targets on iOS', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpSettings(tester, path: '/settings/$slug', platform: TargetPlatform.iOS);
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      handle.dispose();
    });
  }

  testWidgets('the contents list and the two panes meet the same guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpSettings(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await tester.pumpWidget(const SizedBox());
    await pumpSettings(tester, size: const Size(1024, 1366));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  test('every registered slug has a test', () {
    expect(registeredSlugs.where((s) => s != 'keyboard').toSet(), _slugs.toSet());
  });
}
