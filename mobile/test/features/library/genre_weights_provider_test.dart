import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/library/providers/genre_weights_provider.dart';
import 'package:manhwamaniacs/features/library/repositories/library_repository.dart';
import 'package:manhwamaniacs/features/sources/models/source_genre.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

class _Repo implements LibraryRepository {
  @override
  Future<Result<WorldSuggestResponse>> localSuggest(String prompt, {int limit = 6}) => throw UnimplementedError();

  _Repo(this.result);

  final Result<List<GenreWeight>> result;
  final limits = <int>[];

  @override
  Future<Result<List<GenreWeight>>> genreWeights({int limit = 40}) async {
    limits.add(limit);
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('requests the limit and sorts by weight, ties alphabetical', () async {
    final repo = _Repo(const Ok([
      GenreWeight(genre: 'b', weight: 0.5),
      GenreWeight(genre: 'a', weight: 0.5),
      GenreWeight(genre: 'z', weight: 0.9),
    ]),);
    final c = ProviderContainer(
        overrides: [libraryRepositoryProvider.overrideWithValue(repo)],);
    addTearDown(c.dispose);
    final out = await c.read(genreWeightsProvider(8).future);
    expect(out.map((e) => e.genre), ['z', 'a', 'b']);
    expect(repo.limits, [8]);
  });

  test('an error resolves to an empty list', () async {
    final repo = _Repo(const Err(UnknownError(message: 'x')));
    final c = ProviderContainer(
        overrides: [libraryRepositoryProvider.overrideWithValue(repo)],);
    addTearDown(c.dispose);
    expect(await c.read(genreWeightsProvider(40).future), isEmpty);
  });
}
