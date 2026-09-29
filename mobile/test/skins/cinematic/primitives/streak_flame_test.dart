// ignore_for_file: require_trailing_commas
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/gallery/fixtures.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/streak_flame.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/test_overrides.dart';

Future<void> pumpFlame(WidgetTester t, HomeStreak s, DateTime now, {bool reduced = false, bool? ignite = false, double size = 24}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await t.pumpWidget(ProviderScope(
    overrides: [sharedPrefsProvider.overrideWithValue(prefs), authenticatedAuthOverride(), activeProfileOverride()],
    child: MaterialApp(
      theme: ThemeData(extensions: const [cinematicTokens]),
      builder: (context, app) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: reduced), child: app!),
      home: Scaffold(body: Center(child: StreakFlame(streak: s, size: size, now: now, ignite: ignite))),
    ),
  ));
  await t.pump();
}

HomeStreak streak(int days, {DateTime? last}) => HomeStreak(currentDays: days, longestDays: days, lastActiveDate: last);

void main() {
  final today = DateTime(2026, 9, 30), evening = DateTime(2026, 9, 30, 21);

  testWidgets('tier by days: the ember dot, flame-1, flame-3, ring, sparks', (t) async {
    await pumpFlame(t, streak(0), evening);
    expect(find.byType(Icon), findsNothing);
    expect(t.getSemantics(find.byType(StreakFlame)).label, 'No streak');
    await pumpFlame(t, streak(3, last: today), evening);
    expect(find.byType(Icon), findsOneWidget);
    await pumpFlame(t, streak(12, last: today), evening);
    expect(find.byType(Icon), findsNWidgets(2), reason: 'two tongues');
    expect(find.byType(CustomPaint).evaluate().any((e) => e.widget is CustomPaint && (e.widget as CustomPaint).painter.runtimeType.toString() == '_RingPainter'), isFalse);
    await pumpFlame(t, streak(45, last: today), evening);
    expect(find.byType(CustomPaint).evaluate().any((e) => (e.widget as CustomPaint).painter.runtimeType.toString() == '_RingPainter'), isTrue);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('state by the pinned clock: read today, alive, at risk', (t) async {
    await pumpFlame(t, streak(12, last: today), evening);
    expect(t.getSemantics(find.byType(StreakFlame)).label, '12-day streak, read today');
    await pumpFlame(t, streak(12, last: DateTime(2026, 9, 29)), DateTime(2026, 9, 30, 14));
    expect(t.getSemantics(find.byType(StreakFlame)).label, '12-day streak, not read yet today');
    await pumpFlame(t, streak(12, last: DateTime(2026, 9, 29)), evening);
    expect(t.getSemantics(find.byType(StreakFlame)).label, '12-day streak, at risk');
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('the gallery cases all render, and the reduced branch runs no tickers', (t) async {
    for (final (_, s, now) in galleryStreaks) {
      await pumpFlame(t, s, now, reduced: true, size: 96);
      expect(t.binding.transientCallbackCount, 0, reason: 'reduced motion: static flame, static ring, no sparks');
    }
    await pumpFlame(t, streak(120, last: today), evening);
    expect(t.binding.transientCallbackCount, greaterThan(0));
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('Ignite runs once when the day was just extended', (t) async {
    SharedPreferences.setMockInitialValues({'mm.streak.seen.u1p1': '2026-09-29'});
    final prefs = await SharedPreferences.getInstance();
    final s = streak(13, last: today);
    Widget host() => ProviderScope(
          overrides: [sharedPrefsProvider.overrideWithValue(prefs), authenticatedAuthOverride(), activeProfileOverride()],
          child: MaterialApp(theme: ThemeData(extensions: const [cinematicTokens]), home: Scaffold(body: StreakFlame(streak: s, size: 24, now: evening))),
        );
    await t.pumpWidget(host());
    await t.pump(const Duration(milliseconds: 100));
    expect(prefs.getString('mm.streak.seen.u1p1'), '2026-09-30');
    expect(t.binding.transientCallbackCount, greaterThan(0));
    await t.pump(const Duration(milliseconds: 500));
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
}
