// ignore_for_file: directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/features/library/models/reading_history_item.dart';
import 'package:manhwamaniacs/features/library/providers/intelligence_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_switch.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/sections/circle_section.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_kit.dart' show JumpRow;

import '../../../features/circle/fakes.dart';
import '../downloads/downloads_rig.dart' show settle;
import 'settings_rig.dart';

Future<ProviderContainer> _pump(WidgetTester t, FakeCircleRepository repo, {bool gate = false, List<ReadingHistoryItem> history = const []}) => pumpSettings(
      t,
      path: '/settings/circle',
      more: [
        circleRepositoryProvider.overrideWithValue(repo),
        matureGateOpenProvider.overrideWithValue(gate),
        readingHistoryProvider.overrideWith((ref) async => history),
      ],
    );

ReadingHistoryItem _row({bool done = true}) => ReadingHistoryItem(id: 1, sourceId: 's', seriesKey: 'or', chapterKey: 'c142', chapterNumber: 142, lastPage: 10, pageCount: 10, isCompleted: done, seriesTitle: 'Omniscient Reader');

Finder _switchIn(String rowId) => find.descendant(of: find.byWidgetPredicate((w) => w is JumpRow && w.id == rowId), matching: find.byType(CineSwitch));

void main() {
  testWidgets('every row of the section, the 18+ row only with the gate open', (t) async {
    final repo = FakeCircleRepository(sharingValue: const Sharing(activity: true));
    await _pump(t, repo);
    for (final l in ["Share what I'm reading", 'Show my reactions', 'Let others add me to shared shelves', 'Receive recommendations', 'Hide this series from my activity', 'Clear my shared activity']) {
      expect(find.text(l), findsWidgets, reason: l);
    }
    expect(find.text('Include 18+ titles in my activity'), findsNothing);
    await t.pumpWidget(const SizedBox());
    await _pump(t, repo, gate: true);
    expect(find.text('Include 18+ titles in my activity'), findsOneWidget);
  });

  testWidgets('the master disables the next four and captions them', (t) async {
    await _pump(t, FakeCircleRepository(sharingValue: const Sharing()), gate: true);
    expect(find.text('Turn on sharing first.'), findsNWidgets(4));
  });

  testWidgets('PATCH bodies carry only changed keys, never presence or streak', (t) async {
    final repo = FakeCircleRepository(sharingValue: const Sharing(activity: true));
    await _pump(t, repo);
    await t.tap(_switchIn('share-reactions'));
    await settle(t, ms: 600);
    await t.tap(_switchIn('share-recommendations'));
    await settle(t, ms: 600);
    expect(repo.patches, [
      {'reactions': false},
      {'recommendations': false},
    ]);
    for (final p in repo.patches) {
      expect(p.keys, isNot(contains('show_presence')));
      expect(p.keys, isNot(contains('share_streak')));
    }
  });

  testWidgets('a refused save reverts the switch and says so', (t) async {
    final repo = FakeCircleRepository(sharingValue: const Sharing(activity: true))..failSharing = const NetworkError(message: 'x');
    await _pump(t, repo);
    await t.tap(_switchIn('share-reactions'));
    await settle(t, ms: 600);
    expect(find.text("Couldn't save. Try again."), findsWidgets);
  });

  testWidgets('hidden series: the whole list is sent on Remove', (t) async {
    final repo = FakeCircleRepository(sharingValue: const Sharing(activity: true, excludedSeries: [ExcludedSeries(sourceId: 's', seriesKey: 'a', title: 'Alpha'), ExcludedSeries(sourceId: 's', seriesKey: 'b', title: 'Beta')]));
    await _pump(t, repo);
    expect(find.text('Alpha'), findsWidgets);
    await t.tap(find.text('Remove').first);
    await settle(t, ms: 600);
    expect(repo.patches.single['excluded_series'], [
      {'source_id': 's', 'series_key': 'b'},
    ]);
  });

  testWidgets('Clear my shared activity arms for 1000 ms, then clears and toasts', (t) async {
    final repo = FakeCircleRepository(sharingValue: const Sharing(activity: true));
    final container = await _pump(t, repo);
    await t.ensureVisible(find.text('Clear my shared activity').last);
    await t.tap(find.text('Clear my shared activity').last);
    await settle(t, ms: 400);
    expect(find.textContaining("Clear everything you've shared?"), findsOneWidget);
    await t.tap(find.text('Clear').last);
    await settle(t, ms: 100);
    expect(repo.log, isNot(contains('clearActivity')));
    await settle(t, ms: 1200);
    await t.tap(find.text('Clear').last);
    await settle(t, ms: 600);
    expect(repo.log, contains('clearActivity'));
    expect(container.read(cineToastsProvider).map((x) => x.text), contains('Cleared your shared activity.'));
  });

  group('the preview line', () {
    test('three forms', () {
      String text(List<dynamic> runs) => runs.map((r) => r.text as String).join();
      expect(text(circlePreviewRuns(sharing: true, name: 'Yash', latest: _row())), 'Others see: Yash finished chapter 142 of Omniscient Reader.');
      expect(text(circlePreviewRuns(sharing: true, name: 'Yash', latest: _row(done: false))), 'Others see: Yash started Omniscient Reader.');
      expect(text(circlePreviewRuns(sharing: false, name: 'Yash', latest: _row())), "Others see nothing. You're reading privately.");
      expect(text(circlePreviewRuns(sharing: true, name: 'Yash')), 'Others see nothing yet. Read a chapter and it appears here.');
    });

    testWidgets('is typed on the screen', (t) async {
      await _pump(t, FakeCircleRepository(sharingValue: const Sharing(activity: true)), history: [_row()]);
      await settle(t, ms: 3500);
      expect(find.bySemanticsLabel('Others see: Tester finished chapter 142 of Omniscient Reader.'), findsOneWidget);
    });
  });
}
