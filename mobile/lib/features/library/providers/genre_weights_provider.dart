import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/sources/models/source_genre.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

/// The one genre-weights client of the app: `GET /library/recommendations`.
/// Sorted by weight (highest first, ties alphabetical); `[]` on an empty answer
/// or an error. Kept alive for 10 minutes after the last listener.
final genreWeightsProvider = FutureProvider.autoDispose
    .family<List<GenreWeight>, int>((ref, limit) async {
  final link = ref.keepAlive();
  Timer? timer;
  ref.onCancel(() => timer = Timer(const Duration(minutes: 10), link.close));
  ref.onResume(() => timer?.cancel());
  ref.onDispose(() => timer?.cancel());

  final result =
      await ref.watch(libraryRepositoryProvider).genreWeights(limit: limit);
  if (result.isErr) return const [];
  return [...result.value]..sort((a, b) {
      final c = b.weight.compareTo(a.weight);
      return c != 0
          ? c
          : a.genre.toLowerCase().compareTo(b.genre.toLowerCase());
    });
});
