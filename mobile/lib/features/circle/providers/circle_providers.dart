import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/repositories/circle_repository.dart';
import 'package:manhwamaniacs/features/circle/repositories/circle_repository_impl.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

final circleRepositoryProvider = Provider<CircleRepository>((ref) => CircleRepositoryImpl(ref.watch(dioProvider)), name: 'circleRepository');

typedef CircleSeriesKey = ({String sourceId, String seriesKey});

/// The Circle's readers and reactions for one series. `null` means the Circle is not deployed
/// (404): the reader removes the tab. An error throws, for the tab's `CORRECTION` line.
final circleSeriesProvider = FutureProvider.autoDispose.family<CircleSeriesData?, CircleSeriesKey>((ref, key) async {
  final r = await ref.watch(circleRepositoryProvider).series(sourceId: key.sourceId, seriesKey: key.seriesKey);
  if (r.isErr) throw r.error;
  return r.value;
}, name: 'circleSeries',);
