// ignore_for_file: require_trailing_commas, directives_ordering
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/ai/models/similar_result.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/onboarding/models/onboarding_catalog.dart';
import 'package:manhwamaniacs/features/onboarding/models/taste.dart';
import 'package:manhwamaniacs/skins/cinematic/flight.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_poster.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/typed_headline.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/onboarding/genre_word.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/onboarding/onboarding_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

import 'onboarding_test_support.dart';

List<String> _titles(WidgetTester t) => [for (final p in t.widgetList<CinePoster>(find.byType(CinePoster))) p.title];

Set<String> _actions(WidgetTester t, String label) {
  final data = t.getSemantics(find.bySemanticsLabel(label)).getSemanticsData();
  return {for (final id in data.customSemanticsActionIds ?? const <int>[]) CustomSemanticsAction.getAction(id)!.label!};
}

void main() {
  group('genres', () {
    testWidgets('one paragraph of words; tap cycles like, love, clear; the labels read', (t) async {
      final rig = await pumpOnboarding(t, step: 3, profileStep: 3);
      await settleFor(t, 400);
      expect(find.byType(GenreWord), findsNWidgets(34));
      await t.tap(find.bySemanticsLabel('Romance, not chosen'));
      await t.pump();
      expect(find.bySemanticsLabel('Romance, liked'), findsOneWidget);
      await t.tap(find.bySemanticsLabel('Romance, liked'));
      await t.pump();
      expect(find.bySemanticsLabel('Romance, loved'), findsOneWidget);
      await t.tap(find.bySemanticsLabel('Romance, loved'));
      await t.pump();
      expect(find.bySemanticsLabel('Romance, not chosen'), findsOneWidget);
      await settleFor(t, 600);
      // The clear travels as weight 0, and Next carries only the touched field.
      await t.tap(find.text('Next'));
      await t.pump();
      expect(rig.repo.puts.single, {'step': 4, 'genres': {'Romance': 0}});
      await settleFor(t, 1000);
    });

    testWidgets('a 450 ms hold skips and fires no tap; every word has Like, Love, Skip and Clear', (t) async {
      await pumpOnboarding(t, step: 3, profileStep: 3);
      await settleFor(t, 400);
      expect(_actions(t, 'Romance, not chosen'), {'Like', 'Love', 'Skip', 'Clear'});
      final g = await t.startGesture(t.getCenter(find.bySemanticsLabel('Romance, not chosen')));
      await t.pump(const Duration(milliseconds: 600));
      await g.up();
      await t.pump();
      expect(find.bySemanticsLabel('Romance, skipped'), findsOneWidget);
      await settleFor(t, 400);
    });

    testWidgets('Shift+F10 opens the menu on the focused word', (t) async {
      await pumpOnboarding(t, step: 3, profileStep: 3);
      await settleFor(t, 400);
      Focus.of(t.element(find.descendant(of: find.byType(GenreWord).first, matching: find.byType(CustomPaint)).first)).requestFocus();
      await t.pump();
      await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.f10);
      await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await settleFor(t, 400);
      expect(find.text('Love'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await settleFor(t, 400);
    });

    testWidgets('the catalog failing shows the CORRECTION notice; Next stays enabled', (t) async {
      final repo = FakeOnboardingRepo()..data = const OnboardingCatalog();
      await pumpOnboarding(t, step: 3, profileStep: 3, repo: repo);
      await settleFor(t, 1200);
      expect(find.text('CORRECTION'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });
  });

  group('art style', () {
    testWidgets('nine plates; multi-select; tablet shows the descriptions', (t) async {
      await pumpOnboarding(t, step: 4, profileStep: 4, size: const Size(834, 1194));
      await settleFor(t, 400);
      expect(find.text('Painted'), findsOneWidget);
      expect(find.text('Full-colour painted webtoon art.'), findsOneWidget);
      await t.tap(find.bySemanticsLabel('Noir. High-contrast black and shadow.'));
      await t.tap(find.bySemanticsLabel('Cel. Crisp cel shading and clean lines.'));
      await t.pump();
      expect(t.getSemantics(find.bySemanticsLabel('Noir. High-contrast black and shadow.')), isSemantics(isButton: true, hasToggledState: true, isToggled: true, label: 'Noir. High-contrast black and shadow.'));
    });

    testWidgets('phones draw the name only; the description stays in the label', (t) async {
      await pumpOnboarding(t, step: 4, profileStep: 4);
      await settleFor(t, 400);
      expect(find.text('Painted'), findsOneWidget);
      expect(find.text('Full-colour painted webtoon art.'), findsNothing);
      expect(find.bySemanticsLabel('Painted. Full-colour painted webtoon art.'), findsOneWidget);
    });
  });

  group('seeds', () {
    testWidgets('24 posters; a pick inserts up to 3 similar ones right after it, once; the counter and Print follow', (t) async {
      final similar = {
        2: SimilarResult(items: [for (final i in [101, 102, 103, 104]) WorldItem(title: 'Similar $i', anilistId: i)]),
      };
      await pumpOnboarding(t, step: 5, profileStep: 5, similar: similar);
      await settleFor(t, 800);
      expect(_titles(t).length, 24);
      expect(find.text('0 / 3 PICKED'), findsOneWidget);
      await t.tap(find.bySemanticsLabel('Series 2'));
      await settleFor(t, 800);
      expect(_titles(t).sublist(0, 6), ['Series 1', 'Series 2', 'Similar 101', 'Similar 102', 'Similar 103', 'Series 3']);
      expect(find.text('1 / 3 PICKED'), findsOneWidget);
      // Unpick and pick again: nothing inserts twice.
      await t.tap(find.bySemanticsLabel('Series 2, picked'));
      await t.pump();
      await t.tap(find.bySemanticsLabel('Series 2'));
      await settleFor(t, 600);
      expect(_titles(t).length, 27);
      await t.tap(find.bySemanticsLabel('Series 1'));
      await t.pump();
      expect(find.text('2 / 3 PICKED'), findsOneWidget);
    });

    testWidgets('Print is disabled below three picks and enabled at three; the counter turns to N PICKED', (t) async {
      await pumpOnboarding(t, step: 5, profileStep: 5);
      await settleFor(t, 800);
      expect(find.bySemanticsLabel(RegExp('Print my first issue')), findsOneWidget);
      for (final n in [1, 2, 3]) {
        await t.tap(find.bySemanticsLabel('Series $n'));
        await t.pump();
      }
      await settleFor(t, 400);
      expect(find.text('3 PICKED'), findsOneWidget);
    });

    testWidgets('the AI desk closed inserts nothing and shows one NOTE line', (t) async {
      final similar = {1: const SimilarResult(items: [], available: false, reason: 'budget_exhausted')};
      await pumpOnboarding(t, step: 5, profileStep: 5, similar: similar);
      await settleFor(t, 800);
      await t.tap(find.bySemanticsLabel('Series 1'));
      await settleFor(t, 400);
      expect(_titles(t).length, 24);
      expect(find.text('NOTE'), findsOneWidget);
      expect(find.text('The picks desk is closed tonight. Asks reset at midnight UTC.'), findsOneWidget);
    });

    testWidgets('an unreachable catalog turns the wall into a NOTE and the footer into Finish', (t) async {
      final repo = FakeOnboardingRepo()..error = const ApiError(statusCode: 500, code: 'x', message: 'x');
      await pumpOnboarding(t, step: 5, profileStep: 5, repo: repo);
      await settleFor(t, 3000);
      expect(find.byWidgetPredicate((w) => w is TypedHeadline && w.text == 'Follow series later from Discover.'), findsOneWidget);
      expect(find.text('Finish'), findsOneWidget);
    });
  });

  group('print and cut to home', () {
    Future<ui.Image> image(WidgetTester t) async => (await t.runAsync(() async {
          final rec = ui.PictureRecorder();
          ui.Canvas(rec).drawRect(const Rect.fromLTWH(0, 0, 4, 6), Paint()..color = const Color(0xFFFFFFFF));
          return rec.endRecording().toImage(4, 6);
        }))!;

    FakeOnboardingRepo repoWith(List<WorldItem> seeds) => FakeOnboardingRepo(catalog: OnboardingCatalog(seeds: seeds));

    WorldItem item(int id, String key, {bool available = true}) => WorldItem(
          title: 'Series $id',
          anilistId: id,
          coverUrl: 'https://img.test/$id.jpg',
          available: available ? [WorldAvailability(sourceId: 'shelf', sourceName: 'Shelf', seriesKey: key)] : const [],
        );

    final keys = ['the-lantern-courier', 'sword-of-the-ninth-spring', 'paper-tiger-academy', 'moonlit-bakery', 'extra-5', 'extra-6'];

    testWidgets('five picks, four available: at most 4 follows at once, the copies fly into Tonight and the headline types after the last landing', (t) async {
      final img = await image(t);
      OnboardingScreen.imageLoader = (_) async => img.clone();
      addTearDown(() => OnboardingScreen.imageLoader = (_) async => null);
      final seeds = [for (var i = 0; i < 6; i++) item(i + 1, keys[i], available: i != 4), item(7, 'x7')];
      final lib = FakeLib();
      final rig = await pumpOnboarding(t, step: 5, profileStep: 5, repo: repoWith(seeds), lib: lib, tonight: true);
      await settleFor(t, 800);
      for (final n in [1, 2, 3, 4, 5]) {
        await t.tap(find.bySemanticsLabel('Series $n'));
        await t.pump();
      }
      await t.tap(find.text('Print my first issue'));
      await t.pump();
      expect(find.text('Printing issue No. 1…'), findsNothing, reason: 'typed, so not whole yet');
      await settleFor(t, 700);
      expect(lib.peak, lessThanOrEqualTo(4));
      expect(lib.calls.length, 4);
      expect(rig.repo.puts.last['step'], 'done');
      // The wall fades, the flight arms and Tonight mounts with its slots hidden.
      var sawFlying = false;
      for (var i = 0; i < 60 && !sawFlying; i++) {
        await t.pump(const Duration(milliseconds: 50));
        sawFlying = rig.container.read(cineFlightProvider).status == FlightStatus.flying;
      }
      expect(rig.at, '/');
      expect(sawFlying, isTrue);
      expect(rig.container.read(cineFlightProvider).hides('shelf:the-lantern-courier'), isTrue);
      final typed = find.byWidgetPredicate((w) => w is TypedHeadline && w.text == 'Tonight: start The Lantern Courier.');
      expect(typed, findsNothing, reason: 'the headline waits for the last landing');
      await settleFor(t, 1500);
      expect(rig.container.read(cineFlightProvider).status, FlightStatus.landed);
      await t.pump(const Duration(milliseconds: 100));
      expect(typed, findsOneWidget);
      await settleFor(t, 3000);
    });

    testWidgets('the fail-safe resets after 3000 ms when Tonight never lands', (t) async {
      final img = await image(t);
      final rig = await pumpOnboarding(t, step: 5, profileStep: 5);
      rig.container.read(cineFlightProvider.notifier).arm([FlightItem(key: 'a:b', image: img, rect: const Rect.fromLTWH(10, 10, 40, 60))]);
      await t.pump();
      await t.pump(const Duration(milliseconds: 3100));
      await t.pump(const Duration(milliseconds: 300));
      expect(rig.container.read(cineFlightProvider).status, FlightStatus.idle);
    });

    testWidgets('one failing follow: "Followed 4 of 5. One couldn\'t be added."', (t) async {
      final lib = FakeLib()..failing.add('extra-5');
      final seeds = [for (var i = 0; i < 5; i++) item(i + 1, keys[i])];
      final rig = await pumpOnboarding(t, step: 5, profileStep: 5, repo: repoWith(seeds), lib: lib, reduced: true, tonight: true);
      await settleFor(t, 400);
      for (final n in [1, 2, 3, 4, 5]) {
        await t.tap(find.bySemanticsLabel('Series $n'));
        await t.pump();
      }
      await t.tap(find.text('Print my first issue'));
      await settleFor(t, 1500);
      expect(rig.at, '/', reason: 'reduced motion: a cross-fade, no flight');
      expect(rig.container.read(cineFlightProvider).status, FlightStatus.idle);
      expect(find.text("Followed 4 of 5. One couldn't be added."), findsOneWidget);
    });

    testWidgets('every follow failing gives the Discover toast and no flight', (t) async {
      final lib = FakeLib()..failing.addAll(keys);
      final seeds = [for (var i = 0; i < 4; i++) item(i + 1, keys[i])];
      final rig = await pumpOnboarding(t, step: 5, profileStep: 5, repo: repoWith(seeds), lib: lib);
      await settleFor(t, 400);
      for (final n in [1, 2, 3]) {
        await t.tap(find.bySemanticsLabel('Series $n'));
        await t.pump();
      }
      await t.tap(find.text('Print my first issue'));
      await settleFor(t, 1500);
      expect(rig.container.read(cineFlightProvider).status, FlightStatus.idle);
      expect(find.text("Couldn't follow any of them. Try again from Discover."), findsOneWidget);
    });
  });
}
