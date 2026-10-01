import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/providers/numbers_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/glass_chart.dart';

import 'stats_rig.dart';

Future<void> _frames(WidgetTester t, [int n = 4]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('chapters per day: a drag scrubs with one select per day crossed and the readout', (t) async {
    await pumpStats(t, FakeNumbers(), start: '/library/statistics?range=7');
    final chart = find.byType(GlassChart).first;
    await t.ensureVisible(chart);
    await _frames(t);
    final r = t.getRect(chart);
    GlassHaptics.debugLog.clear();
    final g = await t.startGesture(Offset(r.left + 12, r.center.dy));
    for (var x = r.left + 12; x < r.right - 12; x += 8) {
      await g.moveTo(Offset(x, r.center.dy));
      await t.pump(const Duration(milliseconds: 16));
    }
    expect(find.byKey(const ValueKey('glass-chart-readout')), findsOneWidget, reason: 'the readout capsule while scrubbing');
    await g.up();
    final selects = GlassHaptics.debugLog.where((e) => e.event == HapticEvent.select).length;
    expect(selects, inInclusiveRange(5, 7), reason: 'one select per day crossed (7 days)');
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('the semantics increase and decrease actions step the selection with a live value', (t) async {
    final h = t.ensureSemantics();
    await pumpStats(t, FakeNumbers(), start: '/library/statistics?range=7');
    await t.ensureVisible(find.byType(GlassChart).first);
    await _frames(t);
    final node = find.semantics.byPredicate((n) => n.label == 'Chapters per day' && n.getSemanticsData().hasAction(SemanticsAction.increase));
    String value() => node.evaluate().single.value;
    final before = value();
    t.semantics.increase(node);
    await _frames(t, 2);
    final first = value();
    expect(first, isNot(before));
    expect(first, contains('pages'));
    t.semantics.increase(node);
    await _frames(t, 2);
    final second = value();
    expect(second, isNot(first));
    t.semantics.decrease(node);
    await _frames(t, 2);
    expect(value(), first);
    h.dispose();
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('[ and ] step the range: the request, the URL and statsRangeProvider follow', (t) async {
    final repo = FakeNumbers();
    final rig = await pumpStats(t, repo);
    await t.sendKeyEvent(LogicalKeyboardKey.bracketRight);
    await _frames(t, 6);
    expect(repo.statisticsDays.last, 90);
    expect(rig.at, '/library/statistics');
    expect(rig.router.routerDelegate.currentConfiguration.uri.queryParameters['range'], '90');
    await t.sendKeyEvent(LogicalKeyboardKey.bracketRight);
    await _frames(t, 6);
    expect(repo.statisticsDays.last, 365, reason: 'Year asks for 365 days');
    await t.sendKeyEvent(LogicalKeyboardKey.bracketLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.bracketLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.bracketLeft);
    await _frames(t, 6);
    expect(repo.statisticsDays.last, 7);
    expect(rig.container.read(statsRangeProvider), 7);
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('hit targets on Statistics at 390 x 844', (t) async {
    final h = t.ensureSemantics();
    await pumpStats(t, FakeNumbers());
    await expectLater(t, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(t, meetsGuideline(androidTapTargetGuideline));
    await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
    h.dispose();
    await t.pump(const Duration(minutes: 11));
  });
}
