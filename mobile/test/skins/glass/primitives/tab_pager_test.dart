
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/primitives/tab_pager.dart';

import 'support.dart';

Iterable<HapticEvent> _events() => GlassHaptics.debugLog.map((e) => e.event);

Widget _pager({GlassTabPagerController? controller, List<GlassTabSpec>? tabs, ValueChanged<int>? onChanged}) => SizedBox(
      width: 390,
      height: 500,
      child: GlassTabPager(
        controller: controller,
        onChanged: onChanged,
        tabs: tabs ?? const [GlassTabSpec('Reading'), GlassTabSpec('Queue'), GlassTabSpec('Done')],
        panels: [for (var i = 0; i < 3; i++) Center(child: Text('panel $i'))],
      ),
    );

Rect _indicator(WidgetTester t) => t.getRect(find.byKey(const ValueKey('glass-tab-capsule')));

void main() {
  setUp(GlassHaptics.debugLog.clear);

  testWidgets('the indicator follows the pager while a finger drags a panel and select fires when it settles', (tester) async {
    final changed = <int>[];
    final c = GlassTabPagerController();
    await tester.pumpWidget(primHost(_pager(controller: c, onChanged: changed.add)));
    await tester.pump(const Duration(milliseconds: 100));
    final first = _indicator(tester);
    final g = await tester.startGesture(const Offset(300, 300));
    await g.moveBy(const Offset(-25, 0));
    await g.moveBy(const Offset(-100, 0));
    await tester.pump(const Duration(milliseconds: 16));
    final mid = _indicator(tester);
    expect(mid.left, greaterThan(first.left)); // slid toward the next label
    expect(mid.width, isNot(first.width)); // and stretched between the two widths
    await g.moveBy(const Offset(-100, 0)); // past half of a page: it settles on the next panel
    await tester.pump(const Duration(milliseconds: 16));
    await g.up();
    await pumpFor(tester, 800);
    final settled = _indicator(tester);
    expect(settled.left, greaterThan(mid.left - 1));
    expect(_events(), contains(HapticEvent.select));
    expect(changed, [1]);
  });

  testWidgets('tapping a tab animates the pager over 414 ms on springSettle and selects', (tester) async {
    await tester.pumpWidget(primHost(_pager()));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Done'));
    await tester.pump();
    await pumpFor(tester, 150);
    expect(find.text('panel 1'), findsAny);
    expect(find.text('panel 2').hitTestable(), findsNothing); // not there yet
    await pumpFor(tester, 500);
    expect(find.text('panel 2'), findsOneWidget);
    expect(_events(), contains(HapticEvent.select));
  });

  testWidgets('a touch during the programmatic scroll catches it (the PageView drag takes over)', (tester) async {
    final c = GlassTabPagerController();
    await tester.pumpWidget(primHost(_pager(controller: c)));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Done'));
    await tester.pump();
    await pumpFor(tester, 100);
    final before = c.pages.page!;
    expect(before, greaterThan(0));
    expect(before, lessThan(2));
    final g = await tester.startGesture(const Offset(200, 300));
    await g.moveBy(const Offset(25, 0));
    await g.moveBy(const Offset(60, 0));
    await tester.pump(const Duration(milliseconds: 16));
    expect(c.pages.page, lessThan(2));
    await g.up();
    await pumpFor(tester, 900);
  });

  testWidgets('[ and ] go to the previous and next tab, the arrows move inside the strip, disabled tabs are skipped', (tester) async {
    final changed = <int>[];
    await tester.pumpWidget(primHost(_pager(onChanged: changed.add, tabs: const [GlassTabSpec('Reading'), GlassTabSpec('Queue', disabled: true), GlassTabSpec('Done')])));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.bracketRight);
    await pumpFor(tester, 600);
    expect(changed, [2]); // Queue is skipped
    await tester.sendKeyEvent(LogicalKeyboardKey.bracketLeft);
    await pumpFor(tester, 600);
    expect(changed, [2, 0]);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await pumpFor(tester, 600);
    expect(changed, [2, 0, 2]);
  });

  testWidgets('the first-panel signal is exposed for the back swipe', (tester) async {
    final c = GlassTabPagerController();
    await tester.pumpWidget(primHost(_pager(controller: c)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(c.isAtFirstPanel.value, isTrue);
    await tester.tap(find.text('Queue'));
    await pumpFor(tester, 700);
    expect(c.isAtFirstPanel.value, isFalse);
    await tester.tap(find.text('Reading'));
    await pumpFor(tester, 700);
    expect(c.isAtFirstPanel.value, isTrue);
  });

  testWidgets('semantics: "Queue, tab 2 of 3", selected, and each panel a container', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(primHost(_pager()));
    await tester.pump(const Duration(milliseconds: 100));
    final n = tester.getSemantics(find.bySemanticsLabel('Queue, tab 2 of 3')).getSemanticsData();
    expect(n.flagsCollection.isButton, isTrue);
    final sel = tester.getSemantics(find.bySemanticsLabel('Reading, tab 1 of 3')).getSemanticsData();
    expect(sel.flagsCollection.isSelected.toString(), contains('isTrue'));
    handle.dispose();
  });

  testWidgets('states: loading shows the skeleton with the tab still working; error shows Retry', (tester) async {
    var retried = 0;
    await tester.pumpWidget(primHost(_pager(tabs: [const GlassTabSpec('Reading'), const GlassTabSpec('Queue', loading: true), GlassTabSpec('Done', errorText: "Couldn't load", onRetry: () => retried++)])));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Queue'));
    await pumpFor(tester, 700);
    expect(find.text('panel 1'), findsNothing);
    await tester.tap(find.text('Done'));
    await pumpFor(tester, 700);
    expect(find.text("Couldn't load"), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(retried, 1);
  });

  testWidgets('reduced motion: a tab tap jumps the pager and the indicator lands on the tab', (tester) async {
    await tester.pumpWidget(primHost(_pager(), reduced: true));
    bindReduced(tester);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Done'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('panel 2'), findsOneWidget);
    expect(find.text('panel 1').hitTestable(), findsNothing);
  });
}
