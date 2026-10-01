import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/switch.dart';

import '../../../screenshots/support/shot_harness.dart';
import 'circle_rig.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('keys: j moves to the next row, r refreshes, f opens the focused row\'s friend', (t) async {
    final repo = circleFake();
    final rig = await pumpCircle(t, repo);
    focusRow(t, 'a3');
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.keyJ);
    await t.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, isNot('activity a3'));
    expect(FocusManager.instance.primaryFocus?.debugLabel, startsWith('activity '));
    final feeds = repo.log.where((l) => l.startsWith('feed')).length;
    await t.sendKeyEvent(LogicalKeyboardKey.keyR);
    await settle(t, 400);
    expect(repo.log.where((l) => l.startsWith('feed')).length, greaterThan(feeds));
    focusRow(t, 'a3');
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.keyF);
    await settle(t, 600);
    expect(rig.at, '/circle/2');
    await unmount(t);
  });

  testWidgets('hit targets on Circle at 390 x 844 meet the Android guideline', (t) async {
    final h = t.ensureSemantics();
    await pumpCircle(t, circleFake());
    await expectLater(t, meetsGuideline(androidTapTargetGuideline));
    h.dispose();
    await unmount(t);
  });

  testWidgets('Circle and privacy: show_presence and share_streak each patch only their field', (t) async {
    final repo = circleFake();
    await pumpCircle(t, repo, start: '/settings/circle');
    await settle(t);
    Future<void> flip(String title) async {
      final sw = find.byWidgetPredicate((w) => w is GlassSwitch && w.label == title);
      await t.scrollUntilVisible(sw, 200, scrollable: find.byType(Scrollable).first);
      await t.tap(sw);
      await settle(t, 600);
    }

    await flip('Show me in presence');
    expect(repo.patches.last, {'show_presence': true});
    await flip('Share my streak');
    expect(repo.patches.last, {'share_streak': true});
    await unmount(t);
  });

  testWidgets('Clear my activity asks, then sends DELETE /circle/activity', (t) async {
    final repo = circleFake();
    await pumpCircle(t, repo, start: '/settings/circle');
    await settle(t);
    final clear = find.text('Clear my activity');
    await t.scrollUntilVisible(clear, 200, scrollable: find.byType(Scrollable).first);
    await t.ensureVisible(clear);
    await t.pump();
    await t.tap(clear);
    await settle(t, 600);
    expect(find.text("Remove everything you've shared so far?"), findsOneWidget);
    await t.tap(find.text('Clear'));
    await settle(t, 600);
    expect(repo.log, contains('clearActivity'));
    await unmount(t);
  });
}
