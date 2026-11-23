import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/features/updates/repositories/updates_repository.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

/// "Check for new chapters" on a series page: runs the check for [followedId] and, when it found
/// any, refetches the follow cache and the page's own chapter list ([sourceId]/[seriesKey], the key
/// the page was opened with). Returns how many new chapters it found.
Future<Result<int>> checkSeriesForNew(WidgetRef ref, {required int followedId, required String sourceId, required String seriesKey}) {
  final repo = ref.read(updatesRepositoryProvider);
  return _check(repo, followedId, () {
    ref.invalidate(updatesProvider);
    ref.invalidate(sourceSeriesDetailProvider((sourceId: sourceId, seriesId: seriesKey)));
  });
}

/// The same check for a caller that may leave its screen while it runs (the check takes seconds): a
/// [WidgetRef] throws once its widget is disposed, a container does not.
Future<Result<int>> checkSeriesForNewIn(ProviderContainer container, {required int followedId, required String sourceId, required String seriesKey}) {
  final repo = container.read(updatesRepositoryProvider);
  return _check(repo, followedId, () {
    container.invalidate(updatesProvider);
    container.invalidate(sourceSeriesDetailProvider((sourceId: sourceId, seriesId: seriesKey)));
  });
}

Future<Result<int>> _check(UpdatesRepository repo, int followedId, void Function() refetch) async {
  final r = await repo.checkFollowed(followedId);
  if (r.isErr) return Err(r.error);
  final n = r.value.newChaptersFound;
  if (n > 0) refetch();
  return Ok(n);
}
