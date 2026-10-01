import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/features/library/models/reading_history_item.dart';
import 'package:manhwamaniacs/features/library/models/suggestion.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/library/repositories/ask_repository.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

final statisticsProvider = FutureProvider.autoDispose<LibraryStatistics>((ref) async {
  final repo = ref.watch(libraryRepositoryProvider);
  final result = await repo.statistics();
  if (result.isErr) throw result.error;
  return result.value;
});

/// "For you" and the "Because you read …" rows, from the worldwide catalog.
///
/// Profile-scoped and 18+-gated on the server (which sources a title is "on"
/// depends on both), so it sits in the profile and mature invalidator lists
/// under this name — the genre list it replaced was wired in there already.
final recommendationsProvider =
    FutureProvider.autoDispose<WorldRecommendations>((ref) async {
  final repo = ref.watch(libraryRepositoryProvider);
  final result = await repo.worldRecommendations();
  if (result.isErr) throw result.error;
  return result.value;
});

final readingHistoryProvider =
    FutureProvider.autoDispose<List<ReadingHistoryItem>>((ref) async {
  final repo = ref.watch(libraryRepositoryProvider);
  final result = await repo.readingHistory();
  if (result.isErr) throw result.error;
  return result.value;
});

/// Whether the AI suggestion box should be shown at all.
///
/// Free on the server — it reads a config flag and a counter, no network, no
/// spend — so it is safe to fire on mount, unlike the suggestion itself.
final suggestAvailabilityProvider =
    FutureProvider.autoDispose<SuggestionAvailability>((ref) async {
  final repo = ref.watch(libraryRepositoryProvider);
  final result = await repo.suggestAvailability();
  if (result.isErr) throw result.error;
  return result.value;
});

/// The AI suggestions (worldwide titles) for the last description the reader
/// submitted.
///
/// A notifier with an explicit [SuggestionsNotifier.submit], deliberately NOT
/// a `FutureProvider`: every rebuild of one of those would be another paid API
/// request, and a pull-to-refresh would be a second. It starts empty and only
/// ever runs when somebody presses the button.
final suggestionsProvider =
    AsyncNotifierProvider.autoDispose<SuggestionsNotifier, WorldSuggestResponse?>(
  SuggestionsNotifier.new,
);

class SuggestionsNotifier extends AutoDisposeAsyncNotifier<WorldSuggestResponse?> {
  /// Guards against a slow first answer overwriting a faster second one.
  int _requestId = 0;

  /// This request is the longest-running one in the app — the model reasons
  /// before it answers, so a submit can sit in flight for well over a minute.
  /// `autoDispose` tears the notifier down the moment its one listener (the
  /// Recommendations screen) unmounts, or the 18+ toggle invalidates it
  /// mid-flight, and `_requestId` alone only catches a stale RESPONSE, not a
  /// notifier that is simply gone. Riverpod has no `ref.mounted` here, so this
  /// is the same guard `bookmarks_provider.dart` carries for the same reason.
  bool _disposed = false;

  @override
  Future<WorldSuggestResponse?> build() async {
    ref.onDispose(() => _disposed = true);
    return null;
  }

  Future<void> submit(String prompt) async {
    final trimmed = prompt.trim();
    if (trimmed.length < 3) return;
    final id = ++_requestId;
    state = const AsyncValue<WorldSuggestResponse?>.loading();
    final result = await ref.read(libraryRepositoryProvider).worldSuggest(trimmed);
    if (_disposed || id != _requestId) return;
    if (result.isErr) {
      state = AsyncValue<WorldSuggestResponse?>.error(
        result.error,
        StackTrace.current,
      );
      return;
    }
    state = AsyncValue<WorldSuggestResponse?>.data(result.value);
    // The allowance just moved, and the box shows what is left of it.
    ref.invalidate(suggestAvailabilityProvider);
  }

  void clear() {
    _requestId++;
    state = const AsyncValue<WorldSuggestResponse?>.data(null);
  }
}

/// The same box answered from the reader's own sources (`POST /library/suggest`): shelf rows for
/// the last description submitted. Shaped like [suggestionsProvider]: only an explicit
/// [LocalSuggestionsNotifier.submit] spends a request.
final localSuggestionsProvider =
    AsyncNotifierProvider.autoDispose<LocalSuggestionsNotifier, WorldSuggestResponse?>(
  LocalSuggestionsNotifier.new,
);

class LocalSuggestionsNotifier extends AutoDisposeAsyncNotifier<WorldSuggestResponse?> {
  int _requestId = 0;
  bool _disposed = false;

  @override
  Future<WorldSuggestResponse?> build() async {
    ref.onDispose(() => _disposed = true);
    return null;
  }

  /// A newer submit supersedes an older one: its answer is dropped when it lands.
  Future<void> submit(String prompt) async {
    final trimmed = prompt.trim();
    if (trimmed.length < 3) return;
    final id = ++_requestId;
    state = const AsyncValue<WorldSuggestResponse?>.loading();
    final result = await ref.read(libraryRepositoryProvider).localSuggest(trimmed);
    if (_disposed || id != _requestId) return;
    if (result.isErr) {
      state = AsyncValue<WorldSuggestResponse?>.error(result.error, StackTrace.current);
      return;
    }
    state = AsyncValue<WorldSuggestResponse?>.data(result.value);
    ref.invalidate(suggestAvailabilityProvider);
  }

  void clear() {
    _requestId++;
    state = const AsyncValue<WorldSuggestResponse?>.data(null);
  }
}

/// The Ask box's calls (glass 9.1.2).
final askRepositoryProvider = Provider<AskRepository>((ref) => AskRepository(ref.watch(dioProvider)), name: 'askRepository');

/// `GET /library/world/recommendations?genre=` for one genre (null: none). Same invalidator slot as [recommendationsProvider].
final worldRecommendationsProvider = FutureProvider.autoDispose.family<WorldRecommendations, String?>((ref, genre) async {
  final result = await ref.watch(askRepositoryProvider).worldRecommendations(genre: genre);
  if (result.isErr) throw result.error;
  return result.value;
}, name: 'worldRecommendations',);
