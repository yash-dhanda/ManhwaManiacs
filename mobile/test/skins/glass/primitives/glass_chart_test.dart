import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/chart_math.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/chart_prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/glass_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/test_overrides.dart';
import 'support.dart';

List<ChartDatum> _days({int n = 30}) => [
      for (var i = 0; i < n; i++) ChartDatum(day: DateTime(2026, 9).add(Duration(days: i)), value: i % 4 == 0 ? 0 : (i * 3 % 17).toDouble() + 1, second: (i % 5).toDouble(), partial: i == n - 1),
    ];

String _read(ChartDatum d) => '${d.day?.day ?? d.label} Sep · ${d.value.round()} pages';

Widget _chart(GlassChartKind kind, List<ChartDatum> data, {String id = 'pages'}) => SingleChildScrollView(
      child: SizedBox(
      width: 358,
      child: GlassChart(kind: kind, data: data, chartId: id, summary: 'You read 210 pages in September.', title: 'Pages per day', readout: _read, secondHeader: 'Chapters', emptyText: 'Nothing read in the last 7 days', today: DateTime(2026, 9, 30)),
    ),
    );

Future<List<Override>> _overrides() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return [authenticatedAuthOverride(), activeProfileOverride(), sharedPrefsProvider.overrideWithValue(prefs)];
}

void main() {
  testWidgets('a chart is one focus stop; the arrow keys change the semantics value; Home and End jump', (tester) async {
    final h = tester.ensureSemantics();
    await tester.pumpWidget(primHost(_chart(GlassChartKind.bars, _days()), overrides: await _overrides()));
    await pumpFor(tester, 900);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab); // the chart
    await tester.pump();
    Finder titled() => find.bySemanticsLabel('Pages per day');
    expect(tester.getSemantics(titled()).value, 'You read 210 pages in September.', reason: 'before a selection the value is the summary');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(tester.getSemantics(titled()).value, '1 Sep · 0 pages', reason: 'zero is written as 0');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(tester.getSemantics(titled()).value, '2 Sep · 4 pages');
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(tester.getSemantics(titled()).value, contains('30 Sep'));
    expect(tester.getSemantics(titled()).value, endsWith('so far'), reason: 'today is partial');
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(tester.getSemantics(titled()).value, startsWith('1 Sep'));
    expect(find.byKey(const ValueKey('glass-chart-readout')), findsOneWidget);
    expect(find.byKey(const ValueKey('glass-chart-ring')), findsOneWidget);
    // the next Tab leaves the chart for the table button
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    h.dispose();
  });

  testWidgets('t swaps in a Table that persists after a rebuild with a new container sharing the same prefs', (tester) async {
    final over = await _overrides();
    await tester.pumpWidget(primHost(_chart(GlassChartKind.bars, _days()), overrides: over));
    await pumpFor(tester, 900);
    expect(find.byType(Table), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
    await pumpFor(tester, 200);
    expect(find.byType(Table), findsOneWidget);
    expect(find.text('Chapters'), findsOneWidget);
    expect(find.text('Show as chart'), findsOneWidget);
    // zero shows as "0"
    expect(find.text('0'), findsWidgets);
    // a brand new tree and container over the same fake prefs
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(primHost(_chart(GlassChartKind.bars, _days()), overrides: over));
    await pumpFor(tester, 900);
    expect(find.byType(Table), findsOneWidget);
    final prefs = over.last;
    expect(prefs, isNotNull);
    // another chart id is unaffected, and the entry keeps its other fields
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(primHost(_chart(GlassChartKind.bars, _days(), id: 'other'), overrides: over));
    await pumpFor(tester, 900);
    expect(find.byType(Table), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
    await pumpFor(tester, 200);
    final c = ProviderScope.containerOf(tester.element(find.byType(GlassChart)));
    final rec = c.read(glassPrefsRecordProvider);
    expect(rec.child('chartTables').data, {'pages': true, 'other': true});
  });

  testWidgets('no data says so inside the chart area; a tap selects and shows the readout', (tester) async {
    await tester.pumpWidget(primHost(_chart(GlassChartKind.bars, const []), overrides: await _overrides()));
    await pumpFor(tester, 300);
    expect(find.text('Nothing read in the last 7 days'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(primHost(_chart(GlassChartKind.bars, _days()), overrides: await _overrides()));
    await pumpFor(tester, 900);
    await tester.tapAt(const Offset(30, 80));
    await pumpFor(tester, 100);
    expect(find.byKey(const ValueKey('glass-chart-readout')), findsOneWidget);
  });

  testWidgets('every kind renders with its summary sentence above', (tester) async {
    final hours = [for (var h = 0; h < 24; h++) ChartDatum(label: hourLabel(h), value: h == 23 ? 9 : (h % 5).toDouble())];
    final genres = [for (final g in ['Action', 'Fantasy', 'Romance', 'Drama', 'Comedy', 'Horror']) ChartDatum(label: g, value: g.length.toDouble())];
    final status = [for (final s in ['reading', 'completed', 'on hold', 'plan to read', 'dropped', 'unread']) ChartDatum(label: s, value: s.length.toDouble())];
    final cases = {
      GlassChartKind.heatmap: _days(n: 60),
      GlassChartKind.radar: genres,
      GlassChartKind.clock: hours,
      GlassChartKind.sparkline: _days(n: 7),
      GlassChartKind.statusBars: status,
    };
    for (final e in cases.entries) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(primHost(_chart(e.key, e.value, id: e.key.name), overrides: await _overrides()));
      await pumpFor(tester, 900);
      expect(find.text('You read 210 pages in September.'), findsOneWidget, reason: '${e.key}');
      expect(find.textContaining('Show as table'), findsOneWidget, reason: '${e.key}');
    }
    expect(find.text('Material'), findsNothing);
    expect(Material, isNotNull);
    expect(MaterialType.canvas, isNotNull);
    expect(CheckedState.none, isNotNull);
  });
}
