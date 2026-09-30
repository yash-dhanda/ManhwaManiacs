// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';

import 'listen_test_support.dart';

/// Every pressable inside [root] is at least [min] in both directions.
void expectTargets(WidgetTester tester, Finder root, double min, String where) {
  final pressables = find.descendant(of: root, matching: find.byType(CinePressable));
  expect(pressables, findsWidgets, reason: where);
  for (var i = 0; i < pressables.evaluate().length; i++) {
    final f = pressables.at(i);
    final size = tester.getSize(f);
    expect(size.width >= min - 0.01 && size.height >= min - 0.01, isTrue, reason: '$where: pressable #$i is ${size.width} x ${size.height}, under $min');
  }
}

void main() {
  for (final (platform, min) in [(TargetPlatform.android, 48.0), (TargetPlatform.iOS, 44.0)]) {
    testWidgets('the mini player and the reading room meet $min on $platform', (tester) async {
      final l = await pumpListen(tester, platform: platform, size: const Size(390, 1400));
      await settleNovel(tester, ms: 800);
      await tester.tap(find.byKey(const Key('opener-listen')));
      await l.settle();
      expectTargets(tester, find.byKey(const Key('mini-player')), min, 'mini player');
      await tester.tap(find.bySemanticsLabel(RegExp('Open the reading room')));
      await settleNovel(tester, ms: 700);
      expectTargets(tester, find.byKey(const Key('room-play')).evaluate().isEmpty ? find.byType(Scaffold) : find.ancestor(of: find.byKey(const Key('room-play')), matching: find.byType(Stack)).first, min, 'reading room');
      await leaveListen(l);
    });

    testWidgets('the sheets meet $min on $platform: cast, voice picker with Hear and Cast, sleep, audiobook', (tester) async {
      final l = await pumpListen(tester, platform: platform, size: const Size(390, 1400));
      await settleNovel(tester, ms: 800);
      await tester.tap(find.byKey(const Key('opener-listen')));
      await l.settle();
      await tester.tap(find.bySemanticsLabel(RegExp('Open the reading room')));
      await settleNovel(tester, ms: 700);

      await tester.tap(find.byKey(const Key('tile-voices')));
      await settleNovel(tester, ms: 700);
      expectTargets(tester, find.byType(Overlay).last, min, 'cast sheet');
      await tester.tap(find.text('Narrator'));
      await settleNovel(tester, ms: 700);
      expect(find.text('Hear'), findsWidgets);
      expect(find.text('Cast'), findsWidgets);
      expectTargets(tester, find.byType(Overlay).last, min, 'voice picker');
      await leaveListen(l);
    });
  }
}
