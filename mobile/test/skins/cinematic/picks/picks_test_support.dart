import 'dart:async';

import 'package:dio/dio.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/ai/repositories/ai_repository.dart';
import 'package:manhwamaniacs/features/library/models/suggestion.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/library/repositories/library_repository.dart';
import 'package:manhwamaniacs/features/sources/models/source_genre.dart';

WorldItem world(String title, {int id = 1, List<WorldAvailability> on = const [], String? why, bool adult = false}) => WorldItem(
      title: title,
      anilistId: id,
      format: 'Manhwa',
      status: 'Ongoing',
      rating: 8.4,
      why: why,
      isAdult: adult,
      available: on,
    );

const asura = WorldAvailability(sourceId: 'asura', sourceName: 'Asura', seriesKey: 'k1');

class PicksLibrary implements LibraryRepository {
  PicksLibrary({
    WorldRecommendations? recs,
    this.recsError,
    this.availability = const SuggestionAvailability(available: true, reason: 'ok', remainingToday: 8),
    this.genres = const [],
  }) : recs = recs ?? WorldRecommendations(forYou: [world('Lantern Courier', on: const [asura]), world('Salt and Ember', id: 2)]);

  final WorldRecommendations recs;
  final AppError? recsError;
  final SuggestionAvailability availability;
  final List<GenreWeight> genres;

  /// What the next ask answers; a completer makes it wait.
  Completer<Result<WorldSuggestResponse>>? gate;
  Result<WorldSuggestResponse> answer = Ok(WorldSuggestResponse(items: [world('Night Ward', id: 9, why: 'Slow and political.')], remainingToday: 7));
  int worldAsks = 0, localAsks = 0, recCalls = 0;

  /// The token of every world ask, in order.
  final worldTokens = <CancelToken?>[];

  @override
  Future<Result<WorldRecommendations>> worldRecommendations({int seeds = 5, int perSeed = 10}) async {
    recCalls++;
    return recsError != null ? Err(recsError!) : Ok(recs);
  }

  @override
  Future<Result<SuggestionAvailability>> suggestAvailability() async => Ok(availability);

  @override
  Future<Result<List<GenreWeight>>> genreWeights({int limit = 40}) async => Ok(genres);

  Future<Result<WorldSuggestResponse>> _ask() => gate?.future ?? Future.value(answer);

  @override
  Future<Result<WorldSuggestResponse>> worldSuggest(String prompt, {int limit = 12, CancelToken? cancelToken}) {
    worldAsks++;
    worldTokens.add(cancelToken);
    return _ask();
  }

  @override
  Future<Result<WorldSuggestResponse>> localSuggest(String prompt, {int limit = 6}) {
    localAsks++;
    return _ask();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName} is not used here');
}

/// Records `POST /ai/feedback` calls instead of sending them.
class FakeAi extends AiRepository {
  FakeAi() : super(Dio());
  final sent = <Map<String, Object?>>[];

  @override
  Future<Result<void>> sendFeedback({required String signal, int? anilistId, String? sourceId, String? seriesKey, String? tag}) async {
    sent.add({'signal': signal, 'anilist_id': anilistId, 'source_id': sourceId, 'series_key': seriesKey, 'tag': tag});
    return const Ok(null);
  }
}
