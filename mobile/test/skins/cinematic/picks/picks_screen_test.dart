import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/ai/providers/suggested_tags_provider.dart';
import 'package:manhwamaniacs/features/library/models/suggestion.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/library/providers/intelligence_providers.dart';
import 'package:manhwamaniacs/features/sources/models/source_genre.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/picks/picks_screen.dart';

import '../discover/harness.dart';
import 'picks_test_support.dart';

Future<({PicksLibrary lib, FakeAi ai})> pumpPicks(
  WidgetTester tester, {
  PicksLibrary? lib,
  bool focusAsk = false,
  bool reduced = false,
  Size size = const Size(390, 2400),
}) async {
  final l = lib ?? PicksLibrary();
  final ai = FakeAi();
  await pumpScreen(
    tester,
    PicksScreen(focusAsk: focusAsk),
    size: size,
    reduced: reduced,
    extra: [libraryRepositoryProvider.overrideWithValue(l), aiRepositoryProvider.overrideWithValue(ai)],
  );
  await settle(tester);
  return (lib: l, ai: ai);
}

Finder title(String t) => find.text(t).last;

Future<void> advance(WidgetTester tester, int ms) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> type(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(const Key('ask-field')), text);
  await tester.pump();
}

Future<void> ask(WidgetTester tester, String text) async {
  await type(tester, text);
  await tester.tap(find.byKey(const Key('ask-button')));
  await tester.pump();
}

void main() {
  testWidgets('masthead, deck, ask block and For you', (tester) async {
    final h = tester.ensureSemantics();
    await pumpPicks(tester);
    expect(find.text('NO. 12 — PICKS'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is Semantics && (w.properties.header ?? false) && w.properties.label == 'Picks'), findsOneWidget);
    h.dispose();
    expect(find.textContaining('Describe it in your own words'), findsOneWidget);
    expect(find.byKey(const Key('ask-field')), findsOneWidget);
    expect(find.text('8 ASKS LEFT TODAY'), findsOneWidget);
    expect(find.text('FROM EVERYWHERE'), findsOneWidget);
    expect(find.text('01'), findsOneWidget);
    expect(title('Lantern Courier'), findsOneWidget);
  });

  testWidgets('the field counts n / 600 and Ask waits for 3 characters', (tester) async {
    await pumpPicks(tester);
    expect(find.text('0 / 600'), findsOneWidget);
    await type(tester, 'ab');
    final button = tester.widget<Semantics>(find.descendant(of: find.byKey(const Key('ask-button')), matching: find.byType(Semantics)).first);
    expect(button, isNotNull);
    await tester.tap(find.byKey(const Key('ask-button')));
    await tester.pump();
    expect(find.text('2 / 600'), findsOneWidget);
    await type(tester, 'a murim regressor');
    expect(find.text('17 / 600'), findsOneWidget);
  });

  testWidgets('the toggle picks the endpoint: everywhere by default, your sources on switch', (tester) async {
    final t = await pumpPicks(tester);
    await ask(tester, 'a slow political one');
    await advance(tester, 500);
    expect((t.lib.worldAsks, t.lib.localAsks), (1, 0));
    await tester.tap(find.text('FROM YOUR SOURCES'));
    await tester.pump();
    await ask(tester, 'a slow political two');
    await advance(tester, 500);
    expect((t.lib.worldAsks, t.lib.localAsks), (1, 1));
  });

  testWidgets('the keyboard send key and Enter submit; Shift+Enter is a newline', (tester) async {
    final t = await pumpPicks(tester);
    await type(tester, 'a slow political one');
    await tester.showKeyboard(find.byKey(const Key('ask-field')));
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await advance(tester, 300);
    expect(t.lib.worldAsks, 1);
    await tester.tap(find.byKey(const Key('ask-field')));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await advance(tester, 300);
    expect(t.lib.worldAsks, 2);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await advance(tester, 300);
    expect(t.lib.worldAsks, 2, reason: 'Shift+Enter does not ask');
  });

  testWidgets('the hint types the three examples, cycling every 6 s', (tester) async {
    await pumpPicks(tester);
    await advance(tester, 4000);
    expect(find.text('A murim regressor who comes back stronger'), findsWidgets);
    await advance(tester, 4000);
    expect(find.text('Magic academy, but the lead is already strong'), findsWidgets);
  });

  testWidgets('reduced motion: the hint is complete at once', (tester) async {
    await pumpPicks(tester, reduced: true);
    expect(find.text('A murim regressor who comes back stronger'), findsWidgets);
  });

  testWidgets('?ask=1 focuses the field', (tester) async {
    await pumpPicks(tester, focusAsk: true);
    await tester.pump();
    expect(tester.widget<TextField>(find.byKey(const Key('ask-field'))).focusNode!.hasFocus, isTrue);
  });

  testWidgets('thinking: the typed line, the leader dial after 1 s, then the cards fade in', (tester) async {
    final t = await pumpPicks(tester);
    t.lib.gate = Completer();
    await ask(tester, 'a slow political one');
    await advance(tester, 600);
    expect(find.textContaining('Reading'), findsWidgets);
    await advance(tester, 1500);
    expect(find.text('Reading your shelf…'), findsOneWidget);
    expect(find.descendant(of: find.byType(CineLeaderDial), matching: find.byType(CustomPaint)), findsWidgets);
    t.lib.gate!.complete(t.lib.answer);
    await advance(tester, 600);
    expect(find.text('THE EDITORS SUGGEST'), findsOneWidget);
    expect(title('Night Ward'), findsOneWidget);
    expect(find.text('Slow and political.'), findsOneWidget);
  });

  testWidgets('after 40 s the timeout copy shows without cancelling; a late answer still renders', (tester) async {
    final t = await pumpPicks(tester);
    t.lib.gate = Completer();
    await ask(tester, 'a slow political one');
    await advance(tester, 39000);
    expect(find.text('The editors took too long. Try a shorter description.'), findsNothing);
    await advance(tester, 2000);
    await advance(tester, 6000);
    expect(find.text('The editors took too long. Try a shorter description.'), findsOneWidget);
    expect(t.lib.worldAsks, 1, reason: 'not cancelled and not re-asked');
    t.lib.gate!.complete(t.lib.answer);
    await advance(tester, 600);
    expect(find.text('The editors took too long. Try a shorter description.'), findsNothing);
    expect(title('Night Ward'), findsOneWidget);
  });

  testWidgets('Try again cancels the running ask, asks again and keeps the text', (tester) async {
    final t = await pumpPicks(tester);
    t.lib.gate = Completer();
    await ask(tester, 'a slow political one');
    await advance(tester, 41000);
    await advance(tester, 6000);
    expect(t.lib.worldTokens.single!.isCancelled, isFalse);
    final first = t.lib.gate!;
    t.lib.gate = Completer();
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(t.lib.worldAsks, 2);
    expect(t.lib.worldTokens.first!.isCancelled, isTrue, reason: 'the second ask cancels the first');
    expect(t.lib.worldTokens.last!.isCancelled, isFalse);
    // The cancelled ask's failure is dropped: the second ask is still the one in flight.
    first.complete(const Err(NetworkError(message: 'cancelled')));
    await tester.pump();
    final answer = ProviderScope.containerOf(tester.element(find.byType(PicksScreen))).read(suggestionsProvider);
    expect(answer.isLoading && !answer.hasError, isTrue);
    expect(tester.widget<TextField>(find.byKey(const Key('ask-field'))).controller!.text, 'a slow political one');
  });

  Future<void> failWith(WidgetTester tester, String code, {int status = 502, Duration? after}) async {
    final t = await pumpPicks(tester);
    t.lib.answer = Err(ApiError(statusCode: status, code: code, message: 'm', retryAfter: after));
    await ask(tester, 'a slow political one');
    await advance(tester, 6000);
  }

  testWidgets('shelf too thin: the notice with Browse sources and Ask everywhere instead', (tester) async {
    final t = await pumpPicks(tester);
    await tester.tap(find.text('FROM YOUR SOURCES'));
    await tester.pump();
    t.lib.answer = const Err(ApiError(statusCode: 409, code: 'suggest_shelf_empty', message: 'm'));
    await ask(tester, 'a slow political one');
    await advance(tester, 6000);
    expect(find.text('NOTHING TO PICK FROM YET'), findsOneWidget);
    expect(find.text('Browse sources'), findsOneWidget);
    expect(find.text('Ask everywhere instead'), findsOneWidget);
    await tester.tap(find.text('Ask everywhere instead'));
    await tester.pump();
    expect(find.text('Ask everywhere instead'), findsNothing);
  });

  testWidgets('ask failed: the copy and Try again; the field keeps its text', (tester) async {
    await failWith(tester, 'ai_failed');
    expect(find.textContaining("The editors couldn't answer that one"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('no matches', (tester) async {
    await failWith(tester, 'ai_no_matches');
    expect(find.text('Nothing fit that description. Try describing it differently.'), findsOneWidget);
  });

  testWidgets('rate limited: SLOW DOWN with the live countdown (branches on the code, not the 429)', (tester) async {
    await failWith(tester, 'rate_limited', status: 429, after: const Duration(seconds: 12));
    expect(find.text('SLOW DOWN'), findsOneWidget);
    expect(find.textContaining('Try again in'), findsOneWidget);
  });

  testWidgets('a 429 that is the budget reads as the closed desk, not SLOW DOWN', (tester) async {
    await failWith(tester, 'ai_budget_exhausted', status: 429);
    expect(find.text('SLOW DOWN'), findsNothing);
    expect(find.text('The picks desk is closed tonight. Asks reset at midnight UTC.'), findsWidgets);
  });

  testWidgets('not configured: the ask block is replaced by a NOTE, world recs still show', (tester) async {
    await pumpPicks(tester, lib: PicksLibrary(availability: const SuggestionAvailability(available: false, reason: 'not_configured', remainingToday: 0)));
    await advance(tester, 4000);
    expect(find.byKey(const Key('ask-field')), findsNothing);
    expect(find.text("The editors' desk isn't set up on this server."), findsOneWidget);
    expect(find.text('Titles from everywhere, picked from what you read.'), findsOneWidget);
    expect(title('Lantern Courier'), findsOneWidget);
  });

  testWidgets('budget spent: the field is disabled, 0 ASKS LEFT TODAY and the caption', (tester) async {
    await pumpPicks(tester, lib: PicksLibrary(availability: const SuggestionAvailability(available: false, reason: 'budget_exhausted', remainingToday: 0)));
    expect(tester.widget<TextField>(find.byKey(const Key('ask-field'))).enabled, isFalse);
    expect(find.text('0 ASKS LEFT TODAY'), findsOneWidget);
    expect(find.text('The picks desk is closed tonight. Asks reset at midnight UTC.'), findsOneWidget);
    expect(find.textContaining('The picks below still work.'), findsOneWidget);
  });

  testWidgets('Not for me: sends not_interested, fades the card and hides it', (tester) async {
    final t = await pumpPicks(tester);
    await tester.tap(find.bySemanticsLabel('More options for Lantern Courier'));
    await advance(tester, 400);
    await tester.tap(find.text('Not for me'));
    await advance(tester, 100);
    expect(t.ai.sent, [
      {'signal': 'not_interested', 'anilist_id': 1, 'source_id': null, 'series_key': null, 'tag': null},
    ]);
    await advance(tester, 400);
    expect(find.text('Lantern Courier'), findsNothing);
    expect(title('Salt and Ember'), findsOneWidget);
  });

  testWidgets('More like this: liked_pick, a toast, and a second press clears without a request', (tester) async {
    final t = await pumpPicks(tester);
    Future<void> press() async {
      await tester.tap(find.bySemanticsLabel('More options for Lantern Courier'));
      await advance(tester, 400);
      await tester.tap(find.text('More like this'));
      await advance(tester, 300);
    }

    await press();
    expect(t.ai.sent.single['signal'], 'liked_pick');
    expect(find.text('Noted. Picks will lean this way.'), findsOneWidget);
    await press();
    expect(t.ai.sent.length, 1);
  });

  testWidgets('Delete on a focused card is Not for me', (tester) async {
    final t = await pumpPicks(tester);
        // Focus the card through the keyboard: Tab until a card holds focus, then Delete.
    for (var i = 0; i < 40 && t.ai.sent.isEmpty; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();
    }
    expect(t.ai.sent.isNotEmpty, isTrue);
    expect(t.ai.sent.first['signal'], 'not_interested');
    await advance(tester, 500);
  });

  testWidgets('empty profile: NOTHING TO GO ON YET with Find something', (tester) async {
    await pumpPicks(tester, lib: PicksLibrary(recs: const WorldRecommendations()));
    await advance(tester, 3000);
    expect(find.text('NOTHING TO GO ON YET'), findsOneWidget);
    expect(find.text('Find something'), findsOneWidget);
  });

  testWidgets('recommendations failed: CORRECTION with Try again', (tester) async {
    await pumpPicks(tester, lib: PicksLibrary(recsError: const NetworkError(message: 'x')));
    await advance(tester, 3000);
    expect(find.text('CORRECTION'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('a stale generated_at marks PICKED 3 DAYS AGO; none never marks', (tester) async {
    await pumpPicks(tester, lib: PicksLibrary(recs: WorldRecommendations(forYou: [world('A')], generatedAt: DateTime.now().subtract(const Duration(days: 3, hours: 2)))));
    expect(find.text('PICKED 3 DAYS AGO'), findsOneWidget);
  });

  testWidgets('no generated_at is never stale', (tester) async {
    await pumpPicks(tester);
    expect(find.textContaining('PICKED'), findsNothing);
  });

  testWidgets('the world catalogue being unreachable shows the server reason under the masthead', (tester) async {
    await pumpPicks(tester, lib: PicksLibrary(recs: WorldRecommendations(forYou: [world('A')], unavailableReason: 'The worldwide catalog could not be reached; showing what was cached.')));
    expect(find.textContaining('could not be reached'), findsOneWidget);
    expect(title('A'), findsOneWidget);
  });

  testWidgets('partial: the section that failed is omitted, folios renumber, the line says so', (tester) async {
    final recs = WorldRecommendations(
      forYou: [world('A')],
      sections: [
        const WorldSection(becauseTitle: 'Solo Leveling'),
        WorldSection(becauseTitle: 'Tower of God', items: [world('B', id: 5)]),
      ],
    );
    await pumpPicks(tester, lib: PicksLibrary(recs: recs));
    await advance(tester, 3000);
    expect(find.text("Some picks didn't come through."), findsOneWidget);
    expect(find.text('02'), findsOneWidget);
    expect(find.text('03'), findsNothing);
    expect(find.textContaining('Solo Leveling'), findsNothing);
  });

  testWidgets('Your genres: weighted slugs that open Discover on the genre', (tester) async {
    await pumpPicks(tester, lib: PicksLibrary(genres: const [GenreWeight(genre: 'Action', weight: 9), GenreWeight(genre: 'Romance', weight: 2)]));
    expect(find.text('ACTION'), findsOneWidget);
    await tester.tap(find.text('ACTION'));
    await tester.pumpAndSettle();
    expect(find.textContaining('at /search?genre=Action'), findsOneWidget);
  });

  testWidgets('tablet: two For you columns, results in two columns', (tester) async {
    await pumpPicks(tester, size: const Size(834, 1194));
    final a = tester.getTopLeft(title('Lantern Courier'));
    final b = tester.getTopLeft(title('Salt and Ember'));
    expect(b.dx, greaterThan(a.dx + 100));
  });
}
