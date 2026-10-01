import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/chapter_seam.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/side_panels.dart';

import '../primitives/support.dart';

void main() {
  testWidgets("the desktop reader's right panel has a Circle tab when given its body", (t) async {
    await t.pumpWidget(primHost(
      SizedBox(width: 360, height: 700, child: ReaderRightPanel(tab: RightPanelTab.circle, onTab: (_) {}, settings: const SizedBox(), pageText: null, circle: const Text('circle body'))),
    ),);
    await pumpFor(t, 300);
    expect(find.text('Circle'), findsOneWidget);
    expect(find.text('circle body'), findsOneWidget);
    await t.pumpWidget(const SizedBox.shrink());
    await t.pumpWidget(primHost(
      SizedBox(width: 360, height: 700, child: ReaderRightPanel(tab: RightPanelTab.circle, onTab: (_) {}, settings: const Text('settings body'), pageText: null)),
    ),);
    await pumpFor(t, 300);
    expect(find.text('Circle'), findsNothing);
    expect(find.text('settings body'), findsOneWidget);
  });

  testWidgets("the manga end card carries the finished chapter's reactions", (t) async {
    await t.pumpWidget(primHost(CaughtUpCard(nextNumber: '153', inLibrary: true, onFollow: () {}, reactions: const Text('reactions slot'))));
    await pumpFor(t, 300);
    expect(find.text('reactions slot'), findsOneWidget);
    expect(find.text("You're caught up"), findsOneWidget);
  });
}
