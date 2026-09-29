import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/providers/series_detail_provider.dart';
import 'package:manhwamaniacs/features/library/utils/series_identity.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_states.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_view.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

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

/// `/library/:followedId`: the same [FeatureView], located by follow id (cinematic 8.0.10). The
/// follow cache answers at once when it holds the row; otherwise [seriesDetailProvider] resolves
/// it (server first, then the device), with the feature galley while it loads. A series that is
/// gone, unknown or hidden by the 18+ gate is `NOT IN THIS ISSUE`; any other failure is a
/// `CORRECTION` with `Try again`.
class FeatureByFollowScreen extends ConsumerWidget {
  const FeatureByFollowScreen({super.key, required this.followedId});
  final int followedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cached = ref.watch(updatesProvider.select((s) => s.valueOrNull?.followed));
    for (final f in cached ?? const <FollowedSeries>[]) {
      if (f.id == followedId) return FeatureView(sourceId: f.sourceId, seriesKey: f.seriesKey, followed: f);
    }
    return ref.watch(seriesDetailProvider(followedId)).when(
          loading: () => const FeatureGalley(),
          data: (v) => FeatureView(sourceId: v.series.sourceId, seriesKey: v.series.seriesKey, followed: v.series),
          error: (e, _) {
            if (e is ApiError && (e.statusCode == 404 || e.code == 'series_not_found')) return const FeatureNotAvailable();
            return FeatureNotice(
              kicker: 'CORRECTION',
              correction: true,
              headline: "Couldn't load this series.",
              primaryLabel: 'Try again',
              onPrimary: () => ref.invalidate(seriesDetailProvider(followedId)),
              quietLabel: 'Back to library',
              onQuiet: () => context.go(Routes.library()),
            );
          },
        );
  }
}
