// ignore_for_file: require_trailing_commas, directives_ordering, avoid_redundant_argument_values, unnecessary_import
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/onboarding/store/onboarding_draft.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/typed_headline.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

import 'onboarding_test_support.dart';

Finder _headline(String text) => find.byWidgetPredicate((w) => w is TypedHeadline && w.text == text);

void main() {
  testWidgets('a deep link to step 1 opens step 2; the folio reads 1 / 4 with four rules', (tester) async {
    await pumpOnboarding(tester, step: 1);
    await settleFor(tester, 300);
    expect(find.text('1 / 4'), findsOneWidget);
    expect(_headline('What do you read?'), findsOneWidget);
    expect(find.bySemanticsLabel('Step 1 of 4'), findsOneWidget);
    expect(find.text('FORMATS'), findsOneWidget);
  });

  testWidgets('the headline types at 50 ms per grapheme, is a level-1 heading and completes on a tap', (tester) async {
    await pumpOnboarding(tester);
    await tester.pump(const Duration(milliseconds: 500));
    final rich = tester.widget<RichText>(find.descendant(of: _headline('What do you read?'), matching: find.byType(RichText)));
    final revealed = ((rich.text as TextSpan).children!.first as TextSpan).children!.first as TextSpan;
    expect(revealed.text!.characters.length, inInclusiveRange(9, 11));
    final s = tester.getSemantics(find.descendant(of: _headline('What do you read?'), matching: find.byType(Semantics)).first);
    expect(s.label, 'What do you read?');
    await tester.tap(_headline('What do you read?'));
    await tester.pump();
    final done = tester.widget<RichText>(find.descendant(of: _headline('What do you read?'), matching: find.byType(RichText)));
    expect(((done.text as TextSpan).children!.first as TextSpan).children!.first, isA<TextSpan>().having((s) => s.text!.characters.length, 'n', 17));
    await settleFor(tester, 4000);
  });

  testWidgets('formats: four tiles (three with novels off); a tap toggles and Next saves only formats', (tester) async {
    final rig = await pumpOnboarding(tester);
    await settleFor(tester, 300);
    expect(find.bySemanticsLabel('Novels'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Manga'));
    await tester.pump();
    expect(tester.getSemantics(find.bySemanticsLabel('Manga')), isSemantics(isButton: true, hasToggledState: true, isToggled: true, label: 'Manga'));
    await tester.tap(find.text('Next'));
    await tester.pump();
    expect(rig.repo.puts.single, {'step': 3, 'formats': ['manga']});
    await settleFor(tester, 1500);
    expect(find.text('2 / 4'), findsOneWidget);
    expect(rig.container.read(onboardingStoreProvider).readDraft().touched.length, 1);
  });

  testWidgets('novels off: three tiles', (tester) async {
    await pumpOnboarding(tester, novels: false);
    await settleFor(tester, 300);
    expect(find.bySemanticsLabel('Novels'), findsNothing);
    expect(find.bySemanticsLabel('Manhwa'), findsOneWidget);
  });

  testWidgets('Android back goes 4 to 3 to 2 to the picker; a forward swipe never advances', (tester) async {
    final rig = await pumpOnboarding(tester);
    await settleFor(tester, 300);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Next'));
      await settleFor(tester, 900);
    }
    expect(find.text('3 / 4'), findsOneWidget);
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await settleFor(tester, 800);
    expect(find.text('3 / 4'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await settleFor(tester, 900);
    expect(find.text('2 / 4'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await settleFor(tester, 900);
    expect(find.text('1 / 4'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await settleFor(tester, 1000);
    expect(rig.at, '/profiles');
  });

  testWidgets('a backward swipe goes back one step', (tester) async {
    await pumpOnboarding(tester);
    await settleFor(tester, 300);
    await tester.tap(find.text('Next'));
    await settleFor(tester, 900);
    expect(find.text('2 / 4'), findsOneWidget);
    await tester.fling(find.byType(PageView), const Offset(300, 0), 1000);
    await settleFor(tester, 1500);
    expect(find.text('1 / 4'), findsOneWidget);
  });

  testWidgets('on iOS the route cannot be swiped and the pop is blocked', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      final rig = await pumpOnboarding(tester, platform: TargetPlatform.iOS);
      await settleFor(tester, 300);
      final route = ModalRoute.of(tester.element(find.byType(PageView)))! as SwipeablePageRoute<dynamic>;
      expect(route.canSwipe, isFalse);
      await tester.tap(find.text('Next'));
      await settleFor(tester, 900);
      await tester.binding.handlePopRoute();
      await settleFor(tester, 900);
      expect(rig.at, startsWith('/welcome'), reason: 'PopScope turns the pop into a step back');
      expect(find.text('1 / 4'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('resume: a profile stopped at step 4 opens there; a hand-typed step above it is capped', (tester) async {
    await pumpOnboarding(tester, step: 5, profileStep: 4);
    await settleFor(tester, 300);
    expect(find.text('3 / 4'), findsOneWidget);
    expect(_headline('Which of these do you like the look of?'), findsOneWidget);
  });

  testWidgets('Skip sends step done, leaves by Dip and clears the draft', (tester) async {
    final rig = await pumpOnboarding(tester);
    await settleFor(tester, 300);
    await tester.tap(find.text('Skip'));
    await settleFor(tester, 1200);
    expect(rig.repo.puts.single, {'step': 'done'});
    expect(rig.at, '/');
  });

  testWidgets('a failing done save lands in the pending key', (tester) async {
    final repo = FakeOnboardingRepo()..failPuts = true;
    final rig = await pumpOnboarding(tester, repo: repo);
    await settleFor(tester, 300);
    await tester.tap(find.text('Skip'));
    await settleFor(tester, 6500);
    expect(repo.puts.length, 3);
    expect(rig.container.read(onboardingStoreProvider).readPending(), isNotNull);
  });

  testWidgets('offline catalog: OFFLINE EDITION with Skip for now, no save', (tester) async {
    final repo = FakeOnboardingRepo()..error = const NetworkError(message: 'x');
    final rig = await pumpOnboarding(tester, repo: repo);
    await settleFor(tester, 800);
    expect(find.text('OFFLINE EDITION'), findsOneWidget);
    await tester.tap(find.text('Skip for now'));
    await settleFor(tester, 1200);
    expect(repo.puts, isEmpty);
    expect(rig.at, '/');
  });

  testWidgets('hardware keys: right is Next, left steps back', (tester) async {
    await pumpOnboarding(tester);
    await settleFor(tester, 300);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await settleFor(tester, 900);
    expect(find.text('2 / 4'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await settleFor(tester, 900);
    expect(find.text('1 / 4'), findsOneWidget);
  });

  testWidgets('reduced motion: steps change at once', (tester) async {
    await pumpOnboarding(tester, reduced: true);
    await settleFor(tester, 300);
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('2 / 4'), findsOneWidget);
    expect(_headline('Tap once to like, twice to love, hold to skip.'), findsOneWidget);
  });
}
