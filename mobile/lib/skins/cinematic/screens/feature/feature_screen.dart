import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/utils/series_identity.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_states.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_view.dart';

/// `/sources/:sourceId/series/:seriesKey`. Finds the follow row by series
/// identity and renders the shared [FeatureView].
class FeatureScreen extends ConsumerWidget {
  const FeatureScreen({super.key, required this.sourceId, required this.seriesKey, this.chapter});

  final String sourceId;
  final String seriesKey;
  final String? chapter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followed = ref.watch(updatesProvider.select((s) => s.valueOrNull?.followed));
    final id = seriesIdentityOf(sourceId, seriesKey);
    FollowedSeries? row;
    for (final f in followed ?? const <FollowedSeries>[]) {
      if (f.sourceId == sourceId && followIdentity(f) == id) row = f;
    }
    return FeatureView(
        sourceId: sourceId, seriesKey: seriesKey, followed: row, focusChapter: chapter,);
  }
}

/// `/library/:followedId`: the same [FeatureView], located by follow id.
class FeatureByFollowScreen extends ConsumerWidget {
  const FeatureByFollowScreen({super.key, required this.followedId});
  final int followedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updatesProvider);
    if (state.isLoading && state.valueOrNull == null) return const FeatureGalley();
    FollowedSeries? row;
    for (final f in state.valueOrNull?.followed ?? const <FollowedSeries>[]) {
      if (f.id == followedId) row = f;
    }
    if (row == null) return const FeatureNotAvailable();
    return FeatureView(sourceId: row.sourceId, seriesKey: row.seriesKey, followed: row);
  }
}
