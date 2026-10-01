import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/annual.dart';
import 'package:manhwamaniacs/features/library/utils/wrapped_cards.dart' show WrappedCard;
import 'package:manhwamaniacs/skins/glass/glass/registry.dart';
import 'package:manhwamaniacs/skins/glass/wrapped/wrapped_copy.dart' show wrappedHours;

import '../../../support/numbers_fixtures.dart';
import '../shell/shell_rig.dart';
import '../stats/stats_rig.dart';

const _path = '/library/statistics/annual/2026';

Annual _year() => Annual.fromJson({...annualJson(partial: false), 'busiest_day': {'date': '2026-03-14', 'chapters': 42, 'series': <Object?>[]}});

Future<void> _settle(WidgetTester t, [int n = 6]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 300));
  }
}

Finder _card(WrappedCard c) => find.byKey(ValueKey('wrapped-card-${c.name}'));

Future<ShellRig> _open(WidgetTester t) async {
  final rig = await pumpStats(t, FakeNumbers(annuals: {2026: _year()}), start: _path, settle: false);
  await _settle(t);
  return rig;
}

Future<void> _stepTo(WidgetTester t, WrappedCard c) async {
  for (var i = 0; i < 12 && _card(c).evaluate().isEmpty; i++) {
    await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await _settle(t, 3);
  }
  expect(_card(c), findsOneWidget);
}

void main() {
  testWidgets('budget: the frame is the one live glass, card 10 adds its lens (2 layers)', (t) async {
    final rig = await _open(t);
    await _stepTo(t, WrappedCard.time);
    expect(rig.container.read(glassRegistryProvider).layers, 1);
    await _stepTo(t, WrappedCard.topSource);
    expect(rig.container.read(glassRegistryProvider).layers, 2);
    await t.pump(const Duration(minutes: 11));
    await t.pump(const Duration(milliseconds: 50)); // the last card change's haptic timer
  });

  testWidgets('reduced motion: the count-up shows its final value and auto-advance still runs', (t) async {
    t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await _open(t);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await t.pump(const Duration(milliseconds: 250)); // the 200 ms cross-fade, no count-up
    expect(_card(WrappedCard.time), findsOneWidget);
    expect(find.text('${wrappedHours(_year())}'), findsWidgets);
    await t.pump(const Duration(seconds: 6));
    await t.pump(const Duration(milliseconds: 250));
    expect(_card(WrappedCard.volume), findsOneWidget, reason: 'auto-advance is timing, not motion');
    await t.pump(const Duration(minutes: 11));
    await t.pump(const Duration(milliseconds: 50)); // the last card change's haptic timer
  });
}
