/// The world-recommendation rows of the "Find something to read" screen:
/// every state their request can be in, the rows themselves, and
/// pull-to-refresh.
///
/// A section that draws only its data case reads as a blank space for
/// loading, failure and "nothing yet" alike — offline, the screen was a
/// heading pointing at rows that never came, with no error and no retry.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/library/models/suggestion.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/library/repositories/library_repository.dart';
import 'package:manhwamaniacs/features/library/screens/recommendations_screen.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_overrides.dart';

/// Answers `worldRecommendations` from a queue, one entry per call, so a test
/// can script "fails, then works". The last entry repeats.
class _WorldRepository implements LibraryRepository {
  _WorldRepository(this.answers);

  final List<Result<WorldRecommendations>> answers;
  int recommendationCalls = 0;
  int availabilityCalls = 0;
  int suggestCalls = 0;

  /// Set by a test that needs to see the loading state.
  Completer<void>? holdUntil;

  @override
  Future<Result<WorldRecommendations>> worldRecommendations({
    int seeds = 5,
    int perSeed = 10,
  }) async {
    final answer = answers[recommendationCalls.clamp(0, answers.length - 1)];
    recommendationCalls++;
    if (holdUntil != null) await holdUntil!.future;
    return answer;
  }

  // The box stays hidden, as it is offline or once the day's allowance is
  // spent — the case where the rows are the only thing on the screen.
  @override
  Future<Result<SuggestionAvailability>> suggestAvailability() async {
    availabilityCalls++;
    return const Ok(
      SuggestionAvailability(
        available: false,
        reason: 'budget_exhausted',
        remainingToday: 0,
      ),
    );
  }

  @override
  Future<Result<WorldSuggestResponse>> worldSuggest(
    String prompt, {
    int limit = 12,
  }) {
    suggestCalls++;
    throw UnimplementedError('a pull must never ask for suggestions');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not used here');
}

Future<Widget> _wrap(LibraryRepository repo) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      apiBaseUrlOverride('http://127.0.0.1:8000'),
      sharedPrefsProvider.overrideWithValue(prefs),
      libraryRepositoryProvider.overrideWithValue(repo),
      ...contentModeOverrides(),
    ],
    child: const MaterialApp(home: RecommendationsScreen()),
  );
}

const _offline = Err<WorldRecommendations>(
  NetworkError(message: 'connection refused'),
);

/// What the reader is shown for [_offline] — `NetworkError.userMessage`.
const _offlineMessage = 'Network error — check your connection.';

const _rows = WorldRecommendations(
  forYou: [
    WorldItem(
      title: 'Nano Machine',
      available: [
        WorldAvailability(
          sourceId: 'asurascans',
          sourceName: 'Asura Scans',
          seriesKey: 'nano-machine',
        ),
      ],
    ),
  ],
  sections: [
    WorldSection(
      becauseTitle: 'Solo Leveling',
      items: [WorldItem(title: 'Omniscient Reader')],
    ),
    WorldSection(
      becauseTitle: 'Tower of God',
      items: [WorldItem(title: 'The God of High School')],
    ),
    // A seed with nothing to show gets no heading of its own.
    WorldSection(becauseTitle: 'Empty Seed'),
  ],
);

Future<void> _pumpScreen(WidgetTester tester, _WorldRepository repo) async {
  // Tall enough that every row is laid out, not scrolled past the fold.
  await tester.binding.setSurfaceSize(const Size(800, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(await _wrap(repo));
}

void main() {
  testWidgets('For you, then one row per seed', (tester) async {
    final repo = _WorldRepository([const Ok(_rows)]);
    await _pumpScreen(tester, repo);
    await tester.pumpAndSettle();

    expect(find.text('For you'), findsOneWidget);
    expect(find.text('Nano Machine'), findsOneWidget);
    expect(find.text('On: Asura Scans'), findsOneWidget);
    expect(find.text('Because you read Solo Leveling'), findsOneWidget);
    expect(find.text('Omniscient Reader'), findsOneWidget);
    expect(find.text('Because you read Tower of God'), findsOneWidget);
    expect(find.text('The God of High School'), findsOneWidget);
    expect(find.text('Because you read Empty Seed'), findsNothing);
    // Uncarried titles say so, each with its own search.
    expect(find.text('Not on your sources'), findsNWidgets(2));

    final order = [
      'For you',
      'Because you read Solo Leveling',
      'Because you read Tower of God',
    ].map((text) => tester.getTopLeft(find.text(text)).dy).toList();
    expect(order, orderedEquals([...order]..sort()));
  });

  testWidgets('the genre chips are gone', (tester) async {
    final repo = _WorldRepository([const Ok(_rows)]);
    await _pumpScreen(tester, repo);
    await tester.pumpAndSettle();

    expect(find.text('Or start from a genre'), findsNothing);
    expect(find.byType(ActionChip), findsNothing);
  });

  testWidgets('shows placeholders while the rows load', (tester) async {
    final repo = _WorldRepository([const Ok(_rows)])
      ..holdUntil = Completer<void>();
    await _pumpScreen(tester, repo);
    await tester.pump();

    expect(find.byKey(const Key('world-loading')), findsOneWidget);

    repo.holdUntil!.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('world-loading')), findsNothing);
    expect(find.text('For you'), findsOneWidget);
  });

  testWidgets('offline says so and Retry loads the rows', (tester) async {
    final repo = _WorldRepository([_offline, const Ok(_rows)]);
    await _pumpScreen(tester, repo);
    await tester.pumpAndSettle();

    expect(find.text("You're offline"), findsOneWidget);
    expect(find.text(_offlineMessage), findsOneWidget);
    expect(find.text('For you'), findsNothing);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('For you'), findsOneWidget);
    expect(find.text(_offlineMessage), findsNothing);
    expect(repo.recommendationCalls, 2);
  });

  testWidgets('a server failure shows its message with Retry',
      (tester) async {
    final repo = _WorldRepository([
      const Err(
        ApiError(statusCode: 500, code: 'boom', message: 'The server broke.'),
      ),
    ]);
    await _pumpScreen(tester, repo);
    await tester.pumpAndSettle();

    expect(find.text('The server broke.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text("You're offline"), findsNothing);
  });

  testWidgets('no reading history is an empty state with somewhere to go',
      (tester) async {
    final repo = _WorldRepository([const Ok(WorldRecommendations())]);
    await _pumpScreen(tester, repo);
    await tester.pumpAndSettle();

    expect(find.text('Read or follow a few series first'), findsOneWidget);
    // PrimaryPillButton uppercases its label.
    expect(find.text('BROWSE SOURCES'), findsOneWidget);
  });

  testWidgets('an unreachable catalog is a quiet notice, not an empty state',
      (tester) async {
    const reason = 'AniList could not be reached. Showing what we have.';
    final repo = _WorldRepository([
      const Ok(WorldRecommendations(unavailableReason: reason)),
    ]);
    await _pumpScreen(tester, repo);
    await tester.pumpAndSettle();

    expect(find.text(reason), findsOneWidget);
    expect(find.text('Read or follow a few series first'), findsNothing);
  });

  testWidgets('the notice sits above whatever did load', (tester) async {
    const reason = 'AniList is slow right now.';
    final repo = _WorldRepository([
      const Ok(
        WorldRecommendations(
          forYou: [WorldItem(title: 'Nano Machine')],
          unavailableReason: reason,
        ),
      ),
    ]);
    await _pumpScreen(tester, repo);
    await tester.pumpAndSettle();

    expect(find.text(reason), findsOneWidget);
    expect(find.text('Nano Machine'), findsOneWidget);
  });

  testWidgets('pull-to-refresh reloads rows and availability, never suggests',
      (tester) async {
    final repo = _WorldRepository([_offline, const Ok(_rows)]);
    await tester.pumpWidget(await _wrap(repo));
    await tester.pumpAndSettle();
    expect(find.text(_offlineMessage), findsOneWidget);
    final availabilityBefore = repo.availabilityCalls;

    await tester.fling(
      find.byType(ListView),
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();

    expect(find.text('For you'), findsOneWidget);
    expect(repo.recommendationCalls, 2);
    expect(repo.availabilityCalls, greaterThan(availabilityBefore));
    expect(repo.suggestCalls, 0);
  });
}
