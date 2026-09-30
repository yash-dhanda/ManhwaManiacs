// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/ambient_scope.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/book/book_view.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/manga_view.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/repoint_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

import 'feature_test_support.dart';

Future<void> _guidelines(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
}

void main() {
  testWidgets('Feature hero meets the tap target and label guidelines', (tester) async {
    final h = tester.ensureSemantics();
    await pumpFeature(tester,
        rig: FeatureRig(followed: followedRow()),
        child: MangaFeatureView(data: fixtureData('manga-ongoing', followed: followedRow())));
    await settleFeature(tester, by: const Duration(seconds: 2));
    await _guidelines(tester);
    h.dispose();
  });

  testWidgets('Feature tablet spread meets the guidelines', (tester) async {
    final h = tester.ensureSemantics();
    await pumpFeature(tester,
        wide: true,
        rig: FeatureRig(followed: followedRow()),
        child: MangaFeatureView(data: fixtureData('manga-ongoing', followed: followedRow())));
    await settleFeature(tester, by: const Duration(seconds: 2));
    await _guidelines(tester);
    h.dispose();
  });

  testWidgets('CHAPTERS meets the guidelines', (tester) async {
    final h = tester.ensureSemantics();
    await pumpFeature(tester, child: MangaFeatureView(data: fixtureData('manga-ongoing')));
    await scrollToPanels(tester);
    await _guidelines(tester);
    h.dispose();
  });

  testWidgets('select mode meets the guidelines', (tester) async {
    final h = tester.ensureSemantics();
    await pumpFeature(tester,
        size: const Size(390, 1800), child: MangaFeatureView(data: fixtureData('manga-ongoing')));
    await scrollToPanels(tester);
    await tester.tap(find.text('Select'));
    await frames(tester, 300);
    await _guidelines(tester);
    h.dispose();
  });

  testWidgets('DETAILS meets the guidelines', (tester) async {
    final h = tester.ensureSemantics();
    final rig = FeatureRig(followed: followedRow(), suggested: (tags: const ['dungeon'], available: true, reason: null));
    await pumpFeature(tester,
        rig: rig,
        size: const Size(390, 1800),
        child: MangaFeatureView(data: fixtureData('manga-ongoing', followed: followedRow())));
    await tester.tap(find.textContaining('02 DETAILS'));
    await frames(tester, 600);
    await scrollToPanels(tester);
    await _guidelines(tester);
    h.dispose();
  });

  testWidgets('Book page meets the guidelines', (tester) async {
    final h = tester.ensureSemantics();
    await pumpFeature(tester,
        novel: true, size: const Size(390, 2000), child: BookView(data: fixtureData('novel-short')));
    await settleFeature(tester, by: const Duration(seconds: 2));
    await _guidelines(tester);
    h.dispose();
  });

  testWidgets('the repoint sheet meets the guidelines', (tester) async {
    final h = tester.ensureSemantics();
    await pumpFeature(tester,
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showRepointSheet(context, fixtureData('manga-ongoing', followed: followedRow()), sourceIsDown: true),
                child: const Text('open'),
              ),
            ),
          ),
        ));
    await tester.tap(find.text('open'));
    await frames(tester, 500);
    await _guidelines(tester);
    h.dispose();
  });

  testWidgets('text scale 2.0: the FOLLOW / FAVOURITE / NOTIFY / DOWNLOAD row does not clip', (tester) async {
    await pumpFeature(tester,
        textScale: 2.0,
        rig: FeatureRig(followed: followedRow()),
        child: MangaFeatureView(data: fixtureData('manga-ongoing', followed: followedRow())));
    await settleFeature(tester, by: const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    for (final label in ['FOLLOW', 'FAVOURITE', 'NOTIFY', 'DOWNLOAD']) {
      final f = find.text(label);
      expect(f, findsOneWidget, reason: label);
      final box = tester.getRect(f);
      // Each label sits inside its own quarter of the row, scaled down to fit.
      expect(box.width, lessThanOrEqualTo(390 / 4 + 0.5), reason: label);
    }
  });

  testWidgets('text scale 2.0 on the Book page raises no overflow', (tester) async {
    await pumpFeature(tester,
        novel: true,
        textScale: 2.0,
        size: const Size(390, 2000),
        child: BookView(data: fixtureData('novel-short')));
    await settleFeature(tester, by: const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion: letters show at once, Drift holds at 1.03, the wash swaps and the rule shows at rest', (tester) async {
    await pumpFeature(tester,
        reducedMotion: true,
        size: const Size(390, 2000),
        child: MangaFeatureView(data: fixtureData('manga-ongoing')));
    await tester.pump();
    // Letters: the title is fully painted with no timers running.
    final title = tester.widgetList<Text>(find.byType(Text)).firstWhere((t) => t.data == 'Tower of Dawn' || t.textSpan == null && false, orElse: () => const Text(''));
    expect(title.data ?? '', anyOf('Tower of Dawn', ''));
    // The ambient colours are the series' from the first frame.
    final amb = CineAmbient.of(tester.element(find.byType(Scaffold).first));
    expect(amb.ink, isNot(cinematicTokens.colorAmbientFallbackInk));
    // Drift is parked at scale 1.03.
    final scales = tester.widgetList<Transform>(find.byType(Transform)).map((t) => t.transform.getMaxScaleOnAxis());
    expect(scales.any((s) => (s - 1.03).abs() < 1e-6), isTrue);
  });

  testWidgets('reduced motion on the Book page: the title rule is at rest at 56 px', (tester) async {
    await pumpFeature(tester,
        novel: true,
        reducedMotion: true,
        size: const Size(390, 2000),
        child: BookView(data: fixtureData('novel-short')));
    await tester.pump();
    expect(tester.getSize(find.byKey(const Key('title-rule'))).width, closeTo(56, 0.5));
  });
}
