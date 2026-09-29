import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/ai/repositories/ai_repository.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

final aiRepositoryProvider = Provider<AiRepository>(
  (ref) => AiRepository(ref.watch(dioProvider)),
  name: 'aiRepository',
);

final suggestedTagsProvider =
    FutureProvider.autoDispose.family<SuggestedTags, ({String sourceId, String seriesKey})>(
  (ref, k) => ref.watch(aiRepositoryProvider).suggestedTags(k.sourceId, k.seriesKey),
);

Future<void> rejectSuggestedTag(
  WidgetRef ref,
  String sourceId,
  String seriesKey,
  String tag,
) =>
    ref.read(aiRepositoryProvider).rejectSuggestedTag(sourceId, seriesKey, tag);
