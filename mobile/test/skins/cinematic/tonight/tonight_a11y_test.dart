// ignore_for_file: require_trailing_commas, directives_ordering, avoid_redundant_argument_values
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/home/providers/home_feed_provider.dart';

import 'tonight_test_support.dart';

const _stamp = {'mm.tonight.typed.u1p1': '{"date":"2026-09-30","variant":"normal"}'};

HomeFeedView _offline() {
  final f = HomeFeed.fromJson({'headline': 'Offline edition.', 'deck': "Only what's saved on this device is here."}).copyWith(sections: [
    const HomeSection(type: HomeSectionType.saved, title: 'Saved on this device', items: [HomeSavedItem(sourceId: 'shelf', seriesKey: 'iron-kite', title: 'Iron Kite', chapters: 3)]),
  ]);
  return viewOf(f, origin: HomeFeedOrigin.offline, offline: true);
}

void main() {
  for (final (name, feed, view) in <(String, String?, HomeFeedView?)>[('ready', 'ready', null), ('ai-unavailable', 'ai-unavailable', null), ('offline', null, _offline())]) {
    testWidgets('$name: iOS and Android tap targets, labeled targets', (t) async {
      final handle = t.ensureSemantics();
      await pumpTonight(t, feed: feed, view: view, platform: TargetPlatform.iOS, size: const Size(390, 3000), prefs: _stamp);
      await settleTonight(t, by: const Duration(seconds: 1));
      await expectLater(t, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
      await t.pumpWidget(const SizedBox());
      await pumpTonight(t, feed: feed, view: view, platform: TargetPlatform.android, size: const Size(390, 3000), prefs: _stamp);
      await settleTonight(t, by: const Duration(seconds: 1));
      await expectLater(t, meetsGuideline(androidTapTargetGuideline));
      await t.pumpWidget(const SizedBox());
      handle.dispose();
    });
  }
}
