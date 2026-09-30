import 'dart:ui' show CheckedState;

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/list_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/reorder_list.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/swipe_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/overlay_queue.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/bulk_toolbar.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/select_mode.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/selectable_group.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';

import 'overlay_support.dart';
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

class _PopObserver with WidgetsBindingObserver {
  _PopObserver(this.nav);
  final GlobalKey<NavigatorState> nav;

  @override
  Future<bool> didPopRoute() async => nav.currentState!.maybePop();
}

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

  group('reorder', () {
    Widget list(List<String> order, void Function(int, int) onReorder) => StatefulBuilder(
          builder: (context, set) => SizedBox(
            width: 390,
            child: GlassReorderList<String>(
              items: order,
              nameOf: (s) => s,
              onReorder: (a, b) {
                onReorder(a, b);
                set(() => order.insert(b, order.removeAt(a)));
              },
              itemBuilder: (context, item, i, info) => GlassListRow(title: item, onTap: () {}),
            ),
          ),
        );

    testWidgets('Alt+Down moves the focused row and announces it assertively', (tester) async {
      final said = <String>[];
      tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (m) async {
        if (m is Map && m['type'] == 'announce') said.add((m['data'] as Map)['message'] as String);
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, null));
      final order = ['Solo Leveling', 'Tower of God', 'Omniscient', 'Lookism'];
      final moves = <(int, int)>[];
      await tester.pumpWidget(primHost(list(order, (a, b) => moves.add((a, b)))));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await pumpFor(tester, 300);
      expect(moves, [(0, 1)]);
      expect(order.first, 'Tower of God');
      expect(said, ['Solo Leveling moved to position 2 of 4']);
      // the moved row keeps focus, so the next Alt+Shift+Down goes to the bottom
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await pumpFor(tester, 300);
      expect(order.last, 'Solo Leveling');
      expect(said.last, 'Solo Leveling moved to position 4 of 4');
    });

    testWidgets('a 450 ms press opens the preview; a drag of 12 px lifts the row and a release drops it', (tester) async {
      final order = ['A row', 'B row', 'C row', 'D row'];
      final moves = <(int, int)>[];
      await tester.pumpWidget(primHost(list(order, (a, b) => moves.add((a, b)))));
      final g = await tester.startGesture(tester.getCenter(find.text('A row')));
      await pumpFor(tester, 520);
      expect(find.byKey(const ValueKey('glass-context-preview')), findsOneWidget);
      await g.moveBy(const Offset(0, 12));
      await pumpFor(tester, 100);
      expect(find.byKey(const ValueKey('glass-reorder-lifted')), findsOneWidget);
      expect(GlassHaptics.debugLog.map((e) => e.event), contains(HapticEvent.reorderLift));
      await g.moveTo(tester.getCenter(find.text('C row')) + const Offset(0, 20));
      await pumpFor(tester, 200);
      expect(GlassHaptics.debugLog.map((e) => e.event), contains(HapticEvent.reorderPass));
      await g.up();
      await pumpFor(tester, 900);
      expect(moves, [(0, 2)]);
      expect(find.byKey(const ValueKey('glass-reorder-lifted')), findsNothing);
      expect(order, ['B row', 'C row', 'A row', 'D row']);
    });
  });

  group('select mode', () {
    Future<GlassSelectModeController<int>> grid(WidgetTester tester, {List<BulkAction<int>> actions = const []}) async {
      final c = GlassSelectModeController<int>();
      addTearDown(c.dispose);
      final host = OverlayHost(tester);
      final pop = _PopObserver(host.nav);
      WidgetsBinding.instance.addObserver(pop);
      addTearDown(() => WidgetsBinding.instance.removeObserver(pop));
      await host.pump(
        page: Stack(children: [
          GlassSelectableGroup<int>(
            controller: c,
            ids: [for (var i = 0; i < 8; i++) i],
            label: 'Select series',
            child: Column(children: [
              for (var i = 0; i < 8; i++)
                GlassSelectableItem<int>(id: i, child: Focus(child: SizedBox(width: 390, height: 56, child: Text('item $i')))),
            ],),
          ),
          GlassBulkToolbar<int>(controller: c, actions: actions),
        ],),
      );
      return c;
    }

    testWidgets('x enters with the row picked, Space toggles, Shift+Space ranges, Esc clears then exits', (tester) async {
      final c = await grid(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
      await pumpFor(tester, 300);
      expect(c.active, isTrue);
      expect(c.selected, {0});
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space); // the row that entered keeps the keyboard
      expect(c.selected, isEmpty);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter); // Enter toggles too, it never opens
      expect(c.selected, {0});
      c.exit();
      c.enter(1);
      c.toggle(1);
      c.toggle(2);
      c.extendTo(5);
      expect(c.selected, {2, 3, 4, 5});
      await pumpFor(tester, 100);
      final container = ProviderScope.containerOf(tester.element(find.byType(GlassSelectableGroup<int>)));
      expect(container.read(glassBottomBarProvider), GlassBottomBar.bulk);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(c.selected, isEmpty);
      expect(c.active, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(c.active, isFalse);
      await pumpFor(tester, 600);
      expect(container.read(glassBottomBarProvider), GlassBottomBar.none);
    });

    testWidgets('Android back exits select mode and clears the selection', (tester) async {
      final c = await grid(tester);
      c.enter(3);
      await pumpFor(tester, 100);
      expect(c.selected, {3});
      await tester.binding.handlePopRoute();
      await pumpFor(tester, 100);
      expect(c.active, isFalse);
      expect(c.selected, isEmpty);
    });

    testWidgets('items read as checked buttons in a labelled container with a Select semantics label', (tester) async {
      final h = tester.ensureSemantics();
      final c = await grid(tester);
      c.enter(1);
      await pumpFor(tester, 100);
      final node = tester.getSemantics(find.text('item 1'));
      final data = node.getSemanticsData();
      expect(data.flagsCollection.isChecked, CheckedState.isTrue);
      expect(data.flagsCollection.isButton, isTrue);
      expect(tester.getSemantics(find.text('item 2')).getSemanticsData().flagsCollection.isChecked, CheckedState.isFalse);
      h.dispose();
    });
  });
}
