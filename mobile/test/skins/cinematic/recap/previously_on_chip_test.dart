import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart' show RecapAvailability;
import 'package:manhwamaniacs/features/recap/providers/recap_providers.dart';
import 'package:manhwamaniacs/features/recap/recap_setting.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/previously_on_chip.dart';

import '../discover/harness.dart';
import 'recap_test_support.dart';

class _Setting extends RecapSettingNotifier {
  _Setting(this.value);
  final RecapSetting value;
  @override
  RecapSetting build() => value;
}

final _now = DateTime(2026, 9, 30, 12);

Future<FakeRecapRepository> pumpChip(WidgetTester tester, {required RecapSetting setting, required int daysAgo, RecapAvailability? avail}) async {
  final repo = FakeRecapRepository(availability: avail ?? const RecapAvailability(available: true, estSeconds: 100));
  await pumpScreen(
    tester,
    Scaffold(body: PreviouslyOnChip(sourceId: 's', seriesKey: 'k', chapterKey: 'c', lastReadAt: _now.subtract(Duration(days: daysAgo)))),
    extra: [clockProvider.overrideWithValue(() => _now), recapSettingProvider.overrideWith(() => _Setting(setting)), recapRepositoryProvider.overrideWithValue(repo)],
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return repo;
}

void main() {
  testWidgets('shows PREVIOUSLY ON · N MIN after the gap, and opens the recap with origin reader', (tester) async {
    final h = tester.ensureSemantics();
    await pumpChip(tester, setting: const RecapSetting(), daysAgo: 8);
    expect(find.text('PREVIOUSLY ON · 2 MIN'), findsOneWidget);
    expect(find.bySemanticsLabel('Previously on, 2 minutes'), findsWidgets);
    await tester.tap(find.byKey(const Key('previously-on-chip')));
    await tester.pumpAndSettle();
    expect(find.textContaining('at /recap/s/k?to=c'), findsOneWidget);
    h.dispose();
  });

  testWidgets('hidden under the gap, under NEVER and ALWAYS below 14 days, and when unavailable', (tester) async {
    for (final c in [
      (const RecapSetting(), 3, null),
      (const RecapSetting(mode: RecapMode.off), 10, null),
      (const RecapSetting(mode: RecapMode.always), 13, null),
      (const RecapSetting(), 30, const RecapAvailability(available: false)),
    ]) {
      await tester.pumpWidget(const SizedBox());
      final repo = await pumpChip(tester, setting: c.$1, daysAgo: c.$2, avail: c.$3);
      expect(find.byKey(const Key('previously-on-chip')), findsNothing, reason: '$c');
      if (c.$3 == null) expect(repo.events.hasListener, isFalse);
    }
  });

  testWidgets('ALWAYS and NEVER show it from 14 days', (tester) async {
    await pumpChip(tester, setting: const RecapSetting(mode: RecapMode.off), daysAgo: 14);
    expect(find.byKey(const Key('previously-on-chip')), findsOneWidget);
  });
}
