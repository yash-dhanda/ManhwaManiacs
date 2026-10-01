import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/routes/nav_extra.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/series_detail.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

import '../shell/shell_rig.dart';
import 'series_rig.dart';

const _loc = '/sources/demo/series/k1000';

Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 200));
  }
}

/// The series page, its ⋯ menu and a toast: the glass registry readout (glass 15.7).
Future<({int layers, int shapes})> _caseCounts(WidgetTester t, Size size) async {
  final rig = await pumpGlassShell(t, size: size, extra: [...seriesOverrides(followed: [followRow()])]);
  rig.router.push<void>(_loc, extra: const GlassNavExtra()).ignore();
  await t.pump();
  await _settle(t);
  await t.tap(find.descendant(of: find.byType(GlassSeriesPage), matching: find.bySemanticsLabel('More')).first);
  await _settle(t);
  expect(find.text('Reading status…'), findsOneWidget);
  rig.container.read(glassToastProvider.notifier).show(const GlassToastSpec('Saved'));
  await _settle(t);
  final r = rig.container.read(glassRegistryProvider);
  return (layers: r.layers, shapes: r.shapes);
}

void main() {
  testWidgets('§15.7 phone: the series sheet, the ⋯ menu and a toast read at most 4 layers and 8 shapes', (t) async {
    final c = await _caseCounts(t, const Size(390, 844));
    // ignore: avoid_print
    print('BUDGET series phone sheet+menu+toast: ${c.layers} layers / ${c.shapes} shapes');
    expect(c.layers, lessThanOrEqualTo(4));
    expect(c.shapes, lessThanOrEqualTo(8));
    await t.pump(const Duration(seconds: 6));
  });

  testWidgets('§15.7 desktop frame: the series window, the ⋯ menu and a toast read at most 6 layers and 6 shapes', (t) async {
    final c = await _caseCounts(t, const Size(1366, 1024));
    // ignore: avoid_print
    print('BUDGET series desktop window+menu+toast: ${c.layers} layers / ${c.shapes} shapes');
    expect(c.layers, lessThanOrEqualTo(6));
    expect(c.shapes, lessThanOrEqualTo(6));
    await t.pump(const Duration(seconds: 6));
  });
}
