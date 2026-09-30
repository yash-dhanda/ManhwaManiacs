// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../skins/cinematic/reader/reader_test_support.dart';
import 'support/series_shots.dart';
import 'support/shot_covers.dart';
import 'support/shot_network.dart';
import 'support/skin_shots.dart';

/// The mobile-12 proof shots: the Cinematic manga reader at `kSkinShotSizes`, with invented
/// fixtures only (procedural page art, never a source's pages).
void mobile12Shots() {
  Future<void> addPages(WidgetTester tester, {String chapter = 'c2', int pages = 6}) async {
    final png = await tester.runAsync(() async => {
          for (final c in ['c1', 'c2', 'c3'])
            for (var n = 1; n <= pages; n++)
              '/reader/page/$c-$n/image': await ShotCoverArt(title: 'Tower of Dawn', seed: n + (c == chapter ? 0 : 3)).toPng(width: 400, height: 1200),
        });
    addShotCovers(png!);
  }

  Future<void> show(
    WidgetTester tester,
    String name, {
    bool phone = true,
    bool tablet = true,
    Future<void> Function(WidgetTester tester, bool wide)? prepare,
    Future<void> Function(WidgetTester tester, ReaderRig rig)? act,
    bool reduced = false,
    Map<String, Object> prefs = const {},
  }) async {
    for (final (size, wide, on) in [
      (kSkinShotSizes[0], false, phone),
      (kSkinShotSizes[1], true, tablet),
    ]) {
      if (!on) continue;
      await addPages(tester);
      final rig = await pumpReader(tester, wide: wide, reduced: reduced, prefsValues: prefs);
      await pumpUntilCoversLoad(tester, rounds: 12);
      await settleReader(tester, ms: 800);
      if (act != null) await act(tester, rig);
      await captureSeriesShot(tester, name, size);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 11));
    }
  }

  testWidgets('mobile-12 reader chrome', (tester) async {
    await show(tester, 'reader-chrome');
  });
}
