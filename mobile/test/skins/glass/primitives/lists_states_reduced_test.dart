// ignore_for_file: unawaited_futures
import 'package:flutter/material.dart' show CircularProgressIndicator;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/glass/primitives/ai/thinking_orbit.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/bar_painter.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/chart_math.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/glass_chart.dart';
import 'package:manhwamaniacs/skins/glass/primitives/download_control.dart';
import 'package:manhwamaniacs/skins/glass/primitives/icon_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/list_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/reorder_list.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/swipe_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/reactions/reaction_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/test_overrides.dart';
import 'support.dart';

void main() {
  SwipeAction act() => SwipeAction(id: 'remove', label: 'Remove', glyph: const IconData(0xE1FE, fontFamily: 'PhosphorRegular'), destructive: true, run: () async {});

  testWidgets('swipe: tracking stays 1:1, pills appear at scale 1, the release cross-fades to the outcome in 150 ms', (tester) async {
    await tester.pumpWidget(primHost(SizedBox(width: 390, child: GlassSwipeRow(name: 'Row', trailing: [act()], child: const GlassListRow(title: 'Row'))), reduced: true));
    final rest = tester.getTopLeft(find.text('Row')).dx;
    final g = await tester.startGesture(tester.getCenter(find.text('Row')));
    await g.moveBy(const Offset(-40, 0));
    await tester.pump(const Duration(milliseconds: 16));
    await g.moveBy(const Offset(-30, 0));
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.getTopLeft(find.text('Row')).dx, closeTo(rest - 70, 1), reason: '1:1');
    final scales = tester.widgetList<Transform>(find.descendant(of: find.byType(GlassSwipeRow), matching: find.byType(Transform))).map((t) => t.transform.getMaxScaleOnAxis());
    expect(scales.where((s) => s < 0.99), isEmpty, reason: 'pills are not inflating');
    await g.moveBy(const Offset(-40, 0));
    await g.up();
    await pumpFor(tester, 200);
    expect(tester.getTopLeft(find.text('Row')).dx, closeTo(rest - 88, 1), reason: 'settled after 150 ms, not a spring');
  });

  testWidgets('reorder: the drop cross-fades in 150 ms and the row is committed', (tester) async {
    final order = ['A row', 'B row', 'C row'];
    final moves = <(int, int)>[];
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(primHost(
      StatefulBuilder(
        builder: (context, set) => SizedBox(
          width: 390,
          child: GlassReorderList<String>(
            items: order,
            nameOf: (s) => s,
            onReorder: (a, b) => set(() {
              moves.add((a, b));
              order.insert(b, order.removeAt(a));
            }),
            itemBuilder: (context, item, i, info) => GlassListRow(title: item, trailing: info.handle()),
          ),
        ),
      ),
      reduced: true,
    ),);
    await pumpFor(tester, 200);
    final g = await tester.startGesture(tester.getCenter(find.byType(GlassIconButton).first));
    await pumpFor(tester, 100);
    expect(find.byKey(const ValueKey('glass-reorder-lifted')), findsOneWidget);
    await g.moveTo(tester.getCenter(find.text('C row')) + const Offset(0, 10));
    await pumpFor(tester, 100);
    await g.up();
    await pumpFor(tester, 200);
    expect(moves, [(0, 2)]);
    expect(find.byKey(const ValueKey('glass-reorder-lifted')), findsNothing);
  });

  testWidgets('the orbit pulses in place and the queued ring is static', (tester) async {
    await tester.pumpWidget(primHost(const ThinkingOrbit(size: 64), reduced: true));
    await pumpFor(tester, 300);
    final p = tester.widget<CustomPaint>(find.byKey(const ValueKey('glass-thinking-orbit'))).painter! as OrbitPainter;
    expect(p.reduced, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(primHost(const GlassQueuedRing(animate: false)));
    final t0 = tester.widget<CustomPaint>(find.byType(CustomPaint).last).painter.toString();
    await pumpFor(tester, 1500);
    expect(tester.widget<CustomPaint>(find.byType(CustomPaint).last).painter.toString(), t0);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('charts: marks fade in over 150 ms instead of rising', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final data = [for (var i = 0; i < 10; i++) ChartDatum(day: DateTime(2026, 9, 1 + i), value: (i + 1).toDouble())];
    await tester.pumpWidget(primHost(
      SingleChildScrollView(child: SizedBox(width: 358, child: GlassChart(kind: GlassChartKind.bars, data: data, chartId: 'r', summary: 's', readout: (d) => 'r'))),
      reduced: true,
      overrides: [sharedPrefsProvider.overrideWithValue(prefs), authenticatedAuthOverride(), activeProfileOverride()],
    ),);
    await pumpFor(tester, 40);
    final painter = tester.widget<CustomPaint>(find.byWidgetPredicate((w) => w is CustomPaint && w.painter is BarPainter)).painter! as BarPainter;
    expect(painter.reduced, isTrue);
    await pumpFor(tester, 200);
  });

  testWidgets('reaction bubbles appear in place, not travelling from the button', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(primHost(Center(child: GlassReactionButton(onSend: (_) {}, onClear: () {})), reduced: true, align: false));
    final centre = tester.getCenter(find.byType(GlassReactionButton));
    final g = await tester.startGesture(centre);
    await pumpFor(tester, 340);
    expect(find.byKey(const ValueKey('glass-reaction-bubbles')), findsOneWidget);
    final targets = bubbleCentres(centre);
    final hype = tester.getCenter(find.text('Hype'));
    expect(hype.dx, closeTo(targets.first.dx, 1), reason: 'already at its place on the first frame');
    await g.up();
    await pumpFor(tester, 300);
    expect(ReactionKind.values, isNotEmpty);
  });
}
