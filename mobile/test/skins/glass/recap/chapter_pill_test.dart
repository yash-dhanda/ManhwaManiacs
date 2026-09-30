import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/recap/providers/recap_providers.dart';
import 'package:manhwamaniacs/skins/glass/parts/recap/chapter_pill.dart';

import '../../../screenshots/support/shot_harness.dart';
import '../primitives/support.dart' show primHost;

void main() {
  setUpAll(loadAppFonts);

  testWidgets('the chapter pill reads Previously, leaves after 6 s and a swipe up dismisses it', (t) async {
    var gone = 0;
    await t.pumpWidget(primHost(RecapChapterPill(sourceId: 's', seriesKey: 'k', chapterKey: 'c', onGone: () => gone++), overrides: [recapAvailabilityProvider.overrideWith((ref, k) async => const RecapAvailability(available: true, estSeconds: 20))]));
    await t.pump(const Duration(milliseconds: 50));
    expect(find.text('Previously · 20 s'), findsOneWidget);
    await t.pump(const Duration(seconds: 6, milliseconds: 100));
    expect(gone, 1);
    expect(find.textContaining('Previously'), findsNothing);
  });

  testWidgets('a swipe up dismisses the pill', (t) async {
    var gone = 0;
    await t.pumpWidget(primHost(RecapChapterPill(sourceId: 's', seriesKey: 'k', chapterKey: 'c', onGone: () => gone++), overrides: [recapAvailabilityProvider.overrideWith((ref, k) async => const RecapAvailability(available: true))]));
    await t.pump(const Duration(milliseconds: 50));
    await t.drag(find.textContaining('Previously'), const Offset(0, -40));
    await t.pump(const Duration(milliseconds: 100));
    expect(gone, 1);
  });
}
