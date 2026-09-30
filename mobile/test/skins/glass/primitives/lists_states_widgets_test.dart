
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/list_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/swipe_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';

import 'support.dart';

List<String> ran = [];

SwipeAction _act(String id, String label, {bool destructive = false, SwipeTone tone = SwipeTone.neutral}) => SwipeAction(
      id: id,
      label: label,
      glyph: const IconData(0xE1FE, fontFamily: 'PhosphorRegular'),
      tone: tone,
      destructive: destructive,
      run: () async => ran.add(id),
      undo: () async => ran.add('undo-$id'),
    );

Widget _row() => GlassSwipeGroup(
      child: SizedBox(
        width: 390,
        child: GlassSwipeRow(
          name: 'Solo Leveling',
          trailing: [_act('remove', 'Remove', destructive: true, tone: SwipeTone.danger), _act('download', 'Download', tone: SwipeTone.iris)],
          leading: [_act('markRead', 'Mark read', tone: SwipeTone.success)],
          child: const GlassListRow(title: 'Solo Leveling'),
        ),
      ),
    );

double _left(WidgetTester t) => t.getTopLeft(find.text('Solo Leveling')).dx;

void main() {
  setUp(() {
    ran = [];
    GlassHaptics.debugLog.clear();
  });

  group('swipe row', () {
    testWidgets('opens its tray past half the tray width and closes below it', (tester) async {
      await tester.pumpWidget(primHost(_row()));
      final rest = _left(tester);
      await tester.drag(find.text('Solo Leveling'), const Offset(-60, 0));
      await pumpFor(tester, 700);
      expect(_left(tester), closeTo(rest, 0.5));
      await tester.drag(find.text('Solo Leveling'), const Offset(-120, 0));
      await pumpFor(tester, 700);
      expect(_left(tester), closeTo(rest - 176, 1)); // two 88 px slots
    });

    testWidgets('a destructive full swipe past 60 % commits with an Undo toast and both haptics', (tester) async {
      await tester.pumpWidget(primHost(_row()));
      final g = tester.startGesture(tester.getCenter(find.text('Solo Leveling')));
      final gesture = await g;
      await gesture.moveBy(const Offset(-120, 0));
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.moveBy(const Offset(-140, 0)); // 260 of 390 = 0.67
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.moveBy(const Offset(60, 0)); // back under the line
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.moveBy(const Offset(-90, 0));
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.up();
      await pumpFor(tester, 900);
      final log = GlassHaptics.debugLog.map((e) => e.event).toList();
      expect(log, contains(HapticEvent.thresholdCross));
      expect(log, contains(HapticEvent.thresholdBack));
      expect(ran, ['remove']);
      final c = ProviderScope.containerOf(tester.element(find.byType(GlassSwipeRow)));
      expect(c.read(glassToastProvider).single.spec.undo, isNotNull);
      expect(c.read(glassToastProvider.notifier).undoLast(), isTrue);
      await pumpFor(tester, 600);
      expect(ran, ['remove', 'undo-remove']);
    });

    testWidgets('a drag that starts 20 px from the leading edge does not move the row', (tester) async {
      await tester.pumpWidget(primHost(_row()));
      final rest = _left(tester);
      await tester.dragFrom(const Offset(20, 25), const Offset(150, 0));
      await pumpFor(tester, 500);
      expect(_left(tester), closeTo(rest, 0.5));
      await tester.dragFrom(const Offset(40, 25), const Offset(150, 0));
      await pumpFor(tester, 700);
      expect(_left(tester), isNot(closeTo(rest, 0.5))); // 40 px in: the row is dragged
    });

    testWidgets('every swipe action is a custom semantics action; m, Delete and u work from the keyboard', (tester) async {
      final h = tester.ensureSemantics();
      await tester.pumpWidget(primHost(_row()));
      final node = tester.getSemantics(find.text('Solo Leveling'));
      final labels = node.getSemanticsData().customSemanticsActionIds!.map((id) => CustomSemanticsAction.getAction(id)!.label).toSet();
      expect(labels, {'Remove', 'Download', 'Mark read'});
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      await pumpFor(tester, 300);
      expect(ran, ['markRead']);
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await pumpFor(tester, 900);
      expect(ran, ['markRead', 'remove']);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyU);
      await pumpFor(tester, 600);
      expect(ran.last, 'undo-remove');
      h.dispose();
    });
  });
}
