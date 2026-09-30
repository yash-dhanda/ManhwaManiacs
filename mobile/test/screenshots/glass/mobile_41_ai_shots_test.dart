@Tags(['screenshots'])
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/ai/models/similar_result.dart';
import 'package:manhwamaniacs/features/ai/providers/ai_providers.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/library/models/suggestion.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/library/providers/intelligence_providers.dart' show suggestAvailabilityProvider;
import 'package:manhwamaniacs/features/recap/recap_cache.dart';
import 'package:manhwamaniacs/features/recap/recap_deck.dart';
import 'package:manhwamaniacs/skins/glass/parts/ai/more_like_this_rail.dart';
import 'package:manhwamaniacs/skins/glass/parts/recap/chapter_pill.dart';
import 'package:manhwamaniacs/skins/glass/parts/recap/continue_series.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/reveal_slots.dart';
import 'package:manhwamaniacs/skins/glass/routes/nav_extra.dart';
import 'package:manhwamaniacs/skins/glass/screens/picks/ask_box.dart';
import 'package:manhwamaniacs/skins/glass/screens/recap/recap_deck.dart';

import '../../skins/glass/picks/ai_rig.dart';
import '../../skins/glass/primitives/support.dart' show primHost, pumpFor;
import '../../skins/glass/recap/recap_rig.dart';
import '../../support/test_overrides.dart' show contentModeOverrides;
import '../glass_shell_shots_support.dart';
import '../support/shot_harness.dart';
import '../support/skin_shots.dart';

/// The mobile/41 proof captures (glass 9.1.2 to 9.1.4): For you and Ask, the recap offer and deck, How it works, the chapter pill and
/// More like this, every AI answer from fixtures built from the `backend/05` shapes. Written only when `MM_PROOF_DIR` is set.

const _phone = SkinShotSize('phone', Size(390, 844), 3.0, EdgeInsets.only(top: 47, bottom: 34));
final _tablet = kSkinShotSizes[1];

const _lib = SuggestionAvailability(available: true, reason: 'ok', remainingToday: 7);

Future<ShotSession> _open(WidgetTester t, SkinShotSize size, String start, {List<Override> extra = const [], int rounds = 6}) async {
  final s = await openShell(t, size, start: start, settle: false, extra: [clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 1, 12)), ...extra]);
  for (var i = 0; i < rounds; i++) {
    await s.settle(400);
  }
  return s;
}

Future<void> _end(WidgetTester t) async {
  await t.pumpWidget(const SizedBox.shrink());
  await t.pump(const Duration(minutes: 11));
}

Future<void> _ask(WidgetTester t, String text) async {
  await t.enterText(find.byType(EditableText).first, text);
  await t.pump();
  await t.tap(find.text('Ask'));
}

WorldItem _w(String title, int id, {bool available = true}) => WorldItem.fromJson(itemJson(title, id: id, available: available));

void main() {
  setUpAll(loadAppFonts);
  setUp(glassRevealSlots.reset);

  for (final size in [_phone, _tablet]) {
    testWidgets('for you: idle, thinking, deal, results, grid, genre, states at ${size.name}', (t) async {
      var a = RoutedAdapter({});
      var s = await _open(t, size, '/library/recommendations', extra: askOverrides(a, availability: _lib));
      await s.snap('for-you-idle', size);

      a = RoutedAdapter({'/library/world/suggest': (_) => const Reply({}, hang: true)});
      s = await _open(t, size, '/library/recommendations', extra: askOverrides(a, availability: _lib));
      await _ask(t, kAskExamples.first);
      await pumpFor(t, 4100);
      await s.snap('for-you-thinking', size);
      await _end(t);

      a = RoutedAdapter({'/library/world/suggest': (_) => suggestOk(8)});
      s = await _open(t, size, '/library/recommendations', extra: askOverrides(a, availability: _lib));
      await _ask(t, kAskExamples.first);
      await pumpFor(t, 420);
      await s.snap('for-you-deal', size);
      await pumpFor(t, 2500);
      await s.snap('for-you-results', size);
      await t.tap(find.text('Show as grid'));
      await pumpFor(t, 600);
      await s.snap('for-you-grid', size);
      await _end(t);

      a = RoutedAdapter({});
      s = await _open(t, size, '/library/recommendations?genre=Fantasy', extra: askOverrides(a, availability: _lib));
      await s.snap('for-you-genre', size);
      await _end(t);

      a = RoutedAdapter({'/library/world/suggest': (_) => const Reply({'items': <Object>[], 'remaining_today': 5})});
      s = await _open(t, size, '/library/recommendations', extra: askOverrides(a, availability: _lib));
      await _ask(t, 'a quiet farming story with no fights');
      await pumpFor(t, 800);
      await s.snap('for-you-no-matches', size);
      await _end(t);

      s = await _open(t, size, '/library/recommendations', extra: askOverrides(RoutedAdapter({}), availability: const SuggestionAvailability(available: false, reason: 'budget_exhausted', remainingToday: 0)));
      await s.snap('for-you-budget', size);
      await _end(t);

      s = await _open(t, size, '/library/recommendations', extra: askOverrides(RoutedAdapter({}), availability: const SuggestionAvailability(available: false, reason: 'not_configured', remainingToday: 0)));
      await s.snap('for-you-not-configured', size);
      await _end(t);

      s = await _open(t, size, '/library/recommendations', extra: [...askOverrides(RoutedAdapter({})), suggestAvailabilityProvider.overrideWith((ref) async => throw Exception('offline'))]);
      await s.snap('for-you-offline', size);
      await _end(t);

      s = await _open(t, size, '/library/recommendations', extra: [...askOverrides(RoutedAdapter({}), availability: _lib), ...contentModeOverrides(mode: ContentMode.novel, novelsEnabled: true)]);
      await s.snap('for-you-novels', size);
      await _end(t);
    });
  }

  testWidgets('for you: swipe not interested, reduced motion, text scale 2', (t) async {
    final a = RoutedAdapter({'/library/world/suggest': (_) => suggestOk(4)});
    var s = await _open(t, _phone, '/library/recommendations', extra: askOverrides(a, availability: _lib));
    await _ask(t, kAskExamples[1]);
    await pumpFor(t, 2500);
    await t.drag(find.textContaining('Pick 0').first, const Offset(-90, 0));
    await pumpFor(t, 500);
    await s.snap('for-you-swipe-not-interested', _phone);
    await _end(t);

    s = await _open(t, _phone, '/library/recommendations', extra: [...askOverrides(a, availability: _lib), glassMotionPrefsProvider.overrideWith((ref) => const GlassMotionPrefs(reduced: true))]);
    await _ask(t, kAskExamples[1]);
    await pumpFor(t, 600);
    await s.snap('for-you-reduced-motion', _phone);
    await _end(t);

    t.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    s = await _open(t, _phone, '/library/recommendations', extra: askOverrides(RoutedAdapter({}), availability: _lib));
    await s.snap('for-you-text-scale-2', _phone);
    await _end(t);
  });

  for (final size in [_phone, _tablet, kSkinShotTabletWide]) {
    testWidgets('offer at ${size.name}', (t) async {
      final s = await _open(t, size, '/');
      s.container.read(offerTargetProvider.notifier).state = HomeContinueTarget(sourceId: 's', seriesKey: 'k', chapterKey: 'c2', recap: const RecapAvailability(available: true, toKey: 'c2'), lastReadAt: DateTime.utc(2026, 9, 10, 12));
      s.router.go('/?sheet=offer');
      await pumpFor(t, 1400);
      await s.snap('offer', size);
      await _end(t);
    });
  }

  for (final size in [_phone, _tablet]) {
    testWidgets('recap deck at ${size.name}', (t) async {
      final ctl = StreamController<List<int>>();
      var a = RecapAdapter(controller: ctl);
      var s = await _open(t, size, '/', rounds: 2, extra: [recapOverride(a)]);
      unawaited(s.router.push('/recap/s/k?to=c2', extra: const GlassNavExtra()));
      await pumpFor(t, 900);
      for (final e in deckEvents(withDone: false).take(7)) {
        ctl.add(utf8.encode(e));
      }
      await pumpFor(t, 500);
      await s.snap('recap-writing', size);
      await ctl.close();
      await _end(t);

      a = RecapAdapter(chunks: deckEvents());
      s = await _open(t, size, '/', rounds: 2, extra: [recapOverride(a)]);
      unawaited(s.router.push('/recap/s/k?to=c2', extra: const GlassNavExtra()));
      await pumpFor(t, 3500);
      await s.snap('recap-deck-card1', size);
      final deck = t.state<RecapDeckViewState>(find.byType(RecapDeckView));
      unawaited(deck.next());
      await pumpFor(t, 200);
      await s.snap('recap-lift', size);
      await pumpFor(t, 700);
      unawaited(deck.next());
      await pumpFor(t, 900);
      await s.snap('recap-deck-card3', size);
      await _end(t);

      a = RecapAdapter(chunks: [deckEvents()[0], deckEvents()[1], deckEvents()[5], deckEvents().last]);
      s = await _open(t, size, '/', rounds: 2, extra: [recapOverride(a)]);
      unawaited(s.router.push('/recap/s/k?to=c2&scope=chapter', extra: const GlassNavExtra()));
      await pumpFor(t, 3000);
      await s.snap('recap-compact', size);
      await _end(t);

      s = await _open(t, size, '/', rounds: 2, extra: [recapOverride(RecapAdapter(json: {'available': false, 'reason': 'no_dialogue'}))]);
      unawaited(s.router.push('/recap/s/k?to=c2', extra: const GlassNavExtra()));
      await pumpFor(t, 1800);
      await s.snap('recap-no-source-text', size);
      await _end(t);

      s = await _open(t, size, '/', rounds: 2, extra: [recapOverride(RecapAdapter(json: {'available': false, 'reason': 'not_configured'}))]);
      unawaited(s.router.push('/recap/s/k?to=c2', extra: const GlassNavExtra()));
      await pumpFor(t, 1800);
      await s.snap('recap-unavailable', size);
      await _end(t);

      s = await _open(t, size, '/', rounds: 2, extra: [recapOverride(RecapAdapter(chunks: const []))]);
      final done = DeckDone.fromJson({'range': [120, 141], 'covered_through': 141, 'model': 'test-model'});
      await s.container.read(recapCacheProvider).save('s:k:c2:series', DeckState(sections: [const DeckSection(kind: 'left_off', title: 'Where you left off', text: 'Jinwoo stands at the gate.', words: ['Jinwoo', 'stands', 'at', 'the', 'gate.'])], done: done));
      unawaited(s.router.push('/recap/s/k?to=c2', extra: const GlassNavExtra()));
      await pumpFor(t, 2500);
      await s.snap('recap-offline-cached', size);
      await _end(t);
    });
  }

  testWidgets('how it works, the chapter pill, the ready toast and More like this', (t) async {
    final s = await _open(t, _phone, '/');
    s.router.go('/?sheet=how-it-works');
    await pumpFor(t, 1400);
    await s.snap('how-it-works', _phone);
    await _end(t);

    await t.pumpWidget(primHost(const SizedBox(width: 390, height: 120, child: Center(child: RecapChapterPill(sourceId: 's', seriesKey: 'k', chapterKey: 'c'))), overrides: [], align: false));
    await pumpFor(t, 600);
    await _end(t);

    Widget rail(SimilarResult ai, SimilarResult genres) => RepaintBoundary(
          key: kSkinShotKey,
          child: const ColoredBox(color: Color(0xFF0B0B0F), child: SizedBox(width: 390, height: 240, child: MoreLikeThisRail(sourceId: 's', seriesKey: 'k', title: 'Solo Leveling'))),
        );
    for (final (name, ai, genres) in [
      ('more-like-this', SimilarResult(items: [_w('Tower Climb', 1), _w('Gate Keeper', 2), _w('Night Hunter', 3)]), const SimilarResult()),
      ('more-like-this-genres', const SimilarResult(available: false, reason: 'not_configured'), SimilarResult(items: [_w('Tower Climb', 1), _w('Gate Keeper', 2), _w('Night Hunter', 3)], basis: 'genres')),
    ]) {
      await captureSkinWidget(t, name: name, size: _phone, overrides: [similarProvider.overrideWith((ref, q) async => q.fallbackGenres ? genres : ai)], child: primHost(rail(ai, genres), align: false));
    }
  });
}
